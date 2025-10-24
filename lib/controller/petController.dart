import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_loc/models/pet.dart';
import '../models/pet.dart';

class PetController with ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;

  // Getters
  List<PetModel> get pets => _pets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;

  // Inicializar controller
  PetController() {
    _loadPets();
  }

  // Carregar todos os pets
  Future<void> _loadPets() async {
    try {
      _setLoading(true);
      
      // Usando Realtime Database (conforme seus códigos)
      final snapshot = await _database.child('pets').get();
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> petsMap = snapshot.value as Map<dynamic, dynamic>;
        _pets = petsMap.entries.map((entry) {
          return PetModel.fromRTDB(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key as String,
          );
        }).toList();
      } else {
        _pets = [];
      }
      
      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao carregar pets: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Stream de pets para atualização em tempo real
  Stream<List<PetModel>> get petsStream {
    return _database.child('pets').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data == null) return [];
      
      return data.entries.map((entry) {
        return PetModel.fromRTDB(
          Map<String, dynamic>.from(entry.value as Map),
          entry.key as String,
        );
      }).toList();
    });
  }

  // Cadastrar novo pet
  Future<bool> cadastrarPet({
    required String nome,
    required String descricao,
    required String contato,
    String? userId,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      String? imagemBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imagemBase64 = base64Encode(bytes);
      }

      final novoPetRef = _database.child('pets').push();
      final petId = novoPetRef.key!;

      final pet = PetModel(
        id: petId,
        nome: nome,
        descricao: descricao,
        contato: contato,
        imagemBase64: imagemBase64,
        userId: userId,
      );

      await novoPetRef.set(pet.toRTDB());

      // Também salvar no Firestore para consistência
      await _firestore.collection('pets').doc(petId).set(pet.toFirestore());

      _pets.add(pet);
      _clearImage();
      _setLoading(false);
      
      return true;
    } catch (e) {
      _error = 'Erro ao cadastrar pet: $e';
      _setLoading(false);
      return false;
    }
  }

  // Editar pet
  Future<bool> editarPet({
    required String petId,
    required String nome,
    required String descricao,
    required String contato,
    File? novaImagem,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      String? imagemBase64;
      if (novaImagem != null) {
        final bytes = await novaImagem.readAsBytes();
        imagemBase64 = base64Encode(bytes);
      }

      // Buscar pet atual para manter a imagem existente se não houver nova
      final petIndex = _pets.indexWhere((pet) => pet.id == petId);
      if (petIndex == -1) {
        _error = 'Pet não encontrado';
        _setLoading(false);
        return false;
      }

      final petAtual = _pets[petIndex];
      final imagemParaSalvar = imagemBase64 ?? petAtual.imagemBase64;

      await _database.child('pets').child(petId).update({
        'nome': nome,
        'descricao': descricao,
        'contato': contato,
        'imagemBase64': imagemParaSalvar ?? '',
      });

      // Atualizar no Firestore também
      await _firestore.collection('pets').doc(petId).update({
        'nome': nome,
        'descricao': descricao,
        'contato': contato,
        'imagemBase64': imagemParaSalvar ?? '',
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      // Atualizar lista local
      _pets[petIndex] = petAtual.copyWith(
        nome: nome,
        descricao: descricao,
        contato: contato,
        imagemBase64: imagemParaSalvar,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao editar pet: $e';
      _setLoading(false);
      return false;
    }
  }

  // Deletar pet
  Future<bool> deletarPet(String petId) async {
    try {
      _setLoading(true);
      _error = null;

      await _database.child('pets').child(petId).remove();
      await _firestore.collection('pets').doc(petId).delete();

      _pets.removeWhere((pet) => pet.id == petId);
      _setLoading(false);
      
      return true;
    } catch (e) {
      _error = 'Erro ao deletar pet: $e';
      _setLoading(false);
      return false;
    }
  }

  // Buscar pet por ID
  PetModel? getPetById(String petId) {
    try {
      return _pets.firstWhere((pet) => pet.id == petId);
    } catch (e) {
      return null;
    }
  }

  // Selecionar imagem da galeria
  Future<void> selecionarImagem() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao selecionar imagem: $e';
      notifyListeners();
    }
  }

  // Tirar foto com câmera
  Future<void> tirarFoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao tirar foto: $e';
      notifyListeners();
    }
  }

  // Limpar imagem selecionada
  void _clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // Buscar pets por nome
  List<PetModel> buscarPets(String query) {
    if (query.isEmpty) return _pets;
    
    return _pets.where((pet) {
      return pet.nome.toLowerCase().contains(query.toLowerCase()) ||
             pet.descricao.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Buscar pets do usuário atual
  List<PetModel> getPetsDoUsuario(String? userId) {
    if (userId == null) return [];
    
    return _pets.where((pet) => pet.userId == userId).toList();
  }

  // Controlar estado de loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Limpar erros
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Forçar recarregamento
  Future<void> refresh() async {
    await _loadPets();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
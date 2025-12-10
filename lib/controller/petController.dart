import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_loc/models/pet_model.dart';

class PetController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;

  List<PetModel> get pets => _pets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;

  PetController() {
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      _setLoading(true);
      _error = null;
      
      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _setLoading(false);
        notifyListeners();
        return;
      }
      
      final querySnapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: usuarioAtual.uid)
          .orderBy('criadoEm', descending: true)
          .get();
      
      _pets = querySnapshot.docs.map((doc) {
        return PetModel.fromFirestore(doc);
      }).toList();
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar pets: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  Stream<List<PetModel>> get petsStream {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('pets')
        .where('userId', isEqualTo: usuarioAtual.uid)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PetModel.fromFirestore(doc);
      }).toList();
    });
  }

  Future<String?> cadastrarPet({
    required String nome,
    required String descricao,
    required String contato,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        _setLoading(false);
        notifyListeners();
        return null;
      }

      String? imagemBase64;
      if (_selectedImage != null) {
        try {
          final bytes = await _selectedImage!.readAsBytes();
          if (bytes.length > 5 * 1024 * 1024) {
            _error = 'Imagem muito grande (máximo 5MB)';
            _setLoading(false);
            notifyListeners();
            return null;
          }
          imagemBase64 = base64Encode(bytes);
        } catch (e) {}
      }

      final petData = {
        'nome': nome,
        'descricao': descricao,
        'contato': contato,
        'imagemBase64': imagemBase64 ?? '',
        'userId': usuarioAtual.uid,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('pets').add(petData);
      final petId = docRef.id;

      final novoPet = PetModel(
        id: petId,
        nome: nome,
        descricao: descricao,
        contato: contato,
        imagemBase64: imagemBase64,
        userId: usuarioAtual.uid,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      _pets.insert(0, novoPet);
      _clearImage();
      _setLoading(false);
      notifyListeners();
      
      return petId;
    } catch (e) {
      _error = 'Erro ao cadastrar pet: $e';
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

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

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final petIndex = _pets.indexWhere((pet) => pet.id == petId);
      if (petIndex == -1) {
        _error = 'Pet não encontrado';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final petAtual = _pets[petIndex];
      if (petAtual.userId != usuarioAtual.uid) {
        _error = 'Você só pode editar seus próprios pets';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      String? imagemBase64;
      if (novaImagem != null) {
        try {
          final bytes = await novaImagem.readAsBytes();
          if (bytes.length > 5 * 1024 * 1024) {
            _error = 'Imagem muito grande (máximo 5MB)';
            _setLoading(false);
            notifyListeners();
            return false;
          }
          imagemBase64 = base64Encode(bytes);
        } catch (e) {}
      }

      final imagemParaSalvar = imagemBase64 ?? petAtual.imagemBase64;

      await _firestore.collection('pets').doc(petId).update({
        'nome': nome,
        'descricao': descricao,
        'contato': contato,
        'imagemBase64': imagemParaSalvar ?? '',
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      _pets[petIndex] = petAtual.copyWith(
        nome: nome,
        descricao: descricao,
        contato: contato,
        imagemBase64: imagemParaSalvar,
        atualizadoEm: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao editar pet: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletarPet(String petId) async {
    try {
      _setLoading(true);
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        _setLoading(false);
        return false;
      }

      final pet = _pets.firstWhere((p) => p.id == petId);
      if (pet.userId != usuarioAtual.uid) {
        _error = 'Você só pode deletar seus próprios pets';
        _setLoading(false);
        return false;
      }

      await _firestore.collection('pets').doc(petId).delete();
      _pets.removeWhere((pet) => pet.id == petId);
      _setLoading(false);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Erro ao deletar pet: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  PetModel? getPetById(String petId) {
    try {
      return _pets.firstWhere((pet) => pet.id == petId);
    } catch (e) {
      return null;
    }
  }

  bool isPetDoUsuario(String petId) {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return false;
    
    try {
      final pet = _pets.firstWhere((p) => p.id == petId);
      return pet.userId == usuarioAtual.uid;
    } catch (e) {
      return false;
    }
  }

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

  void removerImagemSelecionada() {
    _selectedImage = null;
    notifyListeners();
  }

  void _clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  List<PetModel> buscarPets(String query) {
    if (query.isEmpty) return _pets;
    
    return _pets.where((pet) {
      return pet.nome.toLowerCase().contains(query.toLowerCase()) ||
             pet.descricao.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<PetModel> getPetsDoUsuario() {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return [];
    
    return _pets.where((pet) => pet.userId == usuarioAtual.uid).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadPets();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
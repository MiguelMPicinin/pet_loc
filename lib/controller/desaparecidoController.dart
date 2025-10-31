import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/desaparecidos_model.dart';

class DesaparecidosController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  List<DesaparecidoModel> _desaparecidos = [];
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;

  // Getters
  List<DesaparecidoModel> get desaparecidos => _desaparecidos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;

  List<DesaparecidoModel> get desaparecidosAtivos =>
      _desaparecidos.where((d) => !d.encontrado).toList();

  List<DesaparecidoModel> get desaparecidosEncontrados =>
      _desaparecidos.where((d) => d.encontrado).toList();

  // Inicializar controller
  DesaparecidosController() {
    _loadDesaparecidos();
  }

  // Carregar todos os desaparecidos
  Future<void> _loadDesaparecidos() async {
    try {
      _setLoading(true);
      
      final snapshot = await _firestore
          .collection('desaparecidos')
          .orderBy('criadoEm', descending: true)
          .get();
      
      _desaparecidos = snapshot.docs
          .map((doc) => DesaparecidoModel.fromFirestore(doc))
          .toList();
      
      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao carregar desaparecidos: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Stream de desaparecidos para atualização em tempo real
  Stream<List<DesaparecidoModel>> get desaparecidosStream {
    return _firestore
        .collection('desaparecidos')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DesaparecidoModel.fromFirestore(doc))
            .toList());
  }

  // Cadastrar novo desaparecido
  Future<bool> cadastrarDesaparecido({
    required String nome,
    required String descricao,
    required String contato,
    String? userId,
    DateTime? desaparecidoEm,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      // Validar campos obrigatórios
      if (nome.isEmpty || descricao.isEmpty || contato.isEmpty) {
        _error = 'Preencha todos os campos obrigatórios';
        _setLoading(false);
        return false;
      }

      String? imagemBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imagemBase64 = base64Encode(bytes);
      }

      final desaparecido = DesaparecidoModel(
        nome: nome.trim(),
        descricao: descricao.trim(),
        contato: contato.trim(),
        imagemBase64: imagemBase64,
        userId: userId,
        desaparecidoEm: desaparecidoEm,
      );

      final docRef = await _firestore
          .collection('desaparecidos')
          .add(desaparecido.toFirestore());

      // Adicionar à lista local com o ID gerado
      _desaparecidos.insert(0, desaparecido.copyWith(id: docRef.id));
      _clearImage();
      _setLoading(false);
      
      return true;
    } catch (e) {
      _error = 'Erro ao cadastrar desaparecido: $e';
      _setLoading(false);
      return false;
    }
  }

  // Editar desaparecido
  Future<bool> editarDesaparecido({
    required String desaparecidoId,
    required String nome,
    required String descricao,
    required String contato,
    File? novaImagem,
    bool? encontrado,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      String? imagemBase64;
      if (novaImagem != null) {
        final bytes = await novaImagem.readAsBytes();
        imagemBase64 = base64Encode(bytes);
      }

      // Buscar desaparecido atual
      final desaparecidoIndex = _desaparecidos.indexWhere((d) => d.id == desaparecidoId);
      if (desaparecidoIndex == -1) {
        _error = 'Desaparecido não encontrado';
        _setLoading(false);
        return false;
      }

      final desaparecidoAtual = _desaparecidos[desaparecidoIndex];
      final imagemParaSalvar = imagemBase64 ?? desaparecidoAtual.imagemBase64;

      final updateData = {
        'nome': nome,
        'descricao': descricao,
        'contato': contato,
        'imagemBase64': imagemParaSalvar ?? '',
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      // Adicionar campo encontrado se fornecido
      if (encontrado != null) {
        updateData['encontrado'] = encontrado;
      }

      await _firestore
          .collection('desaparecidos')
          .doc(desaparecidoId)
          .update(updateData);

      // Atualizar lista local
      _desaparecidos[desaparecidoIndex] = desaparecidoAtual.copyWith(
        nome: nome,
        descricao: descricao,
        contato: contato,
        imagemBase64: imagemParaSalvar,
        encontrado: encontrado ?? desaparecidoAtual.encontrado,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao editar desaparecido: $e';
      _setLoading(false);
      return false;
    }
  }

  // Marcar como encontrado
  Future<bool> marcarComoEncontrado(String desaparecidoId) async {
    try {
      await _firestore
          .collection('desaparecidos')
          .doc(desaparecidoId)
          .update({
            'encontrado': true,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

      // Atualizar lista local
      final index = _desaparecidos.indexWhere((d) => d.id == desaparecidoId);
      if (index != -1) {
        _desaparecidos[index] = _desaparecidos[index].copyWith(encontrado: true);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Erro ao marcar como encontrado: $e';
      notifyListeners();
      return false;
    }
  }

  // Deletar desaparecido
  Future<bool> deletarDesaparecido(String desaparecidoId) async {
    try {
      _setLoading(true);
      _error = null;

      await _firestore
          .collection('desaparecidos')
          .doc(desaparecidoId)
          .delete();

      _desaparecidos.removeWhere((d) => d.id == desaparecidoId);
      _setLoading(false);
      
      return true;
    } catch (e) {
      _error = 'Erro ao deletar desaparecido: $e';
      _setLoading(false);
      return false;
    }
  }

  // Buscar desaparecido por ID
  DesaparecidoModel? getDesaparecidoById(String desaparecidoId) {
    try {
      return _desaparecidos.firstWhere((d) => d.id == desaparecidoId);
    } catch (e) {
      return null;
    }
  }

  // Buscar desaparecidos por nome ou descrição
  List<DesaparecidoModel> buscarDesaparecidos(String query) {
    if (query.isEmpty) return _desaparecidos;
    
    return _desaparecidos.where((desaparecido) {
      return desaparecido.nome.toLowerCase().contains(query.toLowerCase()) ||
             desaparecido.descricao.toLowerCase().contains(query.toLowerCase()) ||
             desaparecido.contato.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Buscar desaparecidos do usuário atual
  List<DesaparecidoModel> getDesaparecidosDoUsuario(String? userId) {
    if (userId == null) return [];
    
    return _desaparecidos.where((d) => d.userId == userId).toList();
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

  // Remover imagem selecionada
  void removerImagemSelecionada() {
    _selectedImage = null;
    notifyListeners();
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
    await _loadDesaparecidos();
  }

  // Estatísticas
  Map<String, int> get estatisticas {
    final ativos = desaparecidosAtivos.length;
    final encontrados = desaparecidosEncontrados.length;
    final total = _desaparecidos.length;

    return {
      'ativos': ativos,
      'encontrados': encontrados,
      'total': total,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
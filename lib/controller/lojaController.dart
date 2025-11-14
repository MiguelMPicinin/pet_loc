import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/produto_model.dart';

class LojaController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  List<ProdutoModel> _produtos = [];
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;

  // Getters
  List<ProdutoModel> get produtos => _produtos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;

  List<ProdutoModel> get produtosAtivos => _produtos.where((p) => p.ativo).toList();

  // Inicializar controller
  LojaController() {
    _loadProdutos();
  }

  // Carregar produtos
  Future<void> _loadProdutos() async {
    try {
      _setLoading(true);
      _error = null;
      
      print('🔄 Carregando produtos do Firestore...');
      
      final snapshot = await _firestore
          .collection('produtos_loja')
          .where('ativo', isEqualTo: true)
          .orderBy('criadoEm', descending: true)
          .get();
      
      print('✅ ${snapshot.docs.length} produtos encontrados');
      
      _produtos = snapshot.docs
          .map((doc) => ProdutoModel.fromFirestore(doc))
          .toList();
      
      _setLoading(false);
    } catch (e) {
      print('❌ Erro ao carregar produtos: $e');
      _error = 'Erro ao carregar produtos: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Stream de produtos para atualização em tempo real
  Stream<List<ProdutoModel>> get produtosStream {
    return _firestore
        .collection('produtos_loja')
        .where('ativo', isEqualTo: true)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProdutoModel.fromFirestore(doc))
            .toList());
  }

  // Cadastrar novo produto
  Future<bool> cadastrarProduto({
    required String nome,
    required String descricao,
    required String preco,
    required String contato,
    int? estoque,
    String? categoria,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        _setLoading(false);
        return false;
      }

      // Validar campos obrigatórios
      if (nome.isEmpty || descricao.isEmpty || preco.isEmpty || contato.isEmpty) {
        _error = 'Preencha todos os campos obrigatórios';
        _setLoading(false);
        return false;
      }

      // Validar preço
      try {
        double.parse(preco.replaceAll(',', '.'));
      } catch (e) {
        _error = 'Preço inválido';
        _setLoading(false);
        return false;
      }

      String? imagemBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imagemBase64 = base64Encode(bytes);
      }

      final produto = ProdutoModel(
        nome: nome.trim(),
        descricao: descricao.trim(),
        preco: preco.trim(),
        contato: contato.trim(),
        imagemBase64: imagemBase64,
        userId: usuarioAtual.uid,
        estoque: estoque,
        categoria: categoria ?? 'Geral', // ADICIONE CATEGORIA
      );

      print('💾 Salvando produto no Firestore...');
      final docRef = await _firestore
          .collection('produtos_loja')
          .add(produto.toFirestore());

      print('✅ Produto salvo com ID: ${docRef.id}');

      // Adicionar à lista local com o ID gerado
      _produtos.insert(0, produto.copyWith(id: docRef.id));

      _clearImage();
      _setLoading(false);
      
      return true;
    } catch (e) {
      print('❌ Erro ao cadastrar produto: $e');
      _error = 'Erro ao cadastrar produto: $e';
      _setLoading(false);
      return false;
    }
  }

  // Editar produto
  Future<bool> editarProduto({
    required String produtoId,
    required String nome,
    required String descricao,
    required String preco,
    required String contato,
    File? novaImagem,
    int? estoque,
    String? categoria,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        _setLoading(false);
        return false;
      }

      // Verificar se o produto pertence ao usuário
      final produtoIndex = _produtos.indexWhere((p) => p.id == produtoId);
      if (produtoIndex == -1) {
        _error = 'Produto não encontrado';
        _setLoading(false);
        return false;
      }

      final produtoAtual = _produtos[produtoIndex];
      if (produtoAtual.userId != usuarioAtual.uid) {
        _error = 'Você só pode editar seus próprios produtos';
        _setLoading(false);
        return false;
      }

      String? imagemBase64;
      if (novaImagem != null) {
        final bytes = await novaImagem.readAsBytes();
        imagemBase64 = base64Encode(bytes);
      }

      final imagemParaSalvar = imagemBase64 ?? produtoAtual.imagemBase64;

      final updateData = {
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'contato': contato,
        'imagemBase64': imagemParaSalvar ?? '',
        'atualizadoEm': FieldValue.serverTimestamp(),
        'categoria': categoria ?? produtoAtual.categoria ?? 'Geral', // ADICIONE CATEGORIA
      };

      if (estoque != null) updateData['estoque'] = estoque;

      await _firestore
          .collection('produtos_loja')
          .doc(produtoId)
          .update(updateData);

      // Atualizar lista local
      _produtos[produtoIndex] = produtoAtual.copyWith(
        nome: nome,
        descricao: descricao,
        preco: preco,
        contato: contato,
        imagemBase64: imagemParaSalvar,
        estoque: estoque ?? produtoAtual.estoque,
        categoria: categoria ?? produtoAtual.categoria, // ADICIONE CATEGORIA
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao editar produto: $e';
      _setLoading(false);
      return false;
    }
  }

  // Deletar produto
  Future<bool> deletarProduto(String produtoId) async {
    try {
      _setLoading(true);
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        _setLoading(false);
        return false;
      }

      // Verificar se o produto pertence ao usuário
      final produto = _produtos.firstWhere((p) => p.id == produtoId);
      if (produto.userId != usuarioAtual.uid) {
        _error = 'Você só pode deletar seus próprios produtos';
        _setLoading(false);
        return false;
      }

      // Soft delete - marcar como inativo
      await _firestore
          .collection('produtos_loja')
          .doc(produtoId)
          .update({
            'ativo': false,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

      // Remover da lista local
      _produtos.removeWhere((p) => p.id == produtoId);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao deletar produto: $e';
      _setLoading(false);
      return false;
    }
  }

  // Buscar produtos do usuário atual
  List<ProdutoModel> getProdutosDoUsuario() {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return [];
    
    return _produtos.where((p) => p.userId == usuarioAtual.uid).toList();
  }

  // Buscar produto por ID
  ProdutoModel? getProdutoById(String produtoId) {
    try {
      return _produtos.firstWhere((p) => p.id == produtoId);
    } catch (e) {
      return null;
    }
  }

  // Verificar se o usuário é dono do produto
  bool isProdutoDoUsuario(String produtoId) {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return false;
    
    try {
      final produto = _produtos.firstWhere((p) => p.id == produtoId);
      return produto.userId == usuarioAtual.uid;
    } catch (e) {
      return false;
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

  // Remover imagem selecionada
  void removerImagemSelecionada() {
    _selectedImage = null;
    notifyListeners();
  }

  // Limpar imagem selecionada
  void _clearImage() {
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
    await _loadProdutos();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
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
  List<ProdutoModel> _produtosFiltrados = [];
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;
  String _searchQuery = '';

  List<ProdutoModel> get produtos => _produtos;
  List<ProdutoModel> get produtosFiltrados => _produtosFiltrados;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;
  String get searchQuery => _searchQuery;

  List<ProdutoModel> get produtosAtivos => _produtos.where((p) => p.ativo).toList();

  LojaController() {
    _loadProdutos();
  }

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
      
      _produtosFiltrados = List.from(_produtos);
      
      _setLoading(false);
    } catch (e) {
      print('❌ Erro ao carregar produtos: $e');
      _error = 'Erro ao carregar produtos: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

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

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase().trim();
    
    if (_searchQuery.isEmpty) {
      _produtosFiltrados = List.from(_produtos);
    } else {
      _produtosFiltrados = _produtos.where((produto) {
        final nome = produto.nome.toLowerCase();
        final descricao = produto.descricao.toLowerCase();
        final categoria = produto.categoria?.toLowerCase() ?? '';
        
        return nome.contains(_searchQuery) || 
               descricao.contains(_searchQuery) ||
               categoria.contains(_searchQuery);
      }).toList();
    }
    
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _produtosFiltrados = List.from(_produtos);
    notifyListeners();
  }

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

      if (nome.isEmpty || descricao.isEmpty || preco.isEmpty || contato.isEmpty) {
        _error = 'Preencha todos os campos obrigatórios';
        _setLoading(false);
        return false;
      }

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
        categoria: categoria ?? 'Geral',
      );

      print('💾 Salvando produto no Firestore...');
      final docRef = await _firestore
          .collection('produtos_loja')
          .add(produto.toFirestore());

      print('✅ Produto salvo com ID: ${docRef.id}');

      final novoProduto = produto.copyWith(id: docRef.id);
      _produtos.insert(0, novoProduto);
      
      if (_searchQuery.isEmpty) {
        _produtosFiltrados.insert(0, novoProduto);
      } else {
        searchProducts(_searchQuery);
      }

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
        'categoria': categoria ?? produtoAtual.categoria ?? 'Geral',
      };

      if (estoque != null) updateData['estoque'] = estoque;

      await _firestore
          .collection('produtos_loja')
          .doc(produtoId)
          .update(updateData);

      final produtoAtualizado = produtoAtual.copyWith(
        nome: nome,
        descricao: descricao,
        preco: preco,
        contato: contato,
        imagemBase64: imagemParaSalvar,
        estoque: estoque ?? produtoAtual.estoque,
        categoria: categoria ?? produtoAtual.categoria,
      );

      _produtos[produtoIndex] = produtoAtualizado;
      
      final filteredIndex = _produtosFiltrados.indexWhere((p) => p.id == produtoId);
      if (filteredIndex != -1) {
        _produtosFiltrados[filteredIndex] = produtoAtualizado;
      } else {
        searchProducts(_searchQuery);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao editar produto: $e';
      _setLoading(false);
      return false;
    }
  }

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

      final produto = _produtos.firstWhere((p) => p.id == produtoId);
      if (produto.userId != usuarioAtual.uid) {
        _error = 'Você só pode deletar seus próprios produtos';
        _setLoading(false);
        return false;
      }

      await _firestore
          .collection('produtos_loja')
          .doc(produtoId)
          .update({
            'ativo': false,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

      _produtos.removeWhere((p) => p.id == produtoId);
      _produtosFiltrados.removeWhere((p) => p.id == produtoId);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao deletar produto: $e';
      _setLoading(false);
      return false;
    }
  }

  List<ProdutoModel> getProdutosDoUsuario() {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return [];
    
    return _produtos.where((p) => p.userId == usuarioAtual.uid).toList();
  }

  ProdutoModel? getProdutoById(String produtoId) {
    try {
      return _produtos.firstWhere((p) => p.id == produtoId);
    } catch (e) {
      return null;
    }
  }

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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadProdutos();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
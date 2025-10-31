import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/produto_model.dart';
import '../models/loja_model.dart';

class LojaController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  List<ProdutoModel> _produtos = [];
  List<LojaModel> _lojas = [];
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;

  // Getters
  List<ProdutoModel> get produtos => _produtos;
  List<LojaModel> get lojas => _lojas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;

  List<ProdutoModel> get produtosAtivos =>
      _produtos.where((p) => p.ativo && p.temEstoque).toList();

  // Inicializar controller
  LojaController() {
    _loadProdutos();
    _loadLojas();
  }

  // Carregar produtos
  Future<void> _loadProdutos() async {
    try {
      _setLoading(true);
      
      final snapshot = await _firestore
          .collection('produtos_loja')
          .orderBy('criadoEm', descending: true)
          .get();
      
      _produtos = snapshot.docs
          .map((doc) => ProdutoModel.fromFirestore(doc))
          .toList();
      
      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao carregar produtos: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Carregar lojas
  Future<void> _loadLojas() async {
    try {
      final snapshot = await _firestore
          .collection('lojas')
          .where('ativa', isEqualTo: true)
          .get();
      
      _lojas = snapshot.docs
          .map((doc) => LojaModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = 'Erro ao carregar lojas: $e';
      notifyListeners();
    }
  }

  // Stream de produtos para atualização em tempo real
  Stream<List<ProdutoModel>> get produtosStream {
    return _firestore
        .collection('produtos_loja')
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
    String? lojaId,
    String? userId,
    int? estoque,
  }) async {
    try {
      _setLoading(true);
      _error = null;

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
        lojaId: lojaId,
        userId: userId,
        estoque: estoque,
      );

      final docRef = await _firestore
          .collection('produtos_loja')
          .add(produto.toFirestore());

      // Adicionar à lista local com o ID gerado
      _produtos.insert(0, produto.copyWith(id: docRef.id));
      
      // Atualizar loja se for o caso
      if (lojaId != null) {
        await _adicionarProdutoALoja(lojaId, docRef.id);
      }

      _clearImage();
      _setLoading(false);
      
      return true;
    } catch (e) {
      _error = 'Erro ao cadastrar produto: $e';
      _setLoading(false);
      return false;
    }
  }

  // Adicionar produto à loja
  Future<void> _adicionarProdutoALoja(String lojaId, String produtoId) async {
    try {
      await _firestore.collection('lojas').doc(lojaId).update({
        'produtosIds': FieldValue.arrayUnion([produtoId]),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao adicionar produto à loja: $e');
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
    bool? ativo,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      String? imagemBase64;
      if (novaImagem != null) {
        final bytes = await novaImagem.readAsBytes();
        imagemBase64 = base64Encode(bytes);
      }

      // Buscar produto atual
      final produtoIndex = _produtos.indexWhere((p) => p.id == produtoId);
      if (produtoIndex == -1) {
        _error = 'Produto não encontrado';
        _setLoading(false);
        return false;
      }

      final produtoAtual = _produtos[produtoIndex];
      final imagemParaSalvar = imagemBase64 ?? produtoAtual.imagemBase64;

      final updateData = {
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'contato': contato,
        'imagemBase64': imagemParaSalvar ?? '',
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      // Adicionar campos opcionais se fornecidos
      if (estoque != null) updateData['estoque'] = estoque;
      if (ativo != null) updateData['ativo'] = ativo;

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
        ativo: ativo ?? produtoAtual.ativo,
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

      await _firestore
          .collection('produtos_loja')
          .doc(produtoId)
          .delete();

      // Remover da lista local
      _produtos.removeWhere((p) => p.id == produtoId);
      
      // Remover das lojas
      await _removerProdutoDeLojas(produtoId);

      _setLoading(false);
      
      return true;
    } catch (e) {
      _error = 'Erro ao deletar produto: $e';
      _setLoading(false);
      return false;
    }
  }

  // Remover produto de todas as lojas
  Future<void> _removerProdutoDeLojas(String produtoId) async {
    try {
      final lojasComProduto = _lojas.where((loja) => loja.produtosIds.contains(produtoId));
      
      for (final loja in lojasComProduto) {
        await _firestore.collection('lojas').doc(loja.id).update({
          'produtosIds': FieldValue.arrayRemove([produtoId]),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erro ao remover produto das lojas: $e');
    }
  }

  // Buscar produto por ID
  ProdutoModel? getProdutoById(String produtoId) {
    try {
      return _produtos.firstWhere((p) => p.id == produtoId);
    } catch (e) {
      return null;
    }
  }

  // Buscar produtos por nome ou descrição
  List<ProdutoModel> buscarProdutos(String query) {
    if (query.isEmpty) return _produtos;
    
    return _produtos.where((produto) {
      return produto.nome.toLowerCase().contains(query.toLowerCase()) ||
             produto.descricao.toLowerCase().contains(query.toLowerCase()) ||
             produto.preco.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Buscar produtos do usuário atual
  List<ProdutoModel> getProdutosDoUsuario(String? userId) {
    if (userId == null) return [];
    
    return _produtos.where((p) => p.userId == userId).toList();
  }

  // Buscar produtos de uma loja específica
  List<ProdutoModel> getProdutosDaLoja(String lojaId) {
    return _produtos.where((p) => p.lojaId == lojaId).toList();
  }

  // Criar nova loja
  Future<bool> criarLoja({
    required String nome,
    required String descricao,
    required String contato,
    required String userId,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final loja = LojaModel(
        nome: nome.trim(),
        descricao: descricao.trim(),
        contato: contato.trim(),
        userId: userId,
      );

      final docRef = await _firestore
          .collection('lojas')
          .add(loja.toFirestore());

      _lojas.add(loja.copyWith(id: docRef.id));
      _setLoading(false);
      
      return true;
    } catch (e) {
      _error = 'Erro ao criar loja: $e';
      _setLoading(false);
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

  // Simular compra (processar pedido)
  Future<bool> processarPedido({
    required String produtoId,
    required int quantidade,
    required double precoTotal,
  }) async {
    try {
      _setLoading(true);
      
      // Aqui você pode integrar com um gateway de pagamento
      // Por enquanto, apenas simulamos a compra
      
      // Atualizar estoque se necessário
      final produto = getProdutoById(produtoId);
      if (produto != null && produto.estoque != null) {
        final novoEstoque = produto.estoque! - quantidade;
        await editarProduto(
          produtoId: produtoId,
          nome: produto.nome,
          descricao: produto.descricao,
          preco: produto.preco,
          contato: produto.contato,
          estoque: novoEstoque,
        );
      }

      // Registrar pedido (opcional)
      await _firestore.collection('pedidos').add({
        'produtoId': produtoId,
        'quantidade': quantidade,
        'precoTotal': precoTotal,
        'status': 'concluido',
        'criadoEm': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao processar pedido: $e';
      _setLoading(false);
      return false;
    }
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
    await _loadLojas();
  }

  // Estatísticas
  Map<String, int> get estatisticas {
    final produtosAtivosCount = produtosAtivos.length;
    final lojasAtivasCount = _lojas.where((l) => l.ativa).length;
    final totalProdutos = _produtos.length;

    return {
      'produtosAtivos': produtosAtivosCount,
      'lojasAtivas': lojasAtivasCount,
      'totalProdutos': totalProdutos,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
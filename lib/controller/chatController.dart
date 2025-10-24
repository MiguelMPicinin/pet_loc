import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart' hide MensagemModel;
import '../models/mensagem.dart' hide ChatModel;

class ChatController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ChatModel> _chats = [];
  List<MensagemModel> _mensagens = [];
  bool _isLoading = false;
  String? _error;
  String? _chatSelecionadoId;

  // Getters
  List<ChatModel> get chats => _chats;
  List<MensagemModel> get mensagens => _mensagens;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get chatSelecionadoId => _chatSelecionadoId;

  ChatModel? get chatSelecionado {
    if (_chatSelecionadoId == null) return null;
    try {
      return _chats.firstWhere((chat) => chat.id == _chatSelecionadoId);
    } catch (e) {
      return null;
    }
  }

  // Inicializar controller
  ChatController() {
    _loadChatsDoUsuario();
  }

  // Carregar chats do usuário atual
  Future<void> _loadChatsDoUsuario() async {
    try {
      _setLoading(true);
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _setLoading(false);
        return;
      }

      final snapshot = await _firestore
          .collection('chats')
          .where('participantesIds', arrayContains: userId)
          .orderBy('atualizadoEm', descending: true)
          .get();
      
      _chats = snapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();
      
      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao carregar chats: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Stream de chats para atualização em tempo real
  Stream<List<ChatModel>> get chatsStream {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participantesIds', arrayContains: userId)
        .orderBy('atualizadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList());
  }

  // Stream de mensagens de um chat específico
  Stream<List<MensagemModel>> mensagensStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('mensagens')
        .orderBy('enviadoEm', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MensagemModel.fromFirestore(doc))
            .toList());
  }

  // Criar ou buscar chat existente
  Future<String?> criarOuBuscarChat({
    required String outroUsuarioId,
    required String outroUsuarioNome,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        _setLoading(false);
        return null;
      }

      // Verificar se já existe um chat entre os usuários
      final chatExistente = await _buscarChatExistente(
        usuarioAtual.uid,
        outroUsuarioId,
      );

      if (chatExistente != null) {
        _setLoading(false);
        return chatExistente.id;
      }

      // Criar novo chat
      final novoChat = ChatModel(
        participantesIds: [usuarioAtual.uid, outroUsuarioId],
        participantesNomes: [usuarioAtual.displayName ?? 'Usuário', outroUsuarioNome],
      );

      final docRef = await _firestore
          .collection('chats')
          .add(novoChat.toFirestore());

      _chats.add(novoChat.copyWith(id: docRef.id));
      _setLoading(false);
      
      return docRef.id;
    } catch (e) {
      _error = 'Erro ao criar chat: $e';
      _setLoading(false);
      return null;
    }
  }

  // Buscar chat existente entre dois usuários
  Future<ChatModel?> _buscarChatExistente(String usuarioId1, String usuarioId2) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participantesIds', arrayContains: usuarioId1)
          .get();

      for (final doc in snapshot.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participantesIds.contains(usuarioId2)) {
          return chat;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Enviar mensagem
  Future<bool> enviarMensagem({
    required String chatId,
    required String texto,
  }) async {
    try {
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        return false;
      }

      if (texto.trim().isEmpty) {
        _error = 'Mensagem não pode estar vazia';
        return false;
      }

      final mensagem = MensagemModel(
        id: '', // Será gerado pelo Firestore
        texto: texto.trim(),
        remetenteId: usuarioAtual.uid,
        remetenteNome: usuarioAtual.displayName ?? 'Usuário',
        enviadoEm: DateTime.now(),
      );

      // Adicionar mensagem à subcoleção
      final mensagemRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensagens')
          .add(mensagem.toFirestore());

      // Atualizar última mensagem no chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({
            'ultimaMensagem': mensagem.copyWith(id: mensagemRef.id).toFirestore(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      _error = 'Erro ao enviar mensagem: $e';
      return false;
    }
  }

  // Carregar mensagens de um chat
  Future<void> carregarMensagens(String chatId) async {
    try {
      _setLoading(true);
      _chatSelecionadoId = chatId;

      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensagens')
          .orderBy('enviadoEm', descending: false)
          .get();

      _mensagens = snapshot.docs
          .map((doc) => MensagemModel.fromFirestore(doc))
          .toList();

      // Marcar mensagens como lidas
      await _marcarMensagensComoLidas(chatId);

      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao carregar mensagens: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Marcar mensagens como lidas
  Future<void> _marcarMensagensComoLidas(String chatId) async {
    try {
      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) return;

      final mensagensNaoLidas = _mensagens.where((msg) => 
        !msg.lida && msg.remetenteId != usuarioAtual.uid
      );

      for (final mensagem in mensagensNaoLidas) {
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('mensagens')
            .doc(mensagem.id)
            .update({'lida': true});
      }
    } catch (e) {
      print('Erro ao marcar mensagens como lidas: $e');
    }
  }

  // Deletar mensagem
  Future<bool> deletarMensagem({
    required String chatId,
    required String mensagemId,
  }) async {
    try {
      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        return false;
      }

      // Verificar se o usuário é o remetente da mensagem
      final mensagemDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensagens')
          .doc(mensagemId)
          .get();

      if (!mensagemDoc.exists) {
        _error = 'Mensagem não encontrada';
        return false;
      }

      final mensagem = MensagemModel.fromFirestore(mensagemDoc);
      if (mensagem.remetenteId != usuarioAtual.uid) {
        _error = 'Você só pode deletar suas próprias mensagens';
        return false;
      }

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensagens')
          .doc(mensagemId)
          .delete();

      // Remover da lista local
      _mensagens.removeWhere((msg) => msg.id == mensagemId);

      // Atualizar última mensagem se necessário
      await _atualizarUltimaMensagem(chatId);

      return true;
    } catch (e) {
      _error = 'Erro ao deletar mensagem: $e';
      return false;
    }
  }

  // Atualizar última mensagem do chat
  Future<void> _atualizarUltimaMensagem(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensagens')
          .orderBy('enviadoEm', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final ultimaMensagem = MensagemModel.fromFirestore(snapshot.docs.first);
        await _firestore
            .collection('chats')
            .doc(chatId)
            .update({
              'ultimaMensagem': ultimaMensagem.toFirestore(),
              'atualizadoEm': FieldValue.serverTimestamp(),
            });
      } else {
        // Se não há mensagens, limpar última mensagem
        await _firestore
            .collection('chats')
            .doc(chatId)
            .update({
              'ultimaMensagem': null,
              'atualizadoEm': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Erro ao atualizar última mensagem: $e');
    }
  }

  // Deletar chat
  Future<bool> deletarChat(String chatId) async {
    try {
      _setLoading(true);
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        _setLoading(false);
        return false;
      }

      // Verificar se o usuário é participante do chat
      final chat = _chats.firstWhere((c) => c.id == chatId);
      if (!chat.participantesIds.contains(usuarioAtual.uid)) {
        _error = 'Você não tem permissão para deletar este chat';
        _setLoading(false);
        return false;
      }

      // Deletar todas as mensagens primeiro
      final mensagensSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensagens')
          .get();

      final batch = _firestore.batch();
      for (final doc in mensagensSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Deletar o chat
      await _firestore.collection('chats').doc(chatId).delete();

      // Remover da lista local
      _chats.removeWhere((c) => c.id == chatId);
      if (_chatSelecionadoId == chatId) {
        _chatSelecionadoId = null;
        _mensagens.clear();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao deletar chat: $e';
      _setLoading(false);
      return false;
    }
  }

  // Buscar chats por nome do participante
  List<ChatModel> buscarChats(String query) {
    if (query.isEmpty) return _chats;
    
    return _chats.where((chat) {
      return chat.participantesNomes.any((nome) => 
        nome.toLowerCase().contains(query.toLowerCase())
      );
    }).toList();
  }

  // Obter nome do outro participante do chat
  String? getOutroParticipanteNome(ChatModel chat) {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return null;

    final index = chat.participantesIds.indexOf(usuarioAtual.uid);
    if (index == -1) return null;

    return chat.participantesNomes[index == 0 ? 1 : 0];
  }

  // Obter ID do outro participante do chat
  String? getOutroParticipanteId(ChatModel chat) {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return null;

    final index = chat.participantesIds.indexOf(usuarioAtual.uid);
    if (index == -1) return null;

    return chat.participantesIds[index == 0 ? 1 : 0];
  }

  // Verificar se uma mensagem foi enviada pelo usuário atual
  bool isMensagemDoUsuarioAtual(MensagemModel mensagem) {
    final usuarioAtual = _auth.currentUser;
    return usuarioAtual != null && mensagem.remetenteId == usuarioAtual.uid;
  }

  // Contar mensagens não lidas em um chat
  int contarMensagensNaoLidas(ChatModel chat) {
    if (chat.ultimaMensagem == null) return 0;
    
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return 0;

    // Aqui você pode implementar uma lógica mais sofisticada
    // para contar mensagens não lidas se necessário
    return chat.ultimaMensagem!.lida || 
           chat.ultimaMensagem!.remetenteId == usuarioAtual.uid ? 0 : 1;
  }

  // Limpar mensagens do chat atual
  void limparMensagens() {
    _mensagens.clear();
    _chatSelecionadoId = null;
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
    await _loadChatsDoUsuario();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
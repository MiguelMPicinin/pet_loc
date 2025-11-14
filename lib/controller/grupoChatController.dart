// group_chat_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _grupos = [];
  List<Map<String, dynamic>> _mensagens = [];
  bool _isLoading = false;
  String? _error;
  String? _grupoSelecionadoId;

  // Getters
  List<Map<String, dynamic>> get grupos => _grupos;
  List<Map<String, dynamic>> get mensagens => _mensagens;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get grupoSelecionadoId => _grupoSelecionadoId;

  Map<String, dynamic>? get grupoSelecionado {
    if (_grupoSelecionadoId == null) return null;
    try {
      return _grupos.firstWhere((grupo) => grupo['id'] == _grupoSelecionadoId);
    } catch (e) {
      return null;
    }
  }

  // Carregar grupos
  Future<void> carregarGrupos() async {
    try {
      _setLoading(true);
      
      final snapshot = await _firestore
          .collection('chat_grupos')
          .where('ativo', isEqualTo: true)
          .orderBy('ultimaMensagemData', descending: true)
          .get();
      
      _grupos = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nome': data['nome'] ?? '',
          'descricao': data['descricao'] ?? '',
          'categoria': data['categoria'] ?? 'Geral',
          'criadorId': data['criadorId'] ?? '',
          'criadorNome': data['criadorNome'] ?? '',
          'membros': List<String>.from(data['membros'] ?? []),
          'membrosCount': data['membrosCount'] ?? 0,
          'ativo': data['ativo'] ?? true,
          'icone': data['icone'] ?? '💬',
          'ultimaMensagem': data['ultimaMensagem'] ?? '',
          'ultimaMensagemData': data['ultimaMensagemData'],
          'criadoEm': data['criadoEm'],
        };
      }).toList();
      
      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao carregar grupos: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Stream de grupos para atualização em tempo real
  Stream<List<Map<String, dynamic>>> get gruposStream {
    return _firestore
        .collection('chat_grupos')
        .where('ativo', isEqualTo: true)
        .orderBy('ultimaMensagemData', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'nome': data['nome'] ?? '',
            'descricao': data['descricao'] ?? '',
            'categoria': data['categoria'] ?? 'Geral',
            'criadorId': data['criadorId'] ?? '',
            'criadorNome': data['criadorNome'] ?? '',
            'membros': List<String>.from(data['membros'] ?? []),
            'membrosCount': data['membrosCount'] ?? 0,
            'ativo': data['ativo'] ?? true,
            'icone': data['icone'] ?? '💬',
            'ultimaMensagem': data['ultimaMensagem'] ?? '',
            'ultimaMensagemData': data['ultimaMensagemData'],
            'criadoEm': data['criadoEm'],
          };
        }).toList());
  }

  // Stream de mensagens de um grupo específico
  Stream<List<Map<String, dynamic>>> mensagensStream(String grupoId) {
    return _firestore
        .collection('chat_grupos')
        .doc(grupoId)
        .collection('mensagens')
        .orderBy('enviadoEm', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'texto': data['texto'] ?? '',
            'remetenteId': data['remetenteId'] ?? '',
            'remetenteNome': data['remetenteNome'] ?? '',
            'enviadoEm': data['enviadoEm'],
            'lida': data['lida'] ?? false,
          };
        }).toList());
  }

  // Criar novo grupo
  Future<bool> criarGrupo({
    required String nome,
    required String descricao,
    required String categoria,
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

      final novoGrupo = {
        'nome': nome.trim(),
        'descricao': descricao.trim(),
        'categoria': categoria,
        'criadorId': usuarioAtual.uid,
        'criadorNome': usuarioAtual.displayName ?? 'Usuário',
        'membros': [usuarioAtual.uid],
        'membrosCount': 1,
        'ativo': true,
        'icone': _getIconePorCategoria(categoria),
        'ultimaMensagem': 'Grupo criado por ${usuarioAtual.displayName ?? "Usuário"}',
        'ultimaMensagemData': FieldValue.serverTimestamp(),
        'criadoEm': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('chat_grupos').add(novoGrupo);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao criar grupo: $e';
      _setLoading(false);
      return false;
    }
  }

  // Entrar em um grupo
  Future<bool> entrarNoGrupo(String grupoId) async {
    try {
      _error = null;

      final usuarioAtual = _auth.currentUser;
      if (usuarioAtual == null) {
        _error = 'Usuário não autenticado';
        return false;
      }

      await _firestore.collection('chat_grupos').doc(grupoId).update({
        'membros': FieldValue.arrayUnion([usuarioAtual.uid]),
        'membrosCount': FieldValue.increment(1),
        'ultimaMensagemData': FieldValue.serverTimestamp(),
        'ultimaMensagem': '${usuarioAtual.displayName ?? "Novo usuário"} entrou no grupo',
      });

      return true;
    } catch (e) {
      _error = 'Erro ao entrar no grupo: $e';
      return false;
    }
  }

  // Enviar mensagem
  Future<bool> enviarMensagem({
    required String grupoId,
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

      final mensagem = {
        'texto': texto.trim(),
        'remetenteId': usuarioAtual.uid,
        'remetenteNome': usuarioAtual.displayName ?? 'Usuário',
        'enviadoEm': FieldValue.serverTimestamp(),
        'lida': false,
      };

      // Adicionar mensagem à subcoleção
      await _firestore
          .collection('chat_grupos')
          .doc(grupoId)
          .collection('mensagens')
          .add(mensagem);

      // Atualizar última mensagem no grupo
      await _firestore
          .collection('chat_grupos')
          .doc(grupoId)
          .update({
            'ultimaMensagem': texto.trim(),
            'ultimaMensagemData': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      _error = 'Erro ao enviar mensagem: $e';
      return false;
    }
  }

  // Verificar se o usuário é membro de um grupo
  bool isMembroDoGrupo(Map<String, dynamic> grupo) {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return false;
    return (grupo['membros'] as List).contains(usuarioAtual.uid);
  }

  // Verificar se uma mensagem foi enviada pelo usuário atual
  bool isMensagemDoUsuarioAtual(Map<String, dynamic> mensagem) {
    final usuarioAtual = _auth.currentUser;
    return usuarioAtual != null && mensagem['remetenteId'] == usuarioAtual.uid;
  }

  // Obter ícone por categoria
  String _getIconePorCategoria(String categoria) {
    switch (categoria) {
      case 'Adoção':
        return '🏠';
      case 'Saúde':
        return '🏥';
      case 'Comportamento':
        return '🎓';
      case 'Raças':
        return '🐕';
      case 'Nutrição':
        return '🍖';
      default:
        return '💬';
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

  @override
  void dispose() {
    super.dispose();
  }
}
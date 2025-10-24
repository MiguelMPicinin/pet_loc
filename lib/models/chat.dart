import 'package:cloud_firestore/cloud_firestore.dart';

class MensagemModel {
  final String id;
  final String texto;
  final String remetenteId;
  final String remetenteNome;
  final DateTime enviadoEm;
  final bool lida;

  MensagemModel({
    required this.id,
    required this.texto,
    required this.remetenteId,
    required this.remetenteNome,
    required this.enviadoEm,
    this.lida = false,
  });

  factory MensagemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MensagemModel(
      id: doc.id,
      texto: data['texto'] ?? '',
      remetenteId: data['remetenteId'] ?? '',
      remetenteNome: data['remetenteNome'] ?? '',
      enviadoEm: data['enviadoEm']?.toDate() ?? DateTime.now(),
      lida: data['lida'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'remetenteId': remetenteId,
      'remetenteNome': remetenteNome,
      'enviadoEm': FieldValue.serverTimestamp(),
      'lida': lida,
    };
  }

  // Método copyWith adicionado
  MensagemModel copyWith({
    String? id,
    String? texto,
    String? remetenteId,
    String? remetenteNome,
    DateTime? enviadoEm,
    bool? lida,
  }) {
    return MensagemModel(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      remetenteId: remetenteId ?? this.remetenteId,
      remetenteNome: remetenteNome ?? this.remetenteNome,
      enviadoEm: enviadoEm ?? this.enviadoEm,
      lida: lida ?? this.lida,
    );
  }
}

class ChatModel {
  final String? id;
  final List<String> participantesIds;
  final List<String> participantesNomes;
  final MensagemModel? ultimaMensagem;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  ChatModel({
    this.id,
    required this.participantesIds,
    required this.participantesNomes,
    this.ultimaMensagem,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    MensagemModel? ultimaMsg;
    if (data['ultimaMensagem'] != null) {
      final msgData = data['ultimaMensagem'] as Map<String, dynamic>;
      ultimaMsg = MensagemModel(
        id: '',
        texto: msgData['texto'] ?? '',
        remetenteId: msgData['remetenteId'] ?? '',
        remetenteNome: msgData['remetenteNome'] ?? '',
        enviadoEm: msgData['enviadoEm']?.toDate() ?? DateTime.now(),
        lida: msgData['lida'] ?? false,
      );
    }

    return ChatModel(
      id: doc.id,
      participantesIds: List<String>.from(data['participantesIds'] ?? []),
      participantesNomes: List<String>.from(data['participantesNomes'] ?? []),
      ultimaMensagem: ultimaMsg,
      criadoEm: data['criadoEm']?.toDate(),
      atualizadoEm: data['atualizadoEm']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantesIds': participantesIds,
      'participantesNomes': participantesNomes,
      'ultimaMensagem': ultimaMensagem?.toFirestore(),
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  // Método copyWith adicionado
  ChatModel copyWith({
    String? id,
    List<String>? participantesIds,
    List<String>? participantesNomes,
    MensagemModel? ultimaMensagem,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantesIds: participantesIds ?? this.participantesIds,
      participantesNomes: participantesNomes ?? this.participantesNomes,
      ultimaMensagem: ultimaMensagem ?? this.ultimaMensagem,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
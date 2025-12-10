import 'package:cloud_firestore/cloud_firestore.dart';

class MensagemModel {
  final String id;
  final String texto;
  final String remetenteId;
  final String remetenteNome;
  final DateTime enviadoEm;
  final bool lida;
  final String? tipo;
  final String? urlMidia;
  final Map<String, dynamic>? metadados;

  MensagemModel({
    required this.id,
    required this.texto,
    required this.remetenteId,
    required this.remetenteNome,
    required this.enviadoEm,
    this.lida = false,
    this.tipo = 'texto',
    this.urlMidia,
    this.metadados,
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
      tipo: data['tipo'] ?? 'texto',
      urlMidia: data['urlMidia'],
      metadados: data['metadados'] != null 
          ? Map<String, dynamic>.from(data['metadados'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'remetenteId': remetenteId,
      'remetenteNome': remetenteNome,
      'enviadoEm': FieldValue.serverTimestamp(),
      'lida': lida,
      'tipo': tipo,
      'urlMidia': urlMidia,
      'metadados': metadados,
    };
  }

  factory MensagemModel.texto({
    required String id,
    required String texto,
    required String remetenteId,
    required String remetenteNome,
  }) {
    return MensagemModel(
      id: id,
      texto: texto,
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      enviadoEm: DateTime.now(),
      tipo: 'texto',
    );
  }

  factory MensagemModel.imagem({
    required String id,
    required String urlImagem,
    required String remetenteId,
    required String remetenteNome,
    String? legenda,
  }) {
    return MensagemModel(
      id: id,
      texto: legenda ?? '📷 Imagem',
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      enviadoEm: DateTime.now(),
      tipo: 'imagem',
      urlMidia: urlImagem,
      metadados: {
        'largura': 0,
        'altura': 0,
        'tamanho': 0,
      },
    );
  }

  factory MensagemModel.localizacao({
    required String id,
    required double latitude,
    required double longitude,
    required String remetenteId,
    required String remetenteNome,
    String? endereco,
  }) {
    return MensagemModel(
      id: id,
      texto: endereco ?? '📍 Localização',
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      enviadoEm: DateTime.now(),
      tipo: 'localizacao',
      metadados: {
        'latitude': latitude,
        'longitude': longitude,
        'endereco': endereco,
      },
    );
  }

  bool get isTexto => tipo == 'texto';
  bool get isImagem => tipo == 'imagem';
  bool get isLocalizacao => tipo == 'localizacao';

  Map<String, dynamic>? get dadosLocalizacao {
    if (isLocalizacao && metadados != null) {
      return {
        'latitude': metadados!['latitude'],
        'longitude': metadados!['longitude'],
        'endereco': metadados!['endereco'],
      };
    }
    return null;
  }

  MensagemModel copyWith({
    String? id,
    String? texto,
    String? remetenteId,
    String? remetenteNome,
    DateTime? enviadoEm,
    bool? lida,
    String? tipo,
    String? urlMidia,
    Map<String, dynamic>? metadados,
  }) {
    return MensagemModel(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      remetenteId: remetenteId ?? this.remetenteId,
      remetenteNome: remetenteNome ?? this.remetenteNome,
      enviadoEm: enviadoEm ?? this.enviadoEm,
      lida: lida ?? this.lida,
      tipo: tipo ?? this.tipo,
      urlMidia: urlMidia ?? this.urlMidia,
      metadados: metadados ?? this.metadados,
    );
  }

  String get horaFormatada {
    return '${enviadoEm.hour.toString().padLeft(2, '0')}:${enviadoEm.minute.toString().padLeft(2, '0')}';
  }

  String get dataCompleta {
    return '${enviadoEm.day}/${enviadoEm.month}/${enviadoEm.year} $horaFormatada';
  }

  bool get isHoje {
    final now = DateTime.now();
    return enviadoEm.year == now.year &&
           enviadoEm.month == now.month &&
           enviadoEm.day == now.day;
  }

  bool get isOntem {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return enviadoEm.year == yesterday.year &&
           enviadoEm.month == yesterday.month &&
           enviadoEm.day == yesterday.day;
  }

  @override
  String toString() {
    return 'MensagemModel{id: $id, texto: $texto, remetente: $remetenteNome, tipo: $tipo, lida: $lida}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MensagemModel &&
        other.id == id &&
        other.texto == texto &&
        other.remetenteId == remetenteId &&
        other.enviadoEm == enviadoEm;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        texto.hashCode ^
        remetenteId.hashCode ^
        enviadoEm.hashCode;
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
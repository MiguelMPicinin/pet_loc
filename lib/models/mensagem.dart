import 'package:cloud_firestore/cloud_firestore.dart';

class MensagemModel {
  final String id;
  final String texto;
  final String remetenteId;
  final String remetenteNome;
  final DateTime enviadoEm;
  final bool lida;
  final String? tipo; // 'texto', 'imagem', 'localizacao'
  final String? urlMidia; // URL para imagens, arquivos, etc.
  final Map<String, dynamic>? metadados; // Informações adicionais

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

  // Construtor para mensagem de texto simples
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

  // Construtor para mensagem com imagem
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

  // Construtor para mensagem com localização
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

  // Verificar se a mensagem é do tipo texto
  bool get isTexto => tipo == 'texto';

  // Verificar se a mensagem é do tipo imagem
  bool get isImagem => tipo == 'imagem';

  // Verificar se a mensagem é do tipo localização
  bool get isLocalizacao => tipo == 'localizacao';

  // Obter dados de localização se disponível
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

  // Copiar mensagem com novos valores
  // No mensagem_model.dart - Correção do copyWith
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

  // Formatar data para exibição
  String get horaFormatada {
    return '${enviadoEm.hour.toString().padLeft(2, '0')}:${enviadoEm.minute.toString().padLeft(2, '0')}';
  }

  // Formatar data completa
  String get dataCompleta {
    return '${enviadoEm.day}/${enviadoEm.month}/${enviadoEm.year} $horaFormatada';
  }

  // Verificar se a mensagem foi enviada hoje
  bool get isHoje {
    final now = DateTime.now();
    return enviadoEm.year == now.year &&
           enviadoEm.month == now.month &&
           enviadoEm.day == now.day;
  }

  // Verificar se a mensagem foi enviada ontem
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

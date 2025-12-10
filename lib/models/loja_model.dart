import 'package:cloud_firestore/cloud_firestore.dart';

class LojaModel {
  final String? id;
  final String nome;
  final String descricao;
  final String contato;
  final String? imagemBase64;
  final String userId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final List<String> produtosIds;
  final bool ativa;

  LojaModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.contato,
    this.imagemBase64,
    required this.userId,
    this.criadoEm,
    this.atualizadoEm,
    this.produtosIds = const [],
    this.ativa = true,
  });

  factory LojaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LojaModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      contato: data['contato'] ?? '',
      imagemBase64: data['imagemBase64'],
      userId: data['userId'] ?? '',
      criadoEm: data['criadoEm']?.toDate(),
      atualizadoEm: data['atualizadoEm']?.toDate(),
      produtosIds: List<String>.from(data['produtosIds'] ?? []),
      ativa: data['ativa'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'descricao': descricao,
      'contato': contato,
      'imagemBase64': imagemBase64 ?? '',
      'userId': userId,
      'criadoEm': criadoEm != null 
          ? Timestamp.fromDate(criadoEm!) 
          : FieldValue.serverTimestamp(),
      'atualizadoEm': atualizadoEm != null 
          ? Timestamp.fromDate(atualizadoEm!) 
          : FieldValue.serverTimestamp(),
      'produtosIds': produtosIds,
      'ativa': ativa,
    };
  }

  LojaModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? contato,
    String? imagemBase64,
    String? userId,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    List<String>? produtosIds,
    bool? ativa,
  }) {
    return LojaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      contato: contato ?? this.contato,
      imagemBase64: imagemBase64 ?? this.imagemBase64,
      userId: userId ?? this.userId,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      produtosIds: produtosIds ?? this.produtosIds,
      ativa: ativa ?? this.ativa,
    );
  }
}
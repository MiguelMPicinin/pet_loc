import 'package:cloud_firestore/cloud_firestore.dart';

class DesaparecidoModel {
  final String? id;
  final String nome;
  final String descricao;
  final String contato;
  final String? imagemBase64;
  final String? userId;
  final bool encontrado;
  final DateTime? criadoEm;
  final DateTime? desaparecidoEm;
  final DateTime? atualizadoEm;

  DesaparecidoModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.contato,
    this.imagemBase64,
    this.userId,
    this.encontrado = false,
    this.criadoEm,
    this.desaparecidoEm,
    this.atualizadoEm,
  });

  factory DesaparecidoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DesaparecidoModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      contato: data['contato'] ?? '',
      imagemBase64: data['imagemBase64'],
      userId: data['userId'],
      encontrado: data['encontrado'] ?? false,
      criadoEm: data['criadoEm']?.toDate(),
      desaparecidoEm: data['desaparecidoEm']?.toDate(),
      atualizadoEm: data['atualizadoEm']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'descricao': descricao,
      'contato': contato,
      'imagemBase64': imagemBase64 ?? '',
      'userId': userId,
      'encontrado': encontrado,
      'criadoEm': criadoEm != null 
          ? Timestamp.fromDate(criadoEm!) 
          : FieldValue.serverTimestamp(),
      'desaparecidoEm': desaparecidoEm != null 
          ? Timestamp.fromDate(desaparecidoEm!) 
          : FieldValue.serverTimestamp(),
      'atualizadoEm': atualizadoEm != null 
          ? Timestamp.fromDate(atualizadoEm!) 
          : FieldValue.serverTimestamp(),
    };
  }

  DesaparecidoModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? contato,
    String? imagemBase64,
    String? userId,
    bool? encontrado,
    DateTime? criadoEm,
    DateTime? desaparecidoEm,
    DateTime? atualizadoEm,
  }) {
    return DesaparecidoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      contato: contato ?? this.contato,
      imagemBase64: imagemBase64 ?? this.imagemBase64,
      userId: userId ?? this.userId,
      encontrado: encontrado ?? this.encontrado,
      criadoEm: criadoEm ?? this.criadoEm,
      desaparecidoEm: desaparecidoEm ?? this.desaparecidoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
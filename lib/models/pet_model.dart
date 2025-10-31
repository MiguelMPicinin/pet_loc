import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class PetModel {
  final String? id;
  final String nome;
  final String descricao;
  final String contato;
  final String? imagemBase64;
  final String? userId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  PetModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.contato,
    this.imagemBase64,
    this.userId,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory PetModel.fromRTDB(Map<dynamic, dynamic> data, String id) {
    return PetModel(
      id: id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      contato: data['contato'] ?? '',
      imagemBase64: data['imagemBase64'],
    );
  }

  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PetModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      contato: data['contato'] ?? '',
      imagemBase64: data['imagemBase64'],
      userId: data['userId'],
      criadoEm: data['criadoEm']?.toDate(),
      atualizadoEm: data['atualizadoEm']?.toDate(),
    );
  }

  Map<String, dynamic> toRTDB() {
    return {
      'nome': nome,
      'descricao': descricao,
      'contato': contato,
      'imagemBase64': imagemBase64 ?? '',
      'criadoEm': ServerValue.timestamp,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'descricao': descricao,
      'contato': contato,
      'imagemBase64': imagemBase64 ?? '',
      'userId': userId,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  PetModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? contato,
    String? imagemBase64,
    String? userId,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return PetModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      contato: contato ?? this.contato,
      imagemBase64: imagemBase64 ?? this.imagemBase64,
      userId: userId ?? this.userId,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
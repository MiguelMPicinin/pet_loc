import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? fotoUrl;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.fotoUrl,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      telefone: data['telefone'],
      fotoUrl: data['fotoUrl'],
      criadoEm: data['criadoEm']?.toDate(),
      atualizadoEm: data['atualizadoEm']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoUrl': fotoUrl,
      'criadoEm': criadoEm != null 
          ? Timestamp.fromDate(criadoEm!) 
          : FieldValue.serverTimestamp(),
      'atualizadoEm': atualizadoEm != null 
          ? Timestamp.fromDate(atualizadoEm!) 
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? fotoUrl,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
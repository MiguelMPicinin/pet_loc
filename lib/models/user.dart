import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType {
  normal,
  lojista,
}

class UserModel {
  final String? id;
  final String nome;
  final String email;
  final String? telefone;
  final String? fotoUrl;
  final UserType tipo;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  UserModel({
    this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.fotoUrl,
    this.tipo = UserType.normal,
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
      tipo: UserType.values[data['tipo'] ?? 0],
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
      'tipo': tipo.index,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  bool get isLojista => tipo == UserType.lojista;
  bool get isNormal => tipo == UserType.normal;

  UserModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? fotoUrl,
    UserType? tipo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      tipo: tipo ?? this.tipo,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String? id;
  final String nome;
  final String descricao;
  final String contato;
  final String? imagemBase64;
  final String userId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  PetModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.contato,
    this.imagemBase64,
    required this.userId,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // 🔥 GARANTIR QUE O ID VEM DO DOCUMENTO - CORREÇÃO CRÍTICA
    String petId = doc.id;
    
    if (petId.isEmpty) {
      print('⚠️ ATENÇÃO: Documento do Firestore sem ID! Path: ${doc.reference.path}');
      petId = 'erro-sem-id-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return PetModel(
      id: petId, // 🔥 ID DO DOCUMENTO - ESSENCIAL
      nome: data['nome']?.toString() ?? '',
      descricao: data['descricao']?.toString() ?? '',
      contato: data['contato']?.toString() ?? '',
      imagemBase64: data['imagemBase64']?.toString(),
      userId: data['userId']?.toString() ?? '',
      criadoEm: data['criadoEm']?.toDate(),
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
      'criadoEm': criadoEm != null 
          ? Timestamp.fromDate(criadoEm!) 
          : FieldValue.serverTimestamp(),
      'atualizadoEm': atualizadoEm != null 
          ? Timestamp.fromDate(atualizadoEm!) 
          : FieldValue.serverTimestamp(),
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
      id: id ?? this.id, // 🔥 MANTÉM O ID
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      contato: contato ?? this.contato,
      imagemBase64: imagemBase64 ?? this.imagemBase64,
      userId: userId ?? this.userId,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  bool get isValid {
    return nome.isNotEmpty && 
           descricao.isNotEmpty && 
           contato.isNotEmpty &&
           userId.isNotEmpty;
  }

  bool get hasId {
    return id != null && id!.isNotEmpty && id! != 'null' && !id!.contains('erro-sem-id');
  }

  // 🔥 FUNÇÃO PARA DEBUG
  Map<String, dynamic> toDebugMap() {
    return {
      'id': id ?? 'SEM_ID',
      'nome': nome,
      'descricao': descricao.substring(0, min(20, descricao.length)) + (descricao.length > 20 ? '...' : ''),
      'contato': contato,
      'userId': userId,
      'hasId': hasId,
      'criadoEm': criadoEm?.toString() ?? 'N/A',
      'atualizadoEm': atualizadoEm?.toString() ?? 'N/A',
    };
  }

  int min(int a, int b) => a < b ? a : b;
}
import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutoModel {
  final String? id;
  final String nome;
  final String descricao;
  final String preco;
  final String contato;
  final String? imagemBase64;
  final String? lojaId;
  final String? userId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final int? estoque;
  final bool ativo;
  final String? categoria;

  ProdutoModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.contato,
    this.imagemBase64,
    this.lojaId,
    this.userId,
    this.criadoEm,
    this.atualizadoEm,
    this.estoque,
    this.ativo = true,
    this.categoria,
  });

  factory ProdutoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProdutoModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      preco: data['preco'] ?? '',
      contato: data['contato'] ?? '',
      imagemBase64: data['imagemBase64'],
      lojaId: data['lojaId'],
      userId: data['userId'],
      criadoEm: data['criadoEm']?.toDate(),
      atualizadoEm: data['atualizadoEm']?.toDate(),
      estoque: data['estoque'],
      ativo: data['ativo'] ?? true,
      categoria: data['categoria'] ?? 'Geral',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'contato': contato,
      'imagemBase64': imagemBase64 ?? '',
      'lojaId': lojaId,
      'userId': userId,
      'criadoEm': criadoEm != null 
          ? Timestamp.fromDate(criadoEm!) 
          : FieldValue.serverTimestamp(),
      'atualizadoEm': atualizadoEm != null 
          ? Timestamp.fromDate(atualizadoEm!) 
          : FieldValue.serverTimestamp(),
      'estoque': estoque,
      'ativo': ativo,
      'categoria': categoria ?? 'Geral',
    };
  }

  double get precoAsDouble {
    try {
      return double.parse(preco.replaceAll('R\$', '').replaceAll(',', '.').trim());
    } catch (e) {
      return 0.0;
    }
  }

  bool get temEstoque {
    return estoque == null || estoque! > 0;
  }

  ProdutoModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? preco,
    String? contato,
    String? imagemBase64,
    String? lojaId,
    String? userId,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    int? estoque,
    bool? ativo,
    String? categoria,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      contato: contato ?? this.contato,
      imagemBase64: imagemBase64 ?? this.imagemBase64,
      lojaId: lojaId ?? this.lojaId,
      userId: userId ?? this.userId,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      estoque: estoque ?? this.estoque,
      ativo: ativo ?? this.ativo,
      categoria: categoria ?? this.categoria,
    );
  }
}
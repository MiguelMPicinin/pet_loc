import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'location.dart';

class AreaBuscaModel {
  final String? id;
  final LocationModel centro;
  final double raioKm;
  final String? petId;
  final String? userId;
  final String? descricao;
  final DateTime? criadoEm;
  final bool ativa;

  AreaBuscaModel({
    this.id,
    required this.centro,
    required this.raioKm,
    this.petId,
    this.userId,
    this.descricao,
    DateTime? criadoEm,
    this.ativa = true,
  }) : criadoEm = criadoEm;

  // Converter para Map (Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'centro': centro.toFirestore(),
      'raioKm': raioKm,
      'petId': petId,
      'userId': userId,
      'descricao': descricao,
      'criadoEm': criadoEm != null 
          ? Timestamp.fromDate(criadoEm!)
          : Timestamp.fromDate(DateTime.now()),
      'ativa': ativa,
    };
  }

  // Criar a partir do Firestore
  factory AreaBuscaModel.fromFirestore(Map<String, dynamic> data, String id) {
    Timestamp? timestamp = data['criadoEm'] as Timestamp?;
    
    return AreaBuscaModel(
      id: id,
      centro: LocationModel.fromFirestore(data['centro']),
      raioKm: (data['raioKm'] as num?)?.toDouble() ?? 0.0,
      petId: data['petId'],
      userId: data['userId'],
      descricao: data['descricao'],
      criadoEm: timestamp?.toDate(),
      ativa: data['ativa'] ?? true,
    );
  }

  // Criar a partir do JSON
  factory AreaBuscaModel.fromJson(Map<String, dynamic> json) {
    return AreaBuscaModel(
      id: json['id'],
      centro: LocationModel.fromJson(json['centro']),
      raioKm: (json['raioKm'] as num?)?.toDouble() ?? 0.0,
      petId: json['petId'],
      userId: json['userId'],
      descricao: json['descricao'],
      criadoEm: json['criadoEm'] != null 
          ? DateTime.parse(json['criadoEm'])
          : null,
      ativa: json['ativa'] ?? true,
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'centro': centro.toJson(),
      'raioKm': raioKm,
      'petId': petId,
      'userId': userId,
      'descricao': descricao,
      'criadoEm': criadoEm?.toIso8601String(),
      'ativa': ativa,
    };
  }

  // Copiar com alterações
  AreaBuscaModel copyWith({
    String? id,
    LocationModel? centro,
    double? raioKm,
    String? petId,
    String? userId,
    String? descricao,
    DateTime? criadoEm,
    bool? ativa,
  }) {
    return AreaBuscaModel(
      id: id ?? this.id,
      centro: centro ?? this.centro,
      raioKm: raioKm ?? this.raioKm,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      descricao: descricao ?? this.descricao,
      criadoEm: criadoEm ?? this.criadoEm,
      ativa: ativa ?? this.ativa,
    );
  }

  // Verificar se uma localização está dentro da área de busca
  bool containsLocation(LocationModel location) {
    return _calculateDistance(
      centro.latitude,
      centro.longitude,
      location.latitude,
      location.longitude,
    ) <= raioKm;
  }

  // Calcular distância entre dois pontos (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // Raio da Terra em km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * 3.141592653589793 / 180;

  // Obter coordenadas do bounding box (útil para mapas)
  Map<String, double> getBoundingBox() {
    const earthRadius = 6371.0;
    
    final deltaLat = (raioKm / earthRadius) * (180 / 3.141592653589793);
    final deltaLon = deltaLat / cos(_degreesToRadians(centro.latitude));

    return {
      'minLat': centro.latitude - deltaLat,
      'maxLat': centro.latitude + deltaLat,
      'minLon': centro.longitude - deltaLon,
      'maxLon': centro.longitude + deltaLon,
    };
  }

  // Verificar se esta área sobrepõe outra área
  bool overlapsWith(AreaBuscaModel other) {
    final distanciaEntreCentros = _calculateDistance(
      centro.latitude,
      centro.longitude,
      other.centro.latitude,
      other.centro.longitude,
    );
    
    return distanciaEntreCentros <= (raioKm + other.raioKm);
  }

  // Calcular área aproximada em km²
  double get areaKm2 {
    return 3.141592653589793 * raioKm * raioKm;
  }

  // Verificar se a área é válida
  bool get isValid {
    return raioKm > 0 && centro.isValid;
  }

  // Obter data de criação efetiva
  DateTime get effectiveCriadoEm {
    return criadoEm ?? DateTime.now();
  }

  // Descrição formatada
  String get descricaoFormatada {
    if (descricao != null && descricao!.isNotEmpty) {
      return descricao!;
    }
    
    if (petId != null) {
      return 'Busca do Pet $petId';
    }
    
    return 'Área de Busca ${raioKm.toStringAsFixed(1)}km';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AreaBuscaModel &&
        other.id == id &&
        other.centro == centro &&
        other.raioKm == raioKm &&
        other.petId == petId &&
        other.userId == userId &&
        other.descricao == descricao &&
        other.criadoEm == criadoEm &&
        other.ativa == ativa;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      centro,
      raioKm,
      petId,
      userId,
      descricao,
      criadoEm,
      ativa,
    );
  }

  @override
  String toString() {
    return 'AreaBuscaModel('
        'id: $id, '
        'centro: $centro, '
        'raioKm: $raioKm, '
        'petId: $petId, '
        'userId: $userId, '
        'descricao: $descricao, '
        'criadoEm: $criadoEm, '
        'ativa: $ativa'
        ')';
  }
}
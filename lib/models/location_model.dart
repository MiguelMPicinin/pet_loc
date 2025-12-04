// models/location_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String? id;
  final String? petId;
  final double latitude;
  final double longitude;
  final String? endereco;
  final String? cidade;
  final String? estado;
  final String? cep;
  final DateTime? timestamp;
  final String? encontradoPor;
  final String? telefoneEncontrado;
  final bool? confirmado;

  LocationModel({
    this.id,
    this.petId,
    required this.latitude,
    required this.longitude,
    this.endereco,
    this.cidade,
    this.estado,
    this.cep,
    this.timestamp,
    this.encontradoPor,
    this.telefoneEncontrado,
    this.confirmado = false,
  });

  // Converter para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (petId != null) 'petId': petId,
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'timestamp': timestamp != null 
          ? Timestamp.fromDate(timestamp!)
          : Timestamp.fromDate(DateTime.now()),
      'encontradoPor': encontradoPor,
      'telefoneEncontrado': telefoneEncontrado,
      'confirmado': confirmado ?? false,
    };
  }

  // Criar a partir do Firestore
  factory LocationModel.fromFirestore(Map<String, dynamic> data, String? id) {
    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    
    return LocationModel(
      id: id,
      petId: data['petId'],
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      endereco: data['endereco'],
      cidade: data['cidade'],
      estado: data['estado'],
      cep: data['cep'],
      timestamp: timestamp?.toDate(),
      encontradoPor: data['encontradoPor'],
      telefoneEncontrado: data['telefoneEncontrado'],
      confirmado: data['confirmado'] as bool? ?? false,
    );
  }

  // Criar a partir do JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      petId: json['petId'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      endereco: json['endereco'],
      cidade: json['cidade'],
      estado: json['estado'],
      cep: json['cep'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : null,
      encontradoPor: json['encontradoPor'],
      telefoneEncontrado: json['telefoneEncontrado'],
      confirmado: json['confirmado'] as bool? ?? false,
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (petId != null) 'petId': petId,
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'timestamp': timestamp?.toIso8601String(),
      'encontradoPor': encontradoPor,
      'telefoneEncontrado': telefoneEncontrado,
      'confirmado': confirmado,
    };
  }

  // Copiar com alterações
  LocationModel copyWith({
    String? id,
    String? petId,
    double? latitude,
    double? longitude,
    String? endereco,
    String? cidade,
    String? estado,
    String? cep,
    DateTime? timestamp,
    String? encontradoPor,
    String? telefoneEncontrado,
    bool? confirmado,
  }) {
    return LocationModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      endereco: endereco ?? this.endereco,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      cep: cep ?? this.cep,
      timestamp: timestamp ?? this.timestamp,
      encontradoPor: encontradoPor ?? this.encontradoPor,
      telefoneEncontrado: telefoneEncontrado ?? this.telefoneEncontrado,
      confirmado: confirmado ?? this.confirmado,
    );
  }

  // Verificar se a localização é válida
  bool get isValid {
    return latitude >= -90 && 
           latitude <= 90 &&
           longitude >= -180 && 
           longitude <= 180;
  }

  // Obter timestamp atual se for nulo
  DateTime get effectiveTimestamp {
    return timestamp ?? DateTime.now();
  }

  // Descrição formatada do endereço
  String get enderecoFormatado {
    final parts = [endereco, cidade, estado, cep].where((part) => part != null && part!.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Lat: $latitude, Lng: $longitude';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LocationModel &&
        other.id == id &&
        other.petId == petId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.endereco == endereco &&
        other.cidade == cidade &&
        other.estado == estado &&
        other.cep == cep &&
        other.timestamp == timestamp &&
        other.encontradoPor == encontradoPor &&
        other.telefoneEncontrado == telefoneEncontrado &&
        other.confirmado == confirmado;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      petId,
      latitude,
      longitude,
      endereco,
      cidade,
      estado,
      cep,
      timestamp,
      encontradoPor,
      telefoneEncontrado,
      confirmado,
    );
  }

  @override
  String toString() {
    return 'LocationModel('
        'id: $id, '
        'petId: $petId, '
        'lat: $latitude, '
        'lng: $longitude, '
        'endereco: $endereco, '
        'cidade: $cidade, '
        'estado: $estado, '
        'cep: $cep, '
        'timestamp: $timestamp, '
        'encontradoPor: $encontradoPor, '
        'telefoneEncontrado: $telefoneEncontrado, '
        'confirmado: $confirmado'
        ')';
  }
}
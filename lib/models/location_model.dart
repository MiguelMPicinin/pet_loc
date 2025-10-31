import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String? endereco;
  final String? cidade;
  final String? estado;
  final String? cep;
  final DateTime? timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.endereco,
    this.cidade,
    this.estado,
    this.cep,
    this.timestamp,
  });

  // Converter para Map (Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'timestamp': timestamp != null 
          ? Timestamp.fromDate(timestamp!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  // Criar a partir do Firestore
  factory LocationModel.fromFirestore(Map<String, dynamic> data) {
    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    
    return LocationModel(
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      endereco: data['endereco'],
      cidade: data['cidade'],
      estado: data['estado'],
      cep: data['cep'],
      timestamp: timestamp?.toDate(),
    );
  }

  // Criar a partir do JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      endereco: json['endereco'],
      cidade: json['cidade'],
      estado: json['estado'],
      cep: json['cep'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  // Copiar com alterações
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? endereco,
    String? cidade,
    String? estado,
    String? cep,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      endereco: endereco ?? this.endereco,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      cep: cep ?? this.cep,
      timestamp: timestamp ?? this.timestamp,
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
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.endereco == endereco &&
        other.cidade == cidade &&
        other.estado == estado &&
        other.cep == cep &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      latitude,
      longitude,
      endereco,
      cidade,
      estado,
      cep,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'LocationModel('
        'lat: $latitude, '
        'lng: $longitude, '
        'endereco: $endereco, '
        'cidade: $cidade, '
        'estado: $estado, '
        'cep: $cep, '
        'timestamp: $timestamp'
        ')';
  }
}
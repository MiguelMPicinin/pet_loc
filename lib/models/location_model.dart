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
  final bool isQRCodeLocation;
  final String? source;
  final String? finderName;
  final String? finderPhone;

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
    this.isQRCodeLocation = false,
    this.source = 'app',
    this.finderName,
    this.finderPhone,
  });

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
          : FieldValue.serverTimestamp(),
      'encontradoPor': encontradoPor,
      'telefoneEncontrado': telefoneEncontrado,
      'confirmado': confirmado ?? false,
      'isQRCodeLocation': isQRCodeLocation,
      'source': source,
      'finderName': finderName ?? encontradoPor,
      'finderPhone': finderPhone ?? telefoneEncontrado,
    };
  }

  factory LocationModel.fromFirestore(Map<String, dynamic> data, String? id) {
    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    
    return LocationModel(
      id: id,
      petId: data['petId'],
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      endereco: data['endereco'] ?? data['address'],
      cidade: data['cidade'],
      estado: data['estado'],
      cep: data['cep'],
      timestamp: timestamp?.toDate(),
      encontradoPor: data['encontradoPor'] ?? data['finderName'],
      telefoneEncontrado: data['telefoneEncontrado'] ?? data['finderPhone'],
      confirmado: data['confirmado'] as bool? ?? false,
      isQRCodeLocation: data['isQRCodeLocation'] as bool? ?? false,
      source: data['source'] as String? ?? 'app',
      finderName: data['finderName'],
      finderPhone: data['finderPhone'],
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      petId: json['petId'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      endereco: json['endereco'] ?? json['address'],
      cidade: json['cidade'],
      estado: json['estado'],
      cep: json['cep'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : null,
      encontradoPor: json['encontradoPor'] ?? json['finderName'],
      telefoneEncontrado: json['telefoneEncontrado'] ?? json['finderPhone'],
      confirmado: json['confirmado'] as bool? ?? false,
      isQRCodeLocation: json['isQRCodeLocation'] as bool? ?? false,
      source: json['source'] as String? ?? 'qr_code',
      finderName: json['finderName'],
      finderPhone: json['finderPhone'],
    );
  }

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
    bool? isQRCodeLocation,
    String? source,
    String? finderName,
    String? finderPhone,
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
      isQRCodeLocation: isQRCodeLocation ?? this.isQRCodeLocation,
      source: source ?? this.source,
      finderName: finderName ?? this.finderName,
      finderPhone: finderPhone ?? this.finderPhone,
    );
  }

  bool get isValid {
    return latitude >= -90 && 
           latitude <= 90 &&
           longitude >= -180 && 
           longitude <= 180;
  }

  DateTime get effectiveTimestamp {
    return timestamp ?? DateTime.now();
  }

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
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, petId, latitude, longitude, timestamp);
  }
}
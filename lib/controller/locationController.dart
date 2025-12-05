import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';

class LocationController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Position? _currentPosition;
  LocationModel? _currentLocation;
  bool _isLoading = false;
  String? _error;
  bool _locationEnabled = false;
  StreamSubscription<Position>? _positionStream;
  Map<String, List<LocationModel>> _petLocations = {};

  // Getters
  Position? get currentPosition => _currentPosition;
  LocationModel? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get locationEnabled => _locationEnabled;

  // Obter localizações de um pet específico
  List<LocationModel> getPetLocations(String petId) {
    return _petLocations[petId] ?? [];
  }

  // Obter localização mais recente do pet
  LocationModel? getLatestPetLocation(String petId) {
    final locations = getPetLocations(petId);
    if (locations.isEmpty) return null;
    
    return locations.first;
  }

  // Inicializar controller
  LocationController() {
    _initializeLocation();
  }

  // Inicializar serviços de localização
  Future<void> _initializeLocation() async {
    try {
      _setLoading(true);
      
      _locationEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (_locationEnabled) {
        await _checkPermissions();
        await _getInitialLocation(); // CORREÇÃO: método renomeado
        await _startLocationStream();
      }
      
      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao inicializar localização: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // CORREÇÃO: Método _getCurrentLocation renomeado para _getInitialLocation
  Future<void> _getInitialLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obter endereço das coordenadas
      String endereco = await _getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final location = LocationModel(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        endereco: endereco,
        timestamp: DateTime.now(),
      );

      _currentLocation = location;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao obter localização inicial: $e';
      notifyListeners();
    }
  }

  // Verificar e solicitar permissões
  Future<bool> _checkPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          _error = 'Permissão de localização negada';
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _error = 'Permissão de localização permanentemente negada. Ative nas configurações.';
        return false;
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      _error = 'Erro ao verificar permissões: $e';
      return false;
    }
  }

  // Obter localização atual
  Future<LocationModel?> getCurrentLocationWithAddress() async {
    try {
      _setLoading(true);
      
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        _setLoading(false);
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obter endereço das coordenadas
      String endereco = await _getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final location = LocationModel(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        endereco: endereco,
        timestamp: DateTime.now(),
      );

      _currentLocation = location;
      _setLoading(false);
      
      return location;
    } catch (e) {
      _error = 'Erro ao obter localização: $e';
      _setLoading(false);
      return null;
    }
  }

  // Obter endereço a partir das coordenadas
  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      
      if (places.isNotEmpty) {
        final place = places.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea
        ].where((part) => part != null && part!.isNotEmpty).toList();
        
        return parts.isNotEmpty ? parts.join(', ') : 'Endereço não disponível';
      }
      return 'Endereço não disponível';
    } catch (e) {
      return 'Lat: $lat, Lng: $lng';
    }
  }

  // Iniciar stream de localização em tempo real
  Future<void> _startLocationStream() async {
    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) return;

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // metros
        ),
      ).listen((Position position) {
        _currentPosition = position;
        notifyListeners();
      });
    } catch (e) {
      print('Erro ao iniciar stream de localização: $e');
    }
  }

  // Salvar localização do pet no Firestore
  Future<bool> savePetLocation({
    required String petId,
    required LocationModel location,
    String? encontradoPor,
    String? telefoneEncontrado,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final locationWithPet = location.copyWith(
        petId: petId,
        encontradoPor: encontradoPor,
        telefoneEncontrado: telefoneEncontrado,
      );

      await _firestore.collection('pet_locations').add(
        locationWithPet.toFirestore(),
      );

      // Adicionar à lista local
      if (_petLocations[petId] == null) {
        _petLocations[petId] = [];
      }
      _petLocations[petId]!.insert(0, locationWithPet);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao salvar localização: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Carregar localizações de um pet
  Future<void> loadPetLocations(String petId) async {
    try {
      _setLoading(true);
      _error = null;

      final snapshot = await _firestore
          .collection('pet_locations')
          .where('petId', isEqualTo: petId)
          .orderBy('timestamp', descending: true)
          .get();

      final locations = snapshot.docs.map((doc) {
        return LocationModel.fromFirestore(doc.data(), doc.id);
      }).toList();

      _petLocations[petId] = locations;
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar localizações: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Calcular distância entre duas localizações
  double calculateDistance(LocationModel loc1, LocationModel loc2) {
    const earthRadius = 6371.0; // km

    final lat1 = _degreesToRadians(loc1.latitude);
    final lon1 = _degreesToRadians(loc1.longitude);
    final lat2 = _degreesToRadians(loc2.latitude);
    final lon2 = _degreesToRadians(loc2.longitude);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Forçar recarregamento das localizações
  Future<void> refreshPetLocations(String petId) async {
    await loadPetLocations(petId);
  }

  // Limpar erros
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Controlar estado de loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';

class LocationController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Position? _currentPosition;
  LocationModel? _currentLocation;
  bool _isLoading = false;
  String? _error;
  bool _locationEnabled = false;
  StreamSubscription<Position>? _positionStream;
  
  final Map<String, List<LocationModel>> _locations = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _locationStreams = {};
  final Map<String, DateTime> _lastUpdateTime = {};
  final Map<String, List<VoidCallback>> _locationListeners = {};
  
  Timer? _syncTimer;
  UserModel? _currentUser;

  Position? get currentPosition => _currentPosition;
  LocationModel? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get locationEnabled => _locationEnabled;

  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  List<LocationModel> getPetLocations(String petId) {
    return _locations[petId] ?? [];
  }

  List<LocationModel> getAllPetLocations(String petId) {
    return getPetLocations(petId);
  }

  LocationModel? getLatestPetLocation(String petId) {
    final locations = getPetLocations(petId);
    if (locations.isEmpty) return null;
    
    locations.sort((a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp));
    return locations.first;
  }

  bool isListenerHealthy(String petId) {
    if (!_locationStreams.containsKey(petId)) {
      return false;
    }
    
    final lastUpdate = _lastUpdateTime[petId];
    if (lastUpdate == null) {
      return false;
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    return difference.inSeconds < 120;
  }

  void addLocationListener(String petId, VoidCallback callback) {
    if (!_locationListeners.containsKey(petId)) {
      _locationListeners[petId] = [];
    }
    _locationListeners[petId]!.add(callback);
  }

  void removeLocationListener(String petId, VoidCallback callback) {
    _locationListeners[petId]?.remove(callback);
  }

  void _notifyLocationListeners(String petId) {
    _locationListeners[petId]?.forEach((listener) => listener());
  }

  LocationController() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      _setLoading(true);
      
      _locationEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (_locationEnabled) {
        await _checkPermissions();
        await _getInitialLocation();
        await _startLocationStream();
      }
      
      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao inicializar localização: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> _getInitialLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
    } catch (e) {}
  }

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

  Future<void> _startLocationStream() async {
    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) return;

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        _currentPosition = position;
        notifyListeners();
      });
    } catch (e) {}
  }

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
        isQRCodeLocation: false,
        source: 'app',
      );

      final firestoreData = locationWithPet.toFirestore();
      if (_currentUser != null) {
        firestoreData['userId'] = _currentUser!.id;
      }

      await _firestore.collection('pet_locations').add(firestoreData);

      if (_locations[petId] == null) {
        _locations[petId] = [];
      }
      _locations[petId]!.insert(0, locationWithPet);
      
      _setLoading(false);
      _notifyLocationListeners(petId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao salvar localização: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveQRCodeLocation({
    required String petId,
    required double latitude,
    required double longitude,
    required String address,
    required String finderName,
    required String finderPhone,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      if (!LocationModel(
        latitude: latitude,
        longitude: longitude,
        endereco: address,
      ).isValid) {
        throw Exception('Coordenadas inválidas');
      }

      final locationData = {
        'petId': petId,
        'latitude': latitude,
        'longitude': longitude,
        'endereco': address,
        'address': address,
        'encontradoPor': finderName,
        'finderName': finderName,
        'telefoneEncontrado': finderPhone,
        'finderPhone': finderPhone,
        'timestamp': FieldValue.serverTimestamp(),
        'timestamp_client': DateTime.now().toIso8601String(),
        'source': 'qr_code',
        'isQRCodeLocation': true,
        'confirmado': false,
        'status': 'active',
        'validatedAt': FieldValue.serverTimestamp(),
      };

      if (_currentUser != null) {
        locationData['userId'] = _currentUser!.id;
      }

      final docRef = await _firestore.collection('pet_locations').add(locationData);

      final location = LocationModel(
        id: docRef.id,
        petId: petId,
        latitude: latitude,
        longitude: longitude,
        endereco: address,
        encontradoPor: finderName,
        telefoneEncontrado: finderPhone,
        timestamp: DateTime.now(),
        isQRCodeLocation: true,
        confirmado: false,
        source: 'qr_code',
        finderName: finderName,
        finderPhone: finderPhone,
      );

      if (_locations[petId] == null) {
        _locations[petId] = [];
      }
      _locations[petId]!.insert(0, location);
      
      _setLoading(false);
      _notifyLocationListeners(petId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Erro ao salvar localização QR Code: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAllPetLocations(String petId) async {
    try {
      _setLoading(true);
      _error = null;
      
      await startPetLocationListener(petId);
      
      final snapshot = await _firestore
          .collection('pet_locations')
          .where('petId', isEqualTo: petId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      final List<LocationModel> allLocations = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final location = LocationModel.fromFirestore(data, doc.id);
          
          if (location.isValid) {
            allLocations.add(location);
          }
        } catch (e) {}
      }
      
      allLocations.sort((a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp));
      
      _locations[petId] = allLocations;
      _lastUpdateTime[petId] = DateTime.now();
      
      _setLoading(false);
      _notifyLocationListeners(petId);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar localizações: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> startPetLocationListener(String petId) async {
    try {
      _locationStreams[petId]?.cancel();
      
      final stream = _firestore
          .collection('pet_locations')
          .where('petId', isEqualTo: petId)
          .orderBy('timestamp', descending: true)
          .snapshots();
      
      _locationStreams[petId] = stream.listen((snapshot) {
        final List<LocationModel> allLocations = [];
        
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final location = LocationModel.fromFirestore(data, doc.id);
            
            if (location.isValid) {
              allLocations.add(location);
            }
          } catch (e) {}
        }
        
        allLocations.sort((a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp));
        
        _locations[petId] = allLocations;
        _lastUpdateTime[petId] = DateTime.now();
        
        _notifyLocationListeners(petId);
        notifyListeners();
        
      }, onError: (error) {
        _error = 'Erro no listener: $error';
        notifyListeners();
      });
      
    } catch (e) {
      _error = 'Erro ao iniciar listener: $e';
      notifyListeners();
    }
  }

  double calculateDistance(LocationModel loc1, LocationModel loc2) {
    const earthRadius = 6371.0;

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

  Future<void> refreshPetLocations(String petId) async {
    await loadAllPetLocations(petId);
  }

  void stopPetLocationListener(String petId) {
    _locationStreams[petId]?.cancel();
    _locationStreams.remove(petId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    
    _locationStreams.values.forEach((stream) => stream.cancel());
    _locationStreams.clear();
    
    _syncTimer?.cancel();
    
    super.dispose();
  }
}
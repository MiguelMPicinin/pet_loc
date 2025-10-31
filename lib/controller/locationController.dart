import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';
import '../models/area_busca_model.dart';

class LocationController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Position? _currentPosition;
  LocationModel? _currentLocation;
  List<AreaBuscaModel> _areasBusca = [];
  bool _isLoading = false;
  String? _error;
  bool _locationEnabled = false;
  StreamSubscription<Position>? _positionStream;
  List<LocationModel> _ultimosAvistamentos = [];

  // Getters
  Position? get currentPosition => _currentPosition;
  LocationModel? get currentLocation => _currentLocation;
  List<AreaBuscaModel> get areasBusca => _areasBusca;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get locationEnabled => _locationEnabled;
  List<LocationModel> get ultimosAvistamentos => _ultimosAvistamentos;

  // Inicializar controller
  LocationController() {
    _initializeLocation();
  }

  // Inicializar serviços de localização
  Future<void> _initializeLocation() async {
    try {
      _setLoading(true);
      
      // Verificar se a localização está habilitada
      _locationEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (_locationEnabled) {
        await _checkPermissions();
        await _getCurrentLocation();
        await _startLocationStream();
      }
      
      await _loadAreasBusca();
      await _loadUltimosAvistamentos();
      
      _setLoading(false);
    } catch (e) {
      _error = 'Erro ao inicializar localização: $e';
      _setLoading(false);
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
  Future<bool> _getCurrentLocation() async {
    try {
      _setLoading(true);
      
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        _setLoading(false);
        return false;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Converter coordenadas em endereço
      await _getAddressFromCoordinates();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao obter localização: $e';
      _setLoading(false);
      return false;
    }
  }

  // Obter endereço a partir das coordenadas
  Future<void> _getAddressFromCoordinates() async {
    if (_currentPosition == null) return;

    try {
      final places = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (places.isNotEmpty) {
        final place = places.first;
        
        _currentLocation = LocationModel(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          endereco: '${place.street ?? ''} ${place.name ?? ''}'.trim(),
          cidade: place.locality,
          estado: place.administrativeArea,
          cep: place.postalCode,
          timestamp: DateTime.now(),
        );
        
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao obter endereço: $e');
      // Mesmo sem endereço, criamos a localização com coordenadas
      _currentLocation = LocationModel(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        timestamp: DateTime.now(),
      );
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
        _updateCurrentLocation(position);
      });
    } catch (e) {
      print('Erro ao iniciar stream de localização: $e');
    }
  }

  // Atualizar localização atual
  Future<void> _updateCurrentLocation(Position position) async {
    _currentLocation = LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
    
    notifyListeners();
  }

  // Forçar atualização da localização
  Future<bool> refreshLocation() async {
    return await _getCurrentLocation();
  }

  // Carregar áreas de busca
  Future<void> _loadAreasBusca() async {
    try {
      final snapshot = await _firestore
          .collection('areas_busca')
          .orderBy('criadoEm', descending: true)
          .get();

      _areasBusca = snapshot.docs
          .map((doc) => AreaBuscaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar áreas de busca: $e');
    }
  }

  // Carregar últimos avistamentos
  Future<void> _loadUltimosAvistamentos() async {
    try {
      final snapshot = await _firestore
          .collection('avistamentos')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _ultimosAvistamentos = snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao carregar últimos avistamentos: $e');
    }
  }

  // Registrar avistamento de pet desaparecido
  Future<bool> registrarAvistamento({
    required LocationModel localizacao,
    required String petId,
    required String userId,
    String? observacoes,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _firestore.collection('avistamentos').add({
        ...localizacao.toFirestore(),
        'petId': petId,
        'userId': userId,
        'observacoes': observacoes,
        'confirmado': false,
      });

      // Recarregar últimos avistamentos
      await _loadUltimosAvistamentos();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao registrar avistamento: $e';
      _setLoading(false);
      return false;
    }
  }

  // Criar área de busca
  Future<bool> criarAreaBusca({
    required LocationModel centro,
    required double raioKm,
    String? petId,
    String? userId,
    String? descricao,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final areaBusca = AreaBuscaModel(
        centro: centro,
        raioKm: raioKm,
        petId: petId,
        userId: userId,
        descricao: descricao,
      );

      await _firestore
          .collection('areas_busca')
          .add(areaBusca.toFirestore());

      // Recarregar áreas de busca
      await _loadAreasBusca();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro ao criar área de busca: $e';
      _setLoading(false);
      return false;
    }
  }

  // Buscar avistamentos próximos
  Future<List<LocationModel>> buscarAvistamentosProximos({
    required LocationModel localizacao,
    double raioKm = 10.0,
    String? petId,
  }) async {
    try {
      // Esta é uma implementação simplificada
      // Em produção, você usaria Geohashes ou Firebase Geoqueries
      
      final snapshot = await _firestore
          .collection('avistamentos')
          .where('petId', isEqualTo: petId)
          .get();

      final todosAvistamentos = snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc.data()))
          .toList();

      // Filtrar por distância
      return todosAvistamentos.where((avistamento) {
        final distancia = _calculateDistance(
          localizacao.latitude,
          localizacao.longitude,
          avistamento.latitude,
          avistamento.longitude,
        );
        return distancia <= raioKm;
      }).toList();
    } catch (e) {
      _error = 'Erro ao buscar avistamentos próximos: $e';
      return [];
    }
  }

  // Calcular distância entre dois pontos
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;

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

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Buscar endereço por texto
  Future<List<LocationModel>> buscarEndereco(String query) async {
    try {
      if (query.isEmpty) return [];

      final locations = await locationFromAddress(query);
      
      return locations.map((location) {
        return LocationModel(
          latitude: location.latitude,
          longitude: location.longitude,
          endereco: query,
          timestamp: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      _error = 'Erro ao buscar endereço: $e';
      return [];
    }
  }

  // Obter coordenadas por endereço
  Future<LocationModel?> getCoordenadasPorEndereco(String endereco) async {
    try {
      final locations = await locationFromAddress(endereco);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LocationModel(
          latitude: location.latitude,
          longitude: location.longitude,
          endereco: endereco,
          timestamp: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      _error = 'Erro ao obter coordenadas: $e';
      return null;
    }
  }

  // Verificar se está dentro de uma área de busca
  List<AreaBuscaModel> getAreasBuscaProximas() {
    if (_currentLocation == null) return [];

    return _areasBusca.where((area) {
      return area.containsLocation(_currentLocation!);
    }).toList();
  }

  // Calcular rota entre dois pontos (simplificado)
  double calcularDistanciaPara(LocationModel destino) {
    if (_currentLocation == null) return 0.0;

    return _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      destino.latitude,
      destino.longitude,
    );
  }

  // Obter direções (URL para apps externos)
  String getGoogleMapsUrl(LocationModel destino) {
    return 'https://www.google.com/maps/dir/?api=1'
           '&origin=${_currentLocation?.latitude},${_currentLocation?.longitude}'
           '&destination=${destino.latitude},${destino.longitude}'
           '&travelmode=driving';
  }

  String getWazeUrl(LocationModel destino) {
    return 'https://waze.com/ul?ll=${destino.latitude},${destino.longitude}&navigate=yes';
  }

  // Abrir configurações de localização
  Future<void> abrirConfiguracoesLocalizacao() async {
    await Geolocator.openLocationSettings();
  }

  // Verificar status da localização
  Future<void> verificarStatusLocalizacao() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled != _locationEnabled) {
      _locationEnabled = enabled;
      notifyListeners();
    }
  }

  // Controlar estado de loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Limpar erros
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Forçar recarregamento
  Future<void> refresh() async {
    await _initializeLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pet_loc/controller/locationController.dart';
import 'package:pet_loc/models/location_model.dart';
import 'package:pet_loc/controller/authController.dart';

class LocalizacaoPetView extends StatefulWidget {
  final String petId;
  final String? petNome;

  const LocalizacaoPetView({Key? key, required this.petId, this.petNome}) : super(key: key);

  @override
  _LocalizacaoPetViewState createState() => _LocalizacaoPetViewState();
}

class _LocalizacaoPetViewState extends State<LocalizacaoPetView> {
  late MapController _mapController;
  bool _isLoading = true;
  List<LocationModel> _locations = [];
  LocationModel? _latestLocation;
  LatLngBounds? _bounds;
  
  LatLng? _currentUserLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  double _currentZoom = 15.0;
  Timer? _refreshTimer;
  bool _hasListener = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController();
    });
  }

  void _initializeController() {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final locationController = Provider.of<LocationController>(context, listen: false);
      
      locationController.setUser(authController.currentUser);
      
      _loadLocations();
      _startLocationUpdates();
      _startAutoRefresh();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_hasListener) {
      _hasListener = true;
      
      final locationController = Provider.of<LocationController>(context, listen: false);
      
      locationController.addLocationListener(widget.petId, () {
        _onLocationsUpdated();
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkForUpdates();
      }
    });
  }

  void _checkForUpdates() {
    final locationController = Provider.of<LocationController>(context, listen: false);
    final locations = locationController.getPetLocations(widget.petId);
    
    if (locations.length != _locations.length || 
        (locations.isNotEmpty && _locations.isNotEmpty && 
         locations.first.id != _locations.first.id)) {
      _onLocationsUpdated();
    }
  }

  void _onLocationsUpdated() {
    final locationController = Provider.of<LocationController>(context, listen: false);
    final locations = locationController.getPetLocations(widget.petId);
    
    setState(() {
      _locations = locations;
      if (locations.isNotEmpty) {
        _latestLocation = locations.first;
        _updateMapBounds();
      }
    });
    
    if (locations.isNotEmpty && locations.first.isQRCodeLocation) {
      _showNewLocationSnackbar(locations.first);
    }
  }

  void _showNewLocationSnackbar(LocationModel location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📍 Nova localização compartilhada!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${location.finderName ?? "Alguém"} compartilhou a localização do seu pet',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isBoundsValid(LatLngBounds? bounds) {
    if (bounds == null) return false;
    
    bool isCoordinateValid(double lat, double lng) {
      return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
    }
    
    return isCoordinateValid(bounds.southWest.latitude, bounds.southWest.longitude) &&
           isCoordinateValid(bounds.northEast.latitude, bounds.northEast.longitude) &&
           bounds.southWest.latitude <= bounds.northEast.latitude &&
           bounds.southWest.longitude <= bounds.northEast.longitude;
  }

  void _updateMapBounds() {
    if (_locations.isNotEmpty || _currentUserLocation != null) {
      double minLat = _locations.isNotEmpty ? _locations.first.latitude : _currentUserLocation!.latitude;
      double maxLat = _locations.isNotEmpty ? _locations.first.latitude : _currentUserLocation!.latitude;
      double minLng = _locations.isNotEmpty ? _locations.first.longitude : _currentUserLocation!.longitude;
      double maxLng = _locations.isNotEmpty ? _locations.first.longitude : _currentUserLocation!.longitude;
      
      for (var location in _locations) {
        if (location.latitude < minLat) minLat = location.latitude;
        if (location.latitude > maxLat) maxLat = location.latitude;
        if (location.longitude < minLng) minLng = location.longitude;
        if (location.longitude > maxLng) maxLng = location.longitude;
      }
      
      if (_currentUserLocation != null) {
        if (_currentUserLocation!.latitude < minLat) minLat = _currentUserLocation!.latitude;
        if (_currentUserLocation!.latitude > maxLat) maxLat = _currentUserLocation!.latitude;
        if (_currentUserLocation!.longitude < minLng) minLng = _currentUserLocation!.longitude;
        if (_currentUserLocation!.longitude > maxLng) maxLng = _currentUserLocation!.longitude;
      }
      
      const padding = 0.001;
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;
      
      if (minLat >= -90 && maxLat <= 90 && minLng >= -180 && maxLng <= 180) {
        _bounds = LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        );
      } else {
        _bounds = null;
      }
    }
  }

  Future<void> _loadLocations() async {
    try {
      final locationController = Provider.of<LocationController>(context, listen: false);
      
      await locationController.loadAllPetLocations(widget.petId);
      
      final locations = locationController.getPetLocations(widget.petId);
      
      setState(() {
        _locations = locations;
        if (locations.isNotEmpty) {
          _latestLocation = locations.first;
          
          _updateMapBounds();
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _adjustMapView();
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar localizações: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _adjustMapView() {
    if (_bounds != null && _isBoundsValid(_bounds)) {
      try {
        _mapController.fitBounds(
          _bounds!,
          options: const FitBoundsOptions(
            padding: EdgeInsets.all(50),
            maxZoom: 15.0,
          ),
        );
      } catch (e) {
        if (_latestLocation != null) {
          _mapController.move(
            LatLng(_latestLocation!.latitude, _latestLocation!.longitude),
            _currentZoom,
          );
        }
      }
    } else if (_latestLocation != null) {
      _mapController.move(
        LatLng(_latestLocation!.latitude, _latestLocation!.longitude),
        _currentZoom,
      );
    }
  }

  Future<void> _startLocationUpdates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && 
            permission != LocationPermission.always) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentUserLocation = LatLng(
          position.latitude,
          position.longitude,
        );
      });

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (position.latitude != null && position.longitude != null) {
          setState(() {
            _currentUserLocation = LatLng(
              position.latitude,
              position.longitude,
            );
          });
        }
      });
    } catch (e) {}
  }

  void _showLocationDetails(BuildContext context, LocationModel location, bool isLatest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(location.isQRCodeLocation ? 'Localização Compartilhada via QR Code' : (isLatest ? 'Última Localização' : 'Localização Anterior')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (location.isQRCodeLocation) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Localização compartilhada via QR Code',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              if (location.finderName != null && location.finderName!.isNotEmpty) ...[
                const Text('Encontrado por:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(location.finderName!),
                const SizedBox(height: 8),
              ],
              
              if (location.finderPhone != null && location.finderPhone!.isNotEmpty) ...[
                const Text('Telefone:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(location.finderPhone!),
                const SizedBox(height: 8),
              ],
              
              if (location.endereco != null && location.endereco!.isNotEmpty) ...[
                const Text('Endereço:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(location.endereco!),
                const SizedBox(height: 8),
              ],
              
              const Text('Coordenadas:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              
              const Text('Data:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${_formatDateTime(location.effectiveTimestamp)}'),
              
              if (location.isQRCodeLocation) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta localização foi compartilhada por alguém que escaneou o QR Code do seu pet',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () => _openInMaps(location),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
            ),
            child: const Text('Abrir no Maps'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(LocationModel location) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o mapa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshLocations() async {
    setState(() {
      _isLoading = true;
    });
    
    final locationController = Provider.of<LocationController>(context, listen: false);
    await locationController.refreshPetLocations(widget.petId);
    
    await Future.delayed(const Duration(seconds: 1));
    
    final locations = locationController.getPetLocations(widget.petId);
    
    setState(() {
      _locations = locations;
      if (locations.isNotEmpty) {
        _latestLocation = locations.first;
      }
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Localizações atualizadas! ${locations.length} localizações encontradas.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inSeconds < 60) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Há ${difference.inHours} h';
    } else if (difference.inDays < 30) {
      return 'Há ${difference.inDays} dias';
    } else {
      return 'Há ${(difference.inDays / 30).floor()} meses';
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    if (_currentUserLocation != null) {
      markers.add(
        Marker(
          width: 50.0,
          height: 50.0,
          point: _currentUserLocation!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'VOCÊ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (int i = 0; i < _locations.length; i++) {
      final location = _locations[i];
      final isLatest = i == 0;
      
      Color markerColor;
      IconData markerIcon;
      String markerLabel;
      double markerSize;
      
      if (location.isQRCodeLocation) {
        markerColor = Colors.green;
        markerIcon = Icons.qr_code_scanner;
        markerLabel = isLatest ? 'QR RECENTE' : 'QR';
        markerSize = 55.0;
      } else if (isLatest) {
        markerColor = Colors.red;
        markerIcon = Icons.pets;
        markerLabel = 'ÚLTIMA';
        markerSize = 50.0;
      } else {
        markerColor = const Color(0xFF1A73E8);
        markerIcon = Icons.pets;
        markerLabel = 'ANTERIOR';
        markerSize = 45.0;
      }
      
      markers.add(
        Marker(
          width: markerSize,
          height: markerSize,
          point: LatLng(location.latitude, location.longitude),
          child: GestureDetector(
            onTap: () => _showLocationDetails(context, location, isLatest),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    color: markerColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(markerSize / 2),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    markerIcon,
                    color: Colors.white,
                    size: markerSize * 0.6,
                  ),
                ),
                
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: markerColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    markerLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                if (isLatest || location.isQRCodeLocation) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatTimeAgo(location.effectiveTimestamp),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _centerOnUserLocation() {
    if (_currentUserLocation != null) {
      _mapController.move(_currentUserLocation!, _currentZoom);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centralizado em sua localização'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _centerOnPetLocation() {
    if (_latestLocation != null) {
      _mapController.move(
        LatLng(_latestLocation!.latitude, _latestLocation!.longitude),
        _currentZoom,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centralizado na última localização do pet'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showAllLocations() {
    _updateMapBounds();
    if (_bounds != null && _isBoundsValid(_bounds)) {
      _mapController.fitBounds(
        _bounds!,
        options: const FitBoundsOptions(
          padding: EdgeInsets.all(50),
          maxZoom: 15.0,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mostrando todas as localizações'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildStatusIndicator() {
    final locationController = Provider.of<LocationController>(context, listen: false);
    final isHealthy = locationController.isListenerHealthy(widget.petId);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHealthy ? Icons.circle : Icons.warning,
            color: Colors.white,
            size: 10,
          ),
          const SizedBox(width: 6),
          Text(
            isHealthy ? 'CONECTADO' : 'RECONECTANDO',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petNome != null ? 'Localização - ${widget.petNome}' : 'Localização do Pet'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          _buildStatusIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocations,
            tooltip: 'Atualizar localizações',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Carregando localizações...'),
                  SizedBox(height: 10),
                  Text(
                    'Aguardando novas localizações...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentUserLocation ?? 
                           (_latestLocation != null 
                               ? LatLng(_latestLocation!.latitude, _latestLocation!.longitude)
                               : const LatLng(-23.5505, -46.6333)),
                    zoom: _currentZoom,
                    maxZoom: 18.0,
                    minZoom: 1.0,
                    interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) {
                        setState(() {
                          _currentZoom = position.zoom!;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.petloc.app',
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),
                
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'btn_zoom_in',
                        onPressed: () {
                          setState(() {
                            _currentZoom += 1;
                          });
                          _mapController.move(_mapController.center, _currentZoom);
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.add, color: Color(0xFF1A73E8)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'btn_zoom_out',
                        onPressed: () {
                          setState(() {
                            _currentZoom -= 1;
                          });
                          _mapController.move(_mapController.center, _currentZoom);
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.remove, color: Color(0xFF1A73E8)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'btn_center_user',
                        onPressed: _centerOnUserLocation,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.my_location, color: Color(0xFF1A73E8)),
                        tooltip: 'Centralizar em mim',
                      ),
                      if (_latestLocation != null) ...[
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'btn_center_pet',
                          onPressed: _centerOnPetLocation,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.pets, color: Color(0xFF1A73E8)),
                          tooltip: 'Centralizar no pet',
                        ),
                      ],
                      if (_bounds != null && _isBoundsValid(_bounds)) ...[
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'btn_show_all',
                          onPressed: _showAllLocations,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.zoom_out_map, color: Color(0xFF1A73E8)),
                          tooltip: 'Mostrar todas as localizações',
                        ),
                      ],
                    ],
                  ),
                ),
                
                if (_locations.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildInfoCard(),
                  ),
                
                if (_locations.isEmpty && !_isLoading)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_off, size: 60, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhuma localização registrada',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Quando alguém compartilhar a localização do seu pet via QR Code, ela aparecerá aqui automaticamente!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshLocations,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A73E8),
                                ),
                                child: const Text('Atualizar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _latestLocation != null
          ? FloatingActionButton(
              onPressed: () => _openInMaps(_latestLocation!),
              backgroundColor: const Color(0xFF1A73E8),
              child: const Icon(Icons.open_in_browser, color: Colors.white),
              tooltip: 'Abrir no Maps',
            )
          : null,
    );
  }

  Widget _buildInfoCard() {
    int qrCodeLocations = _locations.where((loc) => loc.isQRCodeLocation).length;
    int trackerLocations = _locations.length - qrCodeLocations;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monitoramento em Tempo Real',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'ATIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sua localização atual',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tracker (${trackerLocations} localizações)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QR Code (${qrCodeLocations} localizações)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              
              if (_currentUserLocation != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Sua localização atual:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Lat: ${_currentUserLocation!.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  'Lng: ${_currentUserLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
              
              if (_latestLocation != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Última localização do pet:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatDateTime(_latestLocation!.effectiveTimestamp),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                if (_latestLocation!.isQRCodeLocation) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Compartilhada via QR Code',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_latestLocation!.finderName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Por: ${_latestLocation!.finderName}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ],
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Consumer<LocationController>(
                builder: (context, controller, child) {
                  final isHealthy = controller.isListenerHealthy(widget.petId);
                  return Row(
                    children: [
                      Icon(
                        isHealthy ? Icons.check_circle : Icons.warning,
                        size: 14,
                        color: isHealthy ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isHealthy 
                            ? 'Listener ativo - Recebendo atualizações em tempo real'
                            : 'Listener inativo - Tentando reconectar...',
                          style: TextStyle(
                            fontSize: 10,
                            color: isHealthy ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _refreshTimer?.cancel();
    
    final locationController = Provider.of<LocationController>(context, listen: false);
    locationController.stopPetLocationListener(widget.petId);
    
    super.dispose();
  }
}
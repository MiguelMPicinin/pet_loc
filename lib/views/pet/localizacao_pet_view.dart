import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pet_loc/controller/locationController.dart';
import 'package:pet_loc/models/location_model.dart';

class LocalizacaoPetView extends StatefulWidget {
  final String petId;

  const LocalizacaoPetView({Key? key, required this.petId}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadLocations();
    _startLocationUpdates();
  }

  Future<void> _loadLocations() async {
    try {
      final locationController = Provider.of<LocationController>(context, listen: false);
      await locationController.loadPetLocations(widget.petId);
      
      final locations = locationController.getPetLocations(widget.petId);
      
      setState(() {
        _locations = locations;
        if (locations.isNotEmpty) {
          _latestLocation = locations.first;
          
          if (locations.isNotEmpty || _currentUserLocation != null) {
            double minLat = locations.isNotEmpty ? locations.first.latitude : _currentUserLocation!.latitude;
            double maxLat = locations.isNotEmpty ? locations.first.latitude : _currentUserLocation!.latitude;
            double minLng = locations.isNotEmpty ? locations.first.longitude : _currentUserLocation!.longitude;
            double maxLng = locations.isNotEmpty ? locations.first.longitude : _currentUserLocation!.longitude;
            
            for (var location in locations) {
              minLat = location.latitude < minLat ? location.latitude : minLat;
              maxLat = location.latitude > maxLat ? location.latitude : maxLat;
              minLng = location.longitude < minLng ? location.longitude : minLng;
              maxLng = location.longitude > maxLng ? location.longitude : maxLng;
            }
            
            if (_currentUserLocation != null) {
              minLat = _currentUserLocation!.latitude < minLat ? _currentUserLocation!.latitude : minLat;
              maxLat = _currentUserLocation!.latitude > maxLat ? _currentUserLocation!.latitude : maxLat;
              minLng = _currentUserLocation!.longitude < minLng ? _currentUserLocation!.longitude : minLng;
              maxLng = _currentUserLocation!.longitude > maxLng ? _currentUserLocation!.longitude : maxLng;
            }
            
            _bounds = LatLngBounds(
              LatLng(minLat, minLng),
              LatLng(maxLat, maxLng),
            );
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_bounds != null) {
              _mapController.fitBounds(
                _bounds!,
                options: FitBoundsOptions(
                  padding: EdgeInsets.all(50),
                  maxZoom: 15.0,
                ),
              );
            }
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar localizações: $e');
      setState(() {
        _isLoading = false;
      });
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
    } catch (e) {
      print('Erro ao obter localização: $e');
    }
  }

  void _showLocationDetails(BuildContext context, LocationModel location, bool isLatest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isLatest ? 'Última Localização' : 'Localização Anterior'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (location.encontradoPor != null) ...[
                Text('Encontrado por: ${location.encontradoPor}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              if (location.telefoneEncontrado != null) ...[
                Text('Telefone: ${location.telefoneEncontrado}'),
                const SizedBox(height: 8),
              ],
              if (location.endereco != null) ...[
                Text('Endereço: ${location.endereco}'),
                const SizedBox(height: 8),
              ],
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              Text('Data: ${_formatDateTime(location.effectiveTimestamp)}'),
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
    
    await _loadLocations();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
                ),
                child: const Text(
                  'Você está aqui',
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

    markers.addAll(_locations.asMap().entries.map((entry) {
      final index = entry.key;
      final location = entry.value;
      final isLatest = index == 0;
      
      return Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(location.latitude, location.longitude),
        child: GestureDetector(
          onTap: () => _showLocationDetails(context, location, isLatest),
          child: Column(
            children: [
              Icon(
                Icons.pets,
                color: isLatest ? Colors.red : const Color(0xFF1A73E8),
                size: 40.0,
              ),
              if (isLatest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ÚLTIMA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }));

    return markers;
  }

  void _centerOnUserLocation() {
    if (_currentUserLocation != null) {
      _mapController.move(_currentUserLocation!, _currentZoom);
    }
  }

  void _centerOnPetLocation() {
    if (_latestLocation != null) {
      _mapController.move(
        LatLng(_latestLocation!.latitude, _latestLocation!.longitude),
        _currentZoom,
      );
    }
  }

  void _showAllLocations() {
    if (_bounds != null) {
      _mapController.fitBounds(
        _bounds!,
        options: FitBoundsOptions(
          padding: EdgeInsets.all(50),
          maxZoom: 15.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização do Pet'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocations,
            tooltip: 'Atualizar localizações',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      setState(() {
                        _currentZoom = position.zoom!;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.petloc.app',
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
                      if (_bounds != null) ...[
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
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildInfoCard(),
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Informações do Mapa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sua localização atual',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Última localização do pet',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(0xFF1A73E8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Localizações anteriores do pet',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (_currentUserLocation != null) ...[
              const SizedBox(height: 8),
              Divider(),
              const SizedBox(height: 8),
              Text(
                'Sua localização atual:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Lat: ${_currentUserLocation!.latitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'Lng: ${_currentUserLocation!.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
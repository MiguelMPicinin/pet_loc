// views/localizacao_pet_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pet_loc/controller/locationController.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pet_loc/models/location_model.dart';

class LocalizacaoPetView extends StatefulWidget {
  final String petId;

  const LocalizacaoPetView({Key? key, required this.petId}) : super(key: key);

  @override
  _LocalizacaoPetViewState createState() => _LocalizacaoPetViewState();
}

class _LocalizacaoPetViewState extends State<LocalizacaoPetView> {
  late MapController _mapController;
  List<Marker> _markers = [];
  LatLng? _center;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locationController = Provider.of<LocationController>(context, listen: false);
    await locationController.loadPetLocations(widget.petId);
    
    final locations = locationController.getPetLocations(widget.petId);
    
    if (locations.isNotEmpty) {
      final latest = locations.first;
      _center = LatLng(latest.latitude, latest.longitude);
      _createMarkers(locations);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _createMarkers(List<LocationModel> locations) {
    _markers = locations.asMap().entries.map((entry) {
      final index = entry.key;
      final location = entry.value;
      
      final isLatest = index == 0;
      
      return Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(location.latitude, location.longitude),
        builder: (ctx) => GestureDetector(
          onTap: () {
            _showLocationDetails(context, location, isLatest);
          },
          child: Container(
            child: Icon(
              Icons.location_on,
              color: isLatest ? Colors.red : Color(0xFF1A73E8),
              size: 40,
            ),
          ),
        ),
      );
    }).toList();
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
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
              ],
              if (location.telefoneEncontrado != null) ...[
                Text('Telefone: ${location.telefoneEncontrado}'),
                SizedBox(height: 8),
              ],
              if (location.endereco != null) ...[
                Text('Endereço: ${location.endereco}'),
                SizedBox(height: 8),
              ],
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
              SizedBox(height: 8),
              Text('Data: ${_formatDateTime(location.effectiveTimestamp)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () => _openInMaps(location),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1A73E8),
            ),
            child: Text('Abrir no Maps'),
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
        SnackBar(
          content: Text('Não foi possível abrir o mapa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshLocations() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Localização do Pet'),
        backgroundColor: Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshLocations,
          ),
        ],
      ),
      body: Consumer<LocationController>(
        builder: (context, controller, child) {
          if (_isLoading || controller.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro: ${controller.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshLocations,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A73E8),
                    ),
                    child: Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final locations = controller.getPetLocations(widget.petId);
          
          if (locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma localização registrada',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Compartilhe o QR Code do pet para receber localizações',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final latestLocation = locations.first;
          
          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _center ?? LatLng(-23.5505, -46.6333), // São Paulo como fallback
                    zoom: _center != null ? 14.0 : 10.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.pet_loc',
                    ),
                    MarkerLayer(
                      markers: _markers,
                    ),
                  ],
                ),
              ),
              Container(
                height: 180,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Últimas localizações:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final loc = locations[index];
                          return _buildLocationCard(loc, index == 0);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_center != null) {
            _mapController.move(_center!, 14.0);
          }
        },
        backgroundColor: Color(0xFF1A73E8),
        child: Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildLocationCard(LocationModel location, bool isLatest) {
    return GestureDetector(
      onTap: () {
        _mapController.move(LatLng(location.latitude, location.longitude), 16.0);
      },
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLatest ? Color(0xFF1A73E8).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLatest ? Color(0xFF1A73E8) : Colors.grey[300],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isLatest ? Color(0xFF1A73E8) : Colors.grey,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  isLatest ? 'MAIS RECENTE' : 'ANTERIOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isLatest ? Color(0xFF1A73E8) : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (location.encontradoPor != null) ...[
              Text(
                location.encontradoPor!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
            ],
            Text(
              location.endereco ?? 'Coordenadas: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              'Data: ${_formatDateTime(location.effectiveTimestamp)}',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
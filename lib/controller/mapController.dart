import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapControllerManager extends ChangeNotifier {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  MapController get mapController => _mapController;
  bool get isMapReady => _isMapReady;

  void initialize() {
    _mapController.mapEventStream.listen((event) {
      // Atualiza qualquer estado necessário quando o mapa se move
      notifyListeners();
    });
    
    _isMapReady = true;
    notifyListeners();
  }

  void moveToLocation(double latitude, double longitude, {double zoom = 15.0}) {
    if (_isMapReady) {
      _mapController.move(
        LatLng(latitude, longitude),
        zoom,
      );
      notifyListeners();
    }
  }

  void fitBounds(LatLngBounds bounds, {EdgeInsets? padding}) {
    if (_isMapReady) {
      _mapController.fitBounds(
        bounds,
        options: FitBoundsOptions(
          padding: padding ?? EdgeInsets.all(50),
        ),
      );
      notifyListeners();
    }
  }

  void zoomIn() {
    if (_isMapReady) {
      final currentZoom = _mapController.zoom;
      _mapController.move(_mapController.center, currentZoom + 1);
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_isMapReady) {
      final currentZoom = _mapController.zoom;
      _mapController.move(_mapController.center, currentZoom - 1);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
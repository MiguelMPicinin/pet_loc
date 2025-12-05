import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CameraControllerManager extends ChangeNotifier {
  MobileScannerController _cameraController = MobileScannerController();
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _isScanning = true;

  MobileScannerController get cameraController => _cameraController;
  bool get isFlashOn => _isFlashOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get isScanning => _isScanning;

  void toggleFlash() {
    _cameraController.toggleTorch();
    _isFlashOn = !_isFlashOn;
    notifyListeners();
  }

  void switchCamera() {
    _cameraController.switchCamera();
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }

  void stopScanning() {
    _isScanning = false;
    notifyListeners();
  }

  void startScanning() {
    _isScanning = true;
    notifyListeners();
  }

  void disposeController() {
    _cameraController.dispose();
  }

  void reset() {
    _isScanning = true;
    _isFlashOn = false;
    notifyListeners();
  }
}
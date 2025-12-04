// views/qr_code_scanner_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pet_loc/views/pet/pet_qr_code_scanner_result.dart';

class QRCodeScannerView extends StatefulWidget {
  const QRCodeScannerView({Key? key}) : super(key: key);

  @override
  _QRCodeScannerViewState createState() => _QRCodeScannerViewState();
}

class _QRCodeScannerViewState extends State<QRCodeScannerView> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture barcode) {
    if (!_isScanning) return;
    
    setState(() {
      _isScanning = false;
    });

    final String? qrData = barcode.barcodes.first.rawValue;
    
    if (qrData != null && qrData.isNotEmpty) {
      // Aguarda um momento e navega para a tela de informações
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PetQRCodeInfoView(qrData: qrData),
          ),
        );
      });
    } else {
      // QR Code inválido
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code inválido'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isScanning = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear QR Code'),
        backgroundColor: Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetected,
          ),
          // Overlay do scanner
          _buildScannerOverlay(),
          // Instruções
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Posicione o QR Code dentro da área de leitura',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'O QR Code será escaneado automaticamente',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: Color(0xFF1A73E8),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
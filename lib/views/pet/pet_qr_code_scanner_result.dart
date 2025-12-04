// views/pet_qr_code_info_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pet_loc/controller/locationController.dart';
import 'package:provider/provider.dart';
import 'package:pet_loc/models/pet_model.dart';
import 'package:pet_loc/models/location_model.dart';

class PetQRCodeInfoView extends StatefulWidget {
  final String qrData;

  const PetQRCodeInfoView({Key? key, required this.qrData}) : super(key: key);

  @override
  _PetQRCodeInfoViewState createState() => _PetQRCodeInfoViewState();
}

class _PetQRCodeInfoViewState extends State<PetQRCodeInfoView> {
  late PetModel _pet;
  bool _isLoading = true;
  bool _sharingLocation = false;
  bool _locationShared = false;
  String _errorMessage = '';
  
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _decodeQRData();
  }

  void _decodeQRData() {
    try {
      final data = json.decode(widget.qrData);
      _pet = PetModel.fromJson(data);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'QR Code inválido ou corrompido';
        _isLoading = false;
      });
    }
  }

  Future<void> _shareLocation() async {
    if (_nomeController.text.isEmpty || _telefoneController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, preencha seu nome e telefone';
      });
      return;
    }

    setState(() {
      _sharingLocation = true;
      _errorMessage = '';
    });

    try {
      final locationController = Provider.of<LocationController>(context, listen: false);
      
      // Obter localização atual
      final location = await locationController.getCurrentLocationWithAddress();
      
      if (location == null) {
        throw Exception('Não foi possível obter a localização');
      }

      // Salvar localização do pet
      final success = await locationController.savePetLocation(
        petId: _pet.id,
        location: location,
        encontradoPor: _nomeController.text,
        telefoneEncontrado: _telefoneController.text,
      );

      if (success) {
        setState(() {
          _sharingLocation = false;
          _locationShared = true;
        });

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Localização compartilhada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Esperar um pouco e voltar
        await Future.delayed(Duration(seconds: 2));
        Navigator.of(context).pop();
      } else {
        throw Exception('Erro ao salvar localização');
      }
      
    } catch (e) {
      setState(() {
        _sharingLocation = false;
        _errorMessage = 'Erro ao compartilhar localização: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pet Encontrado'),
        backgroundColor: Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho informativo
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A73E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Color(0xFF1A73E8)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Você encontrou um pet! Ajude o dono a localizá-lo compartilhando sua localização.',
                                style: TextStyle(
                                  color: Color(0xFF1A73E8),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Informações do Pet
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informações do Pet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A73E8),
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              if (_pet.imagemBase64 != null && _pet.imagemBase64!.isNotEmpty)
                                Center(
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(75),
                                      border: Border.all(
                                        color: Color(0xFF1A73E8),
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: MemoryImage(base64.decode(_pet.imagemBase64!)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              
                              SizedBox(height: 16),
                              
                              _buildInfoItem('Nome', _pet.nome, Icons.pets),
                              _buildInfoItem('Descrição', _pet.descricao, Icons.description),
                              _buildInfoItem('Contato do Dono', _pet.contato, Icons.phone),
                              
                              SizedBox(height: 24),
                              
                              if (_locationShared)
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Localização compartilhada com sucesso!\nO dono já foi notificado.',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    Text(
                                      'Compartilhar Localização',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Preencha seus dados para que o dono possa entrar em contato',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16),
                                    
                                    // Campos de formulário
                                    TextField(
                                      controller: _nomeController,
                                      decoration: InputDecoration(
                                        labelText: 'Seu nome',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                    ),
                                    
                                    SizedBox(height: 12),
                                    
                                    TextField(
                                      controller: _telefoneController,
                                      decoration: InputDecoration(
                                        labelText: 'Seu telefone',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.phone),
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                    
                                    SizedBox(height: 16),
                                    
                                    if (_errorMessage.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error, color: Colors.red),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage,
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    SizedBox(height: 16),
                                    
                                    _sharingLocation
                                        ? Center(
                                            child: Column(
                                              children: [
                                                CircularProgressIndicator(),
                                                SizedBox(height: 16),
                                                Text('Obtendo localização...'),
                                              ],
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: _shareLocation,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF1A73E8),
                                              minimumSize: Size(double.infinity, 50),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.location_on, color: Colors.white),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Compartilhar Minha Localização',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    
                                    SizedBox(height: 8),
                                    
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Não compartilhar localização'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF1A73E8), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
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
  PetModel? _pet;
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
      
      // CORREÇÃO: Criar PetModel com o construtor correto
      _pet = PetModel(
        id: data['id']?.toString() ?? '',
        nome: data['nome'] ?? 'Pet',
        descricao: data['descricao'] ?? '',
        contato: data['contato'] ?? '',
        imagemBase64: data['imagemBase64'],
        userId: data['userId'] ?? '', // Campo obrigatório
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'QR Code inválido ou corrompido: $e';
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

    if (_pet == null || _pet!.id == null) {
      setState(() {
        _errorMessage = 'Pet não encontrado';
      });
      return;
    }

    setState(() {
      _sharingLocation = true;
      _errorMessage = '';
    });

    try {
      final locationController = Provider.of<LocationController>(context, listen: false);
      
      final location = await locationController.getCurrentLocationWithAddress();
      
      if (location == null) {
        throw Exception('Não foi possível obter a localização');
      }

      final success = await locationController.savePetLocation(
        petId: _pet!.id!, // Usar o ID do pet
        location: location,
        encontradoPor: _nomeController.text,
        telefoneEncontrado: _telefoneController.text,
      );

      if (success) {
        setState(() {
          _sharingLocation = false;
          _locationShared = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localização compartilhada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
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
        title: const Text('Pet Encontrado'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty || _pet == null
              ? Center(child: Text(_errorMessage.isEmpty ? 'Pet não encontrado' : _errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Color(0xFF1A73E8)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Você encontrou um pet! Ajude o dono a localizá-lo compartilhando sua localização.',
                                style: TextStyle(
                                  color: const Color(0xFF1A73E8),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informações do Pet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A73E8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              if (_pet!.imagemBase64 != null && _pet!.imagemBase64!.isNotEmpty)
                                Center(
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(75),
                                      border: Border.all(
                                        color: const Color(0xFF1A73E8),
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: MemoryImage(base64.decode(_pet!.imagemBase64!)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              _buildInfoItem('Nome', _pet!.nome, Icons.pets),
                              _buildInfoItem('Descrição', _pet!.descricao, Icons.description),
                              _buildInfoItem('Contato do Dono', _pet!.contato, Icons.phone),
                              
                              const SizedBox(height: 24),
                              
                              if (_locationShared)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Localização compartilhada com sucesso!\nO dono já foi notificado.',
                                          style: const TextStyle(color: Colors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    const Text(
                                      'Compartilhar Localização',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Preencha seus dados para que o dono possa entrar em contato',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    TextField(
                                      controller: _nomeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Seu nome',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    TextField(
                                      controller: _telefoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Seu telefone',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.phone),
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    if (_errorMessage.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error, color: Colors.red),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage,
                                                style: const TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    _sharingLocation
                                        ? const Center(
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
                                              backgroundColor: const Color(0xFF1A73E8),
                                              minimumSize: const Size(double.infinity, 50),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Row(
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
                                    
                                    const SizedBox(height: 8),
                                    
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Não compartilhar localização'),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1A73E8), size: 20),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
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
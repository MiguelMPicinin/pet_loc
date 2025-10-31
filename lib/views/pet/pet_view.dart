import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pet_loc/controller/petController.dart';
import 'package:pet_loc/models/pet_model.dart';
import 'package:pet_loc/services/app_routes.dart';

class PetView extends StatefulWidget {
  const PetView({Key? key}) : super(key: key);

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  final TextEditingController _searchController = TextEditingController();
  final PetController _controller = PetController();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _controller.refresh();
    
    setState(() {
      _isLoading = false;
      _error = _controller.error;
    });
  }

  Future<void> _refreshPets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _controller.refresh();
    
    setState(() {
      _isLoading = false;
      _error = _controller.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pets = _searchQuery.isEmpty
        ? _controller.pets
        : _controller.buscarPets(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Pets',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPets,
          ),
        ],
      ),
      body: _isLoading && _controller.pets.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Erro: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshPets,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : pets.isEmpty
                  ? Column(
                      children: [
                        _buildSearchBar(),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nenhum Pet Cadastrado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Toque no + para adicionar seu primeiro pet!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildSearchBar(),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: pets.length,
                            itemBuilder: (context, index) {
                              return _buildPetCard(pets[index], context);
                            },
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.cadastroPet);
        },
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar pets...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildPetCard(PetModel pet, BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do Pet
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  image: pet.imagemBase64 != null && pet.imagemBase64!.isNotEmpty
                      ? DecorationImage(
                          image: MemoryImage(_decodeBase64(pet.imagemBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: pet.imagemBase64 == null || pet.imagemBase64!.isEmpty
                    ? Icon(
                        Icons.pets,
                        size: 60,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Nome do Pet
            Text(
              pet.nome,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A73E8),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Descrição
            Text(
              pet.descricao,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Contato
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  pet.contato,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.editarPet,
                        arguments: pet,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ver Mais',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _showQRCodeDialog(context, pet);
                  },
                  icon: const Icon(Icons.qr_code, color: Color(0xFF1A73E8)),
                  tooltip: 'Gerar QR Code',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, PetModel pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code do Pet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF1A73E8)),
                  const SizedBox(height: 16),
                  Text(
                    'QR Code para: ${pet.nome}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ao escanear, mostrará:\n- Informações de contato\n- Localização atual',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              _generateQRCode(pet);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
            ),
            child: const Text('Gerar QR Code'),
          ),
        ],
      ),
    );
  }

  void _generateQRCode(PetModel pet) {
    // TODO: Implementar geração de QR Code real com pacote qr_flutter
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR Code gerado para ${pet.nome}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      // Retorna uma imagem placeholder em caso de erro
      return base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
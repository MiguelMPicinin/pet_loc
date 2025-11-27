import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _searchQuery = '';
  int _selectedIndex = 1; // Índice 1 corresponde à tela de Pets

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        // Já está na tela de Pets, não faz nada
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.desaparecidos);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.loja);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.community);
        break;
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(int currentIndex) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets_outlined),
          activeIcon: Icon(Icons.pets),
          label: 'Pets',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning_outlined),
          activeIcon: Icon(Icons.warning),
          label: 'Desaparecidos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Loja',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outlined),
          activeIcon: Icon(Icons.people),
          label: 'Comunidade',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF1A73E8),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: _onItemTapped,
    );
  }

  @override
  void initState() {
    super.initState();
    // Forçar recarregamento dos pets quando a tela iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PetController>(context, listen: false);
      if (controller.pets.isEmpty) {
        controller.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              final controller = Provider.of<PetController>(context, listen: false);
              controller.refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Consumer<PetController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.pets.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
              ),
            );
          }

          final pets = _searchQuery.isEmpty
              ? controller.pets // Já são apenas os pets do usuário
              : controller.buscarPets(_searchQuery);

          return Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _buildPetList(controller, pets),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.cadastroPet);
        },
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(_selectedIndex),
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

  Widget _buildPetList(PetController controller, List<PetModel> pets) {
    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Erro: ${controller.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (pets.isEmpty) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<PetController>(context, listen: false).refresh();
      },
      color: const Color(0xFF1A73E8),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          return _buildPetCard(pets[index], context);
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
      return base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
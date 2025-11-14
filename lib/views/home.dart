import 'package:flutter/material.dart';
import 'package:pet_loc/controller/petController.dart';
import 'package:pet_loc/models/pet_model.dart';
import 'package:pet_loc/services/app_routes.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.pets);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.desaparecidos);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.loja);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.community);
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
                // Adicione aqui a lógica de logout
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPetItem(PetModel pet, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.white,
          child: pet.imagemBase64 != null && pet.imagemBase64!.isNotEmpty
              ? ClipOval(
                  child: Image.memory(
                    base64Decode(pet.imagemBase64!),
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.pets, color: Color(0xFF1a237e), size: 42);
                    },
                  ),
                )
              : const Icon(Icons.pets, color: Color(0xFF1a237e), size: 42),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 96,
          child: Text(
            pet.nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAddPetButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1a237e), size: 42),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.cadastroPet);
            },
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          width: 96,
          child: Text(
            'Adicionar Pet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPetSlot() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 48,
          backgroundColor: Colors.white,
          child: Icon(Icons.pets, color: Color(0xFF1a237e), size: 42),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 96,
          child: Text(
            'Sem pet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetLoc'),
        backgroundColor: const Color(0xFF1a237e),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Column(
        children: [
          // Container azul
          Container(
            height: (MediaQuery.of(context).size.height * 0.25),
            color: const Color(0xFF1a237e),
            child: Center(
              child: Consumer<PetController>(
                builder: (context, petController, child) {
                  return StreamBuilder<List<PetModel>>(
                    stream: petController.petsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Erro ao carregar pets',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.white);
                      }

                      final pets = snapshot.data ?? [];
                      final displayedPets = pets.take(2).toList();

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAddPetButton(),
                          const SizedBox(width: 25),
                          ...displayedPets.asMap().entries.map((entry) {
                            final index = entry.key;
                            final pet = entry.value;
                            return Row(
                              children: [
                                _buildPetItem(pet, index),
                                if (index < displayedPets.length - 1) 
                                  const SizedBox(width: 25),
                              ],
                            );
                          }),
                          // Preenche com slots vazios se não houver pets suficientes
                          if (displayedPets.length < 2) ...[
                            const SizedBox(width: 25),
                            _buildEmptyPetSlot(),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0, // Proporção quadrada para evitar overflow
                children: [
                  _buildCard('Comunidade', Icons.people, () {
                    Navigator.pushNamed(context, AppRoutes.community);
                  }),
                  _buildCard('Loja', Icons.shopping_cart, () {
                    Navigator.pushNamed(context, AppRoutes.loja);
                  }),
                  _buildCard('Pets', Icons.pets, () {
                    Navigator.pushNamed(context, AppRoutes.pets);
                  }),
                  _buildCard('Desaparecidos', Icons.warning, () {
                    Navigator.pushNamed(context, AppRoutes.desaparecidos);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(_selectedIndex),
    );
  }

  Widget _buildCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribui o espaço igualmente
            children: [
              // Container do ícone com tamanho fixo
              Container(
                width: 60, // Largura fixa
                height: 60, // Altura fixa
                decoration: BoxDecoration(
                  color: const Color(0xFF1a237e).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  size: 32, // Ícone de tamanho moderado
                  color: const Color(0xFF1a237e),
                ),
              ),
              // Container para texto com altura flexível
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a237e),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCardDescription(title),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCardDescription(String title) {
    switch (title) {
      case 'Comunidade':
        return 'Conecte-se com outros tutores';
      case 'Loja':
        return 'Produtos para seu pet';
      case 'Pets':
        return 'Gerencie seus pets';
      case 'Desaparecidos':
        return 'Ajude a encontrar pets';
      default:
        return '';
    }
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
      selectedItemColor: const Color(0xFF1a237e),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: _onItemTapped,
    );
  }
}
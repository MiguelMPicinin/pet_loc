import 'package:flutter/material.dart';
import 'package:pet_loc/services/app_routes.dart';

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
        // Já está na home
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
        Navigator.pushNamed(context, AppRoutes.blog);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetLoc'),
        backgroundColor: const Color(0xFF1a237e),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Top half: Navy blue background with pet circles
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            color: const Color(0xFF1a237e),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Add pet circle
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFF1a237e)),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.cadastroPet);
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Mock pet circles
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.pets, color: Color(0xFF1a237e)),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.pets, color: Color(0xFF1a237e)),
                  ),
                ],
              ),
            ),
          ),
          // Bottom half: 4 cards in 2x2 grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard('Blog/Chat', Icons.chat, () {
                    Navigator.pushNamed(context, AppRoutes.blog);
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Pets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Desaparecidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Loja',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Blog/Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1a237e),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF1a237e)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:pet_loc/services/app_routes.dart';
import 'package:pet_loc/views/blog-chat/blog_view.dart';
import 'package:pet_loc/views/blog-chat/chat_view.dart';

class CommunityView extends StatefulWidget {
  const CommunityView({Key? key}) : super(key: key);

  @override
  _CommunityViewState createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.pets);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.desaparecidos);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.loja);
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        title: const Text(
          'Comunidade PetLoc',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.article),
              text: 'Blog',
            ),
            Tab(
              icon: Icon(Icons.chat),
              text: 'Chat',
            ),
          ],
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BlogContent(),
          ChatContent(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(4),
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:petloc01/navigation/app_routes.dart';
import 'dart:typed_data';
import '../controller/desaparecidoController.dart';
import '../models/user_model.dart'; // Supondo que você tenha um UserModel

class DesaparecidoScreen extends StatefulWidget {
  const DesaparecidoScreen({Key? key}) : super(key: key);

  @override
  _DesaparecidoScreenState createState() => _DesaparecidoScreenState();
}

class _DesaparecidoScreenState extends State<DesaparecidoScreen> {
  final DesaparecidosController _controller = DesaparecidosController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _desaparecidos = [];
  String? _currentUserId; // ID do usuário logado

  @override
  void initState() {
    super.initState();
    _loadDesaparecidos();
    _getCurrentUser(); // Obter usuário atual
  }

  Future<void> _getCurrentUser() async {
    // Aqui você precisa obter o ID do usuário logado
    // Isso depende da sua implementação de autenticação
    // Por enquanto, vou simular um ID
    setState(() {
      _currentUserId = 'user123'; // Substitua pela lógica real
    });
  }

  Future<void> _loadDesaparecidos() async {
    final snapshot = await _firestore
        .collection('desaparecidos')
        .orderBy('criadoEm', descending: true)
        .get();
    
    setState(() {
      _desaparecidos = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nome': data['nome'] ?? '',
          'descricao': data['descricao'] ?? '',
          'contato': data['contato'] ?? '',
          'imagem': data['imagemBase64'] ?? '',
          'userId': data['userId'] ?? '',
          'encontrado': data['encontrado'] ?? false,
          'criadoEm': data['criadoEm'],
        };
      }).toList();
    });
  }

  Future<void> _deleteDesaparecido(String id) async {
    await _firestore.collection('desaparecidos').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro deletado com sucesso')),
    );
    _loadDesaparecidos();
  }

  Future<void> _marcarComoEncontrado(String id) async {
    await _firestore.collection('desaparecidos').doc(id).update({
      'encontrado': true,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marcado como encontrado!')),
    );
    _loadDesaparecidos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        title: const Row(
          children: [
            Icon(Icons.pets, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Pets Desaparecidos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A73E8),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.criarDesaparecido);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: _desaparecidos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "Nenhum pet desaparecido encontrado",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Toque no + para adicionar um registro",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _desaparecidos.length,
                itemBuilder: (context, index) {
                  final d = _desaparecidos[index];
                  return _buildDesaparecidoCard(
                    d['id'],
                    d['imagem'],
                    d['nome'],
                    d['descricao'],
                    d['contato'],
                    d['userId'],
                    d['encontrado'],
                  );
                },
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDesaparecidoCard(
    String id,
    String? imagemBase64,
    String nome,
    String descricao,
    String contato,
    String userId,
    bool encontrado,
  ) {
    bool isOwner = userId == _currentUserId;
    Widget imageWidget;

    if (imagemBase64 != null && imagemBase64.isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(imagemBase64);
        imageWidget = ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: Stack(
              children: [
                Image.memory(bytes, fit: BoxFit.cover, width: double.infinity),
                if (encontrado)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Text(
                        'ENCONTRADO! 🎉',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      } catch (e) {
        imageWidget = _placeholderImage(encontrado);
      }
    } else {
      imageWidget = _placeholderImage(encontrado);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              imageWidget,
              if (isOwner && !encontrado)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.blue),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.editarDesaparecido,
                            arguments: {
                              'id': id,
                              'nome': nome,
                              'descricao': descricao,
                              'contato': contato,
                              'imagem': imagemBase64,
                            },
                          );
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(id);
                        } else if (value == 'found') {
                          _marcarComoEncontrado(id);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'found',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Marcar como encontrado'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Excluir'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    if (encontrado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ENCONTRADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: Color(0xFF1A73E8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          contato,
                          style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Seu registro',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage(bool encontrado) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.pets, size: 80, color: Colors.grey),
            ),
            if (encontrado)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Text(
                    'ENCONTRADO! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente deletar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteDesaparecido(id);
            },
            child: const Text(
              'Deletar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1A73E8),
      unselectedItemColor: Colors.grey[600],
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
          case 1:
            Navigator.pushReplacementNamed(context, AppRoutes.criarDesaparecido);
            break;
          case 2:
            Navigator.pushReplacementNamed(context, AppRoutes.loja);
            break;
          case 3:
            // Já está nos desaparecidos
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Criar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Loja',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets_outlined),
          activeIcon: Icon(Icons.pets),
          label: 'Desaparecidos',
        ),
      ],
    );
  }
}
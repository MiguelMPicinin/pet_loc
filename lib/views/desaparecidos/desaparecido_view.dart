import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_loc/controller/desaparecidoController.dart';
import 'package:pet_loc/models/desaparecidos_model.dart';
import 'package:pet_loc/services/app_routes.dart';
import 'package:provider/provider.dart';

class DesaparecidoScreen extends StatefulWidget {
  const DesaparecidoScreen({Key? key}) : super(key: key);

  @override
  _DesaparecidoScreenState createState() => _DesaparecidoScreenState();
}

class _DesaparecidoScreenState extends State<DesaparecidoScreen> {
  String? _currentUserId;
  String _filtroSelecionado = 'Todos';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    setState(() {
      _currentUserId = 'user123'; // Substitua pela lógica real de autenticação
    });
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
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.loja);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.community);
        break;
    }
  }

  Widget _buildFiltroChip(String filtro) {
    final bool isSelected = filtro == _filtroSelecionado;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroSelecionado = filtro;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A73E8) : (Colors.grey[300] ?? Colors.grey),
          ),
        ),
        child: Text(
          filtro,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<DesaparecidoModel> _filtrarDesaparecidos(List<DesaparecidoModel> lista) {
    switch (_filtroSelecionado) {
      case 'Desaparecidos':
        return lista.where((d) => !d.encontrado).toList();
      case 'Encontrados':
        return lista.where((d) => d.encontrado).toList();
      case 'Todos':
      default:
        return lista;
    }
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
      body: Consumer<DesaparecidosController>(
        builder: (context, controller, child) {
          return StreamBuilder<List<DesaparecidoModel>>(
            stream: controller.desaparecidosStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar desaparecidos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                  ),
                );
              }

              final desaparecidos = snapshot.data ?? [];
              final desaparecidosFiltrados = _filtrarDesaparecidos(desaparecidos);

              return Column(
                children: [
                  // Filtros
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFiltroChip('Todos'),
                        _buildFiltroChip('Desaparecidos'),
                        _buildFiltroChip('Encontrados'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: desaparecidosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pets, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _filtroSelecionado == 'Desaparecidos'
                                      ? "Nenhum pet desaparecido encontrado"
                                      : _filtroSelecionado == 'Encontrados'
                                          ? "Nenhum pet encontrado"
                                          : "Nenhum pet desaparecido cadastrado",
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
                            itemCount: desaparecidosFiltrados.length,
                            itemBuilder: (context, index) {
                              final d = desaparecidosFiltrados[index];
                              return _buildDesaparecidoCard(
                                context,
                                controller,
                                d.id!,
                                d.imagemBase64,
                                d.nome,
                                d.descricao,
                                d.contato,
                                d.userId,
                                d.encontrado,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(2),
    );
  }

  Widget _buildDesaparecidoCard(
    BuildContext context,
    DesaparecidosController controller,
    String id,
    String? imagemBase64,
    String nome,
    String descricao,
    String contato,
    String? userId,
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
                          _showDeleteConfirmation(context, controller, id);
                        } else if (value == 'found') {
                          controller.marcarComoEncontrado(id);
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

  void _showDeleteConfirmation(BuildContext context, DesaparecidosController controller, String id) {
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
              controller.deletarDesaparecido(id);
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
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_loc/services/app_routes.dart';

class ComprarLojaScreen extends StatefulWidget {
  final Map<String, dynamic> produto;

  const ComprarLojaScreen({Key? key, required this.produto}) : super(key: key);

  @override
  _ComprarLojaScreenState createState() => _ComprarLojaScreenState();
}

class _ComprarLojaScreenState extends State<ComprarLojaScreen> {
  int _quantidade = 1;

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
        // Já está na loja
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.blog);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final produto = widget.produto;

    Uint8List? imageBytes;
    if (produto['imagem'] != null && produto['imagem'].isNotEmpty) {
      try {
        imageBytes = base64Decode(produto['imagem']);
      } catch (e) {
        imageBytes = null;
      }
    }

    double precoUnitario = 0;
    try {
      precoUnitario = double.parse(produto['preco'].toString().replaceAll(',', '.'));
    } catch (_) {}

    double precoTotal = precoUnitario * _quantidade;
    bool semEstoque = (produto['estoque'] ?? 0) <= 0;
    int estoqueDisponivel = produto['estoque'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detalhes do Produto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Compartilhar produto
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Favoritar produto
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carrossel de imagens (simplificado)
                  Container(
                    height: 300,
                    color: Colors.grey[50],
                    child: Stack(
                      children: [
                        imageBytes != null
                            ? Image.memory(
                                imageBytes,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              ),
                        if (semEstoque)
                          Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.black54,
                            child: const Center(
                              child: Text(
                                'PRODUTO ESGOTADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Informações do produto
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produto['nome'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "R\$ ${precoUnitario.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A73E8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!semEstoque) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Text(
                                  '${estoqueDisponivel} disponíveis',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Em estoque',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Descrição',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          produto['descricao'] ?? 'Sem descrição disponível',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quantidade
                        if (!semEstoque) ...[
                          const Text(
                            'Quantidade',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: _quantidade > 1
                                      ? () {
                                          setState(() {
                                            _quantidade--;
                                          });
                                        }
                                      : null,
                                ),
                                Container(
                                  width: 50,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '$_quantidade',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _quantidade < estoqueDisponivel
                                      ? () {
                                          setState(() {
                                            _quantidade++;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Subtotal: R\$ ${precoTotal.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Text(
                          'Informações do vendedor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFF1A73E8),
                                  child: Icon(Icons.store, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PetLoc Shop',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        produto['contato'] ?? 'Contato não disponível',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chat_outlined, color: Color(0xFF1A73E8)),
                                  onPressed: () {
                                    // Abrir chat com vendedor
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Entrega e pagamento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(Icons.local_shipping, 'Frete grátis'),
                        _buildInfoItem(Icons.credit_card, 'Pagamento combinado com vendedor'),
                        _buildInfoItem(Icons.calendar_today, 'Entrega em até 7 dias úteis'),
                        _buildInfoItem(Icons.location_on, 'Todo Brasil'),

                        const SizedBox(height: 80), // Espaço para o botão flutuante
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botão de compra fixo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (!semEstoque) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'R\$ ${precoTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                          Text(
                            '$_quantidade item${_quantidade > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: semEstoque ? null : () {
                        _finalizarCompra(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: semEstoque ? Colors.grey : const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        semEstoque ? 'Produto Esgotado' : 'Comprar Agora',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(3),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A73E8), size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
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
          icon: Icon(Icons.article_outlined),
          activeIcon: Icon(Icons.article),
          label: 'Blog',
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

  void _finalizarCompra(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Compra realizada!'),
          ],
        ),
        content: Text(
          'Você comprou $_quantidade unidade(s) de "${widget.produto['nome']}".\n\n'
          'Total: R\$ ${(_quantidade * (double.tryParse(widget.produto['preco'].toString().replaceAll(',', '.')) ?? 0)).toStringAsFixed(2)}\n\n'
          'Entre em contato com o vendedor para combinar pagamento e entrega:\n'
          '${widget.produto['contato']}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF1A73E8))),
          ),
        ],
      ),
    );
  }
}
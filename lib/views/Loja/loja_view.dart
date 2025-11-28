import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_loc/services/app_routes.dart';

class LojaScreen extends StatefulWidget {
  @override
  _LojaScreenState createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _produtosFiltrados = [];
  bool _isLoading = true;
  final List<String> _categorias = [
    'Todos',
    'Ração',
    'Brinquedos',
    'Coleiras',
    'Medicamentos',
    'Higiene',
    'Acessórios'
  ];
  String _categoriaSelecionada = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Função para truncar o nome do produto
  String _truncateProductName(String name) {
    if (name.length <= 18) {
      return name;
    }
    return '${name.substring(0, 18)}...';
  }

  @override
  void initState() {
    super.initState();
    _loadProdutos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> produtosFiltrados = List.from(_produtos);

    // Aplicar filtro de categoria
    if (_categoriaSelecionada != 'Todos') {
      produtosFiltrados = produtosFiltrados.where((produto) {
        return produto['categoria'] == _categoriaSelecionada;
      }).toList();
    }

    // Aplicar filtro de pesquisa
    if (_searchQuery.isNotEmpty) {
      produtosFiltrados = produtosFiltrados.where((produto) {
        final nome = produto['nome']?.toString().toLowerCase() ?? '';
        final descricao = produto['descricao']?.toString().toLowerCase() ?? '';
        final categoria = produto['categoria']?.toString().toLowerCase() ?? '';
        
        return nome.contains(_searchQuery) || 
               descricao.contains(_searchQuery) ||
               categoria.contains(_searchQuery);
      }).toList();
    }

    setState(() {
      _produtosFiltrados = produtosFiltrados;
    });
  }

  Future<void> _loadProdutos() async {
    try {
      print('🔍 Carregando produtos do Firestore...');
      
      final snapshot = await _firestore
          .collection('produtos_loja')
          .where('ativo', isEqualTo: true)
          .get();
      
      _processarSnapshot(snapshot);
      
    } catch (e) {
      print('❌ Erro geral ao carregar produtos: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar produtos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processarSnapshot(QuerySnapshot snapshot) {
    print('📊 Snapshot size: ${snapshot.docs.length}');
    
    setState(() {
      _produtos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final produto = {
          'id': doc.id,
          'nome': data['nome'] ?? 'Sem nome',
          'descricao': data['descricao'] ?? 'Sem descrição',
          'preco': data['preco']?.toString() ?? '0.00',
          'contato': data['contato'] ?? 'Sem contato',
          'imagem': data['imagemBase64'] ?? '',
          'estoque': data['estoque'] ?? 0,
          'categoria': data['categoria'] ?? 'Geral',
          'ativo': data['ativo'] ?? false,
        };
        print('✅ Produto carregado: ${produto['nome']}');
        return produto;
      }).toList();
      
      _produtosFiltrados = List.from(_produtos);
      _isLoading = false;
    });

    _debugProdutos();
  }

  void _debugProdutos() {
    print('\n=== 🛍️ DEBUG PRODUTOS ===');
    print('Total de produtos carregados: ${_produtos.length}');
    print('Produtos filtrados: ${_produtosFiltrados.length}');
    print('Termo de pesquisa: "$_searchQuery"');
    print('Categoria selecionada: "$_categoriaSelecionada"');
    if (_produtos.isEmpty) {
      print('🚫 NENHUM PRODUTO ENCONTRADO!');
    } else {
      for (var i = 0; i < _produtosFiltrados.length; i++) {
        final produto = _produtosFiltrados[i];
        print('${i + 1}. ${produto['nome']} - ${produto['categoria']}');
      }
    }
    print('========================\n');
  }

  Future<void> _refreshProdutos() async {
    setState(() {
      _isLoading = true;
    });
    await _loadProdutos();
  }

  Widget _buildCategoriaChip(String categoria) {
    final bool isSelected = categoria == _categoriaSelecionada;
    return GestureDetector(
      onTap: () {
        setState(() {
          _categoriaSelecionada = categoria;
        });
        _aplicarFiltros();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          categoria,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> produto) {
    Uint8List? imageBytes;
    if (produto['imagem'] != null && produto['imagem'].isNotEmpty) {
      try {
        imageBytes = base64Decode(produto['imagem']);
      } catch (e) {
        print('Erro ao decodificar imagem: $e');
        imageBytes = null;
      }
    }

    bool semEstoque = (produto['estoque'] ?? 0) <= 0;
    double preco = double.tryParse(produto['preco'].toString().replaceAll(',', '.')) ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.lojaComprar,
            arguments: produto,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGEM DO PRODUTO
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error, color: Colors.red);
                              },
                            )
                          : const Icon(
                              Icons.pets,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  if (semEstoque)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ESGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // INFORMAÇÕES DO PRODUTO
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // NOME E PREÇO
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _truncateProductName(produto['nome']),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'R\$ ${preco.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                        ],
                      ),

                      // FRETE E BOTÃO
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Frete grátis',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: semEstoque ? null : () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.lojaComprar,
                                  arguments: produto,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: semEstoque ? Colors.grey : const Color(0xFF1A73E8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: Text(
                                semEstoque ? 'Indisponível' : 'Comprar',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Pesquisar produtos...',
            prefixIcon: Icon(Icons.search, color: Color(0xFF1A73E8)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.pushNamed(context, AppRoutes.cadastroProduto);
        _refreshProdutos();
      },
      backgroundColor: const Color(0xFF1A73E8),
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
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
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.community);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PetLoc Shop',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Tudo para seu pet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.produtoCrud);
              _refreshProdutos();
            },
            tooltip: 'Meus Produtos',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notificações',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProdutos,
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshProdutos,
              child: Column(
                children: [
                  // CAMPO DE PESQUISA
                  _buildSearchField(),

                  // CATEGORIAS
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        return _buildCategoriaChip(_categorias[index]);
                      },
                    ),
                  ),

                  // CONTADOR DE PRODUTOS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          _searchQuery.isNotEmpty
                              ? '${_produtosFiltrados.length} produto(s) encontrado(s) para "$_searchQuery"'
                              : '${_produtosFiltrados.length} produto(s) encontrado(s)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // LISTA DE PRODUTOS
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _produtosFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Nenhum produto encontrado para "$_searchQuery"'
                                        : 'Nenhum produto disponível',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                      child: Text(
                                        'Limpar pesquisa',
                                        style: TextStyle(
                                          color: Color(0xFF1A73E8),
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.68,
                              ),
                              itemCount: _produtosFiltrados.length,
                              itemBuilder: (context, index) => _buildProductCard(_produtosFiltrados[index]),
                            ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(3),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
}
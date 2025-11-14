import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pet_loc/views/Loja/cadastro_produto_view.dart';
import 'package:provider/provider.dart';
import 'package:pet_loc/controller/lojaController.dart';

class ProdutoCrudScreen extends StatefulWidget {
  const ProdutoCrudScreen({Key? key}) : super(key: key);

  @override
  _ProdutoCrudScreenState createState() => _ProdutoCrudScreenState();
}

class _ProdutoCrudScreenState extends State<ProdutoCrudScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<LojaController>(context, listen: false);
      controller.refresh();
    });
  }

  void _editarProduto(BuildContext context, String produtoId) {
    // Navegar para tela de edição (pode ser a mesma de cadastro com dados pré-preenchidos)
    // Por enquanto, vamos apenas mostrar um dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Produto'),
        content: const Text('Funcionalidade de edição em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deletarProduto(BuildContext context, LojaController controller, String produtoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este produto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await controller.deletarProduto(produtoId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produto excluído com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro: ${controller.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutoCard(Map<String, dynamic> produto, LojaController controller) {
    final bool isOwner = controller.isProdutoDoUsuario(produto['id']);
    final bool semEstoque = (produto['estoque'] ?? 0) <= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: produto['imagem'] != null && produto['imagem'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.memory(
                      base64Decode(produto['imagem']),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.shopping_bag, color: Color(0xFF1A73E8)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  produto['nome'] ?? 'Produto sem nome',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (semEstoque)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ESGOTADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                produto['descricao'] ?? 'Sem descrição',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'R\$ ${produto['preco']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (produto['estoque'] != null)
                    Text(
                      'Estoque: ${produto['estoque']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: semEstoque ? Colors.red : Colors.green,
                      ),
                    ),
                ],
              ),
              if (isOwner)
                const SizedBox(height: 4),
              if (isOwner)
                Text(
                  'Seu produto',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          trailing: isOwner
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editarProduto(context, produto['id']);
                    } else if (value == 'delete') {
                      _deletarProduto(context, controller, produto['id']);
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
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CadastroProdutoScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<LojaController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.produtos.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
              ),
            );
          }

          final userProducts = controller.getProdutosDoUsuario();

          if (userProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum produto cadastrado',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque no + para cadastrar seu primeiro produto',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CadastroProdutoScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                    ),
                    child: const Text('Cadastrar Primeiro Produto'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: userProducts.length,
              itemBuilder: (context, index) {
                final produto = userProducts[index];
                return _buildProdutoCard(
                  {
                    'id': produto.id,
                    'nome': produto.nome,
                    'descricao': produto.descricao,
                    'preco': produto.preco,
                    'contato': produto.contato,
                    'imagem': produto.imagemBase64,
                    'estoque': produto.estoque,
                  },
                  controller,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
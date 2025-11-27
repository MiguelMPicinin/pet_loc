import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_loc/controller/lojaController.dart';

class CadastroProdutoScreen extends StatefulWidget {
  const CadastroProdutoScreen({Key? key}) : super(key: key);

  @override
  _CadastroProdutoScreenState createState() => _CadastroProdutoScreenState();
}

class _CadastroProdutoScreenState extends State<CadastroProdutoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  final _contatoController = TextEditingController();
  final _estoqueController = TextEditingController();

  // Limites de caracteres
  static const int _limiteNome = 30;
  static const int _limiteDescricao = 200;
  static const int _limitePreco = 7;
  static const int _limiteContato = 15;
  static const int _limiteEstoque = 5;

  final List<String> _categorias = [
    'Ração',
    'Brinquedos',
    'Coleiras',
    'Medicamentos',
    'Higiene',
    'Acessórios',
    'Outros'
  ];
  String _categoriaSelecionada = 'Ração';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _cadastrarProduto(LojaController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.cadastrarProduto(
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim(),
      preco: _precoController.text.trim(),
      contato: _contatoController.text.trim(),
      estoque: _estoqueController.text.isEmpty ? null : int.tryParse(_estoqueController.text),
      categoria: _categoriaSelecionada,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${controller.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selecionarImagem(LojaController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                controller.selecionarImagem();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                controller.tirarFoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Produto'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          Consumer<LojaController>(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.check),
                onPressed: controller.isLoading ? null : () => _cadastrarProduto(controller),
              );
            },
          ),
        ],
      ),
      body: Consumer<LojaController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Imagem do produto
                  GestureDetector(
                    onTap: () => _selecionarImagem(controller),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: controller.selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                controller.selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Adicionar imagem',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (controller.selectedImage != null)
                    TextButton(
                      onPressed: () => controller.removerImagemSelecionada(),
                      child: const Text(
                        'Remover imagem',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Nome do produto
                  TextFormField(
                    controller: _nomeController,
                    maxLength: _limiteNome,
                    decoration: InputDecoration(
                      labelText: 'Nome do Produto*',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.shopping_bag),
                      counterText: '${_nomeController.text.length}/$_limiteNome',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o nome do produto';
                      }
                      if (value.length > _limiteNome) {
                        return 'Nome muito longo (máx. $_limiteNome caracteres)';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Descrição
                  TextFormField(
                    controller: _descricaoController,
                    maxLength: _limiteDescricao,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descrição*',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description),
                      counterText: '${_descricaoController.text.length}/$_limiteDescricao',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite a descrição do produto';
                      }
                      if (value.length > _limiteDescricao) {
                        return 'Descrição muito longa (máx. $_limiteDescricao caracteres)';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Preço
                  TextFormField(
                    controller: _precoController,
                    maxLength: _limitePreco,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Preço* (ex: 29.90)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      counterText: '${_precoController.text.length}/$_limitePreco',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o preço do produto';
                      }
                      final preco = double.tryParse(value.replaceAll(',', '.'));
                      if (preco == null) {
                        return 'Digite um preço válido';
                      }
                      if (value.length > _limitePreco) {
                        return 'Preço muito longo (máx. $_limitePreco caracteres)';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Contato
                  TextFormField(
                    controller: _contatoController,
                    maxLength: _limiteContato,
                    decoration: InputDecoration(
                      labelText: 'Contato* (WhatsApp, email, etc.)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.contact_phone),
                      counterText: '${_contatoController.text.length}/$_limiteContato',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite um contato';
                      }
                      if (value.length > _limiteContato) {
                        return 'Contato muito longo (máx. $_limiteContato caracteres)';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Estoque
                  TextFormField(
                    controller: _estoqueController,
                    maxLength: _limiteEstoque,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Estoque (opcional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.inventory),
                      counterText: '${_estoqueController.text.length}/$_limiteEstoque',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Categoria
                  DropdownButtonFormField<String>(
                    value: _categoriaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoria*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categorias.map((categoria) {
                      return DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoriaSelecionada = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione uma categoria';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // Informações sobre limites
                  _buildLimitesInfo(),

                  const SizedBox(height: 20),

                  // Botão de cadastrar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.isLoading ? null : () => _cadastrarProduto(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Cadastrar Produto',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLimitesInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Limites de Caracteres',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoItem('Nome: $_limiteNome caracteres'),
          _buildInfoItem('Descrição: $_limiteDescricao caracteres'),
          _buildInfoItem('Preço: $_limitePreco caracteres'),
          _buildInfoItem('Contato: $_limiteContato caracteres'),
          _buildInfoItem('Estoque: $_limiteEstoque caracteres'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _contatoController.dispose();
    _estoqueController.dispose();
    super.dispose();
  }
}
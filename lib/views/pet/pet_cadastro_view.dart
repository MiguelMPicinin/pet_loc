import 'package:flutter/material.dart';
import 'package:pet_loc/controller/petController.dart';
import 'package:pet_loc/services/app_routes.dart';

class PetCadastroView extends StatefulWidget {
  const PetCadastroView({Key? key}) : super(key: key);

  @override
  State<PetCadastroView> createState() => _PetCadastroViewState();
}

class _PetCadastroViewState extends State<PetCadastroView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();
  final PetController _controller = PetController();

  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastrar Pet',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Seção de Imagem
                  _buildImageSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Campo Nome
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Pet *',
                      prefixIcon: const Icon(Icons.pets),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite o nome do pet';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Campo Descrição
                  TextFormField(
                    controller: _descricaoController,
                    decoration: InputDecoration(
                      labelText: 'Descrição *',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite uma descrição';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Campo Contato
                  TextFormField(
                    controller: _contatoController,
                    decoration: InputDecoration(
                      labelText: 'Contato *',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite um contato';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botão Cadastrar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _cadastrarPet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Cadastrar Pet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Informações adicionais
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
          
          if (_error != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildErrorBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            image: _controller.selectedImage != null
                ? DecorationImage(
                    image: FileImage(_controller.selectedImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _controller.selectedImage == null
              ? const Icon(
                  Icons.pets,
                  size: 60,
                  color: Colors.grey,
                )
              : null,
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await _controller.selecionarImagem();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: const Text(
                'Galeria',
                style: TextStyle(color: Colors.white),
              ),
            ),
            
            const SizedBox(width: 12),
            
            ElevatedButton.icon(
              onPressed: () async {
                await _controller.tirarFoto();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text(
                'Câmera',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        
        if (_controller.selectedImage != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Usando o novo método removerImagemSelecionada
              _controller.removerImagemSelecionada();
              setState(() {});
            },
            child: const Text(
              'Remover imagem',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard() {
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
            '📋 Informações Importantes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoItem('• Todos os campos marcados com * são obrigatórios'),
          _buildInfoItem('• A foto ajuda na identificação do seu pet'),
          _buildInfoItem('• O contato será usado caso seu pet seja encontrado'),
          _buildInfoItem('• Após cadastrar, gere o QR Code para colocar na coleira'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cadastrarPet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await _controller.cadastrarPet(
      nome: _nomeController.text,
      descricao: _descricaoController.text,
      contato: _contatoController.text,
      userId: 'current_user_id', // TODO: Pegar do usuário logado
    );

    setState(() {
      _isLoading = false;
      _error = _controller.error;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${_controller.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _contatoController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
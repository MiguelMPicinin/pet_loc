import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // Limites de caracteres
  static const int _limiteNome = 30;
  static const int _limiteDescricao = 150;
  static const int _limiteContato = 15;

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
      body: Consumer<PetController>(
        builder: (context, controller, child) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Seção de Imagem
                      _buildImageSection(controller),
                      
                      const SizedBox(height: 24),
                      
                      // Campo Nome
                      TextFormField(
                        controller: _nomeController,
                        maxLength: _limiteNome,
                        decoration: InputDecoration(
                          labelText: 'Nome do Pet *',
                          prefixIcon: const Icon(Icons.pets),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          counterText: '${_nomeController.text.length}/$_limiteNome',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite o nome do pet';
                          }
                          if (value.length > _limiteNome) {
                            return 'Nome muito longo (máx. $_limiteNome caracteres)';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Campo Descrição
                      TextFormField(
                        controller: _descricaoController,
                        maxLength: _limiteDescricao,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Descrição *',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          counterText: '${_descricaoController.text.length}/$_limiteDescricao',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite uma descrição';
                          }
                          if (value.length > _limiteDescricao) {
                            return 'Descrição muito longa (máx. $_limiteDescricao caracteres)';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Campo Contato
                      TextFormField(
                        controller: _contatoController,
                        maxLength: _limiteContato,
                        decoration: InputDecoration(
                          labelText: 'Contato *',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          counterText: '${_contatoController.text.length}/$_limiteContato',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite um contato';
                          }
                          if (value.length > _limiteContato) {
                            return 'Contato muito longo (máx. $_limiteContato caracteres)';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Botão Cadastrar
                      ElevatedButton(
                        onPressed: controller.isLoading ? null : () => _cadastrarPet(controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isLoading
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
              
              if (controller.error != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildErrorBanner(controller),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageSection(PetController controller) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            image: controller.selectedImage != null
                ? DecorationImage(
                    image: FileImage(controller.selectedImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: controller.selectedImage == null
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
                await controller.selecionarImagem();
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
                await controller.tirarFoto();
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
        
        if (controller.selectedImage != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              controller.removerImagemSelecionada();
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
          _buildInfoItem('• Nome: máximo $_limiteNome caracteres'),
          _buildInfoItem('• Descrição: máximo $_limiteDescricao caracteres'),
          _buildInfoItem('• Contato: máximo $_limiteContato caracteres'),
          _buildInfoItem('• A foto ajuda na identificação do seu pet'),
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

  Widget _buildErrorBanner(PetController controller) {
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
                controller.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                controller.clearError();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cadastrarPet(PetController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await controller.cadastrarPet(
      nome: _nomeController.text,
      descricao: _descricaoController.text,
      contato: _contatoController.text,
    );

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
          content: Text('Erro: ${controller.error}'),
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
    super.dispose();
  }
}
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/app_routes.dart';

class CriarDesaparecidoScreen extends StatefulWidget {
  final Map<String, dynamic>? desaparecidoData;

  const CriarDesaparecidoScreen({Key? key, this.desaparecidoData}) : super(key: key);

  @override
  _CriarDesaparecidoScreenState createState() => _CriarDesaparecidoScreenState();
}

class _CriarDesaparecidoScreenState extends State<CriarDesaparecidoScreen> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _contatoController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _imageFile;
  bool _isEditing = false;
  String? _desaparecidoId;

  @override
  void initState() {
    super.initState();
    
    // Verificar se está editando
    if (widget.desaparecidoData != null) {
      _isEditing = true;
      _desaparecidoId = widget.desaparecidoData!['id'];
      _nomeController.text = widget.desaparecidoData!['nome'] ?? '';
      _descricaoController.text = widget.desaparecidoData!['descricao'] ?? '';
      _contatoController.text = widget.desaparecidoData!['contato'] ?? '';
    }
  }

  Future<void> _selectImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveData() async {
    if (_nomeController.text.isNotEmpty &&
        _descricaoController.text.isNotEmpty &&
        _contatoController.text.isNotEmpty) {
      try {
        String? base64Image;

        if (_imageFile != null) {
          final bytes = await _imageFile!.readAsBytes();
          base64Image = base64Encode(bytes);
        } else if (_isEditing && widget.desaparecidoData?['imagem'] != null && 
                   widget.desaparecidoData!['imagem'].isNotEmpty) {
          // Manter imagem original se não foi alterada
          base64Image = widget.desaparecidoData!['imagem'];
        }

        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        final String currentUserId = 'user123'; // Substitua pelo ID real do usuário

        if (_isEditing) {
          // Atualizar registro existente
          await firestore.collection('desaparecidos').doc(_desaparecidoId).update({
            'nome': _nomeController.text,
            'descricao': _descricaoController.text,
            'contato': _contatoController.text,
            'imagemBase64': base64Image ?? '',
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
        } else {
          // Criar novo registro
          await firestore.collection('desaparecidos').add({
            'nome': _nomeController.text,
            'descricao': _descricaoController.text,
            'contato': _contatoController.text,
            'imagemBase64': base64Image ?? '',
            'userId': currentUserId,
            'encontrado': false,
            'criadoEm': FieldValue.serverTimestamp(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
        }

        _clearForm();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Registro atualizado com sucesso!'
                : 'Animal desaparecido salvo com sucesso!'
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, AppRoutes.desaparecidos);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar os dados: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _clearForm() {
    _nomeController.clear();
    _descricaoController.clear();
    _contatoController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_imageFile!, fit: BoxFit.cover, height: 200, width: double.infinity),
      );
    } else if (_isEditing && widget.desaparecidoData?['imagem'] != null && 
               widget.desaparecidoData!['imagem'].isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(widget.desaparecidoData!['imagem']);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover, height: 200, width: double.infinity),
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text('Toque para adicionar imagem'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        title: Text(
          _isEditing ? 'Editar Desaparecido' : 'Cadastrar Desaparecido',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _selectImage,
              child: _buildImagePreview(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Pet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descrição (raça, características, última localização)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contatoController,
              decoration: const InputDecoration(
                labelText: 'Contato (telefone/whatsapp)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isEditing ? 'Atualizar' : 'Cadastrar',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1A73E8),
      unselectedItemColor: Colors.grey[600],
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
          case 1:
            // Já está na tela de criar
            break;
          case 2:
            Navigator.pushReplacementNamed(context, AppRoutes.loja);
            break;
          case 3:
            Navigator.pushReplacementNamed(context, AppRoutes.desaparecidos);
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
          icon: Icon(Icons.add_circle_outlined),
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
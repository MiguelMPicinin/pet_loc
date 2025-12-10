import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pet_loc/controller/petController.dart';
import 'package:pet_loc/models/pet_model.dart';
import 'package:pet_loc/services/app_routes.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetCRUDView extends StatefulWidget {
  final PetModel pet;

  const PetCRUDView({Key? key, required this.pet}) : super(key: key);

  @override
  State<PetCRUDView> createState() => _PetCRUDViewState();
}

class _PetCRUDViewState extends State<PetCRUDView> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();
  final PetController _controller = PetController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  static const int _limiteNome = 30;
  static const int _limiteDescricao = 150;
  static const int _limiteContato = 15;

  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    final user = _auth.currentUser;
    _currentUserId = user?.uid;
    
    _loadPetData();
    
    if (_currentUserId == null) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ ATENÇÃO: Usuário não autenticado. O QR Code não funcionará.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
  }

  void _loadPetData() {
    _nomeController.text = widget.pet.nome;
    _descricaoController.text = widget.pet.descricao;
    _contatoController.text = widget.pet.contato;
  }

  String _generatePetUrl() {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return 'https://miguelmpicinin.github.io/Informacoes_Pet/?erro=Usuario+nao+autenticado';
    }
    
    final String encodedPetId = Uri.encodeComponent(widget.pet.id!);
    final String encodedPetName = Uri.encodeComponent(widget.pet.nome);
    final String encodedUserId = Uri.encodeComponent(_currentUserId!);
    final String encodedContato = Uri.encodeComponent(widget.pet.contato);
    final String encodedDescricao = Uri.encodeComponent(widget.pet.descricao);
    
    String url = 'https://miguelmpicinin.github.io/Informacoes_Pet/'
        '?petId=$encodedPetId'
        '&petName=$encodedPetName'
        '&userId=$encodedUserId'
        '&ownerContact=$encodedContato'
        '&description=$encodedDescricao';
    
    url += '&timestamp=${DateTime.now().millisecondsSinceEpoch}'
           '&source=app_petloc';
    
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final bool temUserId = _currentUserId != null && _currentUserId!.isNotEmpty;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editando ${widget.pet.nome}' : widget.pet.nome,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        actions: _isEditing 
            ? [
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: _saveChanges,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _cancelEditing,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _startEditing,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _confirmDelete,
                ),
              ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!temUserId)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '⚠️ USUÁRIO NÃO AUTENTICADO',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'O QR Code não funcionará sem o ID do usuário. Faça login novamente.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[200],
                        image: widget.pet.imagemBase64 != null && 
                               widget.pet.imagemBase64!.isNotEmpty
                            ? DecorationImage(
                                image: MemoryImage(_decodeBase64(widget.pet.imagemBase64!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.pet.imagemBase64 == null || 
                             widget.pet.imagemBase64!.isEmpty
                          ? const Icon(
                              Icons.pets,
                              size: 80,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildEditableField(
                    label: 'Nome',
                    controller: _nomeController,
                    icon: Icons.pets,
                    enabled: _isEditing,
                    maxLength: _limiteNome,
                  ),

                  const SizedBox(height: 16),

                  _buildEditableField(
                    label: 'Descrição',
                    controller: _descricaoController,
                    icon: Icons.description,
                    enabled: _isEditing,
                    maxLines: 3,
                    maxLength: _limiteDescricao,
                  ),

                  const SizedBox(height: 16),

                  _buildEditableField(
                    label: 'Contato',
                    controller: _contatoController,
                    icon: Icons.phone,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    maxLength: _limiteContato,
                  ),

                  if (temUserId)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'ID do Dono:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_currentUserId!.substring(0, 20)}...',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Este ID será usado no QR Code para identificar você como dono.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  if (!_isEditing) ..._buildActionButtons(),

                  const SizedBox(height: 24),

                  _buildInfoSection(),

                  const SizedBox(height: 24),

                  if (temUserId) _buildQRCodeSection(),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
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
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A73E8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            counterText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    final bool temUserId = _currentUserId != null && _currentUserId!.isNotEmpty;
    
    return [
      ElevatedButton(
        onPressed: temUserId ? _generateQRCode : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: temUserId ? const Color(0xFF1A73E8) : Colors.grey,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, color: temUserId ? Colors.white : Colors.grey[300]),
            const SizedBox(width: 8),
            Text(
              'Gerar QR Code',
              style: TextStyle(
                color: temUserId ? Colors.white : Colors.grey[300],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.localizacaoPet,
            arguments: widget.pet.id!,
          );
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFF1A73E8)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: Color(0xFF1A73E8)),
            SizedBox(width: 8),
            Text(
              'Ver Localização',
              style: TextStyle(
                color: Color(0xFF1A73E8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Limites de Caracteres',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Nome', '$_limiteNome caracteres'),
          _buildInfoItem('Descrição', '$_limiteDescricao caracteres'),
          _buildInfoItem('Contato', '$_limiteContato caracteres'),
          const SizedBox(height: 8),
          const Text(
            '📋 O QR Code usará:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          _buildInfoItem('• ID do Pet', widget.pet.id ?? 'Não disponível'),
          _buildInfoItem('• Nome do Pet', widget.pet.nome),
          _buildInfoItem('• ID do Dono', _currentUserId != null ? '${_currentUserId!.substring(0, 8)}...' : 'Não disponível'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    final webUrl = _generatePetUrl();

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
            '🔗 QR Code',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Este QR Code pode ser escaneado por QUALQUER smartphone:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem('✅ Com qualquer app leitor de QR Code'),
          _buildFeatureItem('✅ Não precisa ter este app instalado'),
          _buildFeatureItem('✅ Abre página web com informações'),
          _buildFeatureItem('✅ Permite compartilhar localização'),
          _buildFeatureItem('✅ ID do Pet: ${widget.pet.id}'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A73E8)),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: webUrl,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'QR Code para ${widget.pet.nome}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ID do Pet: ${widget.pet.id}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _copyWebLink(webUrl);
            },
            icon: const Icon(Icons.link),
            label: const Text('Copiar Link Web'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _copyWebLink(String webUrl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link do ${widget.pet.nome} copiado!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _loadPetData();
    });
  }

  void _saveChanges() async {
    if (_nomeController.text.isEmpty || 
        _descricaoController.text.isEmpty || 
        _contatoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nomeController.text.length > _limiteNome) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nome muito longo (máx. $_limiteNome caracteres)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descricaoController.text.length > _limiteDescricao) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Descrição muito longa (máx. $_limiteDescricao caracteres)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contatoController.text.length > _limiteContato) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contato muito longo (máx. $_limiteContato caracteres)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await _controller.editarPet(
      petId: widget.pet.id!,
      nome: _nomeController.text,
      descricao: _descricaoController.text,
      contato: _contatoController.text,
    );

    setState(() {
      _isLoading = false;
      _error = _controller.error;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isEditing = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${_controller.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir ${widget.pet.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePet();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _deletePet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await _controller.deletarPet(widget.pet.id!);

    setState(() {
      _isLoading = false;
      _error = _controller.error;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet excluído com sucesso!'),
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

  void _generateQRCode() {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final webUrl = _generatePetUrl();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - ${widget.pet.nome}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: webUrl,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'QR Code para ${widget.pet.nome}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compatível com qualquer leitor de QR Code',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔗 Link Web:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildQRCodeInfoItem('ID do Pet', widget.pet.id ?? 'N/A'),
                    _buildQRCodeInfoItem('Nome do Pet', widget.pet.nome),
                    _buildQRCodeInfoItem('ID do Dono', '${_currentUserId!.substring(0, 12)}...'),
                    _buildQRCodeInfoItem('Contato', widget.pet.contato),
                    _buildQRCodeInfoItem('Data de Geração', 
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _copyWebLink(webUrl);
                      },
                      icon: const Icon(Icons.content_copy, size: 16),
                      label: const Text('Copiar URL para testar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
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
// group_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_loc/controller/grupoChatController.dart';
import 'package:provider/provider.dart';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> grupo;

  const GroupChatScreen({Key? key, required this.grupo}) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Rolar para baixo quando novas mensagens chegarem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _enviarMensagem(GroupChatController controller) async {
    if (_mensagemController.text.trim().isEmpty) return;

    final success = await controller.enviarMensagem(
      grupoId: widget.grupo['id'],
      texto: _mensagemController.text,
    );

    if (success) {
      _mensagemController.clear();
      // Rolar para a última mensagem
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${controller.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMensagemBubble(Map<String, dynamic> mensagem, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
                child: Text(
                  mensagem['remetenteNome'].toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? const Color(0xFF1A73E8)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      mensagem['remetenteNome'] ?? 'Usuário',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  Text(
                    mensagem['texto'] ?? '',
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatarHora(mensagem['enviadoEm']),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUser ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarHora(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.grupo['nome'] ?? 'Grupo',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.grupo['membrosCount'] ?? 0} membros',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'info') {
                _mostrarInfoGrupo();
              } else if (value == 'sair') {
                _sairDoGrupo(context.read<GroupChatController>());
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Informações do Grupo'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'sair',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sair do Grupo'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<GroupChatController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: controller.mensagensStream(widget.grupo['id']),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erro: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final mensagens = snapshot.data ?? [];

                    if (mensagens.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma mensagem ainda',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Seja o primeiro a enviar uma mensagem!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: mensagens.length,
                      itemBuilder: (context, index) {
                        final mensagem = mensagens[index];
                        final isCurrentUser = controller.isMensagemDoUsuarioAtual(mensagem);
                        
                        return _buildMensagemBubble(mensagem, isCurrentUser);
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mensagemController,
                        decoration: InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _enviarMensagem(controller),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1A73E8),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _enviarMensagem(controller),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarInfoGrupo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${widget.grupo['nome']}'),
            const SizedBox(height: 8),
            Text('Descrição: ${widget.grupo['descricao']}'),
            const SizedBox(height: 8),
            Text('Categoria: ${widget.grupo['categoria']}'),
            const SizedBox(height: 8),
            Text('Membros: ${widget.grupo['membrosCount']}'),
            const SizedBox(height: 8),
            Text('Criado por: ${widget.grupo['criadorNome']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _sairDoGrupo(GroupChatController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Grupo'),
        content: const Text('Tem certeza que deseja sair deste grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Voltar para a tela anterior
              // Aqui você pode adicionar a lógica para sair do grupo
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
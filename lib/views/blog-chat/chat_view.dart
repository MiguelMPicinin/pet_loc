import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_loc/controller/grupoChatController.dart';
import 'package:pet_loc/views/blog-chat/group_chat_view.dart';
import 'package:provider/provider.dart';

class ChatContent extends StatefulWidget {
  const ChatContent({Key? key}) : super(key: key);

  @override
  _ChatContentState createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  
  final List<String> _categorias = [
    'Todos',
    'Adoção',
    'Saúde',
    'Comportamento',
    'Raças',
    'Nutrição',
    'Geral'
  ];
  
  String _categoriaSelecionada = 'Todos';
  String _categoriaNovoGrupo = 'Geral';

  @override
  void initState() {
    super.initState();
    // Carregar grupos após um pequeno delay para garantir que o Provider está disponível
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<GroupChatController>(context, listen: false);
      controller.carregarGrupos();
    });
  }

  Widget _buildCategoriaChip(String categoria) {
    final bool isSelected = categoria == _categoriaSelecionada;
    return GestureDetector(
      onTap: () {
        setState(() {
          _categoriaSelecionada = categoria;
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
          categoria,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getGruposStream(GroupChatController controller) {
    return controller.gruposStream.map((grupos) {
      if (_categoriaSelecionada == 'Todos') {
        return grupos;
      } else {
        return grupos.where((grupo) => grupo['categoria'] == _categoriaSelecionada).toList();
      }
    });
  }

  Future<void> _criarNovoGrupo(GroupChatController controller) async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um nome para o grupo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await controller.criarGrupo(
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim(),
      categoria: _categoriaNovoGrupo,
    );

    if (success) {
      _nomeController.clear();
      _descricaoController.clear();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grupo criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar grupo: ${controller.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoCriarGrupo(GroupChatController controller) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.group_add, color: Color(0xFF1A73E8)),
                SizedBox(width: 8),
                Text('Criar Novo Grupo'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Grupo*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descricaoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _categoriaNovoGrupo,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: _categorias.where((cat) => cat != 'Todos').map((categoria) {
                      return DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoriaNovoGrupo = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => _criarNovoGrupo(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                ),
                child: const Text('Criar Grupo'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrupoCard(Map<String, dynamic> grupo, GroupChatController controller) {
    final isMembro = controller.isMembroDoGrupo(grupo);

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
            child: Center(
              child: Text(
                grupo['icone'] ?? '💬',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  grupo['nome'] ?? 'Grupo sem nome',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!isMembro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ENTRAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
                grupo['descricao'] ?? 'Sem descrição',
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
                  Icon(Icons.people, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${grupo['membrosCount'] ?? 0} membros',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      grupo['ultimaMensagem'] ?? 'Nenhuma mensagem ainda',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatarHora(grupo['ultimaMensagemData']),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            if (!isMembro) {
              controller.entrarNoGrupo(grupo['id']).then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Você entrou no grupo ${grupo['nome']}!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Recarregar os grupos após entrar
                  controller.carregarGrupos();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao entrar no grupo: ${controller.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            } else {
              // Navegar para a tela de mensagens do grupo
              _abrirChatGrupo(grupo);
            }
          },
        ),
      ),
    );
  }

  void _abrirChatGrupo(Map<String, dynamic> grupo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(grupo: grupo),
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
      return '${date.day}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupChatController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.grupos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
            ),
          );
        }

        if (controller.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro: ${controller.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.carregarGrupos(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoCriarGrupo(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.group_add),
                label: const Text(
                  'Criar Novo Grupo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

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

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getGruposStream(controller),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar grupos: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                      ),
                    );
                  }

                  final grupos = snapshot.data ?? [];

                  if (grupos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "Nenhum grupo encontrado",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _categoriaSelecionada == 'Todos' 
                              ? "Crie o primeiro grupo ou aguarde novos grupos"
                              : "Nenhum grupo encontrado na categoria $_categoriaSelecionada",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      itemCount: grupos.length,
                      itemBuilder: (context, index) => _buildGrupoCard(grupos[index], controller),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
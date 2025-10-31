import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_loc/services/app_routes.dart';

class ChatView extends StatefulWidget {
  const ChatView({Key? key}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  Stream<QuerySnapshot> _getGruposStream() {
    if (_categoriaSelecionada == 'Todos') {
      return _firestore
          .collection('chat_grupos')
          .where('ativo', isEqualTo: true)
          .orderBy('ultimaMensagemData', descending: true)
          .snapshots();
    } else {
      return _firestore
          .collection('chat_grupos')
          .where('ativo', isEqualTo: true)
          .where('categoria', isEqualTo: _categoriaSelecionada)
          .orderBy('ultimaMensagemData', descending: true)
          .snapshots();
    }
  }

  Future<void> _criarNovoGrupo() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um nome para o grupo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário não autenticado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final novoGrupo = {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'categoria': _categoriaNovoGrupo,
        'criadorId': user.uid,
        'criadorNome': user.displayName ?? 'Usuário',
        'membros': [user.uid],
        'membrosCount': 1,
        'ativo': true,
        'criadoEm': FieldValue.serverTimestamp(),
        'ultimaMensagemData': FieldValue.serverTimestamp(),
        'ultimaMensagem': 'Grupo criado por ${user.displayName ?? "Usuário"}',
        'icone': _getIconePorCategoria(_categoriaNovoGrupo),
      };

      await _firestore.collection('chat_grupos').add(novoGrupo);

      // Limpar campos
      _nomeController.clear();
      _descricaoController.clear();
      
      // Fechar dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grupo criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar grupo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getIconePorCategoria(String categoria) {
    switch (categoria) {
      case 'Adoção':
        return '🏠';
      case 'Saúde':
        return '🏥';
      case 'Comportamento':
        return '🎓';
      case 'Raças':
        return '🐕';
      case 'Nutrição':
        return '🍖';
      default:
        return '💬';
    }
  }

  Future<void> _entrarNoGrupo(String grupoId, String grupoNome) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('chat_grupos').doc(grupoId).update({
        'membros': FieldValue.arrayUnion([user.uid]),
        'membrosCount': FieldValue.increment(1),
        'ultimaMensagemData': FieldValue.serverTimestamp(),
        'ultimaMensagem': '${user.displayName ?? "Novo usuário"} entrou no grupo',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você entrou no grupo $grupoNome!'),
          backgroundColor: Colors.green,
        ),
      );

      // Aqui você pode navegar para a tela de mensagens do grupo
      // Navigator.pushNamed(context, AppRoutes.chatGrupo, arguments: grupoId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao entrar no grupo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoCriarGrupo() {
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
                onPressed: _criarNovoGrupo,
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

  Widget _buildGrupoCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final user = _auth.currentUser;
    final isMembro = user != null && (data['membros'] as List? ?? []).contains(user.uid);

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
                data['icone'] ?? '💬',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  data['nome'] ?? 'Grupo sem nome',
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
                data['descricao'] ?? 'Sem descrição',
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
                    '${data['membrosCount'] ?? 0} membros',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['ultimaMensagem'] ?? 'Nenhuma mensagem ainda',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatarHora(data['ultimaMensagemData']),
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
              _entrarNoGrupo(doc.id, data['nome'] ?? 'Grupo');
            } else {
              // Navegar para tela de mensagens do grupo
              // Navigator.pushNamed(context, AppRoutes.chatGrupo, arguments: doc.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Abrindo conversa do grupo ${data['nome']}'),
                  backgroundColor: const Color(0xFF1A73E8),
                ),
              );
            }
          },
        ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PetLoc Chat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Converse com outros donos de pets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            onPressed: _mostrarDialogoCriarGrupo,
            tooltip: 'Criar Grupo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Categorias
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

          // Stream de grupos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getGruposStream(),
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

                final grupos = snapshot.data?.docs ?? [];

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
                          "Crie o primeiro grupo ou aguarde novos grupos",
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
                    itemBuilder: (context, index) => _buildGrupoCard(grupos[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1A73E8),
      unselectedItemColor: Colors.grey[600],
      currentIndex: 4,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
          case 1:
            Navigator.pushReplacementNamed(context, AppRoutes.criarDesaparecido);
            break;
          case 2:
            Navigator.pushReplacementNamed(context, AppRoutes.loja);
            break;
          case 3:
            Navigator.pushReplacementNamed(context, AppRoutes.desaparecidos);
            break;
          case 4:
            Navigator.pushReplacementNamed(context, AppRoutes.blog);
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
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          activeIcon: Icon(Icons.article),
          label: 'Blog',
        ),
      ],
    );
  }
}
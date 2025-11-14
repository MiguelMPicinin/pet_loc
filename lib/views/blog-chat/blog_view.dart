import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlogContent extends StatefulWidget {
  const BlogContent({Key? key}) : super(key: key);

  @override
  _BlogContentState createState() => _BlogContentState();
}

class _BlogContentState extends State<BlogContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _categorias = [
    'Todos',
    'Saúde',
    'Nutrição',
    'Comportamento',
    'Entretenimento',
    'Adoção'
  ];
  String _categoriaSelecionada = 'Todos';

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

  Widget _buildNoticiaCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header da notícia
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['icone'] ?? '📰',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['titulo'] ?? 'Sem título',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A73E8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Por ${data['autor'] ?? 'Autor desconhecido'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Corpo da notícia
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['descricao'] ?? 'Sem descrição disponível',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data['categoria'] ?? 'Geral',
                          style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${data['tempoLeitura'] ?? '5'} min de leitura',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatarData(data['dataPublicacao']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(dynamic data) {
    try {
      if (data == null) return 'Data desconhecida';
      
      if (data is Timestamp) {
        final date = data.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } else if (data is String) {
        return data;
      } else {
        return 'Data desconhecida';
      }
    } catch (e) {
      return 'Data desconhecida';
    }
  }

  Stream<QuerySnapshot> _getNoticiasStream() {
    try {
      if (_categoriaSelecionada == 'Todos') {
        return _firestore
            .collection('blog_posts')
            .where('ativo', isEqualTo: true)
            .orderBy('dataPublicacao', descending: true)
            .snapshots();
      } else {
        return _firestore
            .collection('blog_posts')
            .where('ativo', isEqualTo: true)
            .where('categoria', isEqualTo: _categoriaSelecionada)
            .orderBy('dataPublicacao', descending: true)
            .snapshots();
      }
    } catch (e) {
      // Retorna um stream vazio em caso de erro
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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

        // Stream de notícias
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getNoticiasStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar notícias',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tente novamente mais tarde',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                  ),
                );
              }

              final noticias = snapshot.data?.docs ?? [];

              if (noticias.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "Nenhuma notícia encontrada",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "As notícias aparecerão aqui quando forem publicadas",
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
                  itemCount: noticias.length,
                  itemBuilder: (context, index) => _buildNoticiaCard(noticias[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
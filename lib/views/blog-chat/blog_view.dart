import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_loc/models/news_article.dart';
import 'package:pet_loc/services/news_service.dart';
import 'package:pet_loc/widgets/news_card.dart';

class BlogContent extends StatefulWidget {
  const BlogContent({Key? key}) : super(key: key);

  @override
  _BlogContentState createState() => _BlogContentState();
}

class _BlogContentState extends State<BlogContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NewsService _newsService = NewsService();
  final List<String> _categorias = [
    'Todos',
    'Saúde',
    'Nutrição',
    'Comportamento',
    'Entretenimento',
    'Adoção'
  ];
  String _categoriaSelecionada = 'Todos';
  List<NewsArticle> _apiNews = [];
  bool _isLoadingApiNews = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadApiNews();
  }

  Future<void> _loadApiNews() async {
    setState(() {
      _isLoadingApiNews = true;
      _hasError = false;
    });

    try {
      final news = await _newsService.fetchAllPetNews();
      setState(() {
        _apiNews = news;
      });
    } catch (e) {
      print('Erro ao carregar notícias da API: $e');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoadingApiNews = false;
      });
    }
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
                      (data['icone'] as String?) ?? '📰',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (data['titulo'] as String?) ?? 'Sem título',
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
                          'Por ${(data['autor'] as String?) ?? 'Autor desconhecido'}',
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (data['descricao'] as String?) ?? 'Sem descrição disponível',
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
                          (data['categoria'] as String?) ?? 'Geral',
                          style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${(data['tempoLeitura'] as String?) ?? '5'} min de leitura',
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
      print('Erro no stream do Firestore: $e');
      return const Stream.empty();
    }
  }

  List<NewsArticle> _getFilteredApiNews() {
    if (_categoriaSelecionada == 'Todos') {
      return _apiNews;
    }
    return _apiNews.where((article) => article.category == _categoriaSelecionada).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header com título e botão de refresh
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Text(
                'Notícias sobre Pets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadApiNews,
                icon: const Icon(Icons.refresh),
                tooltip: 'Recarregar notícias',
              ),
            ],
          ),
        ),

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

        // Conteúdo combinado
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getNoticiasStream(),
            builder: (context, snapshot) {
              final firestoreNews = snapshot.data?.docs ?? [];
              final filteredApiNews = _getFilteredApiNews();
              final hasFirestoreNews = firestoreNews.isNotEmpty;
              final hasApiNews = filteredApiNews.isNotEmpty;

              if (_hasError && !hasFirestoreNews && !hasApiNews && !_isLoadingApiNews) {
                return _buildErrorState();
              }

              if (!hasFirestoreNews && !hasApiNews && !_isLoadingApiNews) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _loadApiNews,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Notícias do Firestore
                    if (hasFirestoreNews) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Notícias do Nosso Blog',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...firestoreNews.map((doc) => _buildNoticiaCard(doc)),
                    ],

                    // Notícias das APIs
                    if (hasApiNews) ...[
                      if (hasFirestoreNews) const SizedBox(height: 24),
                      
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Notícias da Internet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...filteredApiNews.map((article) => NewsCard(article: article)),
                    ],

                    // Loading
                    if (_isLoadingApiNews)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Erro ao carregar notícias",
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Verifique sua conexão com a internet",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadApiNews,
            icon: const Icon(Icons.refresh),
            label: const Text("Tentar Novamente"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma notícia encontrada",
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tente mudar a categoria ou recarregar as notícias",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
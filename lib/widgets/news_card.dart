import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_article.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final bool isFromApi;

  const NewsCard({
    Key? key,
    required this.article,
    this.isFromApi = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _launchURL(article.url),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.urlToImage.isNotEmpty)
              _buildImageSection(),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: article.urlToImage,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 180,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Imagem não disponível',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSourceColor().withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getSourceAbbreviation(article.apiSource),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            article.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
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
                  color: _getCategoryColor(article.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(article.category), 
                         size: 12, 
                         color: _getCategoryColor(article.category)),
                    const SizedBox(width: 4),
                    Text(
                      article.category,
                      style: TextStyle(
                        color: _getCategoryColor(article.category),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    article.source,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(article.publishedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (article.author.isNotEmpty && article.author != 'Autor desconhecido')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Por ${article.author}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getSourceColor() {
    switch (article.apiSource) {
      case 'NewsAPI':
        return Colors.blue;
      case 'Brasil':
        return Colors.green;
      case 'Reddit':
        return Colors.orange;
      case 'DogAPI':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getSourceAbbreviation(String source) {
    switch (source) {
      case 'NewsAPI': return 'NEWS';
      case 'Brasil': return 'BR';
      case 'Reddit': return 'REDDIT';
      case 'DogAPI': return 'CURIOSIDADE';
      default: return source;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Saúde':
        return Colors.red;
      case 'Nutrição':
        return Colors.orange;
      case 'Comportamento':
        return Colors.blue;
      case 'Adoção':
        return Colors.green;
      case 'Entretenimento':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Saúde':
        return Icons.medical_services;
      case 'Nutrição':
        return Icons.restaurant;
      case 'Comportamento':
        return Icons.psychology;
      case 'Adoção':
        return Icons.favorite;
      case 'Entretenimento':
        return Icons.celebration;
      default:
        return Icons.category;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Hoje';
      } else if (difference.inDays == 1) {
        return 'Ontem';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} dias atrás';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Data desconhecida';
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      if (url.isEmpty) {
        print('URL vazia');
        return;
      }
      
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        print('Não foi possível abrir a URL: $url');
      }
    } catch (e) {
      print('Erro ao abrir URL: $e');
    }
  }
}
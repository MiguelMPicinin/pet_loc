import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

class NewsService {
  static const String _newsApiKey = 'SUA_CHAVE_NEWSAPI_AQUI';
  static const String _newsApiUrl = 'https://newsapi.org/v2/everything';
  static const String _redditApiUrl = 'https://www.reddit.com/r/';
  static const String _dogApiUrl = 'https://api.thedogapi.com/v1/images/search';

  Future<List<NewsArticle>> fetchAllPetNews() async {
    try {
      final results = await Future.wait([
        _fetchNewsFromBrazilianSources(),
        _fetchNewsFromNewsAPI(),
        _fetchNewsFromReddit(),
        _fetchDogFacts(),
      ], eagerError: true);

      List<NewsArticle> allNews = [];
      for (var result in results) {
        if (result is List<NewsArticle>) {
          allNews.addAll(result.where((article) => article.title.isNotEmpty));
        }
      }

      // Ordenar por data (mais recentes primeiro)
      allNews.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      
      return allNews;
    } catch (e) {
      print('Erro ao buscar notícias: $e');
      return [];
    }
  }

  Future<List<NewsArticle>> _fetchNewsFromBrazilianSources() async {
    try {
      List<NewsArticle> brazilianNews = [];

      final ongs = [
        {
          'titulo': 'Campanha de Adoção - Cães SRD',
          'descricao': 'Centenas de cães aguardam por um lar amoroso. Venha conhecer nossos peludos!',
          'url': 'https://www.amparanimal.org.br',
          'imagem': 'https://source.unsplash.com/random/800x600/?dog,brazil',
          'fonte': 'AMPARA Animal',
          'categoria': 'Adoção'
        },
        {
          'titulo': 'Feira de Adoção Responsável',
          'descricao': 'Domingo no Parque Ibirapuera - Venha adotar seu novo melhor amigo!',
          'url': 'https://www.adoteumfocinho.com.br',
          'imagem': 'https://source.unsplash.com/random/800x600/?cat,brazil',
          'fonte': 'Adote um Focinho',
          'categoria': 'Adoção'
        }
      ];

      final noticias = [
        {
          'titulo': 'Cuidados com pets no verão brasileiro',
          'descricao': 'Veterinários dão dicas essenciais para proteger seu pet no calor intenso',
          'url': 'https://exemplo.com/noticia1',
          'imagem': 'https://source.unsplash.com/random/800x600/?summer,dog',
          'fonte': 'Pet Brasil',
          'categoria': 'Saúde'
        },
        {
          'titulo': 'Nova lei de maus-tratos a animais',
          'descricao': 'Entenda as mudanças na legislação brasileira sobre proteção animal',
          'url': 'https://exemplo.com/noticia2',
          'imagem': 'https://source.unsplash.com/random/800x600/?law,animal',
          'fonte': 'Jornal Animal',
          'categoria': 'Comportamento'
        }
      ];

      for (var item in [...ongs, ...noticias]) {
        try {
          brazilianNews.add(NewsArticle(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: item['titulo']?.toString() ?? 'Sem título',
            description: item['descricao']?.toString() ?? 'Sem descrição',
            url: item['url']?.toString() ?? '',
            urlToImage: item['imagem']?.toString() ?? '',
            publishedAt: DateTime.now().toIso8601String(),
            source: item['fonte']?.toString() ?? 'Fonte desconhecida',
            category: item['categoria']?.toString() ?? 'Geral',
            apiSource: 'Brasil',
            author: 'ONG Brasileira',
          ));
        } catch (e) {
          print('Erro ao criar notícia brasileira: $e');
        }
      }

      return brazilianNews;
    } catch (e) {
      print('Erro fontes brasileiras: $e');
      return [];
    }
  }

  Future<List<NewsArticle>> _fetchNewsFromNewsAPI() async {
    try {
      if (_newsApiKey == 'SUA_CHAVE_NEWSAPI_AQUI') {
        print('⚠️  Configure sua chave da NewsAPI em services/news_service.dart');
        return [];
      }

      final queries = [
        'pets OR animais OR saúde animal',
        'cachorro OR gato OR veterinário',
        'adoção animal OR resgate animais',
      ];

      List<NewsArticle> allArticles = [];

      for (final query in queries) {
        try {
          final response = await http.get(
            Uri.parse('$_newsApiUrl?q=$query&language=pt&pageSize=5&sortBy=publishedAt&apiKey=$_newsApiKey'),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final articles = data['articles'] as List? ?? [];
            
            for (var article in articles) {
              try {
                final newsArticle = NewsArticle.fromJson(
                  article is Map<String, dynamic> ? article : {},
                  apiSource: 'NewsAPI',
                );
                allArticles.add(newsArticle);
              } catch (e) {
                print('Erro ao converter artigo NewsAPI: $e');
              }
            }
          } else {
            print('Erro NewsAPI: ${response.statusCode}');
          }

          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          print('Erro na query NewsAPI: $e');
        }
      }

      return allArticles;
    } catch (e) {
      print('Erro NewsAPI: $e');
      return [];
    }
  }

  Future<List<NewsArticle>> _fetchNewsFromReddit() async {
    try {
      final subreddits = ['pets', 'dogs', 'cats', 'dogtraining', 'PetAdvice'];
      List<NewsArticle> allPosts = [];

      for (final subreddit in subreddits) {
        try {
          final response = await http.get(
            Uri.parse('$_redditApiUrl$subreddit/hot.json?limit=10'),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final posts = (data['data']?['children'] as List?) ?? [];

            for (var post in posts) {
              try {
                final postData = post['data'] as Map<String, dynamic>? ?? {};
                
                final article = NewsArticle(
                  id: postData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  title: postData['title']?.toString() ?? 'Sem título',
                  description: postData['selftext']?.toString() ?? 'Clique para ver mais detalhes no Reddit',
                  url: 'https://reddit.com${postData['permalink'] ?? ""}',
                  urlToImage: _getRedditImage(postData),
                  publishedAt: _getRedditPublishedAt(postData),
                  source: 'Reddit - r/${postData['subreddit'] ?? "unknown"}',
                  category: NewsArticle.determineCategory(postData['title']?.toString() ?? ''),
                  apiSource: 'Reddit',
                  author: 'u/${postData['author'] ?? "unknown"}',
                );
                allPosts.add(article);
              } catch (e) {
                print('Erro ao processar post do Reddit: $e');
              }
            }
          } else {
            print('Erro Reddit ${subreddit}: ${response.statusCode}');
          }

          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('Erro no subreddit $subreddit: $e');
        }
      }

      return allPosts;
    } catch (e) {
      print('Erro Reddit: $e');
      return [];
    }
  }

  String _getRedditImage(Map<String, dynamic> postData) {
    try {
      // Tenta obter thumbnail
      if (postData['thumbnail'] != null && 
          postData['thumbnail'] is String &&
          postData['thumbnail'].startsWith('http') &&
          postData['thumbnail'] != 'self' &&
          postData['thumbnail'] != 'default') {
        return postData['thumbnail'] as String;
      }
      
      // Tenta obter preview images
      if (postData['preview'] != null && postData['preview'] is Map) {
        final images = postData['preview']['images'] as List?;
        if (images != null && images.isNotEmpty) {
          final image = images.first as Map<String, dynamic>?;
          if (image != null && image['source'] != null) {
            final url = (image['source']['url'] as String?)?.replaceAll('&amp;', '&');
            if (url != null && url.isNotEmpty) {
              return url;
            }
          }
        }
      }
      
      // Tenta obter URL direta se for imagem
      if (postData['url'] != null && 
          postData['url'] is String &&
          (postData['url'].endsWith('.jpg') || 
           postData['url'].endsWith('.png') ||
           postData['url'].endsWith('.jpeg'))) {
        return postData['url'] as String;
      }
    } catch (e) {
      print('Erro ao obter imagem do Reddit: $e');
    }
    
    return '';
  }

  String _getRedditPublishedAt(Map<String, dynamic> postData) {
    try {
      final createdUtc = postData['created_utc'];
      if (createdUtc != null) {
        final timestamp = (createdUtc as num).toInt() * 1000;
        return DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
      }
    } catch (e) {
      print('Erro ao obter data do Reddit: $e');
    }
    
    return DateTime.now().toIso8601String();
  }

  Future<List<NewsArticle>> _fetchDogFacts() async {
    try {
      final response = await http.get(
        Uri.parse('https://dog-api.kinduff.com/api/facts?number=2'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final facts = (data['facts'] as List?) ?? [];
        
        String imageUrl = '';
        try {
          final imageResponse = await http.get(Uri.parse('$_dogApiUrl?limit=1'));
          if (imageResponse.statusCode == 200) {
            final imageData = json.decode(imageResponse.body) as List?;
            if (imageData != null && imageData.isNotEmpty) {
              imageUrl = (imageData.first['url'] as String?) ?? '';
            }
          }
        } catch (e) {
          print('Erro ao buscar imagem de cachorro: $e');
        }

        return facts.map((fact) {
          return NewsArticle(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Curiosidade Canina 🐕',
            description: fact?.toString() ?? 'Fato interessante sobre cães',
            url: 'https://thedogapi.com',
            urlToImage: imageUrl,
            publishedAt: DateTime.now().toIso8601String(),
            source: 'The Dog API',
            category: 'Entretenimento',
            apiSource: 'DogAPI',
            author: 'The Dog API',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Erro Dog API: $e');
      return [];
    }
  }

  Future<List<NewsArticle>> fetchPetNews() async {
    return await fetchAllPetNews();
  }
}
class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String url;
  final String urlToImage;
  final String publishedAt;
  final String source;
  final String category;
  final String apiSource;
  final String author;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.source,
    required this.category,
    required this.apiSource,
    required this.author,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json, {String apiSource = 'Generic'}) {
    return NewsArticle(
      id: _getStringValue(json['id']) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _getStringValue(json['title']) ?? _getStringValue(json['titulo']) ?? 'Sem título',
      description: _getStringValue(json['description']) ?? 
                  _getStringValue(json['descricao']) ?? 
                  _getStringValue(json['content']) ?? 
                  'Sem descrição disponível',
      url: _getStringValue(json['url']) ?? _getStringValue(json['link']) ?? '',
      urlToImage: _getStringValue(json['urlToImage']) ?? 
                 _getStringValue(json['image']) ?? 
                 _getStringValue(json['imagem']) ?? 
                 _getStringValue(json['thumbnail']) ?? 
                 '',
      publishedAt: _getStringValue(json['publishedAt']) ?? 
                  _getStringValue(json['pubDate']) ?? 
                  _getStringValue(json['dataPublicacao']) ?? 
                  DateTime.now().toIso8601String(),
      source: _getSourceName(json),
      category: determineCategory(_getStringValue(json['title']) ?? _getStringValue(json['titulo']) ?? ''),
      apiSource: apiSource,
      author: _getStringValue(json['author']) ?? 
             _getStringValue(json['autor']) ?? 
             _getStringValue(json['creator']) ?? 
             'Autor desconhecido',
    );
  }

  static String? _getStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static String _getSourceName(Map<String, dynamic> json) {
    if (json['source'] is String) return json['source'] as String;
    if (json['source'] is Map) return (json['source']['name'] as String?) ?? 'Fonte desconhecida';
    if (json['source_name'] != null) return json['source_name'].toString();
    if (json['fonte'] != null) return json['fonte'].toString();
    return 'Fonte desconhecida';
  }

  static String determineCategory(String title) {
    if (title.isEmpty) return 'Entretenimento';
    
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('saúde') || lowerTitle.contains('veterinár') || 
        lowerTitle.contains('doença') || lowerTitle.contains('medicina') ||
        lowerTitle.contains('health') || lowerTitle.contains('vet')) {
      return 'Saúde';
    } else if (lowerTitle.contains('alimentação') || lowerTitle.contains('nutrição') || 
               lowerTitle.contains('ração') || lowerTitle.contains('dieta') ||
               lowerTitle.contains('food') || lowerTitle.contains('nutrition')) {
      return 'Nutrição';
    } else if (lowerTitle.contains('comportamento') || lowerTitle.contains('treinamento') || 
               lowerTitle.contains('adestramento') || lowerTitle.contains('behavior') ||
               lowerTitle.contains('training')) {
      return 'Comportamento';
    } else if (lowerTitle.contains('adoção') || lowerTitle.contains('abandono') || 
               lowerTitle.contains('resgate') || lowerTitle.contains('adoption') ||
               lowerTitle.contains('rescue')) {
      return 'Adoção';
    } else {
      return 'Entretenimento';
    }
  }
}
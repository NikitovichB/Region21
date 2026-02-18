class NewsModel {
  NewsModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? imageUrl;
}

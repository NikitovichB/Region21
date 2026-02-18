import '../models/news_model.dart';

abstract class NewsRepository {
  Future<List<NewsModel>> fetchLatest({int limit = 10});

  // ✅ live stream из базы
  Stream<List<NewsModel>> watchLatest({int limit = 10});
}

import '../models/story_model.dart';

abstract class StoryRepository {
  Future<List<StoryModel>> fetchLatest({int limit = 12});

  /// Live обновления (Firestore snapshots)
  Stream<List<StoryModel>> watchLatest({int limit = 12});
}

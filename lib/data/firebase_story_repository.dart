import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import 'story_repository.dart';

class FirebaseStoryRepository implements StoryRepository {
  FirebaseStoryRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Берём чуть больше, чтобы нормально отсортировать по priority на клиенте
  static const int _prefetchMultiplier = 4;

  @override
  Future<List<StoryModel>> fetchLatest({int limit = 12}) async {
    final prefetch = (limit * _prefetchMultiplier).clamp(limit, 100);

    final snap = await _db
        .collection('stories')
        // Один orderBy = не требует composite index
        .orderBy('createdAt', descending: true)
        .limit(prefetch)
        .get();

    final items = snap.docs.map(_fromDoc).toList();
    return _sortAndCut(items, limit);
  }

  @override
  Stream<List<StoryModel>> watchLatest({int limit = 12}) {
    final prefetch = (limit * _prefetchMultiplier).clamp(limit, 100);

    return _db
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .limit(prefetch)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map(_fromDoc).toList();
          return _sortAndCut(items, limit);
        });
  }

  List<StoryModel> _sortAndCut(List<StoryModel> items, int limit) {
    items.sort((a, b) {
      // 1) priority desc
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      // 2) createdAt desc
      return b.createdAt.compareTo(a.createdAt);
    });

    if (items.length <= limit) return items;
    return items.take(limit).toList();
  }

  StoryModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    // createdAt может быть Timestamp / строкой / отсутствовать — не падаем
    DateTime createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    // priority может быть num / string / null — не падаем
    int priority = 0;
    final rawPriority = data['priority'];
    if (rawPriority is num) {
      priority = rawPriority.toInt();
    } else if (rawPriority is String) {
      priority = int.tryParse(rawPriority) ?? 0;
    }

    final title = (data['title'] ?? '').toString().trim();

    final imageUrl = (data['imageUrl']?.toString().trim().isEmpty ?? true)
        ? null
        : data['imageUrl'].toString().trim();

    final assetPath = (data['assetPath']?.toString().trim().isEmpty ?? true)
        ? null
        : data['assetPath'].toString().trim();

    return StoryModel(
      id: doc.id,
      title: title.isEmpty ? 'Story' : title,
      createdAt: createdAt,
      imageUrl: imageUrl,
      assetPath: assetPath,
      priority: priority,
    );
  }
}

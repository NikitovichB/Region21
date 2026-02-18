import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';
import 'news_repository.dart';

class FirebaseNewsRepository implements NewsRepository {
  FirebaseNewsRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<NewsModel>> fetchLatest({int limit = 10}) async {
    final snap = await _db
        .collection('news')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Stream<List<NewsModel>> watchLatest({int limit = 10}) {
    return _db
        .collection('news')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  NewsModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final createdAt = (data['createdAt'] is Timestamp)
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.tryParse('${data['createdAt']}') ?? DateTime.now();

    return NewsModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      createdAt: createdAt,
      imageUrl: data['imageUrl']?.toString(),
    );
  }    
}

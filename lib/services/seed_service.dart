import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  SeedService(this._db);
  final FirebaseFirestore _db;

  Future<void> seedDemoProducts({int count = 8, required String sellerId}) async {
    final existing = await _db.collection('products').limit(1).get();
    if (existing.docs.isNotEmpty) return; // already seeded
    final batch = _db.batch();
    final now = DateTime.now();
    for (var i = 0; i < count; i++) {
      final doc = _db.collection('products').doc();
      batch.set(doc, {
        'sellerId': sellerId,
        'title': 'Demo Product ${i + 1}',
        'description': 'Sample description for product ${i + 1}.',
        'price': (i + 1) * 3.5,
        'stock': 10 + i,
        'imageUrls': [],
        'ratingAvg': 0,
        'ratingCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'active': true,
      });
    }
    await batch.commit();
  }
}

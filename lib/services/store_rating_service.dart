import 'package:cloud_firestore/cloud_firestore.dart';

class StoreRating {
  final String id;
  final String userId;
  final String sellerId;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;

  StoreRating({
    required this.id,
    required this.userId,
    required this.sellerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'sellerId': sellerId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory StoreRating.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StoreRating(
      id: doc.id,
      userId: d['userId'] ?? '',
      sellerId: d['sellerId'] ?? '',
      rating: (d['rating'] ?? 0) as int,
      comment: d['comment'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class StoreRatingService {
  StoreRatingService(this._db);
  final FirebaseFirestore _db;

  CollectionReference get _ratings => _db.collection('storeRatings');
  CollectionReference get _stores => _db.collection('stores');

  /// Check if user has already rated a store
  Future<StoreRating?> getUserRating(String userId, String sellerId) async {
    final query = await _ratings
        .where('userId', isEqualTo: userId)
        .where('sellerId', isEqualTo: sellerId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return StoreRating.fromDoc(query.docs.first);
  }

  /// Submit or update a store rating
  Future<void> rateStore({
    required String userId,
    required String sellerId,
    required int rating,
    String? comment,
  }) async {
    // Check if user already rated
    final existing = await getUserRating(userId, sellerId);
    
    if (existing != null) {
      // Update existing rating
      await _ratings.doc(existing.id).update({
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new rating
      await _ratings.add({
        'userId': userId,
        'sellerId': sellerId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Recalculate average rating
    await _recalculateStoreRating(sellerId);
  }

  /// Recalculate and update store's average rating
  Future<void> _recalculateStoreRating(String sellerId) async {
    final ratingsSnap = await _ratings.where('sellerId', isEqualTo: sellerId).get();
    
    if (ratingsSnap.docs.isEmpty) {
      await _stores.doc(sellerId).update({'rating': 0.0, 'ratingCount': 0});
      return;
    }

    double sum = 0;
    for (final doc in ratingsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sum += ((data['rating'] ?? 0) as int).toDouble();
    }

    final avg = sum / ratingsSnap.docs.length;
    await _stores.doc(sellerId).update({
      'rating': avg,
      'ratingCount': ratingsSnap.docs.length,
    });
  }

  /// Get all ratings for a store
  Stream<List<StoreRating>> watchStoreRatings(String sellerId) {
    return _ratings
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(StoreRating.fromDoc).toList());
  }
}

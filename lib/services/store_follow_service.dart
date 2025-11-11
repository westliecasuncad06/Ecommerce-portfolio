import 'package:cloud_firestore/cloud_firestore.dart';

class StoreFollowService {
  StoreFollowService(this._db);
  final FirebaseFirestore _db;

  CollectionReference get _followers => _db.collection('storeFollowers');
  CollectionReference get _stores => _db.collection('stores');

  /// Check if a user is following a store
  Future<bool> isFollowing(String userId, String sellerId) async {
    final doc = await _followers.doc('${userId}_$sellerId').get();
    return doc.exists;
  }

  /// Follow a store
  Future<void> followStore(String userId, String sellerId) async {
    final batch = _db.batch();
    
    // Add follow document
    batch.set(_followers.doc('${userId}_$sellerId'), {
      'userId': userId,
      'sellerId': sellerId,
      'followedAt': FieldValue.serverTimestamp(),
    });
    
    // Increment follower count
    batch.update(_stores.doc(sellerId), {
      'followers': FieldValue.increment(1),
    });
    
    await batch.commit();
  }

  /// Unfollow a store
  Future<void> unfollowStore(String userId, String sellerId) async {
    final batch = _db.batch();
    
    // Remove follow document
    batch.delete(_followers.doc('${userId}_$sellerId'));
    
    // Decrement follower count
    batch.update(_stores.doc(sellerId), {
      'followers': FieldValue.increment(-1),
    });
    
    await batch.commit();
  }

  /// Get follower count for a store
  Stream<int> watchFollowerCount(String sellerId) {
    return _stores.doc(sellerId).snapshots().map((doc) {
      if (!doc.exists) return 0;
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['followers'] ?? 0) as int;
    });
  }
}

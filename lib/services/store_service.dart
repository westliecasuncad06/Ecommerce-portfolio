import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_profile.dart';

class StoreService {
  StoreService(this._db);
  final FirebaseFirestore _db;

  CollectionReference get _col => _db.collection('stores');

  Future<StoreProfile?> fetchStore(String sellerId) async {
    final doc = await _col.doc(sellerId).get();
    if (!doc.exists) return null;
    return StoreProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<void> updateStore(String sellerId, StoreProfile profile) async {
    await _col.doc(sellerId).set(profile.toMap(), SetOptions(merge: true));
  }
}

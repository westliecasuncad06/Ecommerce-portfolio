import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  ProductService(this._db);
  final FirebaseFirestore _db;

  CollectionReference get _col => _db.collection('products');

  // NOTE: Removing server-side orderBy here to avoid requiring a composite
  // Firestore index for the combination of where('active') + orderBy('createdAt').
  // We instead fetch the active documents and sort them client-side by
  // createdAt descending. If you prefer a server-side ordered query, create
  // the required composite index in the Firebase console (link provided in
  // Firestore error message).
  Stream<List<Product>> watchActiveProducts() => _col
      .where('active', isEqualTo: true)
      .limit(100)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Product.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<Product?> fetch(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromDoc(doc);
  }

  Stream<List<Product>> watchProductsBySeller(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .where('active', isEqualTo: true)
      .limit(200)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Product.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<String> create(Product p) async {
    final ref = await _col.add(p.toMap());
    return ref.id;
  }

  Future<void> update(Product p) => _col.doc(p.id).update(p.toMap());

  Future<void> deactivate(String id) => _col.doc(id).update({'active': false});
}

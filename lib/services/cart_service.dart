import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';

class CartService {
  CartService(this._db, this.userId);
  final FirebaseFirestore _db;
  final String userId;

  DocumentReference get _doc => _db.collection('carts').doc(userId);

  Stream<List<CartItem>> watchCart() => _doc.snapshots().map((snap) {
        if (!snap.exists) return <CartItem>[];
        final data = snap.data() as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>? ?? [])
            .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        return items;
      });

  Future<void> addItem(CartItem item) async {
    final snap = await _doc.get();
    List<CartItem> items = [];
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      items = (data['items'] as List<dynamic>? ?? [])
          .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    final idx = items.indexWhere((e) => e.productId == item.productId);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(qty: items[idx].qty + item.qty);
    } else {
      items.add(item);
    }
    await _doc.set({'items': items.map((e) => e.toMap()).toList()});
  }

  Future<void> updateQty(String productId, int qty) async {
    final snap = await _doc.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final idx = items.indexWhere((e) => e.productId == productId);
    if (idx >= 0) {
      if (qty <= 0) {
        items.removeAt(idx);
      } else {
        items[idx] = items[idx].copyWith(qty: qty);
      }
      await _doc.set({'items': items.map((e) => e.toMap()).toList()});
    }
  }

  Future<void> clear() => _doc.set({'items': []});

  /// Persist a simple shipping address string on the cart document.
  Future<void> setShippingAddress(String address) async {
    final snap = await _doc.get();
    final data = snap.exists ? (snap.data() as Map<String, dynamic>) : <String, dynamic>{};
    data['shippingAddress'] = address;
    await _doc.set(data, SetOptions(merge: true));
  }

  Future<String?> getShippingAddress() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return data['shippingAddress'] as String?;
  }

  /// Persist a selected payment method id/label on the cart document.
  Future<void> setPaymentMethod(String method) async {
    final snap = await _doc.get();
    final data = snap.exists ? (snap.data() as Map<String, dynamic>) : <String, dynamic>{};
    data['paymentMethod'] = method;
    await _doc.set(data, SetOptions(merge: true));
  }

  Future<String?> getPaymentMethod() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return data['paymentMethod'] as String?;
  }
}

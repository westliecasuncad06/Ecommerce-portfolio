import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';

class OrderService {
  OrderService(this._db);
  final FirebaseFirestore _db;

  CollectionReference get _col => _db.collection('orders');

  // Avoid requiring a composite index by not using server-side orderBy here.
  // We fetch the user's orders and sort by createdAt client-side.
  Stream<List<AppOrder>> watchUserOrders(String userId) => _col
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) {
        final docs = s.docs.toList();
        docs.sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>?)?['createdAt'];
          final tb = (b.data() as Map<String, dynamic>?)?['createdAt'];
          final da = ta is Timestamp ? ta.toDate() : DateTime.tryParse(ta?.toString() ?? '') ?? DateTime.now();
          final db = tb is Timestamp ? tb.toDate() : DateTime.tryParse(tb?.toString() ?? '') ?? DateTime.now();
          return db.compareTo(da);
        });
        return docs.map(AppOrder.fromDoc).toList();
      });

  // Same approach for seller orders to avoid composite index requirement.
  Stream<List<AppOrder>> watchSellerOrders(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map((s) {
        final docs = s.docs.toList();
        docs.sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>?)?['createdAt'];
          final tb = (b.data() as Map<String, dynamic>?)?['createdAt'];
          final da = ta is Timestamp ? ta.toDate() : DateTime.tryParse(ta?.toString() ?? '') ?? DateTime.now();
          final db = tb is Timestamp ? tb.toDate() : DateTime.tryParse(tb?.toString() ?? '') ?? DateTime.now();
          return db.compareTo(da);
        });
        return docs.map(AppOrder.fromDoc).toList();
      });

  Stream<AppOrder?> watchOrderById(String orderId) => _col.doc(orderId).snapshots().map((d) {
        if (!d.exists) return null;
        return AppOrder.fromDoc(d);
      });

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _col.doc(orderId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> setTrackingNumber(String orderId, String tracking) async {
    await _col.doc(orderId).update({
      'trackingNumber': tracking,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<String> checkout({
    required String userId,
    required String sellerId,
    required List<CartItem> items,
    required String shippingAddress,
  }) async {
    final total = items.fold<double>(0, (t, e) => t + e.price * e.qty);
    final order = AppOrder(
      id: '',
      userId: userId,
      sellerId: sellerId,
      items: items
          .map((e) => OrderItem(
                productId: e.productId,
                title: e.title,
                price: e.price,
                qty: e.qty,
                imageUrl: e.imageUrl,
              ))
          .toList(),
      total: total,
      status: OrderStatus.paid, // assume paid for MVP
      shippingAddress: shippingAddress,
      createdAt: DateTime.now(),
    );
    final ref = await _col.add(order.toMap());
    return ref.id;
  }
}

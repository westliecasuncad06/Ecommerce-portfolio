import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';

class OrderService {
  OrderService(this._db);
  final FirebaseFirestore _db;

  CollectionReference get _col => _db.collection('orders');

  Stream<List<AppOrder>> watchUserOrders(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppOrder.fromDoc).toList());

  Stream<List<AppOrder>> watchSellerOrders(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppOrder.fromDoc).toList());

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

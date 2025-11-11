import 'package:cloud_firestore/cloud_firestore.dart';

class SellerEarningsService {
  SellerEarningsService(this._db);
  final FirebaseFirestore _db;

  CollectionReference get _orders => _db.collection('orders');

  /// Computes a simple earnings summary for the seller.
  /// totalEarnings: sum of order totals for non-cancelled orders
  /// pendingPayout: placeholder (e.g., orders not yet settled)
  Future<Map<String, dynamic>> fetchSummary(String sellerId) async {
    final q = await _orders.where('sellerId', isEqualTo: sellerId).get();
    double total = 0;
    final transactions = <Map<String, dynamic>>[];
    for (final doc in q.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final status = (d['status'] ?? 'pending') as String;
      final amount = (d['total'] ?? 0).toDouble();
      if (status != 'cancelled') {
        total += amount;
      }
      transactions.add({
        'orderId': doc.id,
        'amount': amount,
        'status': status,
        'date': (d['createdAt'] as Timestamp?)?.toDate(),
      });
    }
    return {
      'totalEarnings': total,
      'pendingPayout': 0.0,
      'transactions': transactions,
    };
  }
}

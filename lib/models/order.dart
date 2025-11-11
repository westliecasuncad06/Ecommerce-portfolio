import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, paid, shipped, delivered, cancelled }

class OrderItem {
  final String productId;
  final String title;
  final double price;
  final int qty;
  final String imageUrl;

  OrderItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.qty,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'price': price,
        'qty': qty,
        'imageUrl': imageUrl,
      };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'],
        title: m['title'],
        price: (m['price'] ?? 0).toDouble(),
        qty: (m['qty'] ?? 0) as int,
        imageUrl: m['imageUrl'] ?? '',
      );
}

class Order {
  final String id;
  final String userId;
  final String sellerId; // simplified single-seller order for MVP
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final String shippingAddress;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.sellerId,
    required this.items,
    required this.total,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'sellerId': sellerId,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'status': status.name,
        'shippingAddress': shippingAddress,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Order.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: d['userId'] ?? '',
      sellerId: d['sellerId'] ?? '',
      items: (d['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      total: (d['total'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      shippingAddress: d['shippingAddress'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

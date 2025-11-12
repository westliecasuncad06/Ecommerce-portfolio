import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final double discount;
  final double finalPrice;
  final int stock;
  final String sku;
  final String category;
  final String subcategory;
  final List<String> tags;
  final List<String> imageUrls;
  final List<Map<String, dynamic>> variants;
  final Map<String, dynamic>? shipping;
  final double ratingAvg;
  final int ratingCount;
  final int views;
  final int sold;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // active, draft, out_of_stock, archived

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    this.discount = 0,
    double? finalPrice,
    required this.stock,
    this.sku = '',
    this.category = '',
    this.subcategory = '',
    this.tags = const [],
    this.imageUrls = const [],
    this.variants = const [],
    this.shipping,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.views = 0,
    this.sold = 0,
    DateTime? createdAt,
    this.updatedAt,
    this.status = 'active',
  })  : finalPrice = finalPrice ?? (price * (1 - (discount / 100))),
        createdAt = createdAt ?? DateTime.now();


  factory Product.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final price = (d['price'] ?? 0).toDouble();
    final discount = (d['discount'] ?? 0).toDouble();
    final finalPrice = (d['finalPrice'] ?? (price * (1 - (discount / 100))))?.toDouble();
    return Product(
      id: doc.id,
      sellerId: d['sellerId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      price: price,
      discount: discount,
      finalPrice: finalPrice,
      stock: (d['stock'] ?? 0) as int,
      sku: d['sku'] ?? '',
      category: d['category'] ?? '',
      subcategory: d['subcategory'] ?? '',
      tags: List<String>.from(d['tags'] ?? const []),
      imageUrls: List<String>.from(d['imageUrls'] ?? const []),
      variants: (d['variants'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
              .toList() ??
          [],
      shipping: d['shipping'] != null ? Map<String, dynamic>.from(d['shipping']) : null,
      ratingAvg: (d['ratingAvg'] ?? 0).toDouble(),
      ratingCount: (d['ratingCount'] ?? 0) as int,
      views: (d['views'] ?? 0) as int,
      sold: (d['sold'] ?? 0) as int,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      status: d['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'title': title,
        'description': description,
        'price': price,
        'discount': discount,
        'finalPrice': finalPrice,
        'stock': stock,
        'sku': sku,
        'category': category,
        'subcategory': subcategory,
        'tags': tags,
        'imageUrls': imageUrls,
        'variants': variants,
        'shipping': shipping,
        'ratingAvg': ratingAvg,
        'ratingCount': ratingCount,
        'views': views,
        'sold': sold,
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    // Keep a lightweight boolean indexable field for active products. The
    // UI queries `.where('active', isEqualTo: true)` so set this to true
    // when the product status is 'active'. This avoids missing newly
    // created products that only had a 'status' string set.
    'active': status == 'active',
    'status': status,
      };
}

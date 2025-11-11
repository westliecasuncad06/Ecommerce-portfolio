class CartItem {
  final String productId;
  final String title;
  final double price;
  final int qty;
  final String imageUrl;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.qty,
    required this.imageUrl,
  });

  CartItem copyWith({int? qty}) => CartItem(
        productId: productId,
        title: title,
        price: price,
        qty: qty ?? this.qty,
        imageUrl: imageUrl,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'price': price,
        'qty': qty,
        'imageUrl': imageUrl,
      };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
        productId: m['productId'],
        title: m['title'],
        price: (m['price'] ?? 0).toDouble(),
        qty: (m['qty'] ?? 0) as int,
        imageUrl: m['imageUrl'] ?? '',
      );
}

class CartItem {
  final int id; // Order ID dari backend
  final int productId;
  final String productName;
  final String imageUrl;
  final double price;
  int quantity;
  String status;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.status = 'pending',
  });

  double get total => price * quantity;

  /// Untuk mengirim order baru ke backend
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'total_price': total,
    };
  }

  /// Untuk parsing dari response GET /api/orders/user/:userId
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      imageUrl: json['image_url'] ?? '',
      price: double.tryParse(json['total_price'].toString()) ?? 0.0,
      quantity: json['quantity'],
      status: json['status'] ?? 'pending',
    );
  }
}

class OrderHistory {
  final int id;
  final int productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  OrderHistory({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      imageUrl: json['image_url'],
      quantity: json['quantity'],
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

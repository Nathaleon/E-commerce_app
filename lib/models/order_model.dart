class Order {
  final int id;
  final int userId;
  final int productId;
  final int quantity;
  final int totalPrice;
  final String status;
  final String? productName;
  final String? imageUrl;

  Order({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    this.productName,
    this.imageUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        userId: json['user_id'],
        productId: json['product_id'],
        quantity: json['quantity'],
        totalPrice: json['total_price'],
        status: json['status'],
        productName: json['product_name'],
        imageUrl: json['image_url'],
      );
}
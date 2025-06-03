class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'total_price': total,
    };
  }
}

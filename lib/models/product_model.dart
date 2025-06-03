class Product {
  final int id;
  final String name;
  final String price;
  final int stock;
  final String description;
  final String category;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        stock: json['stock'],
        description: json['description'],
        category: json['category'],
        imageUrl: json['image_url'],
      );
}

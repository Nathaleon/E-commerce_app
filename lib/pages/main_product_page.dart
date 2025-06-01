import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:projectakhir_mobile/controllers/auth_controller.dart';
import 'package:projectakhir_mobile/models/product_model.dart';
import 'package:projectakhir_mobile/pages/detail_page.dart';
import 'package:projectakhir_mobile/pages/login_page.dart';
import 'package:projectakhir_mobile/services/order_service.dart';
import 'package:projectakhir_mobile/services/product_service.dart';

class MainProductPage extends StatefulWidget {
  final String? token;
  final String? username;
  final String? role;

  const MainProductPage({super.key, this.token, this.username, this.role});

  @override
  State<MainProductPage> createState() => _MainProductPageState();
}

class _MainProductPageState extends State<MainProductPage> {
  late Future<List<Product>> products;
  String? userRole;
  String? selectedCategory;
  @override
  void initState() {
    super.initState();
    products = ProductService.getAllProducts();

    if (widget.role != null) {
      userRole = widget.role;
    } else if (widget.token != null) {
      final decoded = JwtDecoder.decode(widget.token!);
      userRole = decoded['role'];
    }
  }

  Future<void> addToCart(int productId, int price) async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add to cart")),
      );
      return;
    }

    try {
      await OrderService.createOrder({
        'product_id': productId,
        'quantity': 1,
        'total_price': price,
      }, widget.token!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product added to cart")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add to cart: \$e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.token != null;
    print("User Role: $userRole");
    print("Is Logged In: $isLoggedIn");
    print("Username: ${widget.username}");
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Products"),
        actions: [
  if (!isLoggedIn)
    TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
      child: const Text("Login", style: TextStyle(color: Colors.black)),
    ),
  if (isLoggedIn)
    Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(
            child: Text(
              "Hi, ${widget.username}",
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout, color: Colors.black),
          onPressed: () => AuthController.logout(context),
        ),
      ],
    ),
  PopupMenuButton<String>(
    icon: const Icon(Icons.filter_list),
    tooltip: 'Filter berdasarkan kategori',
    onSelected: (value) {
      setState(() {
        selectedCategory = value == '' ? null : value;
      });
    },
    itemBuilder: (context) => const [
      PopupMenuItem(value: '', child: Text('Pilih Kategori')),
      PopupMenuItem(value: 'fashion', child: Text('Fashion')),
      PopupMenuItem(value: 'electronics', child: Text('Elektronika')),
      PopupMenuItem(value: 'furniture', child: Text('Perabotan')),
      PopupMenuItem(value: 'sports', child: Text('Olahraga')),
      PopupMenuItem(value: 'beauty', child: Text('Kecantikan')),
      PopupMenuItem(value: 'health', child: Text('Kesehatan')),
      PopupMenuItem(value: 'children', child: Text('Perlengkapan Anak')),
    ],
  ),
],

      ),
      body: FutureBuilder<List<Product>>(
        future: products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: \${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products found."));
          }

          final items = snapshot.data!;
          final filteredItems =
              selectedCategory == null
                  ? items
                  : items.where((p) => p.category == selectedCategory).toList();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final product = filteredItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(product: product),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            product.imageUrl.isNotEmpty
                                ? product.imageUrl
                                : 'https://th.bing.com/th/id/OIP.FPIFJ6xedtnTAxk0T7AKhwHaF9?rs=1&pid=ImgDetMain',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Rp. ${product.price}"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                  ),
                                  onPressed:
                                      () => addToCart(
                                        product.id,
                                        int.parse(product.price),
                                      ),
                                  tooltip:
                                      isLoggedIn
                                          ? "Add to cart"
                                          : "Login required",
                                ),
                                if (userRole == "admin") ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // TODO: Navigate to edit page
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      // TODO: Handle product deletion
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

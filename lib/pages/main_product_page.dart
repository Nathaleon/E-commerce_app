import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:projectakhir_mobile/controllers/auth_controller.dart';
import 'package:projectakhir_mobile/models/cart_item_model.dart';
import 'package:projectakhir_mobile/models/product_model.dart';
// import 'package:projectakhir_mobile/pages/cart_page.dart';
import 'package:projectakhir_mobile/pages/detail_page.dart';
import 'package:projectakhir_mobile/pages/login_page.dart';
// import 'package:projectakhir_mobile/pages/profile_page.dart';
import 'package:projectakhir_mobile/services/cart_service.dart';
import 'package:projectakhir_mobile/services/product_service.dart';

class MainProductPage extends StatefulWidget {
  final String? token;
  final String? username;
  final String? role;
  final VoidCallback? onCartUpdated; 

  const MainProductPage({super.key, this.token, this.username, this.role, this.onCartUpdated});

  @override
  State<MainProductPage> createState() => _MainProductPageState();
}

class _MainProductPageState extends State<MainProductPage> {
  late Future<List<Product>> products;
  String? userRole;
  String? selectedCategory;
  String searchQuery = '';
  String sortBy = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    products = ProductService.getAllProducts();
    CartService.loadCart();

    if (widget.role != null) {
      userRole = widget.role;
    } else if (widget.token != null) {
      final decoded = JwtDecoder.decode(widget.token!);
      userRole = decoded['role'];
      print('User Role: $userRole');
    }
  }

  void _applyFilters(List<Product> items) {
    if (searchQuery.isNotEmpty) {
      items.retainWhere(
        (product) =>
            product.name.toLowerCase().contains(searchQuery.toLowerCase()),
      );
    }

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      items.retainWhere((product) => product.category == selectedCategory);
    }

    switch (sortBy) {
      case 'price_asc':
        items.sort(
          (a, b) => double.parse(a.price).compareTo(double.parse(b.price)),
        );
        break;
      case 'price_desc':
        items.sort(
          (a, b) => double.parse(b.price).compareTo(double.parse(a.price)),
        );
        break;
    }
  }

  void addToCart(Product product) async {
  if (widget.token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please login to add to cart")),
    );
    return;
  }

  final cartItem = CartItem(
    id: DateTime.now().millisecondsSinceEpoch,
    productId: product.id,
    productName: product.name,
    imageUrl: product.imageUrl,
    price: double.parse(product.price),
    quantity: product.stock > 0 ? 1 : 0, // Set quantity to 1 if stock is available
  );

  await CartService.addToCart(cartItem);

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product added to cart")),
    );
  }

  widget.onCartUpdated?.call(); 
}

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.token != null;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/Logo2.png',
          height: 40,
        ),
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
          Text(
            widget.username ?? 'User',
            style: const TextStyle(color: Colors.black),
          ),
          //logout
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButton<String>(
                    value: selectedCategory,
                    hint:
                        const Text('Category', style: TextStyle(fontSize: 12)),
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Categories',
                            style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'fashion',
                        child: Text('Fashion', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'electronics',
                        child:
                            Text('Electronics', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'furniture',
                        child:
                            Text('Furniture', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'sports',
                        child: Text('Sports', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'beauty',
                        child: Text('Beauty', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'health',
                        child: Text('Health', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'children',
                        child: Text('Children', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: sortBy,
                    hint: const Text('Sort by', style: TextStyle(fontSize: 12)),
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    items: const [
                      DropdownMenuItem(
                        value: '',
                        child: Text('Default', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('Price: Low to High',
                            style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Price: High to Low',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        sortBy = value ?? '';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No products found."));
                }

                final items = List<Product>.from(snapshot.data!);
                _applyFilters(items);

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailPage(product: product,onCartUpdated: widget.onCartUpdated,token: widget.token
                                  ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
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
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rp ${product.price}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () => addToCart(product),
                                          child: const Icon(
                                            Icons.shopping_cart_outlined,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                        ),
                                        if (userRole == "admin") ...[
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              // TODO: Navigate to edit page
                                            },
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              // TODO: Handle product deletion
                                            },
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }
}

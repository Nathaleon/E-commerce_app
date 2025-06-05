import 'package:flutter/material.dart';
import 'package:projectakhir_mobile/models/cart_item_model.dart';
import 'package:projectakhir_mobile/models/product_model.dart';
import 'package:projectakhir_mobile/pages/detail_page.dart';
import 'package:projectakhir_mobile/pages/edit_product_page.dart';
import 'package:projectakhir_mobile/pages/login_page.dart';
import 'package:projectakhir_mobile/services/cart_service.dart';
import 'package:projectakhir_mobile/services/product_service.dart';

class MainProductPage extends StatefulWidget {
  final String? token;
  final String? username;
  final String? role;
  final VoidCallback? onCartUpdated;
  final VoidCallback onProductAdded;

  const MainProductPage(
      {super.key,
      this.token,
      this.username,
      this.role,
      this.onCartUpdated,
      required this.onProductAdded});

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
    print('Loading products... $products');
    //loop the products

    if (widget.role != null) {
      userRole = widget.role;
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

  void deleteProduct(int productId) async {
    try {
      bool success =
          await ProductService.deleteProduct(productId, widget.token!);
      if (success) {
        setState(() {
          products = ProductService.getAllProducts(); // Refresh product list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete product: $e")),
      );
    }
  }

  void addToCart(Product product) async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to add to cart"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: product.id,
        productName: product.name,
        imageUrl: product.imageUrl,
        price: double.parse(product.price),
        quantity: 1, // Always start with quantity 1
      );

      await CartService.addToCart(cartItem, widget.token!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product added to cart"),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCartUpdated?.call();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.token != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/Logo.png',
              height: 60,
              fit: BoxFit.contain,
            ),
            if (isLoggedIn) ...[
              const SizedBox(width: 12),
              Text(
                'Welcome, ${widget.username ?? 'User'}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
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
                        value: 'health',
                        child: Text('Health', style: TextStyle(fontSize: 12)),
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
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  products = ProductService.getAllProducts();
                });
              },
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final product = items[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(
                                  product: product,
                                  onCartUpdated: widget.onCartUpdated,
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${product.price}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (widget.role == 'admin') ...[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () {
                                              //go to edit product page
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        EditProductPage(
                                                      productId: product.id,
                                                      name: product.name,
                                                      price: product.price,
                                                      stock: product.stock
                                                          .toString(),
                                                      description:
                                                          product.description,
                                                      category:
                                                          product.category,
                                                      imageUrl:
                                                          product.imageUrl,
                                                      token: widget.token,
                                                    ),
                                                  ));
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              deleteProduct(product
                                                  .id); // Call delete method
                                            },
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      // Add to Cart Button for non-admin
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: () => addToCart(product),
                                          icon: const Icon(Icons.shopping_cart,
                                              color: Colors.green),
                                          label: const Text(
                                            'Add to Cart',
                                            style:
                                                TextStyle(color: Colors.green),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                          ),
                                        ),
                                      ),
                                    ]
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
            ),
          ),
        ],
      ),
    );
  }
}

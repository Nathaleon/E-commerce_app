import 'package:flutter/material.dart';
import 'package:projectakhir_mobile/models/cart_item_model.dart';
import 'package:projectakhir_mobile/services/cart_service.dart';

class CartPage extends StatefulWidget {
  final String? token;
  final VoidCallback? onCheckoutDone;

  const CartPage({super.key, this.token, this.onCheckoutDone});

  @override
  State<CartPage> createState() => _CartPageState();
}

class CartPage extends StatefulWidget {
  final String? token;
  final VoidCallback? onCheckoutDone;

  const CartPage({super.key, this.token, this.onCheckoutDone});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = true;
 Set<int> selectedProductIds = {};
  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => isLoading = true);
    await CartService.loadCart();
    setState(() => isLoading = false);
  }

  Future<void> _updateQuantity(CartItem item, int delta) async {
    await CartService.updateQuantity(item.productId, item.quantity + delta);
    setState(() {});
  }

  double get selectedTotal {
    return CartService.items
        .where((item) => selectedProductIds.contains(item.productId))
        .fold(0.0, (sum, item) => sum + item.total);
  }
Future<void> _checkout() async {
    try {
      final selectedItems = CartService.items
          .where((item) => selectedProductIds.contains(item.productId))
          .toList();

      if (selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select items to checkout')),
        );
        return;
      }

      for (var item in selectedItems) {
        await OrderService.createOrder({
          'product_id': item.productId,
          'product_name': item.productName,
          'image_url': item.imageUrl,
          'quantity': item.quantity,
          'total_price': item.total,
        }, widget.token!);
      }

      for (var item in selectedItems) {
        await CartService.removeFromCart(item.productId);
      }

      setState(() {
        selectedProductIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout successful!')),
        );
        widget.onCheckoutDone?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    await CartService.clearCart();
    setState(() {
      selectedProductIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;
    // final total = CartService.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: const Text(
                'Clear Cart',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = selectedProductIds.contains(item.productId);
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedProductIds.add(item.productId);
                                  } else {
                                    selectedProductIds.remove(item.productId);
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Image.network(
                                item.imageUrl.isNotEmpty
                                    ? item.imageUrl
                                    : 'https://th.bing.com/th/id/OIP.FPIFJ6xedtnTAxk0T7AKhwHaF9?rs=1&pid=ImgDetMain',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rp ${item.price}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _updateQuantity(item, -1),
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _updateQuantity(item, 1),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await CartService.removeFromCart(item.productId);
                                setState(() {
                                  selectedProductIds.remove(item.productId);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selected Total:', style: TextStyle(fontSize: 16)),
                      Text(
                        'Rp ${selectedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _checkout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Checkout', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }
}

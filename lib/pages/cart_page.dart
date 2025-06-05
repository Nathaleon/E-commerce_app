import 'package:flutter/material.dart';
import 'package:projectakhir_mobile/models/cart_item_model.dart';
import 'package:projectakhir_mobile/services/cart_service.dart';

class CartPage extends StatefulWidget {
  final String? token;
  final VoidCallback? onCheckoutDone;

  const CartPage({super.key, this.token, this.onCheckoutDone});

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  bool isLoading = true;
  Set<int> selectedOrderIds = {};
  List<CartItem> items = [];

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  @override
  void didUpdateWidget(covariant CartPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token) {
      loadCart();
    }
  }

  Future<void> loadCart() async {
    setState(() => isLoading = true);
    try {
      items = await CartService.getCartItems(widget.token!);
      selectedOrderIds.clear();
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to view products")),
        );
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> _updateQuantity(CartItem item, int delta) async {
    final newQuantity = item.quantity + delta;

    try {
      if (newQuantity <= 0) {
        await CartService.deleteOrder(item.id, widget.token!);
        setState(() {
          items.removeWhere((e) => e.id == item.id);
          selectedOrderIds.remove(item.id);
        });
      } else {
        // final totalPrice = item.price * newQuantity;
        await CartService.updateQuantity(
            item.id, newQuantity, widget.token!, item.price);
        setState(() {
          item.quantity = newQuantity;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update cart: $e")),
        );
      }
    }
  }

  double get selectedTotal {
    return items
        .where((item) => selectedOrderIds.contains(item.id))
        .fold(0.0, (sum, item) => sum + item.total);
  }

  Future<void> _checkout() async {
    try {
      final selectedIds = selectedOrderIds.toList();

      if (selectedIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select items to checkout')),
        );
        return;
      }

      await CartService.checkoutOrders(selectedIds, widget.token!);
      await loadCart();

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
    await CartService.clearCart(widget.token!);
    setState(() {
      selectedOrderIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/emptycart.png',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = selectedOrderIds.contains(item.id);
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
                                    selectedOrderIds.add(item.id);
                                  } else {
                                    selectedOrderIds.remove(item.id);
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
                                    onPressed: () async {
                                      await _updateQuantity(item, -1);
                                    }),
                                Text('${item.quantity}',
                                    style: const TextStyle(fontSize: 16)),
                                IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () async {
                                      await _updateQuantity(item, 1);
                                    }),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await CartService.deleteOrder(
                                    item.id, widget.token!);
                                await loadCart();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: items.isEmpty || selectedOrderIds.isEmpty
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
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Rp ${selectedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:projectakhir_mobile/secrets/user_secrets.dart';
import 'package:projectakhir_mobile/models/cart_item_model.dart';

class CartService {
  static final List<CartItem> _items = [];
  static const String _cartKey = 'shopping_cart';

  static List<CartItem> get items => _items;

  static double get total => _items.fold(0, (sum, item) => sum + item.total);

  // Load cart items from SharedPreferences
  static Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString(_cartKey);
    if (cartJson != null) {
      final List<dynamic> decodedList = json.decode(cartJson);
      _items.clear();
      _items.addAll(
        decodedList.map(
          (item) => CartItem(
            id: item['id'],
            productId: item['product_id'],
            productName: item['product_name'],
            imageUrl: item['image_url'],
            price: item['price'].toDouble(),
            quantity: item['quantity'],
          ),
        ),
      );
    }
  }

  // Save cart items to SharedPreferences
  static Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> cartList = _items
        .map(
          (item) => {
            'id': item.id,
            'product_id': item.productId,
            'product_name': item.productName,
            'image_url': item.imageUrl,
            'price': item.price,
            'quantity': item.quantity,
          },
        )
        .toList();
    await prefs.setString(_cartKey, json.encode(cartList));

    // Notify listeners if using a state management solution
    await loadCart();
  }

  static Future<void> addToCart(CartItem item) async {
    final existingItem = _items.firstWhere(
      (element) => element.productId == item.productId,
      orElse: () => item,
    );

    if (!_items.contains(existingItem)) {
      _items.add(existingItem);
    } else {
      existingItem.quantity++;
    }
    await _saveCart();
  }

  static Future<void> removeFromCart(int productId) async {
    _items.removeWhere((item) => item.productId == productId);
    await _saveCart();
  }

  static Future<void> updateQuantity(int productId, int quantity) async {
    final item = _items.firstWhere((item) => item.productId == productId);
    item.quantity = quantity;
    if (quantity <= 0) {
      await removeFromCart(productId);
    } else {
      await _saveCart();
    }
  }

  static Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
  }
}

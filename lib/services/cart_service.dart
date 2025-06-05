import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:projectakhir_mobile/models/cart_item_model.dart';
import 'package:projectakhir_mobile/secrets/user_secrets.dart';
import 'package:projectakhir_mobile/services/order_service.dart';
import 'package:projectakhir_mobile/services/product_service.dart';

class CartService {
  static const String baseUrl = secretBaseUrl;

  static Future<List<CartItem>> getCartItems(String token) async {
    print('token di service: $token');
    if (token.isEmpty) {
      throw Exception('Token is empty');
    }
    final userId = JwtDecoder.decode(token)['id'];
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Data dari service: $data');
      return data
          .where((item) => item['status'] == 'pending')
          .map((item) => CartItem.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load cart');
    }
  }

  static Future<void> addToCart(CartItem item, String token) async {
    try {
      final currentStock = await ProductService.getProductStock(item.productId);

      if (currentStock <= 0) {
        throw 'Product is out of stock';
      }

      final existingItems = await getCartItems(token);
      final existingItem = existingItems
          .where((i) => i.productId == item.productId && i.status == 'pending')
          .firstOrNull;

      if (existingItem != null) {
        final newQuantity = existingItem.quantity + item.quantity;

        if (newQuantity > currentStock) {
          throw 'Requested quantity exceeds available stock ($currentStock)';
        }

        await updateQuantity(existingItem.id, newQuantity, token,
            existingItem.price * newQuantity);
        return;
      }

      if (item.quantity > currentStock) {
        throw 'Requested quantity exceeds available stock ($currentStock)';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': item.productId,
          'quantity': item.quantity,
          'total_price': item.total,
        }),
      );

      if (response.statusCode != 201) {
        String message = 'Failed to add to cart';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody['message'] != null) {
            message = errorBody['message'];
          }
        } catch (_) {}
        throw message;
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      throw message;
    }
  }

  static Future<void> updateQuantity(
      int orderId, int quantity, String token, double totalPrice) async {
    try {
      final items = await getCartItems(token);
      final item = items.firstWhere((i) => i.id == orderId);

      final currentStock = await ProductService.getProductStock(item.productId);
      if (quantity > currentStock) {
        throw 'Requested quantity exceeds available stock ($currentStock)';
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'quantity': quantity,
          'total_price': totalPrice,
        }),
      );

      if (response.statusCode != 200) {
        throw 'Failed to update quantity';
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      throw message;
    }
  }

  static Future<void> deleteOrder(int orderId, String token) async {
    await http.delete(
      Uri.parse('$baseUrl/api/orders/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> checkoutOrders(List<int> orderIds, String token) async {
    try {
      final items = await getCartItems(token);
      final checkoutItems =
          items.where((item) => orderIds.contains(item.id)).toList();

      if (checkoutItems.isEmpty) {
        throw 'No items found for checkout';
      }
      for (final item in checkoutItems) {
        final currentStock =
            await ProductService.getProductStock(item.productId);
        if (currentStock < item.quantity) {
          throw 'Insufficient stock for product: ${item.productName}. Available: $currentStock, Requested: ${item.quantity}';
        }
      }

      for (final item in checkoutItems) {
        final response = await http.put(
          Uri.parse('$baseUrl/api/orders/checkout/${item.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );

        if (response.statusCode != 200) {
          throw 'Failed to checkout order: ${item.productName}';
        }

        await OrderService.createOrder({
          'product_id': item.productId,
          'product_name': item.productName,
          'image_url': item.imageUrl,
          'quantity': item.quantity,
          'total_price': item.total,
        }, token);
      }
    } catch (e) {
      print('Error during checkout: $e');
      throw 'Failed to checkout orders: $e';
    }
  }

  static Future<void> clearCart(String token) async {
    final items = await getCartItems(token);
    for (final item in items) {
      await deleteOrder(item.id, token);
    }
  }
}

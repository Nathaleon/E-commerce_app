import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:projectakhir_mobile/models/cart_item_model.dart';
import 'package:projectakhir_mobile/secrets/user_secrets.dart';

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
    await http.post(
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
  }

  static Future<void> updateQuantity(
      int orderId, int quantity, String token, double totalPrice) async {
    await http.put(
      Uri.parse('$baseUrl/api/orders/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'quantity': quantity, 'total_price':totalPrice}),
    );
  }

  static Future<void> deleteOrder(int orderId, String token) async {
    await http.delete(
      Uri.parse('$baseUrl/api/orders/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> checkoutOrders(List<int> orderIds, String token) async {
    for (final id in orderIds) {
      await http.put(
        Uri.parse('$baseUrl/api/orders/checkout/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }
  }

  static Future<void> clearCart(String token) async {
    final items = await getCartItems(token);
    for (final item in items) {
      await deleteOrder(item.id, token);
    }
  }
}

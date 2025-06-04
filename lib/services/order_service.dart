import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projectakhir_mobile/models/order_model.dart';
import 'package:projectakhir_mobile/secrets/user_secrets.dart';
import 'package:projectakhir_mobile/models/order_history_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class OrderService {
  static const String baseUrl = secretBaseUrl;
  static const String _orderHistoryKeyPrefix = 'order_history_';

  // Helper method to get user-specific storage key
  static String _getUserOrderHistoryKey(String token) {
    final userId = JwtDecoder.decode(token)['id'];
    return '${_orderHistoryKeyPrefix}$userId';
  }

  static Future<List<Order>> getOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<Order> getOrderById(int id, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get order');
    }
  }

  static Future<void> createOrder(
    Map<String, dynamic> orderData,
    String token,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _getUserOrderHistoryKey(token);
      final String? historyJson = prefs.getString(storageKey);
      List<Map<String, dynamic>> orders = [];

      if (historyJson != null) {
        orders = List<Map<String, dynamic>>.from(json.decode(historyJson));
      }

      final newOrder = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'product_id': orderData['product_id'],
        'product_name': orderData['product_name'] ?? 'Unknown Product',
        'image_url': orderData['image_url'] ?? '',
        'quantity': orderData['quantity'],
        'total_price': orderData['total_price'],
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      };

      orders.add(newOrder);
      await prefs.setString(storageKey, json.encode(orders));
    } catch (e) {
      print('Error creating order history: $e');
      throw Exception('Failed to create order history: $e');
    }
  }

  static Future<void> updateOrder(
    int id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order');
    }
  }

  static Future<void> deleteOrder(int orderId, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _getUserOrderHistoryKey(token);
      final String? historyJson = prefs.getString(storageKey);

      if (historyJson != null) {
        List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
          json.decode(historyJson),
        );
        orders.removeWhere((order) => order['id'] == orderId);
        await prefs.setString(storageKey, json.encode(orders));
      }
    } catch (e) {
      print('Error deleting order: $e');
      throw Exception('Failed to delete order: $e');
    }
  }

  static Future<List<Order>> getOrdersByUserId(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user orders');
    }
  }

  static Future<List<Order>> getCheckedOutOrdersByUserId(
    int userId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/user/$userId/checkedout'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load checked out orders');
    }
  }

  static Future<void> checkoutAllOrders(String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/checkout'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to checkout orders');
    }
  }

  static Future<void> checkoutOrderById(int id, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/checkout/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to checkout order');
    }
  }

  static Future<List<OrderHistory>> getOrderHistory(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _getUserOrderHistoryKey(token);
      final String? historyJson = prefs.getString(storageKey);

      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(historyJson);
        return decodedList
            .map((item) => OrderHistory(
                  id: item['id'],
                  productId: item['product_id'],
                  productName: item['product_name'],
                  imageUrl: item['image_url'] ?? '',
                  quantity: item['quantity'],
                  totalPrice: double.parse(item['total_price'].toString()),
                  status: item['status'],
                  createdAt: DateTime.parse(item['created_at']),
                ))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting order history: $e');
      return [];
    }
  }

  static Future<void> clearAllOrders(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _getUserOrderHistoryKey(token);
      await prefs.remove(storageKey);
    } catch (e) {
      print('Error clearing orders: $e');
      throw Exception('Failed to clear orders: $e');
    }
  }
}

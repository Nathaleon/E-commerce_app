import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projectakhir_mobile/models/order_model.dart';
import 'package:projectakhir_mobile/secrets/user_secrets.dart';

class OrderService {
  static Future<List<Order>> getOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final List list = jsonDecode(response.body);
    return list.map((e) => Order.fromJson(e)).toList();
  }

  static Future<Order> getOrderById(int id, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return Order.fromJson(jsonDecode(response.body));
  }

  static Future<http.Response> createOrder(Map<String, dynamic> data, String token) async {
    return await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> updateOrder(int id, Map<String, dynamic> data, String token) async {
    return await http.put(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> deleteOrder(int id, String token) async {
    return await http.delete(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<List<Order>> getOrdersByUserId(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final List list = jsonDecode(response.body);
    return list.map((e) => Order.fromJson(e)).toList();
  }

  static Future<List<Order>> getCheckedOutOrdersByUserId(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/user/$userId/checkedout'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final List list = jsonDecode(response.body);
    return list.map((e) => Order.fromJson(e)).toList();
  }

  static Future<http.Response> checkoutAllOrders(String token) async {
    return await http.put(
      Uri.parse('$baseUrl/orders/checkout'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> checkoutOrderById(int id, String token) async {
    return await http.put(
      Uri.parse('$baseUrl/orders/checkout/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
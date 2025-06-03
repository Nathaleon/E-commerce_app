import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:projectakhir_mobile/models/product_model.dart';
import 'package:projectakhir_mobile/secrets/user_secrets.dart';

class ProductService {
  static Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/products/'));
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<Product> getProductById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/products/$id'));
    return Product.fromJson(jsonDecode(response.body));
  }

  static Future<bool> createProduct(
    Map<String, String> productData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(productData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to create product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  static Future<bool> updateProduct(
    int id,
    Map<String, dynamic> productData,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(productData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<bool> deleteProduct(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}

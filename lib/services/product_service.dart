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

  static Future<http.StreamedResponse> createProduct(
    Map<String, String> fields,
    File imageFile,
    String token,
  ) async {
    final uri = Uri.parse('$baseUrl/products/add');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    return await request.send();
  }

  static Future<http.StreamedResponse> updateProduct(
    int id,
    Map<String, String> fields,
    File? imageFile,
    String token,
  ) async {
    final uri = Uri.parse('$baseUrl/products/$id');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }
    return await request.send();
  }

  static Future<http.Response> deleteProduct(int id, String token) async {
    return await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

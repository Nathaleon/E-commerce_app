import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:projectakhir_mobile/models/product_model.dart';
import 'package:projectakhir_mobile/secrets/user_secrets.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ProductService {
  static const String baseUrl = secretBaseUrl;

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
    File imageFile, // The image file passed from the UI
  ) async {
    try {
      print('$baseUrl/api/products/add');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '$baseUrl/api/products/add'), // Replace with your API endpoint
      );

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Authorization': 'Bearer $token',
      });

      // Add product data fields
      request.fields['name'] = productData['name']!;
      request.fields['price'] = productData['price']!;
      request.fields['stock'] = productData['stock']!;
      request.fields['description'] = productData['description']!;
      request.fields['category'] = productData['category']!;

      // Add image file as part of multipart
      String mimeType =
          lookupMimeType(imageFile.path) ?? 'image/jpeg'; // Ensure mime type
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // The field name in the backend API
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send request
      final response = await request.send();

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception(response.statusCode);
      }
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  static Future<bool> updateProduct(
      int id, Map<String, dynamic> productData, String token,
      {File? imageFile}) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/products/$id'),
      );

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Authorization': 'Bearer $token',
      });

      // Add product data fields
      request.fields['name'] = productData['name'];
      request.fields['price'] = productData['price'];
      request.fields['stock'] = productData['stock'];
      request.fields['description'] = productData['description'];
      request.fields['category'] = productData['category'];

      // Add image file if provided
      if (imageFile != null) {
        String mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // The field name in the backend API
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      // Send the request
      final response = await request.send();

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

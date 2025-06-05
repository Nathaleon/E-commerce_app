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
    File imageFile,
  ) async {
    try {
      print('$baseUrl/api/products/add');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/products/add'),
      );

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Authorization': 'Bearer $token',
      });

      request.fields['name'] = productData['name']!;
      request.fields['price'] = productData['price']!;
      request.fields['stock'] = productData['stock']!;
      request.fields['description'] = productData['description']!;
      request.fields['category'] = productData['category']!;

      String mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

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

      request.fields['name'] = productData['name'];
      request.fields['price'] = productData['price'];
      request.fields['stock'] = productData['stock'];
      request.fields['description'] = productData['description'];
      request.fields['category'] = productData['category'];

      if (imageFile != null) {
        String mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

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

  static Future<bool> updateStock(
      int productId, int newStock, String token) async {
    try {
      if (newStock < 0) {
        throw Exception('Stock cannot be negative');
      }

      // Get current product first to preserve other fields
      final currentProduct = await getProductById(productId);

      final response = await http.put(
        Uri.parse('$baseUrl/api/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': currentProduct.name,
          'price': currentProduct.price,
          'stock': newStock,
          'description': currentProduct.description,
          'category': currentProduct.category,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        String errorMessage = 'Failed to update stock';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(
            'Stock update failed: $errorMessage (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error updating stock: $e');
      throw Exception('Failed to update stock: $e');
    }
  }

  static Future<int> getProductStock(int productId) async {
    try {
      final product = await getProductById(productId);
      return product.stock;
    } catch (e) {
      throw Exception('Failed to get product stock: $e');
    }
  }
}

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
    // Check stock availability first
    try {
      final currentStock = await ProductService.getProductStock(item.productId);

      // Stock validations
      if (currentStock <= 0) {
        throw 'Product is out of stock';
      }

      if (item.quantity <= 0) {
        throw 'Invalid quantity selected';
      }

      if (item.quantity > currentStock) {
        throw 'Requested quantity (${item.quantity}) exceeds available stock ($currentStock)';
      }

      // Add to cart
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
      // Convert any error to a simple string message
      final message = e.toString().replaceAll('Exception: ', '');
      throw message;
    }
  }

  static Future<void> updateQuantity(
      int orderId, int quantity, String token, double totalPrice) async {
    try {
      // Get the cart item first to get the product ID
      final items = await getCartItems(token);
      final item = items.firstWhere((i) => i.id == orderId);

      // Check stock availability
      final currentStock = await ProductService.getProductStock(item.productId);
      if (quantity > currentStock) {
        throw Exception(
            'Requested quantity exceeds available stock ($currentStock)');
      }

      await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'quantity': quantity, 'total_price': totalPrice}),
      );
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
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
      // First get the cart items that are being checked out
      final items = await getCartItems(token);
      final checkoutItems =
          items.where((item) => orderIds.contains(item.id)).toList();

      if (checkoutItems.isEmpty) {
        throw Exception('No items found for checkout');
      }

      // Check stock availability for all items first
      for (final item in checkoutItems) {
        final currentStock =
            await ProductService.getProductStock(item.productId);
        if (currentStock < item.quantity) {
          throw Exception(
              'Insufficient stock for product: ${item.productName}. Available: $currentStock, Requested: ${item.quantity}');
        }
      }

      // Store successful updates to handle rollback if needed
      final List<Map<String, dynamic>> successfulUpdates = [];

      try {
        // If all stocks are available, proceed with checkout and stock updates
        for (final item in checkoutItems) {
          // Get current stock
          final currentStock =
              await ProductService.getProductStock(item.productId);

          // Update stock in database
          final success = await ProductService.updateStock(
            item.productId,
            currentStock - item.quantity,
            token,
          );

          if (!success) {
            throw Exception(
                'Failed to update stock for product: ${item.productName}');
          }

          // Store successful update for potential rollback
          successfulUpdates.add({
            'productId': item.productId,
            'originalStock': currentStock,
            'newStock': currentStock - item.quantity
          });

          // Checkout the order
          final response = await http.put(
            Uri.parse('$baseUrl/api/orders/checkout/${item.id}'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (response.statusCode != 200) {
            throw Exception('Failed to checkout order: ${item.productName}');
          }

          // Add to order history
          await OrderService.createOrder({
            'product_id': item.productId,
            'product_name': item.productName,
            'image_url': item.imageUrl,
            'quantity': item.quantity,
            'total_price': item.total,
          }, token);
        }
      } catch (e) {
        // If any operation fails, try to rollback stock updates
        print('Error during checkout process: $e');
        for (final update in successfulUpdates) {
          try {
            await ProductService.updateStock(
              update['productId'],
              update['originalStock'],
              token,
            );
          } catch (rollbackError) {
            print('Failed to rollback stock update: $rollbackError');
          }
        }
        throw Exception('Checkout failed: $e');
      }
    } catch (e) {
      print('Error during checkout: $e');
      throw Exception('Failed to checkout orders: $e');
    }
  }

  static Future<void> clearCart(String token) async {
    final items = await getCartItems(token);
    for (final item in items) {
      await deleteOrder(item.id, token);
    }
  }
}

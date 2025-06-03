import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projectakhir_mobile/models/user_model.dart';
import 'package:projectakhir_mobile/secrets/user_secrets.dart';

class UserService {
  static const String baseUrl = secretBaseUrl;
  static Future<http.Response> register(Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse('$baseUrl/api/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  static Future<AuthResponse> login(String username, String password) async {
    print('Logging in with username: $username');
    print('Logging in with password: $password');
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Login failed');
    }
  }

  static Future<User> getUserById(int id, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return User.fromJson(jsonDecode(response.body));
  }

  static Future<http.Response> updateUser(
    int id,
    Map<String, dynamic> data,
    String token,
  ) async {
    return await http.put(
      Uri.parse('$baseUrl/api/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> deleteUser(int id, String token) async {
    return await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

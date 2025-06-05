import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:projectakhir_mobile/pages/login_page.dart';
import 'package:projectakhir_mobile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  /// Login
  static Future<void> login({
    required BuildContext context,
    required String username,
    required String password,
    required void Function(bool) setLoading,
    required void Function(String token, String username, String role)
        onSuccess,
  }) async {
    setLoading(true);
    try {
      final response = await UserService.login(username, password);
      final token = response.token;
      print('Login successful, token: $token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('username', username);
      await prefs.setString('password', password);

      final decoded = JwtDecoder.decode(token);
      final role = decoded['role'];
      await prefs.setString('role', role);
      onSuccess(token, username, role);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      setLoading(false);
    }
  }

  /// Register
  static Future<void> register({
    required BuildContext context,
    required String username,
    required String password,
    required String email,
    required void Function(bool) setLoading,
    required void Function() onSuccess,
  }) async {
    setLoading(true);
    try {
      final response = await UserService.register({
        "username": username,
        "email": email,
        "password": password,
        "role": "customer",
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        onSuccess();
      } else {
        final error =
            response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Register failed: $error');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Register failed: $e')));
    } finally {
      setLoading(false);
    }
  }

  /// Logout
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('username');
    await prefs.remove('role');
    await prefs.remove('password');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

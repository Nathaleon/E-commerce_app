import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:projectakhir_mobile/pages/base_page.dart';
import 'package:projectakhir_mobile/pages/login_page.dart';
import 'package:projectakhir_mobile/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  print('Token: $token');
  final username = prefs.getString('username');
  final password = prefs.getString('password');
  String? role;

  if (token != null) {
    final decoded = JwtDecoder.decode(token);
    role = decoded['role'];
  }

  runApp(
      MyApp(token: token, username: username, role: role, password: password));
}

class MyApp extends StatelessWidget {
  final String? token;
  final String? username;
  final String? role;
  final String? password;

  const MyApp({super.key, this.token, this.username, this.role, this.password});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-commerce',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const BasePage(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

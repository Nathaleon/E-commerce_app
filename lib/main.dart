import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectakhir_mobile/pages/base_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  final username = prefs.getString('username');
  final password = prefs.getString('password');
  final role = prefs.getString('role');
  print('Token  darri main: $token');
  print('Username  darri main: $username');
  print('Password  darri main: $password');
  print('Role darri main: $role');
  runApp(MyApp(token: token, username: username, password: password, role: role));
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
      home: BasePage(
        token: token,
        username: username,
        password: password,
        role:role
      ),
    );
  }
}

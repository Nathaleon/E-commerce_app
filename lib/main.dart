import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/main_product_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  final username = prefs.getString('username');

  runApp(MyApp(token: token, username: username));
}

class MyApp extends StatelessWidget {
  final String? token;
  final String? username;

  const MyApp({super.key, this.token, this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce Flutter',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,
      home: (token != null && username != null)
          ? MainProductPage(token: token!, username: username!)
          : const MainProductPage(token: null, username: null),
    );
  }
}

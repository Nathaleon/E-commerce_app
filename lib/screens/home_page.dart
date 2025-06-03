import 'package:flutter/material.dart';
import 'package:projectakhir_mobile/pages/main_product_page.dart';

class HomePage extends StatelessWidget {
  final String? token;
  final String? username;

  const HomePage({super.key, this.token, this.username});

  @override
  Widget build(BuildContext context) {
    return MainProductPage(token: token, username: username);
  }
}

import 'package:flutter/material.dart';
import 'package:projectakhir_mobile/pages/main_product_page.dart';
import 'package:projectakhir_mobile/pages/cart_page.dart';
import 'package:projectakhir_mobile/pages/profile_page.dart';
import 'package:projectakhir_mobile/pages/add_product_page.dart';

class BasePage extends StatefulWidget {
  final String? token;
  final String? username;
  final String? role;
  final String? password;

  const BasePage({
    super.key,
    this.token,
    this.username,
    this.role,
    this.password,
  });

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _selectedIndex = 0;

  final GlobalKey<ProfilePageState> _profileKey = GlobalKey<ProfilePageState>();

  void _onCheckoutSuccess() {
    setState(() {
      _selectedIndex = 3; // pindah ke Profile tab
    });

    // ⏳ beri delay kecil agar profil benar-benar aktif dulu
    Future.delayed(const Duration(milliseconds: 100), () {
      _profileKey.currentState?.refreshOrderHistory();
    });
  }

  void _onCartUpdated() {
    setState(() {}); // Trigger rebuild, CartService sudah global
  }

  List<Widget> _buildPages() => [
        MainProductPage(
          token: widget.token,
          username: widget.username,
          role: widget.role,
          onCartUpdated: _onCartUpdated,
        ),
        CartPage(
          token: widget.token,
          onCheckoutDone: _onCheckoutSuccess,
        ),
        AddProductPage(token: widget.token),
        ProfilePage(
          token: widget.token,
          username: widget.username,
          password: widget.password,
          key: _profileKey,
        ),
      ];

  void _onItemTapped(int index) {
    if (!mounted) return;

    if (widget.role != 'admin' && index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only admin can access this feature")),
      );
      return;
    }

    if (widget.token == null && index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(); // Rebuild all pages as needed

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle), label: 'Add Product'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

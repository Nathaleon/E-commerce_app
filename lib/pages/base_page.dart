import 'package:flutter/material.dart';
import 'package:projectakhir_mobile/pages/main_product_page.dart';
import 'package:projectakhir_mobile/pages/cart_page.dart';
import 'package:projectakhir_mobile/pages/profile_page.dart';
import 'package:projectakhir_mobile/pages/add_product_page.dart';

class BasePage extends StatefulWidget {
  final String? token;
  final String? username;
  final String? role;

  const BasePage({
    super.key,
    this.token,
    this.username,
    this.role,
  });

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      MainProductPage(
        token: widget.token,
        username: widget.username,
        role: widget.role,
      ),
      CartPage(token: widget.token),
      AddProductPage(token: widget.token),
      ProfilePage(
        token: widget.token,
        username: widget.username,
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (!mounted) return;

    // Jika user bukan admin dan mencoba mengakses Add Product
    if (widget.role != 'admin' && index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only admin can access this feature")),
      );
      return;
    }

    // Jika belum login dan mencoba mengakses fitur selain Home
    if (widget.token == null && index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:projectakhir_mobile/controllers/auth_controller.dart';
import 'package:projectakhir_mobile/models/order_history_model.dart';
import 'package:projectakhir_mobile/services/order_service.dart';
import 'package:projectakhir_mobile/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  final String? token;
  final String? username;
  final String? password;
  final Key? key;

  const ProfilePage({this.token, this.username, this.password, this.key})
      : super(key: key);

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  Future<List<OrderHistory>> orderHistory = Future.value([]);
  Map<String, dynamic>? decodedToken;
  String? get token => widget.token;
  String? username;
  String? password;
  String? email;

  bool showUpdateForm = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.token == null || widget.token!.isEmpty) {
      AuthController.logout(context);
      return;
    } else {
      decodedToken = JwtDecoder.decode(widget.token!);
      print('Decoded Token: $decodedToken');
      username = widget.username;
      password = widget.password;
      email = decodedToken?['email'];
      print('password: $password');

      if (email == null || email!.isEmpty) {
        email = 'Not provided';
      }
      _loadOrderHistory();
    }
  }

  Future<void> refreshOrderHistory() async {
    await _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    orderHistory = OrderService.getOrderHistory(widget.token!);
    setState(() {});
  }

  Future<void> _deleteOrder(int orderId) async {
    try {
      await OrderService.deleteOrder(orderId, widget.token!);
      await _loadOrderHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete order: $e')));
      }
    }
  }

  Future<void> _clearAllOrders() async {
    try {
      await OrderService.clearAllOrders(widget.token!);
      await _loadOrderHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All orders cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear orders: $e')));
      }
    }
  }

  void _updateProfile() async {
    final newUsername = usernameController.text.trim();
    final newEmail = emailController.text.trim();
    final newPassword = passwordController.text.trim();

    if (newUsername.isEmpty || newEmail.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required.")),
      );
      return;
    }

    final userId = decodedToken?['id'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid token or user ID.")),
      );
      return;
    }

    try {
      final response = await UserService.updateUser(
        userId,
        {
          "username": newUsername,
          "email": newEmail,
          "password": newPassword,
        },
        token!,
      );

      if (response.statusCode == 200) {
        setState(() {
          username = newUsername;
          email = newEmail;
          password = newPassword;
          showUpdateForm = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully.")),
        );
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Update failed: ${body['message'] ?? response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () {
              AuthController.logout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        username?[0].toUpperCase() ?? 'U',
                        style:
                            const TextStyle(fontSize: 32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username ?? 'User',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Email: ${email ?? 'Not provided'}',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                          Text(
                            'Role: ${decodedToken?['role'] ?? 'Not provided'}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(showUpdateForm
                          ? Icons.keyboard_arrow_up
                          : Icons.edit),
                      onPressed: () {
                        setState(() {
                          showUpdateForm = !showUpdateForm;
                          usernameController.text = username ?? '';
                          emailController.text = email ?? '';
                          passwordController.text = password ?? '';
                        });
                      },
                    ),
                  ],
                ),
                if (showUpdateForm) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _clearAllOrders,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OrderHistory>>(
              future: orderHistory,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/welcome.png',
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No order history',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final order = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.network(
                            order.imageUrl.isNotEmpty
                                ? order.imageUrl
                                : 'https://th.bing.com/th/id/OIP.FPIFJ6xedtnTAxk0T7AKhwHaF9?rs=1&pid=ImgDetMain',
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          order.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity: ${order.quantity}'),
                            Text(
                              'Total: Rp ${order.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            Text(
                              'Date: ${order.createdAt.toString().split('.')[0]}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteOrder(order.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

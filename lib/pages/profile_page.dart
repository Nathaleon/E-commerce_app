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
  final String? role;
  final Key? key;

  const ProfilePage(
      {this.token, this.username, this.password, this.role, this.key})
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
      username = widget.username;
      password = widget.password;
      email = decodedToken?['email'];

      if (email == null || email!.isEmpty) {
        email = 'Not provided';
      }
      _loadOrderHistory();
    }
  }

  Future<void> refreshOrderHistory() async {
    if (mounted) {
      setState(() {
        orderHistory = OrderService.getOrderHistory(widget.token!);
      });
    }
  }

  Future<void> _loadOrderHistory() async {
    if (mounted) {
      setState(() {
        orderHistory = OrderService.getOrderHistory(widget.token!);
      });
    }
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

  Widget _buildOrderHistoryList() {
    return RefreshIndicator(
      onRefresh: refreshOrderHistory,
      child: FutureBuilder<List<OrderHistory>>(
        future: orderHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
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
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
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
    );
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
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username: $username',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: $email',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
            child: _buildOrderHistoryList(),
          ),
        ],
      ),
    );
  }
}

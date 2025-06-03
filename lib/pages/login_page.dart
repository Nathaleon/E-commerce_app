import 'package:flutter/material.dart';
import 'package:projectakhir_mobile/controllers/auth_controller.dart';
import 'package:projectakhir_mobile/pages/base_page.dart';
import 'package:projectakhir_mobile/pages/main_product_page.dart';
import 'package:projectakhir_mobile/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      await AuthController.login(
                        context: context,
                        username: usernameController.text,
                        password: passwordController.text,
                        setLoading: (value) => setState(() => isLoading = value),
                        onSuccess: (token, username) {
                          // decode role dari token (optional bisa di controller juga)
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BasePage(
                                token: token,
                                username: username,
                                // role bisa diambil dari SharedPreferences di main
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text("Login"),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              child: const Text("Don't have an account? Register here"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainProductPage(
                      token: null,
                      username: null,
                      role: null,
                    ),
                  ),
                );
              },
              child: const Text("Lanjut tanpa login"),
            ),
          ],
        ),
      ),
    );
  }
}

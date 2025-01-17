import 'package:battleships/utils/service.dart';
import 'package:battleships/views/homepage.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Service authentication = Service();
  bool _loading = false;

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _authenticate(bool isLogin) async {
    setState(() {
      _loading = true;
    });

    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    final authResult =
        await authentication.authenticate(username, password, isLogin);

    if (authResult['success']) {
      _showSnackBar(context,
          isLogin ? 'Logged in successfully!' : 'Registered successfully!');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            authentication: authentication,
          ),
        ),
      );
    } else {
      _showSnackBar(context, authResult['message']);
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("BATTLESHIPS"),
            const SizedBox(height: 16.0),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 28.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _authenticate(true),
                  child: const Text('Log In'),
                ),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: () => _authenticate(false),
                  child: const Text('Register'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
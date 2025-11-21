import 'package:flutter/material.dart';
import 'package:flutter_demo/navigator_screens/navigator_home.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login in Navigator")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Login & Go Home"),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const NavigatorHome()),
              (_) => false,
            );
          },
        ),
      ),
    );
  }
}
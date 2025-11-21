import 'package:flutter/material.dart';
import 'package:flutter_demo/navigator_screens/setting_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class NavigatorHome extends StatelessWidget {
  const NavigatorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Navigator API")),
      body: Center(
        child: Column(
          spacing: 24,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Go to Profile"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Go to Settings"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingScreen()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Replace with Login"),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

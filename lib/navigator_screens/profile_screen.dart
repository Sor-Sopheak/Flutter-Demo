import 'package:flutter/material.dart';
import 'package:flutter_demo/navigator_screens/setting_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile in Navigator")),
      body: Center(
        child: Column(
          spacing: 24,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Go Back"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Go to Setting Screen"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

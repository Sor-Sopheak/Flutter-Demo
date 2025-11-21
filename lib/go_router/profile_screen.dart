import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile in GoRouter")),
      body: Center(
        child: Column(
          spacing: 24,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/profile/edit'),
              child: const Text("Edit Profile"),
            ),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}

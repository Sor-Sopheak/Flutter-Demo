import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeGoRouter extends StatelessWidget {
  const HomeGoRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GoRouter Home")),
      body: Center(
        child: Column(
          spacing: 24,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Go to Profile"),
              onPressed: () => context.go('/profile'),
            ),
            ElevatedButton(
              child: const Text("Settings"),
              onPressed: () => context.go('/settings'),
            ),
            ElevatedButton(
              child: const Text("User 123"),
              onPressed: () => context.go('/user/123'),
            ),
          ],
        ),
      ),
    );
  }
}
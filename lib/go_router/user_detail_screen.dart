import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User $userId in GoRouter")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text("Back"),
        ),
      ),
    );
  }
}

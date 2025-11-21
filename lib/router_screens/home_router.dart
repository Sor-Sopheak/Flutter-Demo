import 'package:flutter/material.dart';

class HomeRouter extends StatelessWidget {
  final Function(String) onNavigate;
  
  const HomeRouter({Key? key, required this.onNavigate}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Router API Home")),
      body: Center(
        child: Column(
          spacing: 24,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Go to Profile"),
              onPressed: () => onNavigate("/profile"),
            ),
            ElevatedButton(
              child: const Text("Go to Settings"),
              onPressed: () => onNavigate("/settings"),
            ),
          ],
        ),
      ),
    );
  }
}
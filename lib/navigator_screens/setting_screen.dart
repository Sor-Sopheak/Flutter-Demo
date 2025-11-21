import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings in Navigator")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Go Back"),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
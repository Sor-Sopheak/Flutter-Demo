import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  final Function(String) onNavigate;
  
  const SettingScreen({Key? key, required this.onNavigate}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings in router")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => onNavigate("/"),
          child: const Text("Go Home"),
        ),
      ),
    );
  }
}

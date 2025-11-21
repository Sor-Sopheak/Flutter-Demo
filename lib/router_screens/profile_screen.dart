import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Function(String) onNavigate;
  
  const ProfileScreen({Key? key, required this.onNavigate}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile in router")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Go Home"),
          onPressed: () => onNavigate("/"),
        ),
      ),
    );
  }
}
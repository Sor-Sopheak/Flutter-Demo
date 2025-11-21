import 'package:flutter/material.dart';
import 'package:flutter_demo/go_router/go_router_app.dart';
import 'package:flutter_demo/navigator_screens/navigator_home.dart';
import 'package:flutter_demo/router_screens/router_app.dart';

class NavigationDemoButtons extends StatelessWidget {
  const NavigationDemoButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Navigation Demo Hub")),
      body: Center(
        child: Column(
          spacing: 24,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Navigator (Push/Pop)"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NavigatorHome()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Router API (Navigator 2.0)"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RouterApp()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("GoRouter Demo"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoRouterApp()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

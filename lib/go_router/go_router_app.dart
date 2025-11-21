import 'package:flutter/material.dart';
import 'package:flutter_demo/go_router/setting_screen.dart';
import 'package:go_router/go_router.dart';
import 'home_go_router.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import 'user_detail_screen.dart';

class GoRouterApp extends StatelessWidget {
  const GoRouterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => HomeGoRouter(),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (_, __) => ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, __) => EditProfileScreen(),
                ),
              ],
            ),
            GoRoute(
              path: 'settings',
              builder: (_, __) => SettingScreen(),
            ),
            GoRoute(
              path: 'user/:id',
              builder: (_, state) => UserDetailScreen(userId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }
}

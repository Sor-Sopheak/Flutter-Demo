import 'package:flutter/material.dart';
import 'package:flutter_demo/router_screens/setting_screen.dart';
import 'home_router.dart';
import 'profile_screen.dart';

class AppRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteInformation> {

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String _path = "/";

  void navigate(String path) {
    _path = path;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MaterialPage(
        key: const ValueKey("home"),
        child: HomeRouter(onNavigate: navigate),
      ),
    ];

    if (_path == "/profile") {
      pages.add(MaterialPage(
        key: const ValueKey("profile"),
        child: ProfileScreen(onNavigate: navigate),
      ));
    } else if (_path == "/settings") {
      pages.add(MaterialPage(
        key: const ValueKey("settings"),
        child: SettingScreen(onNavigate: navigate),
      ));
    }

    return Navigator(
      key: navigatorKey,
      pages: pages,
      onPopPage: (route, result) {
        navigate("/");
        return route.didPop(result);
      },
    );
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) async {}
}

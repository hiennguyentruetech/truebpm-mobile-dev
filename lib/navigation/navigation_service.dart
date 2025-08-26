import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void navigateTo(String routeName) {
    navigatorKey.currentState?.pushNamed(routeName);
  }

  static void replaceWith(String routeName) {
    navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  static void replaceAllWith(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  static void replaceWithScreen(Widget screen) {
    navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  static void pushScreen(Widget screen) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
  }

  static void goBack() {
    navigatorKey.currentState?.pop();
  }
}

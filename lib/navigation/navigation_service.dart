import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void navigateTo(String routeName) {
    navigatorKey.currentState?.pushNamed(routeName);
  }

  static void replaceWith(String routeName) {
    navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  static void replaceAllWith(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  static void replaceWithScreen(Widget screen) {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void replaceWithSmoothTransition(
    Widget screen, {
    String? routeName,
    Duration duration = const Duration(milliseconds: 680),
  }) {
    navigatorKey.currentState?.pushReplacement(
      PageRouteBuilder(
        settings: routeName == null ? null : RouteSettings(name: routeName),
        transitionDuration: duration,
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = animation.drive(
            CurveTween(curve: Curves.easeOutCubic),
          );
          final scaleAnimation = animation.drive(
            Tween<double>(
              begin: 1.012,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      ),
    );
  }

  static void pushScreen(Widget screen) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
  }

  static void goBack() {
    navigatorKey.currentState?.pop();
  }
}

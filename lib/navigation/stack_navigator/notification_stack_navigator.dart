import 'package:flutter/material.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/navigation/stack_navigator/stack_routes.dart';

class NotificationStackNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const NotificationStackNavigator({
    super.key,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateInitialRoutes: (navigator, initialRoute) {
        final route = StackRoutes.generateRoute(
          RouteSettings(name: AppRoutes.notification),
          AppRoutes.notification,
        );
        return route != null ? [route] : [];
      },
      onGenerateRoute: (RouteSettings settings) {
        return StackRoutes.generateRoute(
          settings,
          AppRoutes.notification,
        );
      },
    );
  }
}

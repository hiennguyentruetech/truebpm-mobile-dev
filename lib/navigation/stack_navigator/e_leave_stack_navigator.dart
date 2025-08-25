import 'package:flutter/material.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/navigation/stack_navigator/stack_routes.dart';

class ELeaveStackNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const ELeaveStackNavigator({
    super.key,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateInitialRoutes: (navigator, initialRoute) {
        // Tạo chỉ một route duy nhất cho initial route
        final route = StackRoutes.generateRoute(
          RouteSettings(name: AppRoutes.eLeave),
          AppRoutes.eLeave,
        );
        return route != null ? [route] : [];
      },
      onGenerateRoute: (RouteSettings settings) {
        return StackRoutes.generateRoute(
          settings,
          AppRoutes.eLeave, // default route
        );
      },
    );
  }
}

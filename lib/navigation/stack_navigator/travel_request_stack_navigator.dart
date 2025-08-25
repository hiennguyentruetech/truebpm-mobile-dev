import 'package:flutter/material.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/navigation/stack_navigator/stack_routes.dart';

class TravelRequestStackNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const TravelRequestStackNavigator({
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
          RouteSettings(name: AppRoutes.travelRequest),
          AppRoutes.travelRequest,
        );
        return route != null ? [route] : [];
      },
      onGenerateRoute: (RouteSettings settings) {
        return StackRoutes.generateRoute(
          settings,
          AppRoutes.travelRequest, // default route
        );
      },
    );
  }
}

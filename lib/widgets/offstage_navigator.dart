import 'package:flutter/material.dart';

class OffstageNavigator extends StatelessWidget {
  final bool offstage;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const OffstageNavigator({
    super.key,
    required this.offstage,
    required this.navigatorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (offstage) {
      return Offstage(
        offstage: true,
        child: child, // Directly use the child (stack navigator)
      );
    }

    // For active tab, just return the child (stack navigator) directly
    // The back gesture handling is done in MainTabScreen
    return child;
  }
}

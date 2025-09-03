import 'package:flutter/material.dart';

// Import your custom widgets and screens
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/navigation/stack_navigator/home_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/e_leave_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/task_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/travel_request_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/menu_stack_navigator.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (index) => GlobalKey<NavigatorState>(),
  );

  final List<BottomNavItem> _navItems = const [
    BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
    BottomNavItem(icon: Icons.task_alt_rounded, label: 'Task'),
    BottomNavItem(icon: Icons.event_busy_rounded, label: 'E-Leave'),
    BottomNavItem(icon: Icons.flight_takeoff_rounded, label: 'Travel'),
    BottomNavItem(icon: Icons.menu_rounded, label: 'Menu'),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // If tapping the same tab, pop to root of that stack
      final currentNavigator = _navigatorKeys[index].currentState;
      if (currentNavigator != null && currentNavigator.canPop()) {
        currentNavigator.popUntil((route) => route.isFirst);
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> stackNavigators = [
      HomeStackNavigator(navigatorKey: _navigatorKeys[0]),
      TaskStackNavigator(navigatorKey: _navigatorKeys[1]),
      ELeaveStackNavigator(navigatorKey: _navigatorKeys[2]),
      TravelRequestStackNavigator(navigatorKey: _navigatorKeys[3]),
      MenuStackNavigator(navigatorKey: _navigatorKeys[4]),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final currentNavigator = _navigatorKeys[_selectedIndex].currentState;
          if (currentNavigator != null && currentNavigator.canPop()) {
            // Pop the current stack
            currentNavigator.pop();
            // Navigator.of(context).pop();
          } else {
            // If current stack is empty, exit the app
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        body: TabScreenWrapper(
          selectedIndex: _selectedIndex,
          stackNavigators: stackNavigators,
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: _navItems,
        ),
      ),
    );
  }
}

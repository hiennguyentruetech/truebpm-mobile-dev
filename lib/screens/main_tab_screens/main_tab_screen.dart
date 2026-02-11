import 'package:flutter/material.dart';

// Import your custom widgets and screens
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/navigation/stack_navigator/home_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/e_leave_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/task_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/travel_request_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/menu_stack_navigator.dart';
import 'package:truebpm/navigation/stack_navigator/notification_stack_navigator.dart';
import 'package:truebpm/providers/notification_provider.dart';
import 'package:truebpm/services/firebase_messaging_service.dart';

class MainTabScreen extends StatefulWidget {
  final int initialTabIndex;
  const MainTabScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _selectedIndex = widget.initialTabIndex;
  late NotificationProvider _notificationProvider;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    6,
    (index) => GlobalKey<NavigatorState>(),
  );

  @override
  void initState() {
    super.initState();
    _notificationProvider = NotificationProvider();
    _notificationProvider.addListener(_onNotificationCountChanged);
    _notificationProvider.loadNotifications();

    // Nếu app được mở từ terminated state qua FCM notification tap
    // → tự động chuyển sang Notify tab (index 4)
    if (FirebaseMessagingService.pendingNotifyTabNavigation) {
      FirebaseMessagingService.clearPendingNotifyTabNavigation();
      _selectedIndex = 4;
    }
  }

  @override
  void dispose() {
    _notificationProvider.removeListener(_onNotificationCountChanged);
    // Không dispose vì dùng shared instance
    super.dispose();
  }

  void _onNotificationCountChanged() {
    if (mounted) setState(() {});
  }

  List<BottomNavItem> _buildNavItems() {
    return [
      const BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
      const BottomNavItem(icon: Icons.task_alt_rounded, label: 'Tasks'),
      const BottomNavItem(icon: Icons.flight_takeoff_rounded, label: 'Travel'),
      const BottomNavItem(icon: Icons.event_busy_rounded, label: 'E-Leave'),
      BottomNavItem(
        icon: Icons.notifications_rounded,
        label: 'Notify',
        badgeCount: _notificationProvider.unreadCount,
      ),
      const BottomNavItem(icon: Icons.menu_rounded, label: 'More'),
    ];
  }

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
      TravelRequestStackNavigator(navigatorKey: _navigatorKeys[2]),
      ELeaveStackNavigator(navigatorKey: _navigatorKeys[3]),
      NotificationStackNavigator(navigatorKey: _navigatorKeys[4]),
      MenuStackNavigator(navigatorKey: _navigatorKeys[5]),
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
          items: _buildNavItems(),
        ),
      ),
    );
  }
}

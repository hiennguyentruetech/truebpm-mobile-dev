import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/notification_item.dart';
import 'package:truebpm/providers/notification_provider.dart';
import 'package:truebpm/styles/app_colors.dart';
import 'package:truebpm/widgets/notification/notification_card.dart';
import 'package:truebpm/widgets/notification/notification_empty_state.dart';
import 'package:truebpm/widgets/notification/notification_popup.dart';
import 'package:truebpm/navigation/notification_navigation_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationProvider _provider;
  final ScrollController _allScrollController = ScrollController();
  final ScrollController _unreadScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _provider = NotificationProvider();
    // Chỉ load nếu chưa có data (shared instance có thể đã load từ MainTabScreen)
    if (_provider.allNotifications.isEmpty && !_provider.isLoading) {
      _provider.loadNotifications();
    }

    _allScrollController.addListener(_onAllScroll);
    _unreadScrollController.addListener(_onUnreadScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allScrollController.removeListener(_onAllScroll);
    _unreadScrollController.removeListener(_onUnreadScroll);
    _allScrollController.dispose();
    _unreadScrollController.dispose();
    // Không dispose _provider vì dùng shared instance
    super.dispose();
  }

  void _onAllScroll() {
    if (_allScrollController.position.pixels >=
        _allScrollController.position.maxScrollExtent - 200) {
      _provider.loadMoreNotifications();
    }
  }

  void _onUnreadScroll() {
    // Unread tab is a filtered view, no separate pagination needed
  }

  void _onNotificationTap(NotificationItem notification) {
    // Mark as read chỉ khi chưa đọc
    if (!notification.isRead) {
      _provider.markAsRead(notification.id);
    }

    if (notification.isStatusChange) {
      // Navigate to module detail or task
      NotificationNavigationService.navigateFromNotification(
        context,
        notification,
      );
    } else if (notification.isInformation) {
      if (notification.hasTemplate) {
        // Show HTML template popup
        NotificationPopup.showTemplatePopup(context, notification);
      } else {
        // Show plain info popup
        NotificationPopup.showInfoPopup(context, notification);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab All
            _buildNotificationList(isUnreadOnly: false),
            // Tab Unread
            _buildNotificationList(isUnreadOnly: true),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Notifications'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        // Unread badge
        Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            if (provider.unreadCount > 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.unreadCount} new',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: _buildTabBar(),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(3),
            dividerColor: Colors.transparent,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.white.withOpacity(0.8),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              const Tab(text: 'All'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Unread'),
                    if (provider.unreadCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${provider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationList({required bool isUnreadOnly}) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          );
        }

        if (provider.errorMessage != null && provider.allNotifications.isEmpty) {
          return NotificationEmptyState(
            onRefresh: () => provider.refreshNotifications(),
          );
        }

        final notifications = isUnreadOnly
            ? provider.unreadNotifications
            : provider.allNotifications;

        if (notifications.isEmpty) {
          return RefreshIndicator(
            color: Colors.blue,
            onRefresh: () => provider.refreshNotifications(),
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: NotificationEmptyState(
                    isUnreadTab: isUnreadOnly,
                    onRefresh: () => provider.refreshNotifications(),
                  ),
                ),
              ],
            ),
          );
        }

        final scrollController =
            isUnreadOnly ? _unreadScrollController : _allScrollController;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: RefreshIndicator(
            color: Colors.blue,
            onRefresh: () => provider.refreshNotifications(),
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: notifications.length + (provider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  return _buildLoadingMoreIndicator();
                }

                final notification = notifications[index];
                return NotificationCard(
                  notification: notification,
                  onTap: () => _onNotificationTap(notification),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}

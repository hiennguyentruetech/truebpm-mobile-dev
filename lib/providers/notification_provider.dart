import 'package:flutter/foundation.dart';
import 'package:truebpm/models/notification_item.dart';
import 'package:truebpm/services/notification_service.dart';

/// Provider quản lý state cho màn hình Notification
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService.instance;

  // Shared instance dùng chung giữa MainTabScreen (badge) và NotificationScreen
  static NotificationProvider? _shared;
  static NotificationProvider get shared {
    _shared ??= NotificationProvider._internal();
    return _shared!;
  }

  /// Private constructor cho shared instance
  NotificationProvider._internal();

  /// Public constructor (tạo instance riêng nếu cần)
  factory NotificationProvider() => shared;

  // ============================================================================
  // STATE
  // ============================================================================

  List<NotificationItem> _allNotifications = [];
  List<NotificationItem> get allNotifications => _allNotifications;

  List<NotificationItem> get unreadNotifications =>
      _allNotifications.where((n) => !n.isRead).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;

  int _currentPage = 0;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _allNotifications.where((n) => !n.isRead).length;

  // ============================================================================
  // DATA LOADING
  // ============================================================================

  /// Load initial notifications (page 0)
  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.fetchNotifications();
      _allNotifications = data;
      _currentPage = 0;
      _hasMoreData = data.isNotEmpty;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more notifications (next page)
  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final data = await _service.fetchNotifications(pageNumber: nextPage);

      if (data.isEmpty) {
        _hasMoreData = false;
      } else {
        // Filter out duplicates by id
        final existingIds = _allNotifications.map((n) => n.id).toSet();
        final newItems = data.where((n) => !existingIds.contains(n.id)).toList();
        _allNotifications.addAll(newItems);
        _currentPage = nextPage;
        _hasMoreData = data.isNotEmpty;
      }
    } catch (e) {
      // Silent fail for load more
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh notifications (pull to refresh)
  Future<void> refreshNotifications() async {
    _currentPage = 0;
    _hasMoreData = true;
    _errorMessage = null;

    try {
      final data = await _service.fetchNotifications();
      _allNotifications = data;
      _hasMoreData = data.isNotEmpty;
    } catch (e) {
      _errorMessage = 'Failed to refresh notifications';
    }
    notifyListeners();
  }

  /// Mark a notification as read locally and on server
  /// Chỉ trigger khi isRead == false
  Future<void> markAsRead(String notificationId) async {
    // Tìm item và chỉ xử lý khi chưa read
    final index = _allNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_allNotifications[index].isRead) {
      final item = _allNotifications[index];

      // Update locally first for instant UI feedback
      _allNotifications[index] = NotificationItem(
        id: item.id,
        userId: item.userId,
        title: item.title,
        content: item.content,
        notificationType: item.notificationType,
        targetUrl: item.targetUrl,
        imageUrl: item.imageUrl,
        isRead: true,
        readAt: DateTime.now().toIso8601String(),
        createdDate: item.createdDate,
        notificationConfigId: item.notificationConfigId,
        isShowTemplate: item.isShowTemplate,
        notificationTemplate: item.notificationTemplate,
      );
      notifyListeners();

      // Fire-and-forget POST to server
      _service.markAsRead(
        notificationId: item.id,
        userId: item.userId,
      );
    }
  }

  /// Reset state
  void reset() {
    _allNotifications = [];
    _isLoading = false;
    _isLoadingMore = false;
    _hasMoreData = true;
    _currentPage = 0;
    _errorMessage = null;
    notifyListeners();
  }
}

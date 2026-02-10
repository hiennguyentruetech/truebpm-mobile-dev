import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truebpm/models/notification_item.dart';
import 'package:truebpm/utils/global_store.dart';

/// Service để gọi API notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final Dio _dio = Dio();

  /// Lấy headers với cookies + Bonita token (cùng pattern với CoreService)
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Get cookies from saved login
    List<String> cookies = [];
    final cookiesStr = prefs.getString('session_cookies');
    if (cookiesStr != null && cookiesStr.isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(cookiesStr);
        if (parsed is List) {
          cookies = parsed.map((e) => e.toString()).toList();
        }
      } catch (_) {
        cookies = [cookiesStr];
      }
    }

    // Extract X-Bonita-API-Token from cookies
    if (cookies.isNotEmpty) {
      headers['cookie'] = cookies.join('; ');
      for (final c in cookies) {
        final cookiePair = c.split(';')[0];
        final parts = cookiePair.split('=');
        if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
          headers['X-Bonita-API-Token'] = parts[1];
          break;
        }
      }
    }

    return headers;
  }

  /// Lấy userId từ SharedPreferences
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonStr = prefs.getString('user_info');
    if (userJsonStr != null) {
      try {
        final userMap = jsonDecode(userJsonStr);
        return userMap['id']?.toString();
      } catch (_) {}
    }
    return null;
  }

  /// Fetch notification history
  /// [pageNumber] - 0-based page index (null = page 0)
  Future<List<NotificationItem>> fetchNotifications({int? pageNumber}) async {
    try {
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) {
        logger.w('⚠️ No userId found for notifications');
        return [];
      }

      final headers = await _getHeaders();

      // Build URL with optional pageNumber
      String url =
          '${hosts.flexAPIUrl}notifications/history?userId=$userId';
      if (pageNumber != null && pageNumber > 0) {
        url += '&pageNumber=$pageNumber';
      }

      logger.i('📬 Fetching notifications: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Parse response format: { status, code, message, data: [...] }
        if (data is Map<String, dynamic>) {
          final status = data['status'];
          if (status == 'SUCCESS' && data['data'] is List) {
            final list = (data['data'] as List)
                .map((item) =>
                    NotificationItem.fromJson(item as Map<String, dynamic>))
                .toList();
            logger.i(
                '✅ Fetched ${list.length} notifications (page: ${pageNumber ?? 0})');
            return list;
          }
        }
      }

      logger.w('⚠️ Failed to fetch notifications: ${response.statusCode}');
      return [];
    } catch (e) {
      logger.e('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark a notification as read
  /// POST to notifications/history/mark-as-read with userId + id
  Future<bool> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      final headers = await _getHeaders();
      final url =
          '${hosts.flexAPIUrl}notifications/history/mark-as-read';

      final payload = {
        'userId': userId,
        'id': notificationId,
      };

      logger.i('📬 Marking notification as read: $notificationId');

      final response = await _dio.post(
        url,
        data: jsonEncode(payload),
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        logger.i('✅ Notification marked as read: $notificationId');
        return true;
      }

      logger.w('⚠️ Failed to mark notification as read: ${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('❌ Error marking notification as read: $e');
      return false;
    }
  }
}

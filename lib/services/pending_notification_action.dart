import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:truebpm/navigation/notification_navigation_service.dart';
import 'package:truebpm/screens/main_tab_screens/main_tab_screen.dart';

final _logger = Logger();

/// Service quản lý pending notification action
/// Khi user tap push notification mà chưa login → lưu action
/// Sau khi login xong → execute action đã lưu
class PendingNotificationAction {
  static const _key = 'pending_notification_action';

  /// Lưu pending action từ FCM push data
  static Future<void> save({
    required String moduleCode,
    required String recordId,
    required String targetUrl,
    String notificationType = 'STATUS_CHANGE',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'moduleCode': moduleCode,
        'recordId': recordId,
        'targetUrl': targetUrl,
        'notificationType': notificationType,
        'savedAt': DateTime.now().toIso8601String(),
      });
      await prefs.setString(_key, data);
      _logger.i('📌 Saved pending notification action: type=$notificationType, $moduleCode / $recordId');
    } catch (e) {
      _logger.e('Error saving pending action: $e');
    }
  }

  /// Kiểm tra có pending action hay không
  static Future<bool> hasPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  /// Execute pending action (gọi sau login thành công)
  /// Tự xóa action sau khi execute
  static Future<void> executePending(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_key);
      if (dataStr == null) return;

      // Xóa trước để tránh execute lại
      await prefs.remove(_key);

      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      final moduleCode = data['moduleCode'] as String?;
      final recordId = data['recordId'] as String?;
      final targetUrl = data['targetUrl'] as String?;
      final notificationType = data['notificationType'] as String? ?? 'STATUS_CHANGE';

      // Chờ 1 chút để MainTabScreen render xong
      await Future.delayed(const Duration(milliseconds: 800));

      if (!context.mounted) return;

      if (notificationType == 'STATUS_CHANGE') {
        // STATUS_CHANGE → navigate đến detail screen
        if (moduleCode == null || moduleCode.isEmpty || recordId == null || recordId.isEmpty) {
          _logger.w('⚠️ Invalid pending STATUS_CHANGE action data');
          return;
        }

        final isTaskList = targetUrl?.contains('task-list') == true;
        _logger.i('🚀 Executing pending STATUS_CHANGE: $moduleCode / $recordId (task=$isTaskList)');

        await NotificationNavigationService.navigateDirectly(
          context,
          moduleCode: moduleCode,
          recordId: recordId,
          fromTaskScreen: isTaskList,
        );
      } else if (notificationType == 'INFORMATION') {
        // INFORMATION → navigate đến Notify tab để user xem popup từ list
        _logger.i('📋 Executing pending INFORMATION → navigate to Notify tab');

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MainTabScreen(initialTabIndex: 4),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error executing pending action: $e');
    }
  }

  /// Xóa pending action (ví dụ khi logout)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

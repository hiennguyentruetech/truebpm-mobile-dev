import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:truebpm/screens/main_tab_screens/main_tab_screen.dart';

final _logger = Logger();

/// Service quản lý pending notification action
/// Khi user tap push notification mà chưa login → lưu action
/// Sau khi login xong → execute action đã lưu (navigate đến Notify tab)
class PendingNotificationAction {
  static const _key = 'pending_notification_action';

  /// Lưu pending action từ FCM push data
  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
      });
      await prefs.setString(_key, data);
      _logger.i('📌 Saved pending notification action → will navigate to Notify tab after login');
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
  /// Navigate đến Notify tab
  static Future<void> executePending(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_key);
      if (dataStr == null) return;

      // Xóa trước để tránh execute lại
      await prefs.remove(_key);

      // Chờ 1 chút để MainTabScreen render xong
      await Future.delayed(const Duration(milliseconds: 800));

      if (!context.mounted) return;

      _logger.i('📋 Executing pending action → navigate to Notify tab');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainTabScreen(initialTabIndex: 4),
        ),
        (route) => false,
      );
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

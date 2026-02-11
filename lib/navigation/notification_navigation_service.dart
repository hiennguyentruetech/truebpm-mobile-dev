import 'package:flutter/material.dart';
import 'package:truebpm/models/notification_item.dart';
import 'package:truebpm/navigation/task_navigation_config.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/utils/global_store.dart';

/// Service xử lý navigation từ notification đến màn hình chi tiết module
class NotificationNavigationService {
  /// Navigate từ notification STATUS_CHANGE
  /// Dùng recordId (ID thực của record) để navigate trực tiếp
  static Future<void> navigateFromNotification(
    BuildContext context,
    NotificationItem notification,
  ) async {
    if (!notification.isStatusChange) return;

    final moduleCode = notification.targetModuleCode;
    final recordId = notification.recordId;

    if (moduleCode == null) {
      logger.w('⚠️ Cannot parse moduleCode from targetUrl: ${notification.targetUrl}');
      return;
    }

    if (recordId == null || recordId.isEmpty) {
      logger.w('⚠️ No recordId for notification: ${notification.id}');
      _showErrorSnackBar(context, 'Cannot open this record');
      return;
    }

    // task-list → navigate sang detail với fromTaskScreen=true
    // non-task-list → navigate sang module detail với fromTaskScreen=false
    final fromTask = notification.isTaskListTarget;
    await _navigateToDetail(context, moduleCode, recordId, fromTask);
  }

  /// Navigate trực tiếp bằng moduleCode + recordId (không cần lookup API)
  /// Dùng chung cho cả onTap notification item và FCM push tap
  static Future<void> navigateDirectly(
    BuildContext context, {
    required String moduleCode,
    required String recordId,
    bool fromTaskScreen = false,
  }) async {
    await _navigateToDetail(context, moduleCode, recordId, fromTaskScreen);
  }

  /// Core navigation logic
  /// Notification navigate luôn tạo screen trực tiếp (không gọi TaskNavigationService)
  /// vì từ notification không có taskId → _fetchPagedData sẽ gây lỗi 500
  static Future<void> _navigateToDetail(
    BuildContext context,
    String moduleCode,
    String recordId,
    bool fromTaskScreen,
  ) async {
    try {
      _showLoadingDialog(context);

      final config = TaskNavigationConfig(
        moduleCode: moduleCode,
        listItemId: recordId,
        taskId: '',
        fromTaskScreen: fromTaskScreen,
      );

      // Tạo detail screen trực tiếp — KHÔNG gọi TaskNavigationService
      // vì notification không có taskId → fetchPagedData sẽ gây 500 error
      final moduleType = TaskModuleType.fromCode(moduleCode);
      final Widget detailScreen;

      if (moduleType == TaskModuleType.generic) {
        detailScreen = GenericDetailCoreScreen(
          moduleCode: moduleCode,
          listItem: {'id': recordId},
          initialTabCode: 'DTLS',
          fromTaskScreen: fromTaskScreen,
        );
      } else {
        detailScreen = TaskScreenFactory.createScreen(config);
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      }

      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => detailScreen),
      );
    } catch (e) {
      logger.e('❌ Error navigating to detail: $e');
      if (context.mounted) {
        // Dismiss loading nếu còn
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        _showErrorSnackBar(context, 'Error loading record');
      }
    }
  }

  /// Show a simple loading dialog
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  /// Show error snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:truebpm/models/notification_item.dart';
import 'package:truebpm/navigation/task_navigation_config.dart';
import 'package:truebpm/navigation/task_navigation_service.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/utils/global_store.dart';

/// Service xử lý navigation từ notification đến màn hình chi tiết module
class NotificationNavigationService {
  /// Navigate từ notification STATUS_CHANGE
  /// Parse targetUrl để xác định module và code, sau đó navigate đến detail screen
  static Future<void> navigateFromNotification(
    BuildContext context,
    NotificationItem notification,
  ) async {
    if (!notification.isStatusChange) return;

    final moduleCode = notification.targetModuleCode;
    final recordCode = notification.targetRecordCode;

    if (moduleCode == null || recordCode == null) {
      logger.w('⚠️ Cannot parse module/code from notification targetUrl: ${notification.targetUrl}');
      return;
    }

    // Check if targetUrl points to task-list → navigate to task module
    if (notification.isTaskListTarget) {
      await _navigateToTaskDetail(context, moduleCode, recordCode);
    } else {
      await _navigateToModuleDetail(context, moduleCode, recordCode);
    }
  }

  /// Navigate to module detail screen (STATUS_CHANGE, non-task)
  static Future<void> _navigateToModuleDetail(
    BuildContext context,
    String moduleCode,
    String recordCode,
  ) async {
    try {
      // Show loading
      _showLoadingDialog(context);

      // Lookup listItem by code using fetchListData to get id
      final listItemData = await _lookupListItem(moduleCode, recordCode);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      }

      if (listItemData == null) {
        logger.w('⚠️ Could not find item with code: $recordCode in module: $moduleCode');
        if (context.mounted) {
          _showErrorSnackBar(context, 'Could not find record $recordCode');
        }
        return;
      }

      if (!context.mounted) return;

      // Use TaskScreenFactory to get the correct detail screen
      final moduleType = TaskModuleType.fromCode(moduleCode);
      final Widget detailScreen;

      if (moduleType == TaskModuleType.generic) {
        detailScreen = GenericDetailCoreScreen(
          moduleCode: moduleCode,
          listItem: listItemData,
          initialTabCode: 'DTLS',
        );
      } else {
        final config = TaskNavigationConfig(
          moduleCode: moduleCode,
          listItemId: listItemData['id']?.toString() ?? '',
          taskId: '',
          fromTaskScreen: false,
        );
        detailScreen = TaskScreenFactory.createScreen(config);
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => detailScreen),
      );
    } catch (e) {
      logger.e('❌ Error navigating to module detail: $e');
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        _showErrorSnackBar(context, 'Error loading record');
      }
    }
  }

  /// Navigate to task detail screen (targetUrl contains "task-list")
  static Future<void> _navigateToTaskDetail(
    BuildContext context,
    String moduleCode,
    String recordCode,
  ) async {
    try {
      _showLoadingDialog(context);

      final listItemData = await _lookupListItem(moduleCode, recordCode);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      }

      if (listItemData == null) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Could not find record $recordCode');
        }
        return;
      }

      if (!context.mounted) return;

      // Navigate using TaskNavigationService
      await TaskNavigationService.navigateWithConfig(
        context,
        TaskNavigationConfig(
          moduleCode: moduleCode,
          listItemId: listItemData['id']?.toString() ?? '',
          taskId: '',
          fromTaskScreen: true,
        ),
        skipFetchPaged: false,
      );
    } catch (e) {
      logger.e('❌ Error navigating to task detail: $e');
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar(context, 'Error loading task');
      }
    }
  }

  /// Lookup a list item by code from the server API
  /// Returns listItem map with at least {'id': ..., 'code': ...}
  static Future<Map<String, dynamic>?> _lookupListItem(
    String moduleCode,
    String recordCode,
  ) async {
    try {
      // Use the core list API with filter by code
      final result = await CoreService.instance.fetchListData(
        moduleCode,
        {
          'filterInput': recordCode,
          'moduleCode': moduleCode,
          'tabModuleCode': 'LST',
          'pagination': {'index': 0, 'numberOfResults': 1},
        },
      );

      if (result != null && result['listItem'] is List) {
        final items = result['listItem'] as List;
        if (items.isNotEmpty) {
          final item = items[0] as Map<String, dynamic>;
          return item;
        }
      }

      // Fallback: try with code directly as id
      return {'code': recordCode};
    } catch (e) {
      logger.e('Error looking up list item: $e');
      return {'code': recordCode};
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

import 'package:flutter/material.dart';
import 'package:truebpm/services/core_service.dart';
// import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/utils/session_handler.dart';
import 'package:truebpm/widgets/core/core_action_dialog.dart';
import 'package:truebpm/navigation/task_navigation_config.dart';

/// Service chịu trách nhiệm navigate đến task detail screens
class TaskNavigationService {
  /// Navigate đến task detail screen dựa trên task type
  static Future<void> navigateToTaskDetail(
    BuildContext context,
    Map<String, dynamic> task, {
    bool skipFetchPaged = false,
    VoidCallback? onReturn,
  }) async {
    try {
      // Tạo navigation config từ task
      final config = TaskNavigationConfig.fromTask(task);

      // Validate config
      if (!config.isValid) {
        _showError(context, 'Unable to get module information');
        return;
      }

      // Fetch paged data nếu cần
      if (!skipFetchPaged) {
        final canContinue = await _ensurePagedData(context, config);
        if (!canContinue) return;
      }

      // Tạo target screen dựa trên config
      final targetScreen = TaskScreenFactory.createScreen(config);

      // Navigate và wait for result
      if (context.mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => targetScreen));

        // Call onReturn callback khi user quay lại
        onReturn?.call();
      }
    } catch (e) {
      // logger.e('Error navigating to task detail: $e');
      if (context.mounted) {
        _showError(context, 'Error loading task detail: $e');
      }
    }
  }

  /// Navigate với custom config (để dễ dàng customize)
  static Future<void> navigateWithConfig(
    BuildContext context,
    TaskNavigationConfig config, {
    bool skipFetchPaged = false,
    VoidCallback? onReturn,
  }) async {
    try {
      // Validate config
      if (!config.isValid) {
        _showError(context, 'Invalid navigation configuration');
        return;
      }

      // Fetch paged data nếu cần
      if (!skipFetchPaged) {
        final canContinue = await _ensurePagedData(context, config);
        if (!canContinue) return;
      }

      // Tạo target screen
      final targetScreen = TaskScreenFactory.createScreen(config);

      // Navigate
      if (context.mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => targetScreen));

        onReturn?.call();
      }
    } catch (e) {
      // logger.e('Error navigating with config: $e');
      if (context.mounted) {
        _showError(context, 'Error loading task detail: $e');
      }
    }
  }

  static Future<bool> _ensurePagedData(
    BuildContext context,
    TaskNavigationConfig config,
  ) async {
    var result = await _fetchPagedData(config);
    if (result.success) return true;

    if (result.sessionExpired) {
      if (!context.mounted) return false;
      final relogged = await SessionHandler.handleSessionExpired(context);
      if (!relogged) return false;

      result = await _fetchPagedData(config);
      if (result.success) return true;
    }

    if (context.mounted) {
      _showError(context, 'Failed to load module data');
    }
    return false;
  }

  /// Fetch paged data cho module
  static Future<_PagedDataFetchResult> _fetchPagedData(
    TaskNavigationConfig config,
  ) async {
    try {
      final pagedData = await CoreService.instance.fetchPagedData(
        config.moduleCode,
        {
          'listItem': {'id': config.listItemId},
          'action': 'DETAIL',
        },
      );

      if (pagedData == null) {
        return const _PagedDataFetchResult.sessionExpired();
      }
      return const _PagedDataFetchResult.success();
    } catch (e) {
      // logger.e('Error fetching paged data: $e');
      return const _PagedDataFetchResult.failed();
    }
  }

  /// Show error message
  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    CoreActionDialog.showResponseDialog(
      context,
      response: {'success': false, 'messageType': 'error', 'message': message},
      title: 'Error',
    );
  }

  /// Helper method để check xem module có được support không
  static bool isModuleSupported(String moduleCode) {
    try {
      TaskModuleType.fromCode(moduleCode);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get module type từ task
  static TaskModuleType getModuleType(Map<String, dynamic> task) {
    final moduleCode =
        task['rootContainerId']?['displayDescription']?.toString() ?? '';
    return TaskModuleType.fromCode(moduleCode);
  }

  /// Helper để tạo quick navigation (ví dụ từ notification)
  static Future<void> quickNavigate(
    BuildContext context, {
    required String moduleCode,
    required String listItemId,
    required String taskId,
    String initialTabCode = 'DTLS',
    VoidCallback? onReturn,
  }) async {
    final config = TaskNavigationConfig(
      moduleCode: moduleCode,
      listItemId: listItemId,
      taskId: taskId,
      initialTabCode: initialTabCode,
    );

    await navigateWithConfig(context, config, onReturn: onReturn);
  }
}

class _PagedDataFetchResult {
  const _PagedDataFetchResult({
    required this.success,
    required this.sessionExpired,
  });

  const _PagedDataFetchResult.success()
    : success = true,
      sessionExpired = false;

  const _PagedDataFetchResult.failed()
    : success = false,
      sessionExpired = false;

  const _PagedDataFetchResult.sessionExpired()
    : success = false,
      sessionExpired = true;

  final bool success;
  final bool sessionExpired;
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:truebpm/models/notification_item.dart';
import 'package:truebpm/navigation/task_navigation_config.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/services/core_service.dart';

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
  /// 
  /// Với task-list: kiểm tra task còn tồn tại cho user hay không
  /// - Nếu có task → lấy taskId + fetchPagedData rồi navigate (giống flow từ task-list thật)
  /// - Nếu không có task → fromTaskScreen=false (navigate đến module detail thông thường)
  static Future<void> _navigateToDetail(
    BuildContext context,
    String moduleCode,
    String recordId,
    bool fromTaskScreen,
  ) async {
    try {
      _showLoadingDialog(context);

      // Nếu đây là task-list notification → tìm task thật từ Bonita API
      bool shouldUseTaskScreen = fromTaskScreen;
      String taskId = '';

      if (fromTaskScreen) {
        final matchedTask = await _findTaskForUser(moduleCode, recordId);
        if (matchedTask != null) {
          // Task tồn tại → lấy taskId (Bonita task ID, KHÔNG phải record ID)
          taskId = matchedTask['id']?.toString() ?? '';
          logger.i('✅ Task found: taskId=$taskId → navigate as task detail');

          // Fetch paged data (giống flow task-list thật)
          // Nhưng KHÔNG fallback nếu fail — vẫn giữ task mode vì task tồn tại
          final pagedSuccess = await _fetchPagedData(moduleCode, recordId);
          if (!pagedSuccess) {
            logger.w('⚠️ fetchPagedData failed, nhưng vẫn giữ task mode vì task tồn tại');
          }
        } else {
          logger.i('⚠️ Task không tồn tại cho user → fallback sang module detail');
          shouldUseTaskScreen = false;
        }
      }

      final config = TaskNavigationConfig(
        moduleCode: moduleCode,
        listItemId: recordId,
        taskId: taskId,
        fromTaskScreen: shouldUseTaskScreen,
      );

      final moduleType = TaskModuleType.fromCode(moduleCode);
      final Widget detailScreen;

      if (moduleType == TaskModuleType.generic) {
        detailScreen = GenericDetailCoreScreen(
          moduleCode: moduleCode,
          listItem: {'id': recordId},
          initialTabCode: 'DTLS',
          fromTaskScreen: shouldUseTaskScreen,
          taskId: taskId.isNotEmpty ? taskId : null,
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

  /// Tìm task matching trong danh sách task của user
  /// Return task data (đã parse displayDescription) nếu tìm thấy, null nếu không
  /// 
  /// displayDescription là JSON string cần parse:
  /// {"code":"ELEAVE-10081","id":"C20245EF-...","createdBy":"...",...}
  /// Trong đó `id` chính là recordId của phiếu
  static Future<Map<String, dynamic>?> _findTaskForUser(String moduleCode, String recordId) async {
    try {
      logger.i('🔍 Finding task for moduleCode=$moduleCode, recordId=$recordId');
      
      final tasks = await CoreService.instance.fetchListTaskProcess();
      if (tasks == null || tasks.isEmpty) {
        logger.i('📭 No tasks found for user');
        return null;
      }

      logger.i('📋 Total tasks for user: ${tasks.length}');

      for (final task in tasks) {
        // moduleCode nằm trong rootContainerId.displayDescription (plain string)
        final taskModuleCode = task['rootContainerId']?['displayDescription']?.toString() ?? '';

        // recordId nằm trong displayDescription (JSON string cần parse)
        final displayDescStr = task['displayDescription']?.toString();
        Map<String, dynamic>? parsedDesc;
        if (displayDescStr != null && displayDescStr.isNotEmpty) {
          try {
            parsedDesc = jsonDecode(displayDescStr) as Map<String, dynamic>;
          } catch (_) {
            // displayDescription không phải JSON hợp lệ → skip
          }
        }
        final taskRecordId = parsedDesc?['id']?.toString() ?? '';

        logger.i('  🔎 Task: bonitaTaskId=${task['id']}, module=$taskModuleCode, recordId=$taskRecordId');

        // So sánh case-insensitive (UUID có thể khác case giữa notification API và Bonita)
        if (taskModuleCode.toUpperCase() == moduleCode.toUpperCase() && 
            taskRecordId.toUpperCase() == recordId.toUpperCase()) {
          logger.i('✅ Matched task: bonitaTaskId=${task['id']}, moduleCode=$taskModuleCode, recordId=$taskRecordId');
          // Gắn displayDescriptionParsed vào task data để TaskNavigationConfig.fromTask dùng được
          if (parsedDesc != null) {
            task['displayDescriptionParsed'] = parsedDesc;
          }
          return task;
        }
      }

      logger.i('❌ No matching task found for moduleCode=$moduleCode, recordId=$recordId');
      return null;
    } catch (e) {
      logger.e('⚠️ Error finding task: $e');
      return null;
    }
  }

  /// Fetch paged data cho module (giống TaskNavigationService._fetchPagedData)
  static Future<bool> _fetchPagedData(String moduleCode, String recordId) async {
    try {
      final pagedData = await CoreService.instance.fetchPagedData(
        moduleCode,
        {
          'listItem': {'id': recordId},
          'action': 'DETAIL',
        },
      );
      return pagedData != null;
    } catch (e) {
      logger.e('⚠️ Error fetching paged data: $e');
      return false;
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

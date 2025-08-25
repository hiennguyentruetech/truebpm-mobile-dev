import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/widgets/core_task_list/task_loading_overlay.dart';
import 'package:truebpm/widgets/core_task_list/take_task_dialog.dart';
import 'package:truebpm/navigation/task_navigation_service.dart';

/// Service để xử lý các actions liên quan đến task
class TaskActionService {
  /// Xử lý khi user tap vào task
  static void handleTaskTap(
    BuildContext context,
    Map<String, dynamic> task,
    int index, {
    VoidCallback? onTaskUpdated,
  }) {
    logger.i('Task tapped: ${task.toString()}');
    
    final assignedId = task['assigned_id']?.toString() ?? '';
    
    if (assignedId.isEmpty || assignedId == 'null') {
      // Task chưa được assign, show dialog take task
      _showTakeTaskDialog(context, task, onTaskUpdated: onTaskUpdated);
    } else {
      // Task đã được assign, navigate trực tiếp
      TaskNavigationService.navigateToTaskDetail(
        context,
        task,
        onReturn: onTaskUpdated,
      );
    }
  }

  /// Show dialog xác nhận việc nhận task
  static void _showTakeTaskDialog(
    BuildContext context,
    Map<String, dynamic> task, {
    VoidCallback? onTaskUpdated,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => TakeTaskDialog(
        onTake: () {
          // Close dialog
          Navigator.of(dialogContext).pop();
          // Continue with take flow
          _takeTask(context, task, onTaskUpdated: onTaskUpdated);
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  /// Nhận task bằng cách assign cho user hiện tại
  static Future<void> _takeTask(
    BuildContext context,
    Map<String, dynamic> task, {
    VoidCallback? onTaskUpdated,
  }) async {
    try {
      // Show loading overlay
      TaskLoadingManager.show(context, 'Taking task...');

      // Get current user ID từ Bonita user info
      final prefs = await SharedPreferences.getInstance();
      final bonitaUserInfoStr = prefs.getString('bonita_user_info');
      if (bonitaUserInfoStr == null) {
        if (context.mounted) {
          TaskLoadingManager.hide(context);
          _showError(context, 'Unable to get user information');
        }
        return;
      }

      final bonitaUserInfo = jsonDecode(bonitaUserInfoStr);
      final userId = bonitaUserInfo['user_id']?.toString();
      if (userId == null) {
        if (context.mounted) {
          TaskLoadingManager.hide(context);
          _showError(context, 'Unable to get user ID');
        }
        return;
      }

      // Call API: take task
      final takeOk = await CoreService.instance.takeTask(
        task['id']?.toString() ?? '',
        userId,
      );
      if (!takeOk) {
        if (context.mounted) {
          TaskLoadingManager.hide(context);
          _showError(context, 'Failed to take task');
        }
        return;
      }

      // Update task locally
      task['assigned_id'] = userId;
      onTaskUpdated?.call();

      // Prepare info for fetch
      final moduleCode = task['rootContainerId']?['displayDescription']?.toString() ?? '';
      final parsedDisplayDescription = task['displayDescriptionParsed'] as Map<String, dynamic>?;
      final listItemId = parsedDisplayDescription?['id']?.toString() ?? '';
      
      if (moduleCode.isEmpty || listItemId.isEmpty) {
        if (context.mounted) {
          TaskLoadingManager.hide(context);
          _showError(context, 'Unable to get module information');
        }
        return;
      }

      // Call API: fetch paged data (vẫn trong loading overlay)
      final pagedData = await CoreService.instance.fetchPagedData(
        moduleCode,
        {
          'listItem': {'id': listItemId},
          'action': 'DETAIL',
        },
      );

      if (pagedData == null) {
        if (context.mounted) {
          TaskLoadingManager.hide(context);
          _showError(context, 'Failed to load module data');
        }
        return;
      }

      // Close loading trước khi navigation
      if (context.mounted) {
        TaskLoadingManager.hide(context);
      }

      // Navigate to detail, skip internal fetch vì đã fetch rồi
      if (context.mounted) {
        await TaskNavigationService.navigateToTaskDetail(
          context,
          task,
          skipFetchPaged: true,
          onReturn: onTaskUpdated,
        );
      }
    } catch (e) {
      if (context.mounted) {
        TaskLoadingManager.hide(context);
      }
      // logger.e('Error taking task: $e');
      if (context.mounted) {
        _showError(context, 'Error taking task: $e');
      }
    }
  }

  /// Show error message
  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

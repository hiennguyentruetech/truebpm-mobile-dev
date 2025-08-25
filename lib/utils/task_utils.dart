import 'dart:convert';
// import 'package:truebpm/utils/global_store.dart';

/// Utility class để xử lý parse display description
class TaskDisplayDescriptionUtils {
  /// Parse display description từ string JSON
  static Map<String, dynamic>? parseDisplayDescription(String? displayDescription) {
    if (displayDescription == null || displayDescription.isEmpty) return null;
    
    try {
      return jsonDecode(displayDescription);
    } catch (e) {
      // logger.e('Error parsing displayDescription: $e');
      return null;
    }
  }

  /// Process task list để attach parsed display description
  static List<Map<String, dynamic>> processTaskList(List<dynamic> taskList) {
    return taskList.map<Map<String, dynamic>>((e) {
      final map = Map<String, dynamic>.from(e);
      final parsed = parseDisplayDescription(e['displayDescription']?.toString());
      if (parsed != null) {
        map['displayDescriptionParsed'] = parsed;
      }
      return map;
    }).toList();
  }

  /// Get module code từ task
  static String getModuleCode(Map<String, dynamic> task) {
    return task['rootContainerId']?['displayDescription']?.toString() ?? '';
  }

  /// Get list item ID từ parsed display description
  static String getListItemId(Map<String, dynamic> task) {
    final parsedDisplayDescription = task['displayDescriptionParsed'] as Map<String, dynamic>?;
    return parsedDisplayDescription?['id']?.toString() ?? '';
  }

  /// Check if task is assigned
  static bool isTaskAssigned(Map<String, dynamic> task) {
    final assignedId = task['assigned_id']?.toString() ?? '';
    return assignedId.isNotEmpty && assignedId != 'null';
  }

  /// Get task ID
  static String getTaskId(Map<String, dynamic> task) {
    return task['id']?.toString() ?? '';
  }
}

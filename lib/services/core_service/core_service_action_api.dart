part of 'core_service.dart';

extension CoreServiceActionApiExt on CoreService {
  Future<Map<String, dynamic>?> saveData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": tabModuleCode,
      "dataSpy": dataSpy,
    };

    logger.i('💾 SAVE Action Details:');
    logger.i('  • Module: $moduleCode.$tabModuleCode');
    logger.i('  • User: ${user['fullName'] ?? user['code']}');
    logger.i('  • Record: ${dataSpy['code'] ?? 'New'}');

    final result = await performAction(
      moduleCode,
      tabModuleCode,
      'SAVE',
      payload,
    );

    if (result != null) {
      logger.i('💾 SAVE Response Analysis:');
      logger.i('  • Success: ${result['success'] ?? false}');
      logger.i('  • Message Type: ${result['messageType'] ?? 'N/A'}');
      logger.i('  • Message: ${result['message'] ?? 'N/A'}');

      if (result['itemDetail'] != null) {
        logger.i('  • ItemDetail Updated: ✅');
      } else {
        logger.w('  • ItemDetail Updated: ❌ (NULL)');
      }
    }

    return result;
  }

  /// Submit action for current tab
  Future<Map<String, dynamic>?> submitData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": tabModuleCode,
      "dataSpy": dataSpy,
    };

    logger.i('📮 SUBMIT Action Details:');
    logger.i('  • Module: $moduleCode.$tabModuleCode');
    logger.i('  • User: ${user['fullName'] ?? user['code']}');
    logger.i('  • Record: ${dataSpy['code'] ?? 'Unknown'}');
    logger.i('  • Workflow Transition: Pending → Submitted');

    final result = await performAction(
      moduleCode,
      tabModuleCode,
      'SUBMIT',
      payload,
    );

    if (result != null) {
      logger.i('📮 SUBMIT Response Analysis:');
      logger.i('  • Success: ${result['success'] ?? false}');
      logger.i('  • Message Type: ${result['messageType'] ?? 'N/A'}');
      logger.i('  • Message: ${result['message'] ?? 'N/A'}');

      if (result['success'] == true) {
        logger.i('  • ✅ Workflow transition completed');
      } else {
        logger.w('  • ❌ Workflow transition failed');
      }
    }

    return result;
  }

  /// Copy action for current tab
  Future<Map<String, dynamic>?> copyData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    // Always use 'DTLS' for copyData operations
    final effectiveTabModuleCode = 'DTLS';

    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };

    logger.i('📋 COPY Action Details:');
    logger.i('  • Module: $moduleCode.$effectiveTabModuleCode');
    logger.i('  • User: ${user['fullName'] ?? user['code']}');
    logger.i('  • Source Record: ${dataSpy['code'] ?? 'Unknown'}');
    logger.i('  • Operation: Duplicating record with new ID');

    final result = await performAction(
      moduleCode,
      effectiveTabModuleCode,
      'COPY',
      payload,
    );

    if (result != null) {
      logger.i('📋 COPY Response Analysis:');
      logger.i('  • Success: ${result['success'] ?? false}');
      logger.i('  • Message Type: ${result['messageType'] ?? 'N/A'}');
      logger.i('  • Message: ${result['message'] ?? 'N/A'}');

      if (result['itemDetail'] != null &&
          result['itemDetail']['value'] != null) {
        final newRecord = result['itemDetail']['value'];
        if (newRecord is Map) {
          logger.i('  • New Record Code: ${newRecord['code'] ?? 'N/A'}');
        }
      }
    }

    return result;
  }

  /// Cancel action for current tab
  Future<Map<String, dynamic>?> cancelData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    // Always use 'DTLS' for cancelData operations
    final effectiveTabModuleCode = 'DTLS';

    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };

    logger.i('🚫 CANCEL Action Details:');
    logger.i('  • Module: $moduleCode.$effectiveTabModuleCode');
    logger.i('  • User: ${user['fullName'] ?? user['code']}');
    logger.i('  • Record: ${dataSpy['code'] ?? 'Unknown'}');
    logger.i('  • Reason: User-initiated cancellation');

    final result = await performAction(
      moduleCode,
      effectiveTabModuleCode,
      'CANCEL',
      payload,
    );

    if (result != null) {
      logger.i('🚫 CANCEL Response Analysis:');
      logger.i('  • Success: ${result['success'] ?? false}');
      logger.i('  • Message Type: ${result['messageType'] ?? 'N/A'}');
      logger.i('  • Message: ${result['message'] ?? 'N/A'}');
    }

    return result;
  }

  /// Delete action for current tab
  Future<Map<String, dynamic>?> deleteData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    // Always use 'DTLS' for deleteData operations
    final effectiveTabModuleCode = 'DTLS';

    final payload = {
      "user": user,
      "listItem":
          itemDetail['value'] ?? itemDetail, // Use itemDetail.value as listItem
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };

    logger.i('🗑️ DELETE Action Details:');
    logger.i('  • Module: $moduleCode.$effectiveTabModuleCode');
    logger.i('  • User: ${user['fullName'] ?? user['code']}');
    logger.i('  • Target Record: ${dataSpy['code'] ?? 'Unknown'}');
    logger.i('  • ⚠️ Permanent deletion requested');

    final result = await performAction(
      moduleCode,
      effectiveTabModuleCode,
      'DELETE',
      payload,
    );

    if (result != null) {
      logger.i('🗑️ DELETE Response Analysis:');
      logger.i('  • Success: ${result['success'] ?? false}');
      logger.i('  • Message Type: ${result['messageType'] ?? 'N/A'}');
      logger.i('  • Message: ${result['message'] ?? 'N/A'}');

      if (result['success'] == true) {
        logger.i('  • ✅ Record permanently deleted');
      } else {
        logger.w('  • ❌ Deletion failed');
      }
    }

    return result;
  }

  /// Delete item directly from list (swipe to delete)
  Future<Map<String, dynamic>?> deleteItemFromList(
    String moduleCode,
    Map<String, dynamic> user,
    Map<String, dynamic> listItem,
    Map<String, dynamic> dataSpy,
  ) async {
    // Always use 'DTLS' for deleteData operations from list
    const effectiveTabModuleCode = 'DTLS';

    final payload = {
      "user": user,
      "listItem": listItem, // Direct listItem value
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };

    logger.i('🗑️ DELETE FROM LIST Action:');
    logger.i('  • Module: $moduleCode');
    logger.i('  • User: ${user['fullName'] ?? user['code']}');
    logger.i('  • Item Code: ${listItem['code'] ?? 'Unknown'}');
    logger.i('  • Method: Swipe to delete');

    final result = await performAction(
      moduleCode,
      effectiveTabModuleCode,
      'DELETE',
      payload,
    );

    if (result != null) {
      logger.i('🗑️ DELETE FROM LIST Response:');
      logger.i('  • Success: ${result['success'] ?? false}');
      logger.i('  • Message: ${result['message'] ?? 'N/A'}');
    }

    return result;
  }

  /// Task approval/rejection action with SUBMIT_FORM action
  Future<Map<String, dynamic>?> performTaskAction(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
    String taskId,
    bool isApproved,
  ) async {
    final safeItemDetail = _prepareTaskItemDetailForAction(
      moduleCode,
      itemDetail,
    );

    // Create payload with special task-specific fields
    final payload = {
      "user": user,
      "itemDetail": safeItemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": tabModuleCode,
      "dataSpy": dataSpy,
      "isApproved": isApproved,
      "taskId": taskId,
    };

    final actionEmoji = isApproved ? '✅' : '❌';
    final actionText = isApproved ? 'APPROVE' : 'REJECT';

    logger.i('$actionEmoji TASK ACTION: $actionText');
    logger.i('  • Task ID: $taskId');
    logger.i('  • Module: $moduleCode.$tabModuleCode');
    logger.i('  • User: ${user['fullName'] ?? user['code']}');
    logger.i('  • Record: ${dataSpy['code'] ?? 'Unknown'}');
    logger.i('  • Decision: ${isApproved ? 'APPROVED' : 'REJECTED'}');
    logger.i(
      '  • Workflow Impact: Task will be ${isApproved ? 'moved to next step' : 'returned to initiator'}',
    );

    final result = await performAction(
      moduleCode,
      tabModuleCode,
      'SUBMIT_FORM',
      payload,
    );

    if (result != null) {
      logger.i('$actionEmoji TASK ACTION Response:');
      logger.i('  • Success: ${result['success'] ?? false}');
      logger.i('  • Message Type: ${result['messageType'] ?? 'N/A'}');
      logger.i('  • Message: ${result['message'] ?? 'N/A'}');

      if (result['success'] == true) {
        logger.i('  • ✅ Task completed and workflow updated');
      } else {
        logger.w('  • ❌ Task action failed');
      }
    }

    return result;
  }

  Map<String, dynamic> _prepareTaskItemDetailForAction(
    String moduleCode,
    Map<String, dynamic> itemDetail,
  ) {
    final cloned = _deepCloneMap(itemDetail);

    switch (moduleCode.toUpperCase()) {
      case 'CONSUB':
        return _stripConsubUiOnlyFields(cloned);
      default:
        return cloned;
    }
  }

  Map<String, dynamic> _deepCloneMap(Map<String, dynamic> source) {
    try {
      final decoded = jsonDecode(jsonEncode(source));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Fallback below keeps the action resilient even if a value is not JSON-safe.
    }
    return Map<String, dynamic>.from(source);
  }

  Map<String, dynamic> _stripConsubUiOnlyFields(Map<String, dynamic> source) {
    dynamic strip(dynamic value) {
      if (value is List) {
        return value.map(strip).toList();
      }
      if (value is Map) {
        final sanitized = <String, dynamic>{};
        value.forEach((key, entryValue) {
          final keyText = key.toString();
          if (keyText == 'employeePicDisplay' ||
              keyText == 'listEmployeePicDisplay') {
            return;
          }
          sanitized[keyText] = strip(entryValue);
        });
        return sanitized;
      }
      return value;
    }

    final sanitized = strip(source);
    if (sanitized is Map<String, dynamic>) return sanitized;
    return source;
  }
}

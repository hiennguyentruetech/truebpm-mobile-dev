import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/utils/core_api_logger.dart';
import 'package:http_parser/http_parser.dart';

class CoreService {
  static final CoreService _instance = CoreService._internal();
  static CoreService get instance => _instance;
  
  CoreService._internal();
  
  final Dio _dio = Dio();

  // ============================================================================
  // ENHANCED LOGGING METHODS (Delegated to CoreApiLogger)
  // ============================================================================
  
  /// Log API request with comprehensive details
  void _logApiRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic payload,
    String? action,
  }) {
    // Convert headers to Map<String, dynamic> and show full headers
    final headersMap = <String, dynamic>{};
    if (headers != null) {
      headersMap.addAll(headers);
    }
    
    // Check if URL already contains action parameter to avoid duplication
    final endpoint = action != null && !url.contains('?action=') ? '$url?action=$action' : url;
    
    // Handle different payload types
    Map<String, dynamic>? payloadMap;
    if (payload is Map<String, dynamic>) {
      payloadMap = payload;
    } else if (payload != null) {
      // For non-Map payloads (like FormData), create a descriptive map
      payloadMap = {
        'type': payload.runtimeType.toString(),
        'description': payload.toString().length > 200
            ? '${payload.toString().substring(0, 200)}...'
            : payload.toString(),
      };
    }

    CoreApiLogger.logApiRequest(
      method: method,
      endpoint: endpoint,
      headers: headersMap,
      payload: payloadMap,
    );
  }
  
  /// Log API response with status-based formatting
  void _logApiResponse({
    required int? statusCode,
    dynamic responseData,
    required String url,
    Duration? duration,
    dynamic requestPayload, // Keep for compatibility but won't use
  }) {
    // Normalize response to Map for logging while preserving full content
    Map<String, dynamic>? normalized;
    try {
      if (responseData is Map<String, dynamic>) {
        normalized = responseData;
      } else if (responseData is List) {
        normalized = {
          'type': 'List',
          'length': responseData.length,
          'data': responseData,
        };
      } else if (responseData is String) {
        // Try parse JSON string; if not JSON, keep raw
        try {
          final parsed = jsonDecode(responseData);
          if (parsed is Map<String, dynamic>) {
            normalized = parsed;
          } else if (parsed is List) {
            normalized = {
              'type': 'List',
              'length': parsed.length,
              'data': parsed,
            };
          } else {
            normalized = {'raw': responseData};
          }
        } catch (_) {
          normalized = {'raw': responseData};
        }
      } else if (responseData != null) {
        normalized = {'raw': responseData.toString()};
      }
    } catch (_) {
      // Fallback to raw to avoid logging crash
      normalized = {'raw': responseData.toString()};
    }

    CoreApiLogger.logApiResponse(
      method: 'POST', // Most of our APIs are POST
      endpoint: url,
      statusCode: statusCode ?? 0,
      responseData: normalized,
      duration: duration,
    );
  }
  
  /// Log API errors with detailed context
  void _logApiError({
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? requestPayload,
  }) {
    CoreApiLogger.logApiError(
      method: 'POST',
      endpoint: url,
      error: error,
      stackTrace: stackTrace,
      requestPayload: requestPayload,
    );
  }
  
  /// Log session/authentication details
  void _logAuthentication({
    required String context,
    String? token,
    List<String>? cookies,
    bool isExpired = false,
  }) {
    logger.i('┌────────────────────────────────────────────────────────────────────');
    logger.i('│ 🔐 AUTHENTICATION: $context');
    logger.i('├────────────────────────────────────────────────────────────────────');
    
    if (isExpired) {
      logger.w('│ 🔒 Session Status: EXPIRED - Re-authentication required');
    } else {
      logger.i('│ ✅ Session Status: ACTIVE');
    }
    
    if (token != null) {
      final maskedToken = token.length > 20
          ? '${token.substring(0, 10)}...${token.substring(token.length - 5)}'
          : '***';
      logger.i('│ 🎫 Bonita Token: $maskedToken');
    }
    
    if (cookies != null && cookies.isNotEmpty) {
      logger.i('│ 🍪 Cookies: ${cookies.length} cookie(s) found');
      for (var i = 0; i < math.min(3, cookies.length); i++) {
        final cookie = cookies[i];
        final parts = cookie.split('=');
        if (parts.length >= 2) {
          logger.i('│   • ${parts[0]}: [MASKED]');
        }
      }
    }
    
    logger.i('└────────────────────────────────────────────────────────────────────');
  }
  
  // ============================================================================
  // API METHODS WITH ENHANCED LOGGING
  // ============================================================================

  /// Generic method to fetch paged data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchPagedData(String moduleCode, Map<String, dynamic> payload) async {
    return _makeApiCall('$moduleCode.PAGEDATA', payload);
  }

  /// Generic method to fetch list data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchListData(String moduleCode, Map<String, dynamic> payload) async {
    return _makeApiCall('$moduleCode.LST', payload);
  }

  /// Generic method to fetch detail data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchDetailData(String moduleCode, String tabModuleCode, Map<String, dynamic> payload) async {
    return _makeApiCall('$moduleCode.$tabModuleCode', payload);
  }

  /// Fetch data for creating new records with action=NEW parameter
  Future<Map<String, dynamic>?> fetchNewRecordData(String moduleCode, String tabModuleCode, Map<String, dynamic> payload) async {
    logger.i('🆕 Fetching NEW record data for $moduleCode.$tabModuleCode');
    return _makeApiCall('$moduleCode.$tabModuleCode?action=NEW', payload);
  }

  /// Generic method to perform actions (SAVE, SUBMIT, COPY, CANCEL, DELETE)
  Future<Map<String, dynamic>?> performAction(
    String moduleCode, 
    String tabModuleCode, 
    String action, 
    Map<String, dynamic> payload,
  ) async {
    logger.i('🎬 Performing action: $action on $moduleCode.$tabModuleCode');
    return _makeApiCall('$moduleCode.$tabModuleCode?action=$action', payload);
  }

  /// Fetch list of task processes from Bonita BPM API
  Future<List<Map<String, dynamic>>?> fetchListTaskProcess() async {
    final startTime = DateTime.now();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get Bonita user info to extract user_id
      final bonitaUserInfoStr = prefs.getString('bonita_user_info');
      if (bonitaUserInfoStr == null) {
        logger.e('❌ No Bonita user info found');
        return null;
      }
      
      final bonitaUserInfo = jsonDecode(bonitaUserInfoStr);
      final userId = bonitaUserInfo['user_id']?.toString();
      if (userId == null) {
        logger.e('❌ No user_id found in Bonita user info');
        return null;
      }

      final url = '${hosts.bpmUrl}humanTask?c=1000&d=rootContainerId&f=state%3Dready&f=user_id%3D$userId&p=0';

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
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };

      _logApiRequest(
        method: 'GET',
        url: url,
        headers: headers,
        payload: null,
        action: 'FETCH_TASK_LIST',
      );

      final response = await _dio.get(
        url,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final duration = DateTime.now().difference(startTime);
      _logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: null,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      
      logger.w('⚠️ Failed to fetch task list: ${response.statusCode}');
      return null;
    } catch (e, stack) {
      _logApiError(
        url: '${hosts.bpmUrl}humanTask',
        error: e,
        stackTrace: stack,
        context: 'fetchListTaskProcess',
      );
      return null;
    }
  }

  /// Take (assign) a task to current user in Bonita BPM
  Future<bool> takeTask(String taskId, String userId) async {
    final startTime = DateTime.now();
    
    try {
      logger.i('📝 Taking task: $taskId for user: $userId');
      
      final prefs = await SharedPreferences.getInstance();
      
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
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }

      final url = '${hosts.bpmUrl}humanTask/$taskId';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };
      
      final payload = {
        'assigned_id': userId,
      };

      _logApiRequest(
        method: 'PUT',
        url: url,
        headers: headers,
        payload: payload,
        action: 'TAKE_TASK',
      );

      final response = await _dio.put(
        url,
        data: jsonEncode(payload),
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final duration = DateTime.now().difference(startTime);
      _logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: payload,
      );
      
      if (response.statusCode == 200) {
        logger.i('✅ Task taken successfully');
        return true;
      } else {
        logger.w('⚠️ Failed to take task: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      _logApiError(
        url: '${hosts.bpmUrl}humanTask/$taskId',
        error: e,
        stackTrace: stack,
        context: 'takeTask',
      );
      return false;
    }
  }

  /// Specialized method for uploading files with multipart/form-data
  Future<Map<String, dynamic>?> uploadFile(
    String moduleCode,
    String fileName,
    List<int> fileBytes,
    String userId,
    String userName,
    String recordId,
    String recordCode, {
    String? tabModuleCode,
    String? subTabModuleCode,
    String? revisionId,
    String? documentTypeId,
  }) async {
    final startTime = DateTime.now();
    
    try {
      logger.i('📤 Starting file upload: $fileName (${fileBytes.length} bytes)');
      
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        logger.e('❌ No user info found for upload');
        return null;
      }

      // Use the provided tabModuleCode or default to 'DOC' for backward compatibility
      final effectiveTabModuleCode = tabModuleCode ?? 'DOC';
      final url = '${hosts.coreUrl}$moduleCode.$effectiveTabModuleCode?action=UploadFile';

      // Get cookies from saved login (if any)
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
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }

      _logAuthentication(
        context: 'File Upload',
        token: bonitaToken,
        cookies: cookies,
      );

      // Determine final tabModuleCode value (same logic for both formData and logging)
      // Priority: subTabModuleCode > tabModuleCode > effectiveTabModuleCode
      final finalTabModuleCode = subTabModuleCode ?? tabModuleCode ?? effectiveTabModuleCode;

      // Create FormData for multipart upload
      final Map<String, dynamic> formDataMap = {
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(_getMimeType(fileName)),
        ),
        'userId': userId,
        'userName': userName,
        'recordId': recordId,
        'recordCode': recordCode,
        'moduleCode': moduleCode,
        'tabModuleCode': finalTabModuleCode,
      };

      // Add optional revision and document type parameters
      if (revisionId != null && revisionId.isNotEmpty) {
        formDataMap['revisionId'] = revisionId;
      }
      if (documentTypeId != null && documentTypeId.isNotEmpty) {
        formDataMap['documentTypeId'] = documentTypeId;
      }

      final formData = FormData.fromMap(formDataMap);

      final headers = <String, String>{
        'Content-Type': 'multipart/form-data',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };

      // Create JSON-like payload for logging (excluding file bytes) - SAME as formDataMap
      final logPayload = <String, dynamic>{
        'fileName': fileName,
        'fileSize': '${fileBytes.length} bytes',
        'fileType': _getMimeType(fileName),
        'userId': userId,
        'userName': userName,
        'recordId': recordId,
        'recordCode': recordCode,
        'moduleCode': moduleCode,
        'tabModuleCode': finalTabModuleCode, // Same value as formDataMap
      };

      // Add optional revision and document type parameters to log
      if (revisionId != null && revisionId.isNotEmpty) {
        logPayload['revisionId'] = revisionId;
      }
      if (documentTypeId != null && documentTypeId.isNotEmpty) {
        logPayload['documentTypeId'] = documentTypeId;
      }

      // Add debug info to show the logic used (priority: subTab > tab > default)
      if (subTabModuleCode != null) {
        logPayload['_debug_tabModuleSource'] = 'subTabModuleCode (current subTab)';
        logPayload['_debug_originalTabCode'] = tabModuleCode ?? effectiveTabModuleCode;
      } else if (tabModuleCode != null) {
        logPayload['_debug_tabModuleSource'] = 'provided tabModuleCode';
      } else {
        logPayload['_debug_tabModuleSource'] = 'effectiveTabModuleCode (default)';
      }

      _logApiRequest(
        method: 'POST',
        url: url,
        headers: headers,
        payload: logPayload,
        action: null, // URL already contains action
      );

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            // Accept more status codes to get proper error response
            return status != null && (status >= 200 && status < 600);
          },
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      
      // Check if response indicates session expired (401 or specific error)
      if (response.statusCode == 401) {
        _logAuthentication(
          context: 'Upload Failed',
          isExpired: true,
        );
        return null;
      }
      
      _logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: logPayload, // Use logPayload instead of formDataMap (which contains MultipartFile)
      );
      
      // Handle different response status codes
      if (response.data != null) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data);

        // Handle successful responses (200)
        if (response.statusCode == 200) {
          return responseData;
        }

        // Handle client errors (400) that may contain valid data
        if (response.statusCode == 400) {
          logger.w('⚠️ Upload returned 400 with data');
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Bad Request',
              ...responseData,
            };
          }
        }

        // Handle server errors (500) that may contain error details
        if (response.statusCode == 500) {
          logger.e('❌ Upload returned 500 - Server Error');
          if (responseData is Map<String, dynamic>) {
            return {
              'success': false,
              'messageType': 'error',
              'message': responseData['message'] ?? 'Internal Server Error',
              'statusCode': 500,
              ...responseData,
            };
          } else {
            return {
              'success': false,
              'messageType': 'error',
              'message': 'Internal Server Error - ${responseData.toString()}',
              'statusCode': 500,
            };
          }
        }

        // Handle other status codes
        return {
          'success': false,
          'messageType': 'error',
          'message': 'HTTP ${response.statusCode}: ${response.statusMessage ?? 'Unknown error'}',
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }

      // No response data
      return {
        'success': false,
        'messageType': 'error',
        'message': 'No response data received',
        'statusCode': response.statusCode,
      };
    } catch (e, stack) {
      _logApiError(
        url: '${hosts.coreUrl}$moduleCode.${tabModuleCode ?? 'DOC'}?action=UploadFile',
        error: e,
        stackTrace: stack,
        context: 'uploadFile',
      );
      
      // Check if error is due to session expiry
      if (e is DioException && e.response?.statusCode == 401) {
        _logAuthentication(
          context: 'Upload Error',
          isExpired: true,
        );
        return null;
      }
      
      // Handle DioException with status 400 (which may contain valid response data)
      if (e is DioException && e.response?.statusCode == 400 && e.response?.data != null) {
        logger.w('⚠️ Upload DioException 400 with response data');
        try {
          final responseData = e.response?.data is Map<String, dynamic>
              ? e.response?.data
              : jsonDecode(e.response?.data);
              
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Upload failed',
              ...responseData,
            };
          }
        } catch (parseError) {
          logger.e('❌ Error parsing 400 response data: $parseError');
        }
      }
      
      return null;
    }
  }

  /// Save action for current tab
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
    
    final result = await performAction(moduleCode, tabModuleCode, 'SAVE', payload);
    
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
    
    final result = await performAction(moduleCode, tabModuleCode, 'SUBMIT', payload);
    
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
    
    final result = await performAction(moduleCode, effectiveTabModuleCode, 'COPY', payload);
    
    if (result != null) {
      logger.i('📋 COPY Response Analysis:');
      logger.i('  • Success: ${result['success'] ?? false}');
      logger.i('  • Message Type: ${result['messageType'] ?? 'N/A'}');
      logger.i('  • Message: ${result['message'] ?? 'N/A'}');
      
      if (result['itemDetail'] != null && result['itemDetail']['value'] != null) {
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
    
    final result = await performAction(moduleCode, effectiveTabModuleCode, 'CANCEL', payload);
    
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
      "listItem": itemDetail['value'] ?? itemDetail, // Use itemDetail.value as listItem
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };
    
    logger.i('🗑️ DELETE Action Details:');
    logger.i('  • Module: $moduleCode.$effectiveTabModuleCode');
    logger.i('  • User: ${user['fullName'] ?? user['code']}');
    logger.i('  • Target Record: ${dataSpy['code'] ?? 'Unknown'}');
    logger.i('  • ⚠️ Permanent deletion requested');
    
    final result = await performAction(moduleCode, effectiveTabModuleCode, 'DELETE', payload);
    
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
    
    final result = await performAction(moduleCode, effectiveTabModuleCode, 'DELETE', payload);
    
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
    // Create payload with special task-specific fields
    final payload = {
      "user": user,
      "itemDetail": itemDetail,
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
    logger.i('  • Workflow Impact: Task will be ${isApproved ? 'moved to next step' : 'returned to initiator'}');
    
    final result = await performAction(moduleCode, tabModuleCode, 'SUBMIT_FORM', payload);
    
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

  /// Generic method to fetch dropdown data using GET request
  Future<Map<String, dynamic>> getDropdownData(String endpoint) async {
    final startTime = DateTime.now();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        logger.e('❌ No user info found for dropdown');
        return {'success': false, 'message': 'No user info found'};
      }
      
      final url = '${hosts.coreUrl}$endpoint';

      // Get cookies from saved login (if any)
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
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };

      _logApiRequest(
        method: 'GET',
        url: url,
        headers: headers,
        payload: null,
        action: 'GET_DROPDOWN',
      );

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );
      
      final duration = DateTime.now().difference(startTime);
      
      if (response.statusCode == 401) {
        _logAuthentication(
          context: 'Dropdown Request',
          isExpired: true,
        );
        return {'success': false, 'message': 'Session expired'};
      }
      
      _logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: null,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        // Handle different response types
        dynamic data;
        if (response.data is List) {
          // API returned a List directly
          data = response.data;
        } else if (response.data is Map<String, dynamic>) {
          // API returned a Map directly
          data = response.data;
        } else if (response.data is String) {
          // API returned a JSON string that needs to be decoded
          try {
            data = jsonDecode(response.data);
          } catch (e) {
            logger.e('❌ Error decoding JSON response: $e');
            return {'success': false, 'message': 'Invalid JSON response'};
          }
        } else {
          // Unknown response type
          data = response.data;
        }
        
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'No data received'};
    } catch (e, stack) {
      _logApiError(
        url: '${hosts.coreUrl}$endpoint',
        error: e,
        stackTrace: stack,
        context: 'getDropdownData',
      );
      
      if (e is DioException && e.response?.statusCode == 401) {
        _logAuthentication(
          context: 'Dropdown Error',
          isExpired: true,
        );
        return {'success': false, 'message': 'Session expired'};
      }
      
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Generic method to make API calls with session cookies and authentication
  Future<Map<String, dynamic>?> _makeApiCall(String endpoint, Map<String, dynamic> payload) async {
    final startTime = DateTime.now();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        logger.e('❌ No user info found');
        return null;
      }
      final url = '${hosts.coreUrl}$endpoint';

      // Get cookies from saved login (if any)
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
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          // Only get the part before ; if any
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };

      final bool isActionCall = endpoint.contains('?action=');
      final action = isActionCall 
          ? endpoint.split('action=').last.split('&').first 
          : null;

      _logApiRequest(
        method: 'POST',
        url: url,
        headers: headers,
        payload: payload,
        action: action,
      );

      // Normalize itemDetail.tree so server always receives latest tree changes
      try {
        if (payload['itemDetail'] is Map) {
          final id = payload['itemDetail'] as Map;
          dynamic tree = id['tree'];
          if (tree == null && id['value'] is Map) {
            final v = id['value'] as Map;
            if (v['tree'] != null) tree = v['tree'];
          }
          if (tree != null) {
            if (tree is List) {
              id['tree'] = {'data': tree};
            } else if (tree is Map) {
              // Ensure data exists as list if children provided
              id['tree'] = tree;
            }
          }
        }
      } catch (_) {
        // ignore normalization errors
      }

      final response = await _dio.post(
        url,
        data: jsonEncode(payload),
        options: Options(
          headers: headers,
          validateStatus: (status) {
            // Accept 200 and 400 as before; 401/500 will be handled in catch as DioException
            return status != null && (status == 200 || status == 400);
          },
        ),
      );

      final duration = DateTime.now().difference(startTime);

      // Check if response indicates session expired (401 or specific error)
      if (response.statusCode == 401) {
        _logAuthentication(
          context: 'API Call Failed',
          isExpired: true,
        );
        return null;
      }

      _logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: payload,
      );
      
      // Handle successful responses (200) and client errors (400) that may contain valid data
      if ((response.statusCode == 200 || response.statusCode == 400) && response.data != null) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data);
            
        // For status 400, still return the data as it may contain messageType info
        if (response.statusCode == 400) {
          logger.w('⚠️ API returned 400 with data');
          // Ensure we have proper structure for error responses
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Unknown error occurred',
              ...responseData, // Include any additional fields
            };
          }
        }
        
        return responseData;
      }
      return null;
    } catch (e, stack) {
      _logApiError(
        url: '${hosts.coreUrl}$endpoint',
        error: e,
        stackTrace: stack,
        context: '_makeApiCall',
      );
      
      // Check if error is due to session expiry
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 401) {
          _logAuthentication(
            context: 'API Error',
            isExpired: true,
          );
          return null;
        }
        
        // Handle DioException with status 400 (which may contain valid response data)
        if (status == 400 && e.response?.data != null) {
          logger.w('⚠️ DioException 400 with response data');
          try {
            final responseData = e.response?.data is Map<String, dynamic>
                ? e.response?.data
                : jsonDecode(e.response?.data);
                
            if (responseData is Map<String, dynamic>) {
              return {
                'success': responseData['success'] ?? false,
                'messageType': responseData['messageType'] ?? 'error',
                'message': responseData['message'] ?? 'Request failed',
                ...responseData, // Include any additional fields
              };
            }
          } catch (parseError) {
            logger.e('❌ Error parsing 400 response data: $parseError');
          }
        }

        // NEW: Treat 5xx as generic server error (do NOT trigger session expired)
        if (status != null && status >= 500) {
          logger.e('🚨 Server error - Status: $status');
          return {
            'success': false,
            'messageType': 'error',
            'message': 'Server error. Please try again later.',
            'statusCode': status,
          };
        }

        // NEW: Network or unknown Dio error (no status)
        if (status == null) {
          logger.e('🌐 Network error - Check connection');
          return {
            'success': false,
            'messageType': 'error',
            'message': 'Network error. Please check your connection and try again.',
          };
        }
      }
      
      // Do not treat as session expired; return a generic error map
      return {
        'success': false,
        'messageType': 'error',
        'message': 'Unexpected error. Please try again.',
      };
    }
  }

  /// Download file with proper headers and payload structure
  /// Returns response with file data
  static Future<Map<String, dynamic>?> downloadFile(
    String moduleCode,
    Map<String, dynamic> userInfo,
    Map<String, dynamic> fileData, {
    String? tabModuleCode,
    String? subTabModuleCode,
  }) async {
    final startTime = DateTime.now();
    
    try {
      logger.i('📥 Starting file download');
      logger.i('  • Module: $moduleCode');
      logger.i('  • File: ${fileData['fileName'] ?? 'Unknown'}');
      
      // Get session data
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        logger.e('❌ No user info found for download');
        return null;
      }

      // Get cookies from saved login (if any)
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
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }
      
      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };
      
      // Build payload
      final payload = {
        'user': {
          'id': userInfo['id'],
          'code': userInfo['code'],
          'fullName': userInfo['fullName'],
          'phone': userInfo['phone'],
          'email': userInfo['email'],
          'personalEmail': userInfo['personalEmail'],
          'position': userInfo['position'],
          'createdDate': userInfo['createdDate'],
          'managerFullName': userInfo['managerFullName'],
          'roles': userInfo['roles'] ?? [],
        },
        'moduleCode': moduleCode,
        'tabModuleCode': subTabModuleCode ?? tabModuleCode ?? 'DOC',
        'file': fileData,
      };
      
      // Make API call
      final effectiveTabModuleCode = tabModuleCode ?? 'DOC';
      final url = '${hosts.coreUrl}$moduleCode.$effectiveTabModuleCode?action=DownloadFile';


      instance._logApiRequest(
        method: 'POST',
        url: url,
        headers: headers,
        payload: payload,
        action: 'DownloadFile',
      );
      
      final response = await Dio().post(
        url,
        data: payload,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return status != null && (status == 200 || status == 400);
          },
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      
      // Check if response indicates session expired (401 or specific error)
      if (response.statusCode == 401) {
        instance._logAuthentication(
          context: 'Download Failed',
          isExpired: true,
        );
        return null;
      }
      
      instance._logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: payload,
      );
      
      // Handle successful responses (200) and client errors (400) that may contain valid data
      if ((response.statusCode == 200 || response.statusCode == 400) && response.data != null) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data);
            
        // For status 400, still return the data as it may contain messageType info
        if (response.statusCode == 400) {
          logger.w('⚠️ Download returned 400 with data');
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Download failed',
              ...responseData,
            };
          }
        }
        
        return responseData;
      }
      return null;
    } catch (e, stack) {
      instance._logApiError(
        url: '${hosts.coreUrl}$moduleCode.${tabModuleCode ?? 'DOC'}?action=DownloadFile',
        error: e,
        stackTrace: stack,
        context: 'downloadFile',
      );
      
      // Check if error is due to session expiry
      if (e is DioException && e.response?.statusCode == 401) {
        instance._logAuthentication(
          context: 'Download Error',
          isExpired: true,
        );
        return null;
      }
      
      // Handle DioException with status 400 (which may contain valid response data)
      if (e is DioException && e.response?.statusCode == 400 && e.response?.data != null) {
        logger.w('⚠️ Download DioException 400 with response data');
        try {
          final responseData = e.response?.data is Map<String, dynamic>
              ? e.response?.data
              : jsonDecode(e.response?.data);
              
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Download failed',
              ...responseData,
            };
          }
        } catch (parseError) {
          logger.e('❌ Error parsing 400 response data: $parseError');
        }
      }
      
      throw e;
    }
  }

  /// Delete file with proper headers and payload structure
  /// Returns response similar to module tab load
  /// @param tabModuleCode: Main tab code for URL (e.g., 'DOC', 'CMDRMD')
  /// @param subTabCode: Optional subtab code for payload (when DOC has sub-tabs)
  static Future<Map<String, dynamic>?> deleteFile(
    String moduleCode,
    Map<String, dynamic> userInfo,
    Map<String, dynamic> fileData, {
    String? tabModuleCode,
    String? subTabCode,
  }) async {
    final startTime = DateTime.now();
    
    try {
      logger.i('🗑️ Starting file deletion');
      logger.i('  • Module: $moduleCode');
      logger.i('  • File: ${fileData['fileName'] ?? 'Unknown'}');
      if (subTabCode != null) {
        logger.i('  • Sub-tab: $subTabCode');
      }
      
      // Get session data
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        logger.e('❌ No user info found for delete');
        return null;
      }

      // Get cookies from saved login (if any)
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
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }
      
      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };
      
      // Build payload
      final payload = {
        'user': {
          'id': userInfo['id'],
          'code': userInfo['code'],
          'fullName': userInfo['fullName'],
          'phone': userInfo['phone'],
          'email': userInfo['email'],
          'personalEmail': userInfo['personalEmail'],
          'position': userInfo['position'],
          'createdDate': userInfo['createdDate'],
          'managerFullName': userInfo['managerFullName'],
          'roles': userInfo['roles'] ?? [],
        },
        'moduleCode': moduleCode,
        'tabModuleCode': subTabCode ?? tabModuleCode ?? 'DOC', // Use subTabCode if provided, otherwise use tabModuleCode, default to 'DOC'
        'file': fileData,
      };
      
      // Make API call - Use tabModuleCode for URL, default to 'DOC' if not provided
      final effectiveTabModuleCode = tabModuleCode ?? 'DOC';
      final url = '${hosts.coreUrl}$moduleCode.$effectiveTabModuleCode?action=DeleteFile';
      
      instance._logApiRequest(
        method: 'POST',
        url: url,
        headers: headers,
        payload: payload,
        action: 'DeleteFile',
      );
      
      // Use the regular Dio instance - headers already contain cookies
      final response = await Dio().post(
        url,
        data: payload,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            // Accept 200, 400, and 403 as valid responses to handle properly
            return status != null && (status == 200 || status == 400 || status == 403);
          },
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      
      // Check if response indicates session expired (401 or specific error)
      if (response.statusCode == 401) {
        instance._logAuthentication(
          context: 'Delete Failed',
          isExpired: true,
        );
        return null;
      }
      
      instance._logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: payload,
      );
      
      // Handle responses including 403 (Forbidden)
      if (response.statusCode == 403) {
        logger.w('⚠️ Delete returned 403 - Forbidden');
        return {
          'success': false,
          'messageType': 'error',
          'message': 'Permission denied. You do not have permission to delete this file.',
          'statusCode': 403,
        };
      }
      
      // Handle successful responses (200) and client errors (400) that may contain valid data
      if ((response.statusCode == 200 || response.statusCode == 400) && response.data != null) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data);
            
        // For status 400, still return the data as it may contain messageType info
        if (response.statusCode == 400) {
          logger.w('⚠️ Delete returned 400 with data');
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Delete failed',
              ...responseData,
            };
          }
        }
        
        return responseData;
      }
      return null;
    } catch (e, stack) {
      instance._logApiError(
        url: '${hosts.coreUrl}$moduleCode.${tabModuleCode ?? 'DOC'}?action=DeleteFile',
        error: e,
        stackTrace: stack,
        context: 'deleteFile',
      );
      
      // Check if error is due to session expiry
      if (e is DioException && e.response?.statusCode == 401) {
        instance._logAuthentication(
          context: 'Delete Error',
          isExpired: true,
        );
        return null;
      }
      
      // Handle DioException with status 400 (which may contain valid response data)
      if (e is DioException && e.response?.statusCode == 400 && e.response?.data != null) {
        logger.w('⚠️ Delete DioException 400 with response data');
        try {
          final responseData = e.response?.data is Map<String, dynamic>
              ? e.response?.data
              : jsonDecode(e.response?.data);
              
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Delete failed',
              ...responseData,
            };
          }
        } catch (parseError) {
          logger.e('❌ Error parsing 400 response data: $parseError');
        }
      }
      
      throw e;
    }
  }

  /// Get MIME type based on file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'rtf':
        return 'application/rtf';
      case 'epub':
        return 'application/epub+zip';

      // Word
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'docm':
        return 'application/vnd.ms-word.document.macroEnabled.12';
      case 'dot':
        return 'application/msword';
      case 'dotx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.template';
      case 'dotm':
        return 'application/vnd.ms-word.template.macroEnabled.12';

      // Excel
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xlsm':
        return 'application/vnd.ms-excel.sheet.macroEnabled.12';
      case 'xltx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.template';
      case 'xltm':
        return 'application/vnd.ms-excel.template.macroEnabled.12';
      case 'xlam':
        return 'application/vnd.ms-excel.addin.macroEnabled.12';
      case 'xlsb':
        return 'application/vnd.ms-excel.sheet.binary.macroEnabled.12';
      case 'csv':
        return 'text/csv';
      case 'tsv':
        return 'text/tab-separated-values';

      // PowerPoint
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'pptm':
        return 'application/vnd.ms-powerpoint.presentation.macroEnabled.12';
      case 'potx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.template';
      case 'potm':
        return 'application/vnd.ms-powerpoint.template.macroEnabled.12';
      case 'pps':
        return 'application/vnd.ms-powerpoint';
      case 'ppsx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.slideshow';
      case 'ppsm':
        return 'application/vnd.ms-powerpoint.slideshow.macroEnabled.12';

      // OpenDocument formats
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      case 'ott':
        return 'application/vnd.oasis.opendocument.text-template';
      case 'ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case 'ots':
        return 'application/vnd.oasis.opendocument.spreadsheet-template';
      case 'odp':
        return 'application/vnd.oasis.opendocument.presentation';
      case 'otp':
        return 'application/vnd.oasis.opendocument.presentation-template';

      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      case 'webp':
        return 'image/webp';
      case 'svg':
      case 'svgz':
        return 'image/svg+xml';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'ico':
        return 'image/x-icon';

      // Text / Markup / Code
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'md':
      case 'markdown':
        return 'text/markdown';
      case 'yaml':
      case 'yml':
        return 'application/x-yaml';
      case 'ini':
      case 'log':
        return 'text/plain';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';

      // Archives / Compressed
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';
      case 'tgz':
        return 'application/gzip';
      case 'bz2':
        return 'application/x-bzip2';
      case 'xz':
        return 'application/x-xz';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'aac':
        return 'audio/aac';

      // Video
      case 'mp4':
        return 'video/mp4';
      case 'm4v':
        return 'video/x-m4v';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';

      default:
        return 'application/octet-stream';
    }
  }

  // Pretty-print large JSON and log in chunks to avoid truncation

}

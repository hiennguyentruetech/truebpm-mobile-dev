part of 'core_service.dart';

extension CoreServiceFileApiExt on CoreService {
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
      logger.i(
        '📤 Starting file upload: $fileName (${fileBytes.length} bytes)',
      );

      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        logger.e('❌ No user info found for upload');
        return null;
      }

      // Use the provided tabModuleCode or default to 'DOC' for backward compatibility
      final effectiveTabModuleCode = tabModuleCode ?? 'DOC';
      final url =
          '${hosts.coreUrl}$moduleCode.$effectiveTabModuleCode?action=UploadFile';

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
      final finalTabModuleCode =
          subTabModuleCode ?? tabModuleCode ?? effectiveTabModuleCode;

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
        logPayload['_debug_tabModuleSource'] =
            'subTabModuleCode (current subTab)';
        logPayload['_debug_originalTabCode'] =
            tabModuleCode ?? effectiveTabModuleCode;
      } else if (tabModuleCode != null) {
        logPayload['_debug_tabModuleSource'] = 'provided tabModuleCode';
      } else {
        logPayload['_debug_tabModuleSource'] =
            'effectiveTabModuleCode (default)';
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
        _logAuthentication(context: 'Upload Failed', isExpired: true);
        return null;
      }

      _logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload:
            logPayload, // Use logPayload instead of formDataMap (which contains MultipartFile)
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
          'message':
              'HTTP ${response.statusCode}: ${response.statusMessage ?? 'Unknown error'}',
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
        url:
            '${hosts.coreUrl}$moduleCode.${tabModuleCode ?? 'DOC'}?action=UploadFile',
        error: e,
        stackTrace: stack,
        context: 'uploadFile',
      );

      // Check if error is due to session expiry
      if (e is DioException && e.response?.statusCode == 401) {
        _logAuthentication(context: 'Upload Error', isExpired: true);
        return null;
      }

      // Handle DioException with status 400 (which may contain valid response data)
      if (e is DioException &&
          e.response?.statusCode == 400 &&
          e.response?.data != null) {
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

      final response = await _dio.get(url, options: Options(headers: headers));

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 401) {
        _logAuthentication(context: 'Dropdown Request', isExpired: true);
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
        _logAuthentication(context: 'Dropdown Error', isExpired: true);
        return {'success': false, 'message': 'Session expired'};
      }

      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

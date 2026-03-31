part of 'core_service.dart';

class CoreService {
  static final CoreService _instance = CoreService._internal();
  static CoreService get instance => _instance;

  CoreService._internal();

  final Dio _dio = Dio();

  // ============================================================================
  // API METHODS WITH ENHANCED LOGGING
  // ============================================================================

  /// Generic method to fetch paged data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchPagedData(
    String moduleCode,
    Map<String, dynamic> payload,
  ) async {
    return _makeApiCall('$moduleCode.PAGEDATA', payload);
  }

  /// Generic method to fetch list data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchListData(
    String moduleCode,
    Map<String, dynamic> payload,
  ) async {
    return _makeApiCall('$moduleCode.LST', payload);
  }

  /// Generic method to fetch detail data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchDetailData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> payload,
  ) async {
    return _makeApiCall('$moduleCode.$tabModuleCode', payload);
  }

  /// Fetch data for creating new records with action=NEW parameter
  Future<Map<String, dynamic>?> fetchNewRecordData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> payload,
  ) async {
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

  // ============================================================================
  // SEMANTIC ACTION METHODS (self-documenting API)
  // ============================================================================

  /// Save data for a specific module and tab
  Future<Map<String, dynamic>?> saveData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> userData,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    return performAction(moduleCode, tabModuleCode, 'SAVE', {
      'user': userData,
      'itemDetail': itemDetail,
      'dataSpy': dataSpy,
    });
  }

  /// Submit data for a specific module and tab
  Future<Map<String, dynamic>?> submitData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> userData,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    return performAction(moduleCode, tabModuleCode, 'SUBMIT', {
      'user': userData,
      'itemDetail': itemDetail,
      'dataSpy': dataSpy,
    });
  }

  /// Copy data for a specific module and tab
  Future<Map<String, dynamic>?> copyData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> userData,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    return performAction(moduleCode, tabModuleCode, 'COPY', {
      'user': userData,
      'itemDetail': itemDetail,
      'dataSpy': dataSpy,
    });
  }

  /// Cancel data for a specific module and tab
  Future<Map<String, dynamic>?> cancelData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> userData,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    return performAction(moduleCode, tabModuleCode, 'CANCEL', {
      'user': userData,
      'itemDetail': itemDetail,
      'dataSpy': dataSpy,
    });
  }

  /// Delete data for a specific module and tab
  Future<Map<String, dynamic>?> deleteData(
    String moduleCode,
    String tabModuleCode,
    Map<String, dynamic> userData,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    return performAction(moduleCode, tabModuleCode, 'DELETE', {
      'user': userData,
      'itemDetail': itemDetail,
      'dataSpy': dataSpy,
    });
  }

  /// Generic method to make API calls with session cookies and authentication
  Future<Map<String, dynamic>?> _makeApiCall(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final startTime = DateTime.now();

    try {
      // Get session data (cookies, token, headers)
      final session = await _getSessionData();
      final url = '${hosts.coreUrl}$endpoint';

      final bool isActionCall = endpoint.contains('?action=');
      final action = isActionCall
          ? endpoint.split('action=').last.split('&').first
          : null;

      _logApiRequest(
        method: 'POST',
        url: url,
        headers: session.headers,
        payload: payload,
        action: action,
      );

      // Normalize itemDetail.tree before sending
      if (payload['itemDetail'] is Map) {
        final itemDetailMap = payload['itemDetail'] as Map;
        dynamic tree = itemDetailMap['tree'];
        if (tree == null && itemDetailMap['value'] is Map) {
          tree = (itemDetailMap['value'] as Map)['tree'];
        }
        if (tree != null) {
          if (tree is List) {
            itemDetailMap['tree'] = {'data': tree};
          } else if (tree is Map) {
            itemDetailMap['tree'] = tree;
          }
        }
      }

      // Make API call
      final response = await _dio.post(
        url,
        data: jsonEncode(payload),
        options: Options(
          headers: session.headers,
          validateStatus: (status) {
            return status != null && (status == 200 || status == 400);
          },
        ),
      );

      final duration = DateTime.now().difference(startTime);

      // Check if session expired
      if (response.statusCode == 401) {
        _logAuthentication(context: 'API Call Failed', isExpired: true);
        return null;
      }

      _logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: payload,
      );

      return _handleApiResponseSuccess(response);
    } on Exception catch (e) {
      if (e.toString().contains('No user info found')) {
        logger.e('❌ No user info found');
        return null;
      }
      rethrow;
    } catch (e, stack) {
      _logApiError(
        url: '${hosts.coreUrl}$endpoint',
        error: e,
        stackTrace: stack,
        context: '_makeApiCall',
      );

      // Check if session expired
      if (e is DioException && e.response?.statusCode == 401) {
        _logAuthentication(context: 'API Error', isExpired: true);
        return null;
      }

      return _handleApiError(e, errorMessage: 'API call failed');
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
      final session = await instance._getSessionData();

      // Build payload using helper
      final payload = {
        'user': instance._buildUserPayload(userInfo),
        'moduleCode': moduleCode,
        'tabModuleCode': subTabModuleCode ?? tabModuleCode ?? 'DOC',
        'file': fileData,
      };

      // Make API call
      final effectiveTabModuleCode = tabModuleCode ?? 'DOC';
      final url =
          '${hosts.coreUrl}$moduleCode.$effectiveTabModuleCode?action=DownloadFile';

      instance._logApiRequest(
        method: 'POST',
        url: url,
        headers: session.headers,
        payload: payload,
        action: 'DownloadFile',
      );

      final response = await Dio().post(
        url,
        data: payload,
        options: Options(
          headers: session.headers,
          validateStatus: (status) {
            return status != null && (status == 200 || status == 400);
          },
        ),
      );

      final duration = DateTime.now().difference(startTime);

      // Check if session expired
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

      return instance._handleApiResponseSuccess(
        response,
        failureMessage: 'Download failed',
      );
    } catch (e, stack) {
      instance._logApiError(
        url:
            '${hosts.coreUrl}$moduleCode.${tabModuleCode ?? 'DOC'}?action=DownloadFile',
        error: e,
        stackTrace: stack,
        context: 'downloadFile',
      );

      // Check if session expired
      if (e is DioException && e.response?.statusCode == 401) {
        instance._logAuthentication(context: 'Download Error', isExpired: true);
        return null;
      }

      return instance._handleApiError(e, errorMessage: 'Download failed');
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
      final session = await instance._getSessionData();

      // Build payload using helper
      final payload = {
        'user': instance._buildUserPayload(userInfo),
        'moduleCode': moduleCode,
        'tabModuleCode': subTabCode ?? tabModuleCode ?? 'DOC',
        'file': fileData,
      };

      // Make API call - Use tabModuleCode for URL, default to 'DOC' if not provided
      final effectiveTabModuleCode = tabModuleCode ?? 'DOC';
      final url =
          '${hosts.coreUrl}$moduleCode.$effectiveTabModuleCode?action=DeleteFile';

      instance._logApiRequest(
        method: 'POST',
        url: url,
        headers: session.headers,
        payload: payload,
        action: 'DeleteFile',
      );

      final response = await Dio().post(
        url,
        data: payload,
        options: Options(
          headers: session.headers,
          validateStatus: (status) {
            return status != null &&
                (status == 200 || status == 400 || status == 403);
          },
        ),
      );

      final duration = DateTime.now().difference(startTime);

      // Check if session expired
      if (response.statusCode == 401) {
        instance._logAuthentication(context: 'Delete Failed', isExpired: true);
        return null;
      }

      instance._logApiResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        url: url,
        duration: duration,
        requestPayload: payload,
      );

      // Handle 403 Forbidden
      if (response.statusCode == 403) {
        logger.w('⚠️ Delete returned 403 - Forbidden');
        return {
          'success': false,
          'messageType': 'error',
          'message':
              'Permission denied. You do not have permission to delete this file.',
          'statusCode': 403,
        };
      }

      return instance._handleApiResponseSuccess(
        response,
        failureMessage: 'Delete failed',
      );
    } catch (e, stack) {
      instance._logApiError(
        url:
            '${hosts.coreUrl}$moduleCode.${tabModuleCode ?? 'DOC'}?action=DeleteFile',
        error: e,
        stackTrace: stack,
        context: 'deleteFile',
      );

      // Check if session expired
      if (e is DioException && e.response?.statusCode == 401) {
        instance._logAuthentication(context: 'Delete Error', isExpired: true);
        return null;
      }

      return instance._handleApiError(e, errorMessage: 'Delete failed');
    }
  }

  // Pretty-print large JSON and log in chunks to avoid truncation
}

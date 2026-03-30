part of 'core_service.dart';

extension CoreServiceTaskApiExt on CoreService {
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

      final url =
          '${hosts.bpmUrl}humanTask?c=1000&d=rootContainerId&f=state%3Dready&f=user_id%3D$userId&p=0';

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

      final payload = {'assigned_id': userId};

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
}

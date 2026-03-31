part of 'core_service.dart';

/// Data class to hold session information (cookies, token, headers)
class _SessionData {
  final List<String> cookies;
  final String? bonitaToken;
  final Map<String, String> headers;

  _SessionData({
    required this.cookies,
    required this.bonitaToken,
    required this.headers,
  });
}

/// Extension containing session and data handling helpers
extension _CoreServiceHelpers on CoreService {
  /// Get session data (cookies, token, headers) from SharedPreferences
  /// Throws exception if user info not found
  Future<_SessionData> _getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonStr = prefs.getString('user_info');
    if (userJsonStr == null) {
      throw Exception('No user info found');
    }

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

    final bonitaToken = _extractBonitaToken(cookies);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
      if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
    };

    return _SessionData(
      cookies: cookies,
      bonitaToken: bonitaToken,
      headers: headers,
    );
  }

  /// Extract X-Bonita-API-Token from cookies list
  String? _extractBonitaToken(List<String> cookies) {
    for (final c in cookies) {
      final cookiePair = c.split(';')[0];
      final parts = cookiePair.split('=');
      if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
        return parts[1];
      }
    }
    return null;
  }

  /// Build standardized user object for API payload
  Map<String, dynamic> _buildUserPayload(Map<String, dynamic> userInfo) {
    return {
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
    };
  }

  /// Handle API response success (200 or 400 status)
  Map<String, dynamic>? _handleApiResponseSuccess(
    Response response, {
    String? failureMessage = 'Operation failed',
  }) {
    if ((response.statusCode == 200 || response.statusCode == 400) &&
        response.data != null) {
      final responseData = response.data is Map<String, dynamic>
          ? response.data
          : jsonDecode(response.data);

      if (response.statusCode == 400) {
        logger.w('⚠️ API returned 400 with data');
        if (responseData is Map<String, dynamic>) {
          return {
            'success': responseData['success'] ?? false,
            'messageType': responseData['messageType'] ?? 'error',
            'message': responseData['message'] ?? failureMessage,
            ...responseData,
          };
        }
      }

      return responseData;
    }
    return null;
  }

  /// Handle API error response (400, 403, etc.)
  Map<String, dynamic> _handleApiError(
    dynamic error, {
    String? errorMessage = 'Unexpected error',
  }) {
    if (error is DioException) {
      final status = error.response?.statusCode;

      // Handle 400 response with data
      if (status == 400 && error.response?.data != null) {
        logger.w('⚠️ DioException 400 with response data');
        try {
          final responseData = error.response?.data is Map<String, dynamic>
              ? error.response?.data
              : jsonDecode(error.response?.data);

          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? errorMessage,
              ...responseData,
            };
          }
        } catch (parseError) {
          logger.e('❌ Error parsing 400 response data: $parseError');
        }
      }

      // Handle 5xx server errors
      if (status != null && status >= 500) {
        logger.e('🚨 Server error - Status: $status');
        return {
          'success': false,
          'messageType': 'error',
          'message': 'Server error. Please try again later.',
          'statusCode': status,
        };
      }

      // Handle network errors
      if (status == null) {
        logger.e('🌐 Network error - Check connection');
        return {
          'success': false,
          'messageType': 'error',
          'message':
              'Network error. Please check your connection and try again.',
        };
      }
    }

    return {'success': false, 'messageType': 'error', 'message': errorMessage};
  }

  /// Get MIME type based on file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return kMimeTypeMap[extension] ?? 'application/octet-stream';
  }
}

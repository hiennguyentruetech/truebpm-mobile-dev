part of 'core_service.dart';

/// Extension containing all API logging methods
extension _CoreServiceLogging on CoreService {
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
    final endpoint = action != null && !url.contains('?action=')
        ? '$url?action=$action'
        : url;

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
    logger.i(
      '┌────────────────────────────────────────────────────────────────────',
    );
    logger.i('│ 🔐 AUTHENTICATION: $context');
    logger.i(
      '├────────────────────────────────────────────────────────────────────',
    );

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

    logger.i(
      '└────────────────────────────────────────────────────────────────────',
    );
  }
}

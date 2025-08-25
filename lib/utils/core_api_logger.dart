import 'dart:convert';

class CoreApiLogger {

  /// Log API request with full details
  static void logApiRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? payload,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    
    // Start with top border
    print('\n┌────────────────────────────────────────────────────────────────────');
    print('│ 🚀 API REQUEST - $method');
    print('├────────────────────────────────────────────────────────────────────');
    print('│ ⏰ Timestamp: $timestamp');
    print('│ 📍 Endpoint: $endpoint');
    
    // Headers - Show full headers without truncation
    if (headers != null && headers.isNotEmpty) {
      print('│ 📋 Headers:');
      headers.forEach((key, value) {
        print('│   • $key: $value');
      });
    }
    
    // Payload
    if (payload != null && payload.isNotEmpty) {
      print('│ 📦 Payload:');
      final payloadStr = _formatJson(payload);
      // Print each line with prefix and bug emoji for payload
      for (final line in payloadStr.split('\n')) {
        print('│ 🐛 $line');
      }
    }
    
    print('└────────────────────────────────────────────────────────────────────\n');
  }

  /// Log API response with full details
  static void logApiResponse({
    required String method,
    required String endpoint,
    required int statusCode,
    Map<String, dynamic>? responseData,
    Duration? duration,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final emoji = _getStatusEmoji(statusCode);
    final statusText = _getStatusText(statusCode);
    
    // Start with top border
    print('\n┌────────────────────────────────────────────────────────────────────');
    print('│ $emoji API RESPONSE - $method');
    print('├────────────────────────────────────────────────────────────────────');
    print('│ ⏰ Timestamp: $timestamp');
    print('│ 📍 Endpoint: $endpoint');
    print('│ 📊 Status: $statusCode $statusText');
    
    // Duration
    if (duration != null) {
      print('│ ⏱️ Duration: ${duration.inMilliseconds}ms');
    }
    
    // Response Data
    if (responseData != null && responseData.isNotEmpty) {
      print('│ 📥 Response:');
      final responseStr = _formatJson(responseData);
      // Print each line with prefix and lightbulb emoji for response
      for (final line in responseStr.split('\n')) {
        print('│ 💡 $line');
      }
    }
    
    print('└────────────────────────────────────────────────────────────────────\n');
  }

  /// Log API error
  static void logApiError({
    required String method,
    required String endpoint,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? requestPayload,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    
    // Start with top border
    print('\n┌────────────────────────────────────────────────────────────────────');
    print('│ ❌ API ERROR - $method');
    print('├────────────────────────────────────────────────────────────────────');
    print('│ ⏰ Timestamp: $timestamp');
    print('│ 📍 Endpoint: $endpoint');
    print('│ ⚠️ Error: $error');
    
    // Request payload for debugging
    if (requestPayload != null && requestPayload.isNotEmpty) {
      print('│ 📦 Request Payload:');
      final payloadStr = _formatJson(requestPayload);
      // Print each line with prefix and bug emoji for payload
      for (final line in payloadStr.split('\n')) {
        print('│ 🐛 $line');
      }
    }
    
    if (stackTrace != null) {
      print('│ 📚 Stack Trace:');
      final stackLines = stackTrace.toString().split('\n');
      for (final line in stackLines.take(10)) { // Limit stack trace lines
        print('│ $line');
      }
      if (stackLines.length > 10) {
        print('│ ... ${stackLines.length - 10} more lines');
      }
    }
    
    print('└────────────────────────────────────────────────────────────────────\n');
  }

  /// Helper method to format JSON with proper indentation
  static String _formatJson(Map<String, dynamic> json) {
    try {
      // Always show full JSON, no matter the size
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(json);
      
      // Check if very large for warning message only
      if (formatted.length > 10000) {
        return '$formatted\n  ⚠️ Large response: ${formatted.length} characters';
      }
      
      return formatted;
    } catch (e) {
      return json.toString();
    }
  }

  /// Get appropriate emoji based on status code
  static String _getStatusEmoji(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return '✅';
    } else if (statusCode >= 400 && statusCode < 500) {
      return '⚠️';
    } else if (statusCode >= 500) {
      return '❌';
    } else {
      return '📡';
    }
  }
  
  /// Get status text description
  static String _getStatusText(int? status) {
    if (status == null) return 'Unknown';
    if (status == 200) return 'OK';
    if (status == 201) return 'Created';
    if (status == 204) return 'No Content';
    if (status == 400) return 'Bad Request';
    if (status == 401) return 'Unauthorized';
    if (status == 403) return 'Forbidden';
    if (status == 404) return 'Not Found';
    if (status == 500) return 'Internal Server Error';
    if (status == 502) return 'Bad Gateway';
    if (status == 503) return 'Service Unavailable';
    return '';
  }

  /// Check if response data is large
  static bool isLargePayload(Map<String, dynamic>? data) {
    if (data == null) return false;
    try {
      final jsonStr = jsonEncode(data);
      // Increased threshold since we want to show full JSON
      return jsonStr.length > 50000;
    } catch (e) {
      return false;
    }
  }
}

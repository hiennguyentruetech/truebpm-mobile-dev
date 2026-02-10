import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:truebpm/services/firebase_messaging_service.dart';
import 'package:truebpm/utils/global_store.dart';

/// Service để lưu device token (FCM) lên server sau khi login thành công.
/// Chạy ngầm, không hiển thị message cho user.
class DeviceTokenService {
  static final DeviceTokenService _instance = DeviceTokenService._internal();
  static DeviceTokenService get instance => _instance;

  DeviceTokenService._internal();

  final Dio _dio = Dio();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const String _keyDeviceKey = 'device_unique_key';

  /// Lấy hoặc tạo deviceKey (UUID duy nhất cho thiết bị này)
  Future<String> _getOrCreateDeviceKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceKey = prefs.getString(_keyDeviceKey);
    if (deviceKey == null || deviceKey.isEmpty) {
      deviceKey = const Uuid().v4();
      await prefs.setString(_keyDeviceKey, deviceKey);
    }
    return deviceKey;
  }

  /// Lấy tên thiết bị từ device_info_plus
  Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.utsname.machine; // e.g. iPhone14,5
      }
    } catch (e) {
      logger.e('Error getting device name: $e');
    }
    return 'Unknown Device';
  }

  /// Lấy platform string
  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Gửi device token lên server.
  /// Gọi sau khi login thành công, chạy ngầm không show message.
  /// [userId] - ID của user đã login
  /// [cookies] - Session cookies từ login result
  Future<void> saveDeviceToken({
    required String userId,
    List<String>? cookies,
  }) async {
    try {
      // Lấy FCM token
      final fcmToken = FirebaseMessagingService().fcmToken;
      if (fcmToken == null || fcmToken.isEmpty) {
        logger.w('⚠️ No FCM token available, skip saving device token');
        return;
      }

      // Lấy thông tin thiết bị
      final deviceKey = await _getOrCreateDeviceKey();
      final deviceName = await _getDeviceName();
      final platform = _getPlatform();

      // Build URL
      final url = '${hosts.flexAPIUrl}user-device-tokens/save-to-token';

      // Build headers với cookies
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (cookies != null && cookies.isNotEmpty) {
        headers['cookie'] = cookies.join('; ');

        // Extract X-Bonita-API-Token from cookies
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            headers['X-Bonita-API-Token'] = parts[1];
            break;
          }
        }
      } else {
        // Fallback: lấy cookies từ SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final cookiesStr = prefs.getString('session_cookies');
        if (cookiesStr != null && cookiesStr.isNotEmpty) {
          try {
            final dynamic parsed = jsonDecode(cookiesStr);
            if (parsed is List) {
              final savedCookies = parsed.map((e) => e.toString()).toList();
              headers['cookie'] = savedCookies.join('; ');

              for (final c in savedCookies) {
                final cookiePair = c.split(';')[0];
                final parts = cookiePair.split('=');
                if (parts.length == 2 &&
                    parts[0].trim() == 'X-Bonita-API-Token') {
                  headers['X-Bonita-API-Token'] = parts[1];
                  break;
                }
              }
            }
          } catch (_) {}
        }
      }

      // Build payload
      final payload = {
        'userId': userId,
        'deviceToken': fcmToken,
        'deviceKey': deviceKey,
        'platform': platform,
        'deviceName': deviceName,
      };

      logger.i('📱 Saving device token to server...');
      logger.i('   userId: $userId');
      logger.i('   platform: $platform');
      logger.i('   deviceName: $deviceName');
      logger.i('   deviceKey: $deviceKey');

      final response = await _dio.post(
        url,
        data: jsonEncode(payload),
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        logger.i('✅ Device token saved successfully (${response.statusCode})');
      } else {
        logger.w(
            '⚠️ Failed to save device token: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      // Chạy ngầm nên chỉ log error, không throw
      logger.e('❌ Error saving device token: $e');
    }
  }
}

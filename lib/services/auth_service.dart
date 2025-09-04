import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:truebpm/services/direct_login_service.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/models/user_model.dart';

/// AuthService that combines direct login with credential management
class AuthService {
  final DirectLoginService _directLoginService;
  // Storage keys
  static const String _keyUsername = 'saved_username';
  static const String _keyPassword = 'saved_password';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserInfo = 'user_info';

  AuthService({
    DirectLoginService? directLoginService,
  }) : _directLoginService = directLoginService ?? DirectLoginService();

  // Diagnostics for biometric last failure
  String? lastBiometricErrorCode;
  String? lastBiometricErrorMessage;

  /// Fetch Bonita user info from session API and save to SharedPreferences
  Future<Map<String, dynamic>?> fetchAndSaveBonitaUserInfo({List<String>? cookies}) async {
    try {
      final url = '${hosts.systemUrl}session/unusedId';
      final dio = Dio();
      Map<String, String> headers = {};
      if (cookies != null && cookies.isNotEmpty) {
        headers['cookie'] = cookies.join('; ');
      }
      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );
      // logger.i('Bonita user info API response: ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bonita_user_info', jsonEncode(response.data));
        // logger.i('Bonita user info saved');
        return response.data;
      } else {
        // logger.w('Failed to fetch Bonita user info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // logger.e('Error fetching Bonita user info: $e');
      return null;
    }
  }

  /// Fetch user info from API and save to SharedPreferences
  Future<UserModel?> fetchAndSaveUserInfo(String username, {List<String>? cookies}) async {
    try {
      final url = '${hosts.coreUrl}USER.GETBY?username=$username';
      final dio = Dio();
      Map<String, String> headers = {};
      if (cookies != null && cookies.isNotEmpty) {
        headers['cookie'] = cookies.join('; ');
      }
      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );
      // logger.i('User info API response: ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserInfo, jsonEncode(user.toJson()));
        // logger.i('User info saved for $username');
        return user;
      } else {
        // logger.w('Failed to fetch user info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // logger.e('Error fetching user info: $e');
      return null;
    }
  }

  /// Get saved Bonita user info from SharedPreferences
  Future<Map<String, dynamic>?> getSavedBonitaUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('bonita_user_info');
      if (jsonStr != null) {
        return jsonDecode(jsonStr);
      }
      return null;
    } catch (e) {
      // logger.e('Error getting saved Bonita user info: $e');
      return null;
    }
  }

  /// Get saved user info from SharedPreferences
  Future<UserModel?> getSavedUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyUserInfo);
      if (jsonStr != null) {
        return UserModel.fromJson(jsonDecode(jsonStr));
      }
      return null;
    } catch (e) {
      // logger.e('Error getting saved user info: $e');
      return null;
    }
  }

  /// Login with username and password using direct API
  Future<AuthResult> loginDirect({
    required String username,
    required String password,
    bool enableBiometric = false,
  }) async {
    try {
      // logger.i('Starting login process for user: $username');
      // Perform direct login
      final directResult = await _directLoginService.login(
        username: username,
        password: password,
      );
      if (directResult.isSuccess) {
        // Save credentials
        await _saveCredentialsInternal(
          username: username,
          password: password,
          enableBiometric: enableBiometric,
        );
        // Save session cookies for later API calls
        final prefs = await SharedPreferences.getInstance();
        if (directResult.cookies.isNotEmpty) {
          await prefs.setString('session_cookies', jsonEncode(directResult.cookies));
          // logger.i('Session cookies saved: ${directResult.cookies}');
        }
        // logger.i('Login successful - credentials and session cookies saved');
        return AuthResult.success(
          message: appStrings.loginSuccess,
          cookies: directResult.cookies,
        );
      } else {
        // logger.w('Login failed: ${directResult.message}');
        return AuthResult.failure(
          directResult.message ?? appStrings.loginFailed,
        );
      }
    } catch (e) {
      // logger.e('Login error: $e');
      return AuthResult.failure(
        appStrings.unknownError,
      );
    }
  }

  /// Login with saved credentials
  Future<AuthResult> loginWithSavedCredentials() async {
    try {
      // logger.i('Attempting login with saved credentials');
      
      final credentials = await _getSavedCredentials();
      
      if (credentials['username'] == null || credentials['password'] == null) {
        // logger.w('No saved credentials found');
        return AuthResult.failure(appStrings.savedCredentialsNotFound);
      }
      // Keep biometric state if previously enabled to avoid clearing password
      final wasEnabled = await isBiometricLoginEnabled();
      return await loginDirect(
        username: credentials['username']!,
        password: credentials['password']!,
        enableBiometric: wasEnabled,
      );
    } catch (e) {
      // logger.e('Error logging in with saved credentials: $e');
      return AuthResult.failure(
        appStrings.credentialsLoadError,
      );
    }
  }

  /// Save credentials securely
  Future<void> _saveCredentialsInternal({
    required String username,
    required String password,
    required bool enableBiometric,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Always save username for auto-fill
      await prefs.setString(_keyUsername, username);
      
      // Save password if biometric is enabled
      if (enableBiometric) {
        await prefs.setString(_keyPassword, password);
        await prefs.setBool(_keyBiometricEnabled, true);
        // logger.i('Credentials saved with biometric authentication enabled');
      } else {
        // If previously enabled, keep existing password to avoid losing biometric login unexpectedly
        final wasEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
        if (!wasEnabled) {
          // Remove password only if it wasn't previously enabled
            await prefs.remove(_keyPassword);
            await prefs.setBool(_keyBiometricEnabled, false);
        }
      }
    } catch (e) {
      // logger.e('Error saving credentials: $e');
      throw Exception('Lỗi lưu thông tin đăng nhập');
    }
  }

  /// Get saved credentials
  Future<Map<String, String?>> _getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'username': prefs.getString(_keyUsername),
        'password': prefs.getString(_keyPassword),
      };
    } catch (e) {
      // logger.e('Error getting saved credentials: $e');
      return {'username': null, 'password': null};
    }
  }

  /// Get saved username
  Future<String?> getSavedUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUsername);
    } catch (e) {
      // logger.e('Error getting saved username: $e');
      return null;
    }
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyBiometricEnabled) ?? false;
    } catch (e) {
      // logger.e('Error checking biometric login status: $e');
      return false;
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final localAuth = LocalAuthentication();
      final isAvailable = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      // logger.e('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final localAuth = LocalAuthentication();
      return await localAuth.getAvailableBiometrics();
    } catch (e) {
      // logger.e('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final localAuth = LocalAuthentication();
      
      // Primary attempt: biometric only
      bool success = await localAuth.authenticate(
        localizedReason: appStrings.biometricReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      // If failed on Android, try a fallback attempt allowing device credential (some devices misreport Face / Fingerprint)
      if (!success && Platform.isAndroid) {
        // Verify still can check biometric (not canceled mid-way)
        final canRetry = await isBiometricAvailable();
        if (canRetry) {
          try {
            // tiny delay to avoid immediate duplicate rejection on some Samsung devices
            await Future.delayed(const Duration(milliseconds: 120));
            success = await localAuth.authenticate(
              localizedReason: appStrings.biometricReason,
              options: const AuthenticationOptions(
                biometricOnly: false, // allow device credential fallback
                stickyAuth: true,
                useErrorDialogs: true,
              ),
            );
          } catch (_) {/* ignore fallback exception */}
        }
      }

      return success;
    } on PlatformException catch (pe) {
      lastBiometricErrorCode = pe.code;
      lastBiometricErrorMessage = pe.message;
      return false;
    } catch (e) {
      // logger.e('Biometric authentication error: $e');
      return false;
    }
  }

  Map<String,String?> getLastBiometricError() => {
    'code': lastBiometricErrorCode,
    'message': lastBiometricErrorMessage,
  };

  /// Force enable biometric for given credentials (used when user logs in before async availability check completes)
  Future<void> enableBiometricForCredentials(String username, String password) async {
    await _saveCredentialsInternal(
      username: username,
      password: password,
      enableBiometric: true,
    );
  }

  /// Clear all saved credentials
  Future<void> clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_keyUsername),
        prefs.remove(_keyPassword),
        prefs.remove(_keyBiometricEnabled),
      ]);
      // logger.i('All saved credentials cleared');
    } catch (e) {
      // logger.e('Error clearing saved credentials: $e');
      throw Exception('Lỗi xóa thông tin đăng nhập');
    }
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_keyPassword),
        prefs.setBool(_keyBiometricEnabled, false),
      ]);
      // logger.i('Biometric login disabled');
    } catch (e) {
      // logger.e('Error disabling biometric login: $e');
      throw Exception('Lỗi tắt đăng nhập sinh trắc học');
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final String? message;
  final List<String>? cookies;
  final DateTime timestamp;

  AuthResult({
    required this.isSuccess,
    this.message,
    this.cookies,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AuthResult.success({
    String? message,
    List<String>? cookies,
  }) {
    return AuthResult(
      isSuccess: true,
      message: message,
      cookies: cookies,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      isSuccess: false,
      message: message,
    );
  }

  @override
  String toString() {
    return 'AuthResult(isSuccess: $isSuccess, message: $message, timestamp: $timestamp)';
  }
}

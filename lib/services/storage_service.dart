import 'package:shared_preferences/shared_preferences.dart';
import 'package:truebpm/utils/global_store.dart';

class StorageService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUsername = 'saved_username';
  static const String _keyPassword = 'saved_password';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLastLoginTime = 'last_login_time';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Save login credentials
  static Future<void> saveLoginCredentials({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    // logger.i('StorageService: Saving login credentials - username: $username, rememberMe: $rememberMe');
    
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyLastLoginTime, DateTime.now().toIso8601String());
    
    if (rememberMe) {
      await prefs.setString(_keyUsername, username);
      await prefs.setString(_keyPassword, password);
      // logger.i('StorageService: Credentials saved with remember me - username: $username');
    } else {
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyPassword);
      // logger.i('StorageService: Credentials saved without remember me');
    }
    
    // Verify that the credentials were saved
    final savedRememberMe = prefs.getBool(_keyRememberMe) ?? false;
    final savedIsLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final savedLastLoginTime = prefs.getString(_keyLastLoginTime);
    logger.i('StorageService: Verification - rememberMe: $savedRememberMe, isLoggedIn: $savedIsLoggedIn, lastLoginTime: $savedLastLoginTime');
  }

  // Get saved login credentials
  static Future<Map<String, String?>> getSavedCredentials() async {
    // logger.i('StorageService: Getting saved credentials');
    
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    final username = rememberMe ? prefs.getString(_keyUsername) : null;
    final password = rememberMe ? prefs.getString(_keyPassword) : null;
    
    // logger.i('StorageService: Remember me: $rememberMe, Has username: ${username != null}, Has password: ${password != null}');
    
    return {
      'username': username,
      'password': password,
    };
  }

  // Check if user should be auto-logged in
  static Future<bool> shouldAutoLogin() async {
    // logger.i('StorageService: Checking if should auto login');
    
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    final lastLoginTimeString = prefs.getString(_keyLastLoginTime);
    
    // logger.i('StorageService: Raw values - isLoggedIn: $isLoggedIn, rememberMe: $rememberMe, lastLoginTimeString: $lastLoginTimeString');
    
    if (!isLoggedIn || !rememberMe || lastLoginTimeString == null) {
      // logger.i('StorageService: Should not auto login - isLoggedIn: $isLoggedIn, rememberMe: $rememberMe, hasLastLoginTime: ${lastLoginTimeString != null}');
      return false;
    }
    
    try {
      final lastLoginTime = DateTime.parse(lastLoginTimeString);
      final now = DateTime.now();
      final daysDifference = now.difference(lastLoginTime).inDays;
      
      // Auto login if last login was within 30 days
      final shouldLogin = daysDifference <= 30;
      // logger.i('StorageService: Days since last login: $daysDifference, Should auto login: $shouldLogin');
      
      return shouldLogin;
    } catch (e) {
      // logger.w('StorageService: Error parsing last login time: $e');
      return false;
    }
  }

  // Clear login credentials
  static Future<void> clearLoginCredentials() async {
    // logger.i('StorageService: Clearing login credentials');
    
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyLastLoginTime);
    
    // logger.i('StorageService: Login credentials cleared');
  }

  // Update last login time
  static Future<void> updateLastLoginTime() async {
    // logger.i('StorageService: Updating last login time');
    
    await prefs.setString(_keyLastLoginTime, DateTime.now().toIso8601String());
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  // Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}

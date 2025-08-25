import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/services/direct_login_service.dart';
import 'package:truebpm/services/storage_service.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Initialize all dependencies
Future<void> setupDependencies() async {
  // External dependencies
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
  
  // SharedPreferences - async dependency
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  
  // Storage Service
  sl.registerLazySingleton<StorageService>(
    () => StorageService(),
  );
  
  // Direct Login Service
  sl.registerLazySingleton<DirectLoginService>(
    () => DirectLoginService(),
  );
  
  // Enhanced Auth Service
  sl.registerLazySingleton<AuthService>(
    () => AuthService(
      directLoginService: sl<DirectLoginService>(),
    ),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}

/// Get dependency from service locator
T get<T extends Object>() => sl.get<T>();
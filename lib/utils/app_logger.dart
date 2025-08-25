import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true, // ignore: deprecated_member_use
    ),
  );

  static void init() {
    // Capture Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logger.e(
        'Flutter Error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    // Capture other errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logger.e(
        'Platform Error: $error',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }

  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    // _logger.d(message, error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      developer.log(message, name: 'DEBUG');
    }
  }

  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    // _logger.i(message, error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      developer.log(message, name: 'INFO');
    }
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    // _logger.w(message, error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      developer.log(message, name: 'WARNING');
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    // _logger.e(message, error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      developer.log(message, name: 'ERROR');
    }
  }
}

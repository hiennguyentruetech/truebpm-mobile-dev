import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A custom logger for the application.
/// 
/// This logger is configured to display logs with different levels of severity
/// and provides pretty formatting with colors, emojis, and stack traces.
/// In production mode, only warnings and errors are logged.
final appLogger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    methodCount: 2, // number of methods shown in the stack trace
    errorMethodCount: 8, // number of methods shown when an error occurs
    lineLength: 120, // width of the log line
    colors: true, // enable colors for different log levels
    printEmojis: true, // print emojis for each log level
    printTime: true // print the time when the log was created
  ),
);

/// A custom filter that only allows certain log levels in production mode.
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // kReleaseMode is a Flutter constant that returns true if the app
    // is running in release mode.
    if (kReleaseMode) {
      // Only allow warning and error logs in release mode
      return event.level.index >= Level.warning.index;
    }
    // Allow all logs in debug mode
    return true;
  }
}

/// Extension methods for easier logging with context information.
extension LoggerExtension on Logger {
  /// Log a message with the class name as a prefix.
  void logWithClass(String className, String message, {Level level = Level.debug}) {
    switch (level) {
      case Level.verbose:
        v('[$className] $message');
        break;
      case Level.debug:
        d('[$className] $message');
        break;
      case Level.info:
        i('[$className] $message');
        break;
      case Level.warning:
        w('[$className] $message');
        break;
      case Level.error:
        e('[$className] $message');
        break;
      case Level.wtf:
        wtf('[$className] $message');
        break;
      default:
        d('[$className] $message');
    }
  }
}
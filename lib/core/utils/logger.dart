import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application logger with production filtering
/// In release mode, only warnings and errors are logged
/// In debug mode, all levels are logged
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: kDebugMode ? 2 : 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kReleaseMode ? Level.error : Level.debug,
    output: kReleaseMode ? null : ConsoleOutput(),
  );

  /// Debug log - only in debug mode
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Info log - only in debug mode
  static void info(String message) {
    if (kDebugMode) {
      _logger.i(message);
    }
  }

  /// Warning log - in both debug and release mode
  static void warning(String message, [dynamic error]) {
    _logger.w(message, error: error);
  }

  /// Error log - always logged
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal error log - always logged
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Convenient aliases for quick access
final log = AppLogger.debug;
final logInfo = AppLogger.info;
final logWarn = AppLogger.warning;
final logError = AppLogger.error;
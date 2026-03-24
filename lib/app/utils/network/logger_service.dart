import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class Log {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    // Only log in debug mode
    filter: ProductionFilter(),
  );

  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  static void info(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    // In production, you might want to send this to Sentry or Crashlytics
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void verbose(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.t(message, error: error, stackTrace: stackTrace);
    }
  }
}

class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      // Only log errors in release mode (this depends on if you're using a console log in production)
      // Usually, we don't log to console in production at all.
      return event.level == Level.error || event.level == Level.fatal;
    }
    return true;
  }
}

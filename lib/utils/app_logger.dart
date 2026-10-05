import 'package:flutter/foundation.dart';

enum LogLevel { info, debug, warning, error, success }

class AppLogger {
  static void i(String message, {String tag = 'INFO'}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void d(String message, {String tag = 'DEBUG'}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  static void w(String message, {String tag = 'WARNING'}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace, String tag = 'ERROR'}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  static void s(String message, {String tag = 'SUCCESS'}) {
    _log(LogLevel.success, message, tag: tag);
  }

  static void firestore(String collection, String action, {String? details}) {
    final msg = details != null ? '[$collection] $action -> $details' : '[$collection] $action';
    _log(LogLevel.info, msg, tag: 'FIRESTORE');
  }

  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    required String tag,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    final prefix = _getPrefix(level);
    final formattedMessage = '[$timestamp] $prefix [$tag] $message';

    debugPrint(formattedMessage);
    if (error != null) {
      debugPrint('   └─ Error details: $error');
    }
    if (stackTrace != null) {
      debugPrint('   └─ StackTrace: $stackTrace');
    }
  }

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.debug:
        return '🔍';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.success:
        return '✅';
    }
  }
}

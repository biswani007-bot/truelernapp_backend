import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Lightweight logging utility for debug-mode logging.
abstract final class AppLogger {
  static void debug(String message, {String tag = 'TrueLern'}) {
    if (kDebugMode) {
      dev.log(message, name: tag, level: 500);
    }
  }

  static void info(String message, {String tag = 'TrueLern'}) {
    if (kDebugMode) {
      dev.log(message, name: tag, level: 800);
    }
  }

  static void error(
    String message, {
    String tag = 'TrueLern',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      dev.log(
        message,
        name: tag,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

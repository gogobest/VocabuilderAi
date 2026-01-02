import 'package:flutter/foundation.dart';

/// A simple logging utility for the application
class Logger {
  /// Log a debug message
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      print('DEBUG ${tag != null ? "[$tag]" : ""}: $message');
    }
  }

  /// Log an info message
  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      print('INFO ${tag != null ? "[$tag]" : ""}: $message');
    }
  }

  /// Log a warning message
  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      print('WARNING ${tag != null ? "[$tag]" : ""}: $message');
    }
  }

  /// Log an error message
  static void e(String message, {String? tag}) {
    if (kDebugMode) {
      print('ERROR ${tag != null ? "[$tag]" : ""}: $message');
    }
  }
} 
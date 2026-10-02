import 'dart:developer' as dev;

class AppLogger {
  static void i(String message, [String name = 'FixOrBid']) {
    dev.log('ℹ️ $message', name: name);
  }

  static void w(String message, [String name = 'FixOrBid']) {
    dev.log('⚠️ $message', name: name);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace, String name = 'FixOrBid']) {
    dev.log('❌ $message', name: name, error: error, stackTrace: stackTrace);
  }
}

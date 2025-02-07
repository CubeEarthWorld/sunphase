// lib/core/error_handler.dart
import 'dart:developer' as developer;

class ErrorHandler {
  /// エラー発生時の基本処理（ここではログ出力を利用）
  static void handleError(Object error) {
    developer.log('Error: $error');
  }
}

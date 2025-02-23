// lib/core/base_parser.dart
import 'parsing_context.dart';
import 'result.dart';

// lib/core/base_parser.dart
abstract class BaseParser {
  /// 入力テキストを解析し、[context] に基づいた解析結果のリストを返す
  List<ParsingResult> parse(String text, ParsingContext context);
}

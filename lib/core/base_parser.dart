// lib/core/base_parser.dart
import 'parsing_context.dart';
import 'result.dart';

/// すべてのパーサーが実装すべき共通の抽象クラス。
abstract class BaseParser {
  /// [text] を解析し、[context] に基づいた解析結果のリストを返す。
  List<ParsingResult> parse(String text, ParsingContext context);
}

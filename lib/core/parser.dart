// lib/core/parser.dart
import 'result.dart';

/// 日付・時刻を解析するためのパーサーインターフェース
abstract class Parser {
  /// テキストから解析結果を返す。
  /// 解析に成功すれば ParsingResult を、失敗すれば null を返す。
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode, bool strict, String? timezone});
}

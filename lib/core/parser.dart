// lib/core/parser.dart
import 'result.dart';

abstract class Parser {
  /// [text] の中から、[referenceDate] を基準に日付情報を抽出し、解析結果リストを返す。
  List<ParsingResult> parse(String text, DateTime referenceDate);
}

// lib/sunphase.dart
import 'core/parser_manager.dart';
import 'core/result.dart';

/// テキストから日付情報を抽出し、解析結果のリストを返す。
/// [text]：解析対象の文字列
/// [referenceDate]：解析の基準日時（指定がない場合は現在日時）
/// [language]：使用する言語コード（例："en", "ja", "zh"）
/// [rangeMode]：true の場合、範囲モードで複数の日時を返す
/// [timezone]：タイムゾーンのオフセット（分単位、例："540"）
List<ParsingResult> parse(String text,
    {DateTime? referenceDate,
      String? language,
      bool rangeMode = false,
      String? timezone}) {
  return ParserManager.parse(text,
      referenceDate: referenceDate,
      language: language,
      rangeMode: rangeMode,
      timezone: timezone);
}

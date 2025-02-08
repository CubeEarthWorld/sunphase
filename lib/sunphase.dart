// lib/sunphase.dart
export 'core/result.dart';
export 'core/parser.dart';
export 'core/refiner.dart';
export 'core/parser_manager.dart';
export 'core/config.dart';
export 'core/timezone_config.dart';
export 'core/error_handler.dart';
export 'core/merger.dart';
export 'languages/language_interface.dart';
export 'languages/en.dart';
export 'languages/ja.dart';
export 'languages/zh.dart';
export 'modes/range_mode.dart';
export 'utils/date_utils.dart';


import 'core/parser_manager.dart';
import 'core/result.dart';

/// テキストから日付情報を抽出し、解析結果のリストを返す。
///
/// [text]：解析対象の文字列
/// [referenceDate]：解析の基準日（指定がない場合は現在日時）
/// [language]：使用する言語コード（例："en", "ja", "zh"）。指定がなければ全言語で解析する。
/// [rangeMode]：true の場合、範囲モード（例：「来週」→１週間分の日付リスト）で返す。
/// [timezone]：タイムゾーン名（例："JST"）を指定可能。
List<ParsingResult> parse(String text,
    {DateTime? referenceDate,
      String? language,
      bool rangeMode = false,
      String? timezone}) {
  return ParserManager.parse(
      text,
      referenceDate: referenceDate,
      language: language,
      rangeMode: rangeMode,
      timezone: timezone);
}

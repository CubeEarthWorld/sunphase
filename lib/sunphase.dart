// lib/sunphase.dart
import 'core/result.dart';  // 内部で使用するため明示的にimport
export 'core/result.dart'; // 利用者が「package:sunphase/sunphase.dart」でParsingResultを利用できるよう再エクスポート
import 'core/parser_manager.dart';

/// Parses natural language date expressions and returns a list of parsing results.
///
/// [text]: The input text to parse.
/// [referenceDate]: The reference date (defaults to current date/time if not provided).
/// [language]: The language code to use (e.g., "en", "ja", "zh").
/// [rangeMode]: If true, returns a range of dates for expressions indicating a period.
/// [timezone]: The timezone offset in minutes as a string (e.g., "540").
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

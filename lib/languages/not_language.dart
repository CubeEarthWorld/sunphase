// lib/language/not_language.dart
import '../core/parser.dart';
import '../core/result.dart';

class NotLanguageParser implements Parser {
  // (1) 完全な日付表現（年あり）："2024-02-24", "2042/4/1", "2012-4-4 12:31"
  final RegExp fullDatePattern = RegExp(
      r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})(?::(\d{1,2}))?)?\b');
  // (2) 月/日表現（年省略）："6/27", "3/14", "6/4 12:42"
  final RegExp mdPattern = RegExp(
      r'\b(\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})(?::(\d{1,2}))?)?\b');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // まず、年ありのパターンを試す
    var match = fullDatePattern.firstMatch(text);
    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: year, month: month, day: day, hour: hour, minute: minute, second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }
    // 次に、年が省略された月/日表現を試す
    match = mdPattern.firstMatch(text);
    if (match != null) {
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      int hour = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year, month: month, day: day, hour: hour, minute: minute, second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }
    return null;
  }
}

/// 非言語用パーサーリスト
List<Parser> parsers = [
  NotLanguageParser(),
];

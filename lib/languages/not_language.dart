// lib/language/not_language.dart
import '../core/parser.dart';
import '../core/result.dart';

/// 非言語的（数字・記号）な表現に対応するパーサー
class NotLanguageParser implements Parser {
  // 年月日形式：例："2024-02-24", "2042/4/1", "2012-4-4 12:31"
  final RegExp fullPattern = RegExp(
      r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})(?::|[：:])(\d{1,2})(?::|[：:])(\d{1,2}))?');
  // 月日だけ (例："6/27", "3/14")
  final RegExp monthDayPattern = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})(?:\s+(\d{1,2})(?::|[：:])(\d{1,2})(?::|[：:])(\d{1,2}))?\b');
  // 時刻だけ (例："4:12", "4:12:00")
  final RegExp timeOnlyPattern = RegExp(r'\b(\d{1,2})(?::|[：:])(\d{1,2})(?::|[：:])?(\d{1,2})?\b');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // ① フル形式
    var match = fullPattern.firstMatch(text);
    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      int second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
          second: second);
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }
    // ② 月日だけの場合：年は補完（現在の年）
    match = monthDayPattern.firstMatch(text);
    if (match != null) {
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      int hour = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int second = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
          second: second);
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }
    // ③ 時刻だけの場合
    match = timeOnlyPattern.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      int second = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: hour,
          minute: minute,
          second: second);
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }
    return null;
  }
}

/// 非言語用パーサー列表
List<Parser> parsers = [
  NotLanguageParser(),
];

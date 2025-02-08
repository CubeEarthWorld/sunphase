// lib/language/not_language.dart
import '../core/parser.dart';
import '../core/result.dart';

/// 非言語的（数字・記号）な表現での日付・時刻に対応するパーサー
class NotLanguageParser implements Parser {
  // 例："2024-02-24", "2042/4/1", "2012-4-4 12:31" など
  final RegExp genericPattern = RegExp(
      r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})(?::|[时])(\d{1,2})(?::|[分])(\d{1,2})?(?:秒)?)?');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    var match = genericPattern.firstMatch(text);
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
    return null;
  }
}

/// 非言語用パーサーリスト
List<Parser> parsers = [
  NotLanguageParser(),
];

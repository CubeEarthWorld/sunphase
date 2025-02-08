// lib/language/zh.dart
import '../core/parser.dart';
import '../core/result.dart';

/// 中国語表現に対応するパーサー実装例
class ChineseDateParser implements Parser {
  // 「今天」「明天」「昨天」に対応
  final RegExp relativePattern = RegExp(r'\b(今天|明天|昨天)\b');
  // 数字形式の日付（例："2024-02-24" や "2042/4/1"、"2012-4-4 12:31" など）
  final RegExp isoPattern = RegExp(
      r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})[:时](\d{1,2})(?::(\d{1,2})秒?)?)?');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    var match = relativePattern.firstMatch(text);
    if (match != null) {
      String word = match.group(1)!;
      ParsedComponents comp;
      if (word == '今天') {
        comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else if (word == '明天') {
        DateTime dt = referenceDate.add(Duration(days: 1));
        comp = ParsedComponents(
          year: dt.year,
          month: dt.month,
          day: dt.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else if (word == '昨天') {
        DateTime dt = referenceDate.subtract(Duration(days: 1));
        comp = ParsedComponents(
          year: dt.year,
          month: dt.month,
          day: dt.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else {
        return null;
      }
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    match = isoPattern.firstMatch(text);
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

/// 中国語用パーサーリスト
List<Parser> parsers = [
  ChineseDateParser(),
];

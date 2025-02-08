// lib/language/en.dart
import '../core/parser.dart';
import '../core/result.dart';

/// 英語表現に対応するパーサー実装例
class EnglishDateParser implements Parser {
  // 「today」「tomorrow」「yesterday」に対応
  final RegExp relativePattern =
  RegExp(r'\b(today|tomorrow|yesterday)\b', caseSensitive: false);

  // ISO形式（例: 2024-02-24 または 2042/4/1、"2012-4-4 12:31" も対応）
  final RegExp isoPattern = RegExp(
      r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // relative 表現の処理
    var match = relativePattern.firstMatch(text);
    if (match != null) {
      String word = match.group(1)!.toLowerCase();
      ParsedComponents comp;
      if (word == 'today') {
        comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else if (word == 'tomorrow') {
        DateTime dt = referenceDate.add(Duration(days: 1));
        comp = ParsedComponents(
          year: dt.year,
          month: dt.month,
          day: dt.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else if (word == 'yesterday') {
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

    // ISO 形式の処理
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

    // その他の英語表現（例："next friday", "this friday" など）は必要に応じて追加可能
    return null;
  }
}

/// 英語用パーサーリスト
List<Parser> parsers = [
  EnglishDateParser(),
  // 他の英語用パーサー実装を追加可能
];

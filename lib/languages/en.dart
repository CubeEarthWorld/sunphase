// lib/language/en.dart
import '../core/parser.dart';
import '../core/result.dart';

/// 英語表現に対応するパーサー実装例
class EnglishDateParser implements Parser {
  // 基本的な相対表現："today", "tomorrow", "yesterday", "now"
  final RegExp relativePattern = RegExp(
      r'\b(today|tomorrow|yesterday|now)\b',
      caseSensitive: false);
  // 時刻のみ (例："4:12" または "04:12")
  final RegExp timeOnlyPattern =
  RegExp(r'\b(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?\b');
  // ISO形式（例："2024-02-24", "2042/4/1", "2012-4-4 12:31"）
  final RegExp isoPattern = RegExp(
      r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:[\sT]+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?');
  // 相対時間（例："3 days later", "two weeks ago", "next week"）
  final RegExp relativeDurationPattern = RegExp(
      r'\b(?:(next|last)|(\d+|\w+))\s*(seconds?|minutes?|hours?|days?|weeks?|months?|years?)\b',
      caseSensitive: false);

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // ① "now", "today", "tomorrow", "yesterday"
    var match = relativePattern.firstMatch(text);
    if (match != null) {
      String word = match.group(1)!.toLowerCase();
      ParsedComponents comp;
      if (word == 'now') {
        // 現在時刻をそのまま返す
        comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: referenceDate.hour,
          minute: referenceDate.minute,
          second: referenceDate.second,
        );
      } else if (word == 'today') {
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
          index: match.start,
          text: match.group(0)!,
          start: comp,
          refDate: referenceDate);
    }

    // ② 時刻のみの表現 (例："4:12")
    match = timeOnlyPattern.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      int second = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      // 時刻だけの場合、現在の日付で補完
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: hour,
          minute: minute,
          second: second);
      return ParsingResult(
          index: match.start,
          text: match.group(0)!,
          start: comp,
          refDate: referenceDate);
    }

    // ③ ISO形式の表現
    match = isoPattern.firstMatch(text);
    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      int second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: year, month: month, day: day, hour: hour, minute: minute, second: second);
      return ParsingResult(
          index: match.start,
          text: match.group(0)!,
          start: comp,
          refDate: referenceDate);
    }

    // ④ 相対時間の表現 (例："3 days later", "two weeks ago", "next week")
    match = relativeDurationPattern.firstMatch(text);
    if (match != null) {
      // 「next」「last」の場合
      if (match.group(1) != null) {
        String keyword = match.group(1)!.toLowerCase();
        int days = 0;
        if (keyword == 'next') {
          days = 7;
        } else if (keyword == 'last') {
          days = -7;
        }
        ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day + days,
          hour: 0,
          minute: 0,
          second: 0,
        );
        return ParsingResult(
            index: match.start,
            text: match.group(0)!,
            start: comp,
            refDate: referenceDate);
      } else if (match.group(2) != null) {
        // 数値表現 (簡易実装：英語の数詞は未対応)
        int value = int.tryParse(match.group(2)!) ?? 0;
        String unit = match.group(3)!.toLowerCase();
        int offsetDays = 0;
        if (unit.startsWith('day')) {
          offsetDays = value;
        } else if (unit.startsWith('week')) {
          offsetDays = value * 7;
        } else if (unit.startsWith('month')) {
          offsetDays = value * 30;
        } else if (unit.startsWith('year')) {
          offsetDays = value * 365;
        } else if (unit.startsWith('hour')) {
          // 時間の場合は時刻のみ補正（単位は hour）
          ParsedComponents comp = ParsedComponents(
              year: referenceDate.year,
              month: referenceDate.month,
              day: referenceDate.day,
              hour: referenceDate.hour + value,
              minute: referenceDate.minute,
              second: referenceDate.second);
          return ParsingResult(
              index: match.start,
              text: match.group(0)!,
              start: comp,
              refDate: referenceDate);
        } else if (unit.startsWith('minute')) {
          ParsedComponents comp = ParsedComponents(
              year: referenceDate.year,
              month: referenceDate.month,
              day: referenceDate.day,
              hour: referenceDate.hour,
              minute: referenceDate.minute + value,
              second: referenceDate.second);
          return ParsingResult(
              index: match.start,
              text: match.group(0)!,
              start: comp,
              refDate: referenceDate);
        } else if (unit.startsWith('second')) {
          ParsedComponents comp = ParsedComponents(
              year: referenceDate.year,
              month: referenceDate.month,
              day: referenceDate.day,
              hour: referenceDate.hour,
              minute: referenceDate.minute,
              second: referenceDate.second + value);
          return ParsingResult(
              index: match.start,
              text: match.group(0)!,
              start: comp,
              refDate: referenceDate);
        }
        // "ago"が付いている場合は負数とする
        if (text.toLowerCase().contains('ago')) {
          offsetDays = -offsetDays;
        }
        ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day + offsetDays,
          hour: 0,
          minute: 0,
          second: 0,
        );
        return ParsingResult(
            index: match.start,
            text: match.group(0)!,
            start: comp,
            refDate: referenceDate);
      }
    }
    return null;
  }
}

/// 英語用パーサーリスト
List<Parser> parsers = [
  EnglishDateParser(),
];

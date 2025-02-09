// lib/languages/ja.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// 日本語の日時表現パターンを定義する定数クラス
class JaPatterns {
  static const Map<String, int> weekdayMap = {
    "月曜": 1, "火曜": 2, "水曜": 3, "木曜": 4,
    "金曜": 5, "土曜": 6, "日曜": 7,
    "月": 1, "火": 2, "水": 3, "木": 4, "金": 5, "土": 6, "日": 7,
  };

  static const Map<String, int> kanjiNumbers = {
    "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
    "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
    "十": 10, "百": 100, "千": 1000
  };

  static const Map<String, int> relativeTimeOffsets = {
    "今日": 0,
    "明日": 1,
    "明後日": 2,
    "明々後日": 3,
    "昨日": -1
  };
}

/// 日本語の数値変換ユーティリティ
class JaNumberConverter {
  static int parse(String input) {
    int? value = int.tryParse(input);
    if (value != null) return value;
    int result = 0;
    int tempValue = 0;
    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      int? number = JaPatterns.kanjiNumbers[char];
      if (number != null) {
        if (char == "十") {
          tempValue = tempValue == 0 ? 10 : tempValue * 10;
        } else if (char == "百" || char == "千") {
          tempValue = tempValue == 0 ? number : tempValue * number;
        } else {
          if (tempValue == 0) {
            tempValue = number;
          } else {
            result += tempValue;
            tempValue = number;
          }
        }
      }
    }
    return result + tempValue;
  }
}

abstract class BaseJaParser extends BaseParser {
  DateTime adjustForPastDate(DateTime date, ParsingContext context) {
    if (date.isBefore(context.referenceDate)) {
      if (date.month < context.referenceDate.month) {
        return DateTime(date.year + 1, date.month, date.day, date.hour, date.minute);
      }
    }
    return date;
  }
  int parseKanjiOrArabicNumber(String text) {
    return JaNumberConverter.parse(text);
  }
}

/// 日本語の相対表現パーサー
class JaRelativeParser extends BaseJaParser {
  // 単体の月表現： 来月、今月、再来月、先月、または数字（漢数字）だけ
  static final RegExp _monthOnlyPattern = RegExp(r'^(来月|今月|再来月|先月|[0-9一二三四五六七八九十]+)月$', caseSensitive: false);

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    String trimmed = text.trim();
    // 単体の相対語の場合（今日、明日、明後日、明々後日、昨日）
    if (JaPatterns.relativeTimeOffsets.containsKey(trimmed)) {
      int offset = JaPatterns.relativeTimeOffsets[trimmed]!;
      DateTime base = context.referenceDate;
      DateTime date = DateTime(base.year, base.month, base.day).add(Duration(days: offset));
      return [ParsingResult(index: 0, text: trimmed, date: date)];
    }
    // 単体の月表現の場合
    RegExpMatch? m = _monthOnlyPattern.firstMatch(trimmed);
    if (m != null) {
      int year = context.referenceDate.year;
      int month;
      String token = m.group(1)!;
      if (token == "今月") {
        month = context.referenceDate.month;
      } else if (token == "来月") {
        month = context.referenceDate.month + 1;
        if (month > 12) { month = 1; year++; }
      } else if (token == "再来月") {
        month = context.referenceDate.month + 2;
        while (month > 12) { month -= 12; year++; }
      } else if (token == "先月") {
        month = context.referenceDate.month - 1;
        if (month < 1) { month = 12; year--; }
      } else {
        month = JaNumberConverter.parse(token);
        // 数字の場合、同月なら今月、過ぎていれば翌年
        if (month < context.referenceDate.month) { year++; }
      }
      return [ParsingResult(index: m.start, text: m.group(0)!, date: DateTime(year, month, 1), rangeType: "month")];
    }

    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;
    _parseFullDate(text, results);
    _parseMonthDayTime(text, context, results);
    _parseMonthDay(text, context, results);
    _parseWeekExpression(text, ref, results);
    _parseDayWithTime(text, ref, results);
    _parseRelativeWithTime(text, ref, results);
    _parseRelativeWithHour(text, ref, results);
    _parseWeekdayWithTime(text, ref, results);
    _parseNextWeekday(text, ref, results);
    _parseSingleWeekday(text, ref, results);
    _parseWithinDays(text, ref, results);
    _parseRelativeExpressions(text, ref, results);
    _parseFixedExpressions(text, ref, results);
    _parseNextMonthWithTime(text, context, results);
    return results;
  }

  void _parseFullDate(String text, List<ParsingResult> results) {
    final yearMonthDay = RegExp(r'([0-9]{4})年([0-9一二三四五六七八九十]+)[日号]');
    for (var match in yearMonthDay.allMatches(text)) {
      int year = int.parse(match.group(1)!);
      int month = JaNumberConverter.parse(match.group(2)!);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(year, month, 1)));
    }
  }

  void _parseMonthDayTime(String text, ParsingContext context, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)[日号]\s*(\d{1,2})(?:[:：時])(\d{1,2})(?:分)?');
    for (var match in pattern.allMatches(text)) {
      int month = parseKanjiOrArabicNumber(match.group(1)!);
      int day = parseKanjiOrArabicNumber(match.group(2)!);
      int hour = int.parse(match.group(3)!);
      int minute = int.parse(match.group(4)!);
      DateTime date = DateTime(context.referenceDate.year, month, day, hour, minute);
      date = adjustForPastDate(date, context);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseMonthDay(String text, ParsingContext context, List<ParsingResult> results) {
    final monthDay = RegExp(r'([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)[日号]');
    for (var match in monthDay.allMatches(text)) {
      int month = JaNumberConverter.parse(match.group(1)!);
      int day = JaNumberConverter.parse(match.group(2)!);
      DateTime date = DateTime(context.referenceDate.year, month, day, 0, 0, 0);
      date = adjustForPastDate(date, context);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseWeekExpression(String text, DateTime ref, List<ParsingResult> results) {
    final weekPattern = RegExp(r'([0-9一二三四五六七八九十]+)週間後([月火水木金土日])曜');
    var match = weekPattern.firstMatch(text);
    if (match != null) {
      int weeks = parseKanjiOrArabicNumber(match.group(1)!);
      DateTime base = ref.add(Duration(days: weeks * 7));
      int targetWeekday = JaPatterns.weekdayMap[match.group(2)! + "曜"] ?? base.weekday;
      int diff = targetWeekday - base.weekday;
      if (diff <= 0) diff += 7;
      DateTime candidate = base.add(Duration(days: diff));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseDayWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)[日号](\d{1,2})時(\d{1,2})分');
    for (final match in pattern.allMatches(text)) {
      int day = parseKanjiOrArabicNumber(match.group(1)!);
      int hour = int.parse(match.group(2)!);
      int minute = int.parse(match.group(3)!);
      DateTime candidate = DateTime(ref.year, ref.month, day, hour, minute);
      if (!candidate.isAfter(DateTime(ref.year, ref.month, ref.day, 0, 0, 0))) {
        int newMonth = ref.month + 1;
        int newYear = ref.year;
        if (newMonth > 12) { newMonth = 1; newYear++; }
        candidate = DateTime(newYear, newMonth, day, hour, minute);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseRelativeWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(明日|今日|明後日|昨日)\s*(\d{1,2})時(\d{1,2})分', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String dayWord = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int minute = int.parse(match.group(3)!);
      int offset = JaPatterns.relativeTimeOffsets[dayWord] ?? 0;
      DateTime base = ref.add(Duration(days: offset));
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseRelativeWithHour(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(明日|今日|明後日|昨日)\s*(\d{1,2})時\b', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String dayWord = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int offset = JaPatterns.relativeTimeOffsets[dayWord] ?? 0;
      DateTime base = ref.add(Duration(days: offset));
      DateTime date = DateTime(base.year, base.month, base.day, hour, 0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseWeekdayWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(月曜|火曜|水曜|木曜|金曜|土曜|日曜)\s*(\d{1,2})時(?:\s*(\d{1,2})分)?', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String weekdayStr = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int targetWeekday = JaPatterns.weekdayMap[weekdayStr]!;
      int diff = (targetWeekday - ref.weekday + 7) % 7;
      if (diff == 0) diff = 7;
      DateTime base = ref.add(Duration(days: diff));
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseNextWeekday(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'来週([月火水木金土日]曜)(?:(\d{1,2})時)?', caseSensitive: false);
    RegExpMatch? match = regex.firstMatch(text);
    if (match != null) {
      String weekdayStr = match.group(1)!;
      int target = JaPatterns.weekdayMap[weekdayStr]!;
      int diff = (target - ref.weekday + 7) % 7;
      if (diff == 0) diff = 7;
      DateTime candidate = ref.add(Duration(days: diff));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      if (match.group(2) != null) {
        int hour = int.parse(match.group(2)!);
        candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, 0, 0);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate, rangeType: 'week'));
    }
  }

  void _parseSingleWeekday(String text, DateTime ref, List<ParsingResult> results) {
    JaPatterns.weekdayMap.forEach((key, value) {
      final regex = RegExp(RegExp.escape(key), caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        int diff = (value - ref.weekday + 7) % 7;
        if (diff == 0) diff = 7;
        DateTime candidate = ref.add(Duration(days: diff));
        candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
        results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
      }
    });
  }

  void _parseWithinDays(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)日以内');
    RegExpMatch? match = regex.firstMatch(text);
    if (match != null) {
      int days = JaNumberConverter.parse(match.group(1)!);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: ref, rangeDays: days + 1));
    }
  }

  void _parseRelativeExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)(日|週間|ヶ月)後');
    for (final match in regex.allMatches(text)) {
      int value = JaNumberConverter.parse(match.group(1)!);
      String unit = match.group(2)!;
      DateTime candidate = ref;
      if (unit == "日") {
        candidate = ref.add(Duration(days: value));
      } else if (unit == "週間") {
        candidate = ref.add(Duration(days: value * 7));
      } else if (unit == "ヶ月") {
        int newMonth = ref.month + value;
        int newYear = ref.year + ((newMonth - 1) ~/ 12);
        newMonth = ((newMonth - 1) % 12) + 1;
        candidate = DateTime(newYear, newMonth, ref.day);
      }
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseFixedExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final Map<String, Function(DateTime)> fixedExpressions = {
      "来週": (date) {
        int diff = (7 - date.weekday + 1) % 7;
        if (diff == 0) diff = 7;
        return date.add(Duration(days: diff));
      },
      "先週": (date) => date.subtract(Duration(days: 7)),
      "来月": (date) => DateTime(date.year, date.month + 1, date.day),
      "先月": (date) => DateTime(date.year, date.month - 1, date.day),
      "来年": (date) => DateTime(date.year + 1, date.month, date.day),
      "今年": (date) => DateTime(date.year, date.month, date.day),
      "週末": (date) {
        int diff = (7 - date.weekday) % 7;
        if (diff == 0) diff = 7;
        return date.add(Duration(days: diff));
      },
    };

    fixedExpressions.forEach((expression, dateCalculator) {
      final regex = RegExp(RegExp.escape(expression));
      for (final match in regex.allMatches(text)) {
        DateTime calculatedDate = dateCalculator(ref);
        calculatedDate = DateTime(calculatedDate.year, calculatedDate.month, calculatedDate.day, 0, 0, 0);
        String? rangeType;
        if (expression == "来月" || expression == "先月") rangeType = "month";
        if (expression == "来週") rangeType = "week";
        results.add(ParsingResult(
            index: match.start,
            text: match.group(0)!,
            date: calculatedDate,
            rangeType: rangeType));
      }
    });
  }

  void _parseNextMonthWithTime(String text, ParsingContext context, List<ParsingResult> results) {
    final regex = RegExp(r'来月\s*([0-9一二三四五六七八九十]+)[日号]\s*(\d{1,2})時(?:\s*(\d{1,2})分)?', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      int day = JaNumberConverter.parse(match.group(1)!);
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int month = context.referenceDate.month + 1;
      int year = context.referenceDate.year;
      if (month > 12) { month = 1; year++; }
      DateTime date = DateTime(year, month, day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }
}

/// 日本語の時刻のみ表現パーサー
class JaTimeOnlyParser extends BaseJaParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    _parseTimeMinute(text, context, results);
    _parseHourOnly(text, context, results);
    return results;
  }

  void _parseTimeMinute(String text, ParsingContext context, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)時([0-9一二三四五六七八九十]+)分');
    for (var match in pattern.allMatches(text)) {
      DateTime date = _createTimeDate(context.referenceDate,
          parseKanjiOrArabicNumber(match.group(1)!),
          parseKanjiOrArabicNumber(match.group(2)!));
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseHourOnly(String text, ParsingContext context, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)時(?![0-9一二三四五六七八九十]+分)');
    for (var match in pattern.allMatches(text)) {
      DateTime date = _createTimeDate(context.referenceDate,
          parseKanjiOrArabicNumber(match.group(1)!),
          0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  DateTime _createTimeDate(DateTime ref, int hour, int minute) {
    DateTime candidate = DateTime(ref.year, ref.month, ref.day, hour, minute);
    if (!candidate.isAfter(ref)) {
      candidate = candidate.add(Duration(days: 1));
    }
    return candidate;
  }
}

/// 日本語パーサー群
class JaParsers {
  static final List<BaseParser> parsers = [
    JaRelativeParser(),
    JaTimeOnlyParser(),
  ];
}

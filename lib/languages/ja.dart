import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// 日本語の日時表現パターンを定義する定数クラス
class JaPatterns {
  static const Map<String, int> weekdayMap = {
    "月曜": 1, "火曜": 2, "水曜": 3, "木曜": 4,
    "金曜": 5, "土曜": 6, "日曜": 7,
    "月": 1, "火": 2, "水": 3, "木": 4, "金": 5, "土": 6, "日": 7, // Short weekday names
  };

  static const Map<String, int> kanjiNumbers = {
    "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
    "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
    "十": 10, "百": 100, "千": 1000
  };

  static const Map<String, int> relativeTimeOffsets = {
    "今日": 0, "明日": 1, "明後日": 2, "昨日": -1
  };
}

/// 日本語の数値変換を担当するユーティリティクラス
class JaNumberConverter {
  static int parseNumber(String input) {
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

/// 日本語の相対表現解析の基本機能を提供する抽象クラス
abstract class BaseJaParser extends BaseParser {
  DateTime adjustForPastDate(DateTime date, ParsingContext context) {
    if (date.isBefore(context.referenceDate)) {
      if (date.month < context.referenceDate.month) {
        return DateTime(date.year + 1, date.month, date.day,
            date.hour, date.minute);
      }
    }
    return date;
  }
}

/// 日本語の相対表現を解析するパーサー
class JaRelativeParser extends BaseJaParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    _parseFullDate(text, results);
    _parseMonthDayTime(text, context, results);
    _parseMonthDay(text, context, results);
    _parseWeekExpression(text, ref, results);
    _parseDayWithTime(text, ref, results);
    _parseWithinDays(text, ref, results);
    _parseRelativeWithTime(text, ref, results);
    _parseNextWeekday(text, ref, results);
    _parseSingleWeekday(text, ref, results); // Parse single weekdays
    _parseRelativeExpressions(text, ref, results);
    _parseFixedExpressions(text, ref, results);

    return results;
  }

  void _parseSingleWeekday(String text, DateTime ref, List<ParsingResult> results) {
    String trimmedText = text.trim();
    if (JaPatterns.weekdayMap.keys.contains(trimmedText + "曜") || JaPatterns.weekdayMap.keys.contains(trimmedText)) { // Check for both "曜" suffix and without
      String weekdayKey = JaPatterns.weekdayMap.keys.contains(trimmedText + "曜") ? trimmedText + "曜" : trimmedText;
      int targetWeekday = JaPatterns.weekdayMap[weekdayKey]!;
      int diff = (targetWeekday - ref.weekday + 7) % 7;
      if (diff == 0) diff = 7;
      DateTime candidate = ref.add(Duration(days: diff));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0); // Set time to midnight
      results.add(ParsingResult(index: 0, text: trimmedText, date: candidate));
    }
  }


  void _parseRelativeWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final regRelativeWithTime = RegExp(r'^(明日|今日|明後日|昨日)(\d{1,2})時(\d{1,2})分$');
    RegExpMatch? match = regRelativeWithTime.firstMatch(text);

    if (match != null) {
      String dayWord = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int minute = int.parse(match.group(3)!.replaceAll('分', '')); // Fix: Remove '分' before parsing

      int offset = JaPatterns.relativeTimeOffsets[dayWord]!;

      DateTime candidate = ref.add(Duration(days: offset));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, minute);

      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }


  void _parseFullDate(String text, List<ParsingResult> results) {
    final yearMonthDay = RegExp(r'([0-9]{4})年([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)日');

    for (var match in yearMonthDay.allMatches(text)) {
      int year = int.parse(match.group(1)!);
      int month = JaNumberConverter.parseNumber(match.group(2)!);
      int day = JaNumberConverter.parseNumber(match.group(3)!);

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(year, month, day, 0, 0, 0) // Set time to midnight
      ));
    }
  }

  void _parseMonthDayTime(String text, ParsingContext context, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)日([0-9一二三四五六七八九十]+)時([0-9一二三四五六七八九十]+)分');

    for (var match in pattern.allMatches(text)) {
      int month = JaNumberConverter.parseNumber(match.group(1)!);
      int day = JaNumberConverter.parseNumber(match.group(2)!);
      int hour = JaNumberConverter.parseNumber(match.group(3)!);
      int minute = JaNumberConverter.parseNumber(match.group(4)!);

      DateTime date = DateTime(context.referenceDate.year, month, day, hour, minute);
      date = adjustForPastDate(date, context);

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date
      ));
    }
  }

  void _parseMonthDay(String text, ParsingContext context, List<ParsingResult> results) {
    final monthDay = RegExp(r'([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)日');

    for (var match in monthDay.allMatches(text)) {
      int month = JaNumberConverter.parseNumber(match.group(1)!);
      int day = JaNumberConverter.parseNumber(match.group(2)!);

      DateTime date = DateTime(context.referenceDate.year, month, day, 0, 0, 0); // Set time to midnight
      date = adjustForPastDate(date, context);

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date
      ));
    }
  }

  void _parseWeekExpression(String text, DateTime ref, List<ParsingResult> results) {
    final weekPattern = RegExp(r'([0-9一二三四五六七八九十]+)週間後([月火水木金土日])曜');
    var match = weekPattern.firstMatch(text);

    if (match != null) {
      int weeks = JaNumberConverter.parseNumber(match.group(1)!);
      int targetWeekday = JaPatterns.weekdayMap[match.group(2)! + "曜"]!;

      DateTime base = ref.add(Duration(days: weeks * 7));
      int diff = (targetWeekday - base.weekday);
      if (diff <= 0) diff += 7;

      DateTime candidate = base.add(Duration(days: diff));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0); // Set time to midnight
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: candidate
      ));
    }
  }

  void _parseDayWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final pattern = RegExp(r'^(今日|明日|明後日|昨日)(?:\s*(\d{1,2})時)?(?:(\d{1,2})分)?$'); // Modified regex to handle optional minutes
    var match = pattern.firstMatch(text);

    if (match != null) {
      String dayWord = match.group(1)!;
      int offset = JaPatterns.relativeTimeOffsets[dayWord]!;

      DateTime date = ref.add(Duration(days: offset));
      if (match.group(2) != null) {
        int hour = int.parse(match.group(2)!);
        int minute = match.group(3) != null ? int.parse(match.group(3)!.replaceAll('分', '')) : 0;
        date = DateTime(date.year, date.month, date.day, hour, minute);
      } else {
        date = DateTime(date.year, date.month, date.day, 0, 0, 0); // Set time to midnight if no time specified
      }

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date
      ));
    }
  }

  void _parseNextWeekday(String text, DateTime ref, List<ParsingResult> results) {
    final regNextWeekday = RegExp(r'来週([月火水木金土日]曜)(?:(\d{1,2})時)?');
    RegExpMatch? match = regNextWeekday.firstMatch(text);
    if (match != null) {
      String weekdayStr = match.group(1)!;

      int target = JaPatterns.weekdayMap[weekdayStr]!;
      int offset = (target - ref.weekday + 7) % 7;
      if (offset == 0) offset = 7;  // Move to the next week if it's the same day
      DateTime candidate = ref.add(Duration(days: offset));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0); // Default to midnight
      if (match.group(2) != null) {
        int hour = int.parse(match.group(2)!);
        candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, 0, 0);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseWithinDays(String text, DateTime ref, List<ParsingResult> results) {
    final withinDays = RegExp(r'([0-9一二三四五六七八九十]+)日以内');
    var match = withinDays.firstMatch(text);

    if (match != null) {
      int days = JaNumberConverter.parseNumber(match.group(1)!);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: ref,
          rangeDays: days + 1
      ));
    }
  }

  void _parseRelativeExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final regRelative = RegExp(r'([0-9一二三四五六七八九十]+)(日|週間|ヶ月)後');
    Iterable<RegExpMatch> matches = regRelative.allMatches(text);
    for (var match in matches) {
      int value = JaNumberConverter.parseNumber(match.group(1)!);
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
      } else {
        continue;
      }
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0); // Default to midnight
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseFixedExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final Map<String, Function(DateTime)> fixedExpressions = {
      "来週": (date) => _getNextWeekStart(date),
      "先週": (date) => date.subtract(Duration(days: 7)),
      "来月": (date) => DateTime(date.year, date.month + 1, 1),
      "先月": (date) => DateTime(date.year, date.month - 1, date.day),
      "来年": (date) => DateTime(date.year + 1, date.month, date.day),
      "今年": (date) => DateTime(date.year, date.month, date.day),
    };

    fixedExpressions.forEach((expression, dateCalculator) {
      if (text.contains(expression)) {
        DateTime calculatedDate = dateCalculator(ref);
        calculatedDate = DateTime(calculatedDate.year, calculatedDate.month, calculatedDate.day, 0, 0, 0); // Default to midnight
        results.add(ParsingResult(
            index: text.indexOf(expression),
            text: expression,
            date: calculatedDate,
            rangeType: _getRangeType(expression)
        ));
      }
    });
  }

  DateTime _getNextWeekStart(DateTime date) {
    int daysToNext = (7 - date.weekday) % 7;
    if (daysToNext == 0) daysToNext = 7;
    return DateTime(date.year, date.month, date.day)
        .add(Duration(days: daysToNext));
  }

  String? _getRangeType(String expression) {
    switch (expression) {
      case "来週":
        return "week";
      case "来月":
        return "month";
      default:
        return null;
    }
  }
}

// 絶対時間表現のパーサー
class JaAbsoluteParser extends BaseJaParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];

    _parseMonthDayTimeMinute(text, context, results);
    _parseDayOnly(text, context, results);

    return results;
  }

  void _parseMonthDayTimeMinute(String text, ParsingContext context, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)日([0-9一二三四五六七八九十]+)時([0-9一二三四五六七八九十]+)分');

    for (var match in pattern.allMatches(text)) {
      DateTime date = DateTime(
          context.referenceDate.year,
          JaNumberConverter.parseNumber(match.group(1)!),
          JaNumberConverter.parseNumber(match.group(2)!),
          JaNumberConverter.parseNumber(match.group(3)!),
          JaNumberConverter.parseNumber(match.group(4)!)
      );

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date
      ));
    }
  }

  void _parseDayOnly(String text, ParsingContext context, List<ParsingResult> results) {
    final dayOnly = RegExp(r'([0-9一二三四五六七八九十]+)[日]');

    for (var match in dayOnly.allMatches(text)) {
      int day = JaNumberConverter.parseNumber(match.group(1)!);
      DateTime date = _getAdjustedDate(context.referenceDate, day);
      date = DateTime(date.year, date.month, date.day, 0, 0, 0); // Set time to midnight

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date
      ));
    }
  }

  DateTime _getAdjustedDate(DateTime ref, int day) {
    DateTime candidate = DateTime(ref.year, ref.month, day);

    if (!candidate.isAfter(ref)) {
      int month = ref.month + 1;
      int year = ref.year;

      if (month > 12) {
        month = 1;
        year += 1;
      }

      candidate = DateTime(year, month, day);
    }

    return candidate;
  }
}

/// 時刻のみの表現を解析するパーサー
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
      DateTime date = _createTimeDate(
          context.referenceDate,
          JaNumberConverter.parseNumber(match.group(1)!),
          JaNumberConverter.parseNumber(match.group(2)!)
      );

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date
      ));
    }
  }

  void _parseHourOnly(String text, ParsingContext context, List<ParsingResult> results) {
    final hourOnly = RegExp(r'([0-9一二三四五六七八九十]+)時');

    for (var match in hourOnly.allMatches(text)) {
      if (!text.contains('分')) {
        DateTime date = _createTimeDate(
            context.referenceDate,
            JaNumberConverter.parseNumber(match.group(1)!),
            0 // 分がない場合は0とする
        );

        results.add(ParsingResult(
            index: match.start,
            text: match.group(0)!,
            date: date
        ));
      }
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
    JaAbsoluteParser(),
    JaTimeOnlyParser(),
  ];
}
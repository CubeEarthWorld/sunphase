// lib/languages/ja.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 日本語固有のパターン定義
class JaPatterns {
  static const Map<String, int> weekdayMap = {
    "月曜": 1, "火曜": 2, "水曜": 3, "木曜": 4,
    "金曜": 5, "土曜": 6, "日曜": 7,
    "月曜日": 1, "火曜日": 2, "水曜日": 3, "木曜日": 4,
    "金曜日": 5, "土曜日": 6, "日曜日": 7,
  };

  static const Map<String, int> kanjiNumbers = {
    "零": 0, "一": 1, "二": 2, "三": 3,
    "四": 4, "五": 5, "六": 6, "七": 7,
    "八": 8, "九": 9, "十": 10, "百": 100, "千": 1000
  };

  static const Map<String, int> relativeTimeOffsets = {
    "今日": 0, "明日": 1, "明後日": 2, "明々後日": 3, "昨日": -1
  };
}

/// 数値変換ユーティリティ
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

/// 日本語パーサーの共通基底クラス
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

/// 特定ケースのパーサー（例："野獣先輩"）
class JaSpecialCaseParser extends BaseJaParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    if (text == "野獣先輩") {
      DateTime now = context.referenceDate;
      int year = now.year;
      DateTime targetDate = DateTime(year, 8, 10, 11, 45, 14);
      if (now.isAfter(targetDate)) {
        year++;
        targetDate = DateTime(year, 8, 10, 11, 45, 14);
      }
      return [ParsingResult(index: 0, text: text, date: targetDate)];
    }
    return [];
  }
}

/// 日本語の相対表現パーサー
class JaRelativeParser extends BaseJaParser {
  static final RegExp _monthOnlyPattern = RegExp(
    r'^(?:(来月|今月|再来月|先月)|([0-9一二三四五六七八九十]+月))$',
    caseSensitive: false,
  );

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    if (!RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]').hasMatch(text)) return [];
    String trimmed = text.trim();
    List<ParsingResult> results = [];
    RegExp relativeWordRegex = RegExp(r'(明日|今日|明後日|明々後日|昨日)', caseSensitive: false);
    for (final match in relativeWordRegex.allMatches(text)) {
      String token = match.group(0)!;
      if (JaPatterns.relativeTimeOffsets.containsKey(token)) {
        int offset = JaPatterns.relativeTimeOffsets[token]!;
        DateTime base = context.referenceDate;
        DateTime date = DateTime(base.year, base.month, base.day)
            .add(Duration(days: offset));
        results.add(ParsingResult(index: match.start, text: token, date: date));
      }
    }
    RegExpMatch? m = _monthOnlyPattern.firstMatch(trimmed);
    if (m != null) {
      int year = context.referenceDate.year;
      int month;
      String token = m.group(1) ?? m.group(2)?.replaceAll("月", "") ?? "";
      DateTime firstDay;
      if (token == "今月") {
        firstDay = DateUtils.firstDayOfMonth(context.referenceDate);
      } else if (token == "来月") {
        firstDay = DateUtils.firstDayOfNextMonth(context.referenceDate);
      } else if (token == "再来月") {
        firstDay = DateUtils.firstDayOfNextMonth(
            DateUtils.firstDayOfNextMonth(context.referenceDate));
      } else if (token == "先月") {
        firstDay = DateUtils.firstDayOfPreviousMonth(context.referenceDate);
      } else {
        month = JaNumberConverter.parse(token);
        if (month < context.referenceDate.month) year++;
        firstDay = DateTime(year, month, 1);
      }
      int rangeDays = DateUtils.getMonthRange(firstDay)['end']!.day;
      results.add(ParsingResult(
        index: m.start,
        text: m.group(0)!,
        date: firstDay,
        rangeType: "month",
        rangeDays: rangeDays,
      ));
      if (trimmed == m.group(0)!) return results;
    }
    _parseFullDate(text, results);
    _parseMonthDayTime(text, context, results);
    _parseMonthDay(text, context, results);
    _parseWeekExpression(text, context.referenceDate, results);
    _parseDayWithTime(text, context.referenceDate, results);
    _parseRelativeWithTime(text, context.referenceDate, results);
    _parseRelativeWithHour(text, context.referenceDate, results);
    _parseWeekdayWithTime(text, context.referenceDate, results);
    _parseNextNextWeekday(text, context.referenceDate, results);
    _parseNextWeekday(text, context.referenceDate, results);
    _parseSingleWeekday(text, context.referenceDate, results);
    _parseWithinDays(text, context.referenceDate, results);
    _parseRelativeExpressions(text, context.referenceDate, results);
    _parseFixedExpressions(text, context.referenceDate, results);
    _parseNextMonthWithTime(text, context, results);
    return results;
  }

  void _parseFullDate(String text, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9]{4})年([0-9一二三四五六七八九十]+)[日号]');
    for (var match in regex.allMatches(text)) {
      int year = int.parse(match.group(1)!);
      int month = JaNumberConverter.parse(match.group(2)!);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: DateTime(year, month, 1)));
    }
  }

  void _parseMonthDay(String text, ParsingContext context, List<ParsingResult> results) {
    final regex = RegExp(r'(?:\s*(来年|去年|今年))?\s*([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)[日号]');
    for (var match in regex.allMatches(text)) {
      int month = JaNumberConverter.parse(match.group(2)!);
      int day = JaNumberConverter.parse(match.group(3)!);
      int year = context.referenceDate.year;
      if (match.group(1) != null) {
        String prefix = match.group(1)!;
        if (prefix == "来年") {
          year++;
        } else if (prefix == "去年") {
          year--;
        }
      }
      DateTime date = DateTime(year, month, day);
      date = adjustForPastDate(date, context);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseMonthDayTime(String text, ParsingContext context, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)[日号]\s*(\d{1,2})(?:[:：時])(\d{1,2})(?:分)?');
    for (var match in regex.allMatches(text)) {
      int month = parseKanjiOrArabicNumber(match.group(1)!);
      int day = parseKanjiOrArabicNumber(match.group(2)!);
      int hour = int.parse(match.group(3)!);
      int minute = int.parse(match.group(4)!);
      DateTime date = DateTime(context.referenceDate.year, month, day, hour, minute);
      date = adjustForPastDate(date, context);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseWeekExpression(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)週間後([月火水木金土日])曜');
    var match = regex.firstMatch(text);
    if (match != null) {
      int weeks = parseKanjiOrArabicNumber(match.group(1)!);
      DateTime base = ref.add(Duration(days: weeks * 7));
      int targetWeekday = JaPatterns.weekdayMap[match.group(2)! + "曜"] ?? base.weekday;
      int diff = targetWeekday - base.weekday;
      if (diff <= 0) diff += 7;
      DateTime candidate = base.add(Duration(days: diff));
      candidate = DateTime(candidate.year, candidate.month, candidate.day);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseDayWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)[日号](\d{1,2})時(\d{1,2})分');
    for (final match in regex.allMatches(text)) {
      int day = parseKanjiOrArabicNumber(match.group(1)!);
      int hour = int.parse(match.group(2)!);
      int minute = int.parse(match.group(3)!);
      DateTime candidate = DateTime(ref.year, ref.month, day, hour, minute);
      if (!candidate.isAfter(DateTime(ref.year, ref.month, ref.day))) {
        int newMonth = ref.month + 1;
        int newYear = ref.year;
        if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        }
        candidate = DateTime(newYear, newMonth, day, hour, minute);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseRelativeWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(明日|今日|明後日|明々後日|昨日)\s*(\d{1,2}|[一二三四五六七八九十]+)時\s*(\d{1,2}|[一二三四五六七八九十]+)分', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String dayWord = match.group(1)!;
      int hour = parseKanjiOrArabicNumber(match.group(2)!);
      int minute = parseKanjiOrArabicNumber(match.group(3)!);
      if (!JaPatterns.relativeTimeOffsets.containsKey(dayWord)) continue;
      int offset = JaPatterns.relativeTimeOffsets[dayWord]!;
      DateTime base = ref.add(Duration(days: offset));
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseRelativeWithHour(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(明日|今日|明後日|昨日)\s*(\d{1,2})時(?![0-9一二三四五六七八九十]*分)', caseSensitive: false);
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
    final regex = RegExp(r'(月曜|火曜|水曜|木曜|金曜|土曜|日曜)(?:\s*(午前|午後))?\s*(\d{1,2})時(?:\s*(\d{1,2})分)?', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String weekdayStr = match.group(1)!;
      String? period = match.group(2);
      int hour = int.parse(match.group(3)!);
      int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      if (period != null && period == "午後" && hour < 12) {
        hour += 12;
      }
      int targetWeekday = JaPatterns.weekdayMap[weekdayStr]!;
      DateTime candidate = DateUtils.nextWeekday(ref, targetWeekday);
      candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseNextNextWeekday(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'再来週([月火水木金土日]曜)(?:(\d{1,2})時)?', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String weekdayStr = match.group(1)!;
      int target = JaPatterns.weekdayMap[weekdayStr]!;
      DateTime candidate = DateUtils.nextWeekday(ref, target).add(Duration(days:7));
      if (match.group(2) != null) {
        int hour = int.parse(match.group(2)!);
        candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, 0, 0);
      } else {
        candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      }
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate, rangeType: 'week'));
    }
  }

  void _parseNextWeekday(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'来週([月火水木金土日]曜)(?:(\d{1,2})時)?', caseSensitive: false);
    RegExpMatch? match = regex.firstMatch(text);
    if (match != null) {
      String weekdayStr = match.group(1)!;
      int target = JaPatterns.weekdayMap[weekdayStr]!;
      DateTime candidate = DateUtils.nextWeekday(ref, target);
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      if (match.group(2) != null) {
        int hour = int.parse(match.group(2)!);
        candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, 0, 0);
      }
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate, rangeType: 'week'));
    }
  }

  void _parseSingleWeekday(String text, DateTime ref, List<ParsingResult> results) {
    JaPatterns.weekdayMap.forEach((key, value) {
      final regex = RegExp(RegExp.escape(key), caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        DateTime candidate = DateUtils.nextWeekday(ref, value);
        candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: candidate));
      }
    });
  }

  void _parseWithinDays(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)日以内');
    RegExpMatch? match = regex.firstMatch(text);
    if (match != null) {
      int days = parseKanjiOrArabicNumber(match.group(1)!);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: ref,
          rangeDays: days + 1));
    }
  }

  void _parseRelativeExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)(日|週間|ヶ月)後');
    for (final match in regex.allMatches(text)) {
      int value = parseKanjiOrArabicNumber(match.group(1)!);
      String unit = match.group(2)!;
      DateTime candidate = ref;
      if (unit == "日") {
        candidate = ref.add(Duration(days: value));
      } else if (unit == "週間") {
        candidate = ref.add(Duration(days: value * 7));
      } else if (unit == "ヶ月") {
        candidate = DateUtils.addMonths(ref, value);
      }
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseFixedExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final fixedExpressions = {
      "再来月": (DateTime date) =>
          DateUtils.firstDayOfNextMonth(DateUtils.firstDayOfNextMonth(date)),
      "来月": (DateTime date) => DateUtils.firstDayOfNextMonth(date),
      "先月": (DateTime date) => DateUtils.firstDayOfPreviousMonth(date),
      "来週": (DateTime date) => DateUtils.nextWeekday(date, 1),
      "今週": (DateTime date) => DateUtils.firstDayOfWeek(date),
      "先週": (DateTime date) => date.subtract(Duration(days: 7)),
      "来年": (DateTime date) => DateTime(date.year + 1, date.month, date.day),
      "今年": (DateTime date) => DateTime(date.year, date.month, date.day),
      "週末": (DateTime date) {
        int diff = (7 - date.weekday) % 7;
        diff = diff == 0 ? 7 : diff;
        return date.add(Duration(days: diff));
      },
    };

    final expressions = fixedExpressions.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final List<_MatchedRegion> matchedRegions = [];
    for (final expression in expressions) {
      final regex = RegExp(RegExp.escape(expression));
      for (final match in regex.allMatches(text)) {
        if (matchedRegions.any((region) =>
            _overlap(region.start, region.end, match.start, match.end))) continue;
        DateTime calculatedDate = fixedExpressions[expression]!(ref);
        calculatedDate =
            DateTime(calculatedDate.year, calculatedDate.month, calculatedDate.day, 0, 0, 0);
        String? rangeType;
        if (["来月", "先月", "再来月"].contains(expression))
          rangeType = "month";
        if (["来週", "今週"].contains(expression))
          rangeType = "week";
        results.add(ParsingResult(
            index: match.start,
            text: match.group(0)!,
            date: calculatedDate,
            rangeType: rangeType));
        matchedRegions.add(_MatchedRegion(match.start, match.end));
      }
    }
  }

  bool _overlap(int start1, int end1, int start2, int end2) {
    return start1 < end2 && start2 < end1;
  }

  void _parseNextMonthWithTime(String text, ParsingContext context, List<ParsingResult> results) {
    final regex = RegExp(r'来月\s*([0-9一二三四五六七八九十]+)[日号]\s*(\d{1,2})時(?:\s*(\d{1,2})分)?', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      int day = parseKanjiOrArabicNumber(match.group(1)!);
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      DateTime date = DateTime(
          DateUtils.firstDayOfNextMonth(context.referenceDate).year,
          DateUtils.firstDayOfNextMonth(context.referenceDate).month,
          day,
          hour,
          minute);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
  }
}

class JaAbsoluteParser extends BaseJaParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    final regex = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日');
    for (final match in regex.allMatches(text)) {
      DateTime? date = DateUtils.parseDate(match.group(0)!,
          reference: context.referenceDate);
      if (date != null) {
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: date));
      }
    }
    return results;
  }
}

class JaTimeOnlyParser extends BaseJaParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    _parseTimeMinute(text, context, results);
    _parseHourOnly(text, context, results);
    return results;
  }

  void _parseTimeMinute(String text, ParsingContext context, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)時([0-9一二三四五六七八九十]+)分');
    for (var match in regex.allMatches(text)) {
      DateTime date = _createTimeDate(context.referenceDate,
          parseKanjiOrArabicNumber(match.group(1)!),
          parseKanjiOrArabicNumber(match.group(2)!));
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseHourOnly(String text, ParsingContext context, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)時(?![0-9一二三四五六七八九十]+分)');
    for (var match in regex.allMatches(text)) {
      DateTime date = _createTimeDate(context.referenceDate,
          parseKanjiOrArabicNumber(match.group(1)!), 0);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
  }

  DateTime _createTimeDate(DateTime ref, int hour, int minute) {
    DateTime candidate = DateTime(ref.year, ref.month, ref.day, hour, minute);
    return candidate.isAfter(ref) ? candidate : candidate.add(Duration(days: 1));
  }
}

class JaParsers {
  static final List<BaseParser> parsers = [
    JaSpecialCaseParser(),
    JaRelativeParser(),
    JaAbsoluteParser(),
    JaTimeOnlyParser(),
  ];
}

/// 内部使用用のマッチ済み領域保持クラス
class _MatchedRegion {
  final int start;
  final int end;
  _MatchedRegion(this.start, this.end);
}

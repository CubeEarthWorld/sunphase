// lib/languages/zh.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 中国語の数値変換ユーティリティ
class ChineseNumberUtil {
  static const Map<String, int> numberMap = {
    "零": 0,
    "一": 1,
    "二": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
    "七": 7,
    "八": 8,
    "九": 9,
    "十": 10,
  };

  static int parse(String input) {
    int? value = int.tryParse(input);
    if (value != null) return value;
    if (input.contains("十")) {
      return _parseWithTen(input);
    }
    return _parseSimpleNumber(input);
  }

  static int _parseWithTen(String input) {
    if (input == "十") return 10;
    if (input.length == 2) {
      if (input.startsWith("十")) {
        return 10 + (numberMap[input[1]] ?? 0);
      }
      return (numberMap[input[0]] ?? 0) * 10 + (numberMap[input[1]] ?? 0);
    }
    if (input.length == 3 && input[1] == '十') {
      return (numberMap[input[0]] ?? 0) * 10 + (numberMap[input[2]] ?? 0);
    }
    return 0;
  }

  static int _parseSimpleNumber(String input) {
    int result = 0;
    for (String char in input.split('')) {
      result = result * 10 + (numberMap[char] ?? 0);
    }
    return result;
  }
}

/// 中国語パーサーの共通基底クラス
abstract class ChineseParserBase extends BaseParser {
  static const Map<String, int> weekdayMap = {
    "一": 1,
    "二": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
    "天": 7,
  };

  DateTime adjustToFuture(DateTime date, DateTime reference) {
    return date.isAfter(reference)
        ? date
        : DateTime(date.year + 1, date.month, date.day, date.hour, date.minute);
  }

  int parseKanjiOrArabicNumber(String text) {
    return ChineseNumberUtil.parse(text);
  }

  int getHourWithPeriod(int hour, String? period) {
    if (period == null) return hour;
    if (period.contains("下午") || period.contains("晚上")) {
      return hour < 12 ? hour + 12 : hour;
    }
    return hour;
  }
}

/// 中国語の相対表現パーサー
class ZhRelativeParser extends ChineseParserBase {
  static final RegExp _combinedPattern = RegExp(
      r'(今天|明天|后天|昨天|这周|下周|上周)(?:\s*(上午|中午|下午|晚上))?\s*(\d{1,2}|[一二三四五六七八九十]+)(?:[点时:：])(?:\s*(\d{1,2}|[一二三四五六七八九十]+)(?:分)?)?');
  static final RegExp _monthOnlyPattern =
  RegExp(r'(下月|上月|[0-9一二三四五六七八九十]+)月', caseSensitive: false);

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    String trimmed = text.trim();
    // 完全一致の場合（例:"今天","明天","后天","昨天"）
    if (trimmed == "今天" || trimmed == "明天" || trimmed == "后天" || trimmed == "昨天") {
      int offset = {"今天": 0, "明天": 1, "后天": 2, "昨天": -1}[trimmed]!;
      DateTime date = DateTime(context.referenceDate.year,
          context.referenceDate.month, context.referenceDate.day)
          .add(Duration(days: offset));
      return [ParsingResult(index: 0, text: trimmed, date: date)];
    }
    // 月のみ表現
    RegExpMatch? m = _monthOnlyPattern.firstMatch(trimmed);
    if (m != null) {
      int year = context.referenceDate.year;
      int month;
      String token = m.group(1) ?? "";
      DateTime firstDay;
      if (token == "今月") {
        firstDay = DateUtils.firstDayOfMonth(context.referenceDate);
      } else if (token == "下月") {
        firstDay = DateUtils.firstDayOfNextMonth(context.referenceDate);
      } else if (token == "上月") {
        firstDay = DateUtils.firstDayOfPreviousMonth(context.referenceDate);
      } else {
        month = ChineseNumberUtil.parse(token);
        DateTime candidate = DateTime(year, month, 1);
        if (candidate.isBefore(context.referenceDate)) {
          year++;
          candidate = DateTime(year, month, 1);
        }
        firstDay = candidate;
      }
      return [
        ParsingResult(
            index: m.start,
            text: m.group(0)!,
            date: firstDay,
            rangeType: "month")
      ];
    }
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;
    var combinedMatch = _combinedPattern.firstMatch(text);
    if (combinedMatch != null) {
      results.add(_parseCombinedDateTime(combinedMatch, ref));
    } else {
      results.addAll(_parseSimpleDayExpressions(text, ref));
      results.addAll(_parseDayOffset(text, ref));
      results.addAll(_parseWeekExpressions(text, ref));
    }
    _parseWeekdayWithTime(text, ref, results);
    return results;
  }

  ParsingResult _parseCombinedDateTime(RegExpMatch match, DateTime ref) {
    final dayOffsets = {"今天": 0, "明天": 1, "后天": 2, "昨天": -1};
    final weekOffsets = {"这周": 0, "下周": 1, "上周": -1};
    String? dayGroup = match.group(1);
    int offset = 0;
    bool isWeek = false;
    if (dayOffsets.containsKey(dayGroup)) {
      offset = dayOffsets[dayGroup]!;
    } else if (weekOffsets.containsKey(dayGroup)) {
      isWeek = true;
      offset = weekOffsets[dayGroup]!;
      ref = DateUtils.nextWeekday(ref, 1).add(Duration(days: offset * 7));
    }
    DateTime date = isWeek ? ref : ref.add(Duration(days: offset));
    // 数値部分は中国語数字にも対応するため、parseKanjiOrArabicNumber を使用
    int hour = parseKanjiOrArabicNumber(match.group(3)!);
    int minute = match.group(4) != null ? parseKanjiOrArabicNumber(match.group(4)!) : 0;
    hour = getHourWithPeriod(hour, match.group(2));
    date = DateTime(date.year, date.month, date.day, hour, minute);
    return ParsingResult(index: match.start, text: match.group(0)!, date: date);
  }

  List<ParsingResult> _parseSimpleDayExpressions(String text, DateTime ref) {
    final dayWords = ["今天", "明天", "后天", "昨天"];
    final offsets = [0, 1, 2, -1];
    List<ParsingResult> results = [];
    for (int i = 0; i < dayWords.length; i++) {
      if (text.contains(dayWords[i])) {
        DateTime date = ref.add(Duration(days: offsets[i]));
        date = DateTime(date.year, date.month, date.day);
        results.add(ParsingResult(
            index: text.indexOf(dayWords[i]), text: dayWords[i], date: date));
      }
    }
    return results;
  }

  List<ParsingResult> _parseDayOffset(String text, DateTime ref) {
    final regex = RegExp(r'(\d+|[零一二三四五六七八九十]+)天(后|前)');
    List<ParsingResult> results = [];
    for (var match in regex.allMatches(text)) {
      int days = ChineseNumberUtil.parse(match.group(1)!);
      bool isForward = match.group(2) == "后";
      DateTime date = isForward ? ref.add(Duration(days: days)) : ref.subtract(Duration(days: days));
      // 時刻を 00:00:00 に正規化
      date = DateTime(date.year, date.month, date.day);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }

  List<ParsingResult> _parseWeekExpressions(String text, DateTime ref) {
    List<ParsingResult> results = [];
    final regex = RegExp(r'(下|上|本|这)周[星期周]?([一二三四五六天])');
    for (var match in regex.allMatches(text)) {
      bool isNext = match.group(1) == '下';
      bool isLast = match.group(1) == '上';
      int weekDay = ChineseParserBase.weekdayMap[match.group(2)!]!;
      DateTime date;
      if (isNext) {
        date = DateUtils.nextWeekday(ref, weekDay);
      } else if (isLast) {
        date = DateUtils.firstDayOfWeek(ref).subtract(Duration(days: 7));
      } else {
        int diff = weekDay - ref.weekday;
        date = ref.add(Duration(days: diff));
      }
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(date.year, date.month, date.day)));
    }
    return results;
  }

  void _parseWeekdayWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(
        r'[星期周]([一二三四五六天])\s*(上午|中午|下午|晚上|早上)?\s*(\d{1,2}|[一二三四五六七八九十]+)(?:[点时])(?:\s*(\d{1,2}|[一二三四五六七八九十]+))?分?',
        caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      int target = ChineseParserBase.weekdayMap[match.group(1)!]!;
      int diff = (target - ref.weekday + 7) % 7;
      DateTime base = ref.add(Duration(days: diff));
      int hour = match.group(3) != null ? parseKanjiOrArabicNumber(match.group(3)!) : 0;
      int minute = match.group(4) != null ? parseKanjiOrArabicNumber(match.group(4)!) : 0;
      if (match.group(2) != null) {
        hour = getHourWithPeriod(hour, match.group(2));
      }
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
  }
}

/// 中国語の絶対表現パーサー
class ZhAbsoluteParser extends ChineseParserBase {
  static final RegExp _fullDatePattern = RegExp(
      r'(?:(明年|去年|今年))?([一二三四五六七八九十]+|\d{1,2})月([一二三四五六七八九十]+|\d{1,2})[号日](?:\s*(上午|中午|下午|晚上))?(?:\s*(\d{1,2}|[一二三四五六七八九十]+)(?::|点)(\d{1,2}|[一二三四五六七八九十]+)?(?:分)?)?');
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    final ref = context.referenceDate;
    final regex = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})[号日]');
    for (final match in regex.allMatches(text)) {
      DateTime? date = DateUtils.parseDate(match.group(0)!, reference: ref);
      if (date != null) {
        results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
      }
    }
    _parseMonthDayAndTime(text, ref, results);
    _parseFullDates(text, ref, results);
    _parseKanjiDates(text, ref, results);
    _parseRelativeMonthDay(text, ref, results);
    _parseDayOnly(text, ref, results);
    final monthOnly = RegExp(r'(下月|上月|[0-9一二三四五六七八九十]+)月', caseSensitive: false);
    for (final m in monthOnly.allMatches(text)) {
      int month;
      int year = context.referenceDate.year;
      String token = m.group(1)!;
      DateTime firstDay;
      if (token == "下月") {
        firstDay = DateUtils.firstDayOfNextMonth(context.referenceDate);
      } else if (token == "上月") {
        firstDay = DateUtils.firstDayOfPreviousMonth(context.referenceDate);
      } else {
        month = ChineseNumberUtil.parse(token);
        DateTime candidate = DateTime(year, month, 1);
        if (candidate.isBefore(context.referenceDate)) {
          year++;
          candidate = DateTime(year, month, 1);
        }
        firstDay = candidate;
      }
      results.add(ParsingResult(
          index: m.start,
          text: m.group(0)!,
          date: firstDay,
          rangeType: "month"));
    }
    final weekPattern = RegExp(r'(下周|上周)');
    for (final m in weekPattern.allMatches(text)) {
      String token = m.group(0)!;
      DateTime base = token == "下周"
          ? DateUtils.nextWeekday(context.referenceDate, 1)
          : DateUtils.firstDayOfWeek(context.referenceDate).subtract(Duration(days: 7));
      results.add(ParsingResult(
          index: m.start,
          text: m.group(0)!,
          date: base,
          rangeType: "week"));
    }
    return results;
  }

  void _parseFullDates(String text, DateTime ref, List<ParsingResult> results) {
    for (final match in _fullDatePattern.allMatches(text)) {
      int month = int.tryParse(match.group(2)!) ??
          ChineseNumberUtil.parse(match.group(2)!);
      int day = int.tryParse(match.group(3)!) ??
          ChineseNumberUtil.parse(match.group(3)!);
      int year = ref.year;
      String? prefix = match.group(1);
      if (prefix != null) {
        if (prefix == "明年") {
          year++;
        } else if (prefix == "去年") {
          year--;
        }
      }
      DateTime date = DateTime(year, month, day);
      if (match.group(5) != null) {
        int hour = int.tryParse(match.group(5)!) ??
            ChineseNumberUtil.parse(match.group(5)!);
        int minute = int.tryParse(match.group(6) ?? "0") ??
            ChineseNumberUtil.parse(match.group(6) ?? "0");
        if (match.group(4) != null) {
          hour = getHourWithPeriod(hour, match.group(4));
        }
        date = DateTime(year, month, day, hour, minute);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseKanjiDates(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)[号日]');
    for (final match in regex.allMatches(text)) {
      int month = ChineseNumberUtil.parse(match.group(1)!);
      int day = ChineseNumberUtil.parse(match.group(2)!);
      DateTime date = DateTime(ref.year, month, day);
      date = adjustToFuture(date, ref);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseRelativeMonthDay(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(上|下)个月(\d{1,2})[号日]');
    RegExpMatch? match = regex.firstMatch(text);
    if (match != null) {
      int day = int.parse(match.group(2)!);
      int monthOffset = match.group(1) == '下' ? 1 : -1;
      DateTime date = DateUtils.addMonths(ref, monthOffset);
      date = DateTime(date.year, date.month, day);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseDayOnly(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(\d{1,2})[号日]');
    RegExpMatch? match = regex.firstMatch(text);
    if (match != null) {
      int day = int.parse(match.group(1)!);
      DateTime candidate = DateTime(ref.year, ref.month, day);
      if (candidate.isBefore(ref)) {
        candidate = DateTime(ref.year, ref.month + 1, day);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseMonthDayAndTime(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(?:([一二三四五六七八九十]+)月)?([一二三四五六七八九十]+)[号日]\s*([一二三四五六七八九十]+)点');
    for (final match in regex.allMatches(text)) {
      int year = ref.year;
      int month;
      DateTime date;
      if (match.group(1) != null) {
        month = ChineseNumberUtil.parse(match.group(1)!);
        int day = ChineseNumberUtil.parse(match.group(2)!);
        int hour = ChineseNumberUtil.parse(match.group(3)!);
        if (month < ref.month || (month == ref.month && day < ref.day)) {
          year++;
        }
        date = DateTime(year, month, day, hour, 0);
      } else {
        month = ref.month;
        int day = ChineseNumberUtil.parse(match.group(2)!);
        int hour = ChineseNumberUtil.parse(match.group(3)!);
        date = DateTime(year, month, day, hour, 0);
        if (date.isBefore(ref)) {
          date = DateUtils.addMonths(date, 1);
          date = DateTime(date.year, date.month, day, hour, 0);
        }
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }
}

/// 中国語の時刻表現パーサー
class ZhTimeOnlyParser extends ChineseParserBase {
  static final RegExp _timeReg = RegExp(
      r'((?:[一二三四五六七八九十]+月[一二三四五六七八九十]+[号日])|(?:明天|今天|后天|昨天))?\s*(上午|中午|下午|晚上|早上)?\s*(\d{1,2}|[一二三四五六七八九十]+)(?:[点时:：])(?:\s*(\d{1,2}|[一二三四五六七八九十]+))?(?:分)?');
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    for (final match in _timeReg.allMatches(text)) {
      ParsingResult? result = _parseTimeMatch(match, context.referenceDate, context);
      if (result != null) results.add(result);
    }
    return results;
  }

  ParsingResult? _parseTimeMatch(RegExpMatch match, DateTime refDate, ParsingContext context) {
    String? monthDayStr = match.group(1);
    String? periodStr = match.group(2);
    String hourStr = match.group(3)!;
    String? minuteStr = match.group(4);
    int hour = parseKanjiOrArabicNumber(hourStr);
    int minute = minuteStr != null ? parseKanjiOrArabicNumber(minuteStr) : 0;
    if (periodStr != null) {
      hour = getHourWithPeriod(hour, periodStr);
    }
    DateTime candidate = DateUtils.nextOccurrenceTime(refDate, hour, minute);
    return ParsingResult(index: match.start, text: match.group(0)!, date: candidate);
  }
}

class ZhParsers {
  static final List<BaseParser> parsers = [
    ZhRelativeParser(),
    ZhAbsoluteParser(),
    ZhTimeOnlyParser(),
  ];
}

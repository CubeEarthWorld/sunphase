// lib/languages/zh.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// Utility class for Chinese number parsing
class ChineseNumberUtil {
  static const Map<String, int> numberMap = {
    "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
    "五": 5, "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
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

abstract class ChineseParserBase extends BaseParser {
  static const Map<String, int> weekdayMap = {
    "一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6,
    "日": 7, "天": 7,
  };

  DateTime adjustToFuture(DateTime date, DateTime reference) {
    if (!date.isAfter(reference)) {
      return DateTime(date.year + 1, date.month, date.day, date.hour, date.minute);
    }
    return date;
  }

  int getHourWithPeriod(int hour, String? period) {
    if (period == null) return hour;
    if (period.contains("下午") || period.contains("晚上")) {
      return hour < 12 ? hour + 12 : hour;
    }
    return hour;
  }

  int parseKanjiOrArabicNumber(String text) {
    return ChineseNumberUtil.parse(text);
  }
}

/// Parser for relative expressions like "今天", "明天", "后天", "昨天"
class ZhRelativeParser extends ChineseParserBase {
  static final RegExp _combinedPattern = RegExp(
      r'(今天|明天|后天|昨天)(?:\s*(上午|中午|下午|晚上))?\s*(\d{1,2})点(?:\s*(\d{1,2})分)?'
  );
  static final RegExp _monthOnlyPattern = RegExp(r'^(下月|[0-9一二三四五六七八九十]+)月$', caseSensitive: false);

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    String trimmed = text.trim();
    // 单体相对词（今天、明天、后天、昨天）
    Map<String, int> dayOffsets = {"今天": 0, "明天": 1, "后天": 2, "昨天": -1};
    if (dayOffsets.containsKey(trimmed)) {
      DateTime base = context.referenceDate;
      DateTime date = DateTime(base.year, base.month, base.day).add(Duration(days: dayOffsets[trimmed]!));
      return [ParsingResult(index: 0, text: trimmed, date: date)];
    }
    // 单体"下周"：返回下周整周的起始日期（range_type: week）
    if (trimmed == "下周") {
      int daysToNextMonday = (8 - context.referenceDate.weekday) % 7;
      if (daysToNextMonday == 0) daysToNextMonday = 7;
      DateTime start = DateTime(context.referenceDate.year, context.referenceDate.month, context.referenceDate.day)
          .add(Duration(days: daysToNextMonday));
      return [ParsingResult(index: 0, text: "下周", date: start, rangeType: "week")];
    }
    // 单体月表达，如"下月"或"2月"/"3月"：返回指定月份的第一天，并设置 range_type "month"
    RegExpMatch? m = _monthOnlyPattern.firstMatch(trimmed);
    if (m != null) {
      int month;
      int year = context.referenceDate.year;
      if (m.group(1) == "下月") {
        month = context.referenceDate.month + 1;
        if (month > 12) { month = 1; year++; }
      } else {
        month = ChineseNumberUtil.parse(m.group(1)!);
        DateTime candidate = DateTime(year, month, 1);
        if (candidate.isBefore(context.referenceDate)) {
          year++;
          candidate = DateTime(year, month, 1);
        }
      }
      return [ParsingResult(index: m.start, text: m.group(0)!, date: DateTime(year, month, 1), rangeType: "month")];
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
    int offset = dayOffsets[match.group(1)] ?? 0;
    DateTime date = ref.add(Duration(days: offset));
    int hour = int.parse(match.group(3)!);
    int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
    hour = getHourWithPeriod(hour, match.group(2));
    date = DateTime(date.year, date.month, date.day, hour, minute);
    return ParsingResult(index: match.start, text: match.group(0)!, date: date);
  }

  List<ParsingResult> _parseSimpleDayExpressions(String text, DateTime ref) {
    final dayWords = ["今天", "明天", "后天", "昨天"];
    final dayOffsets = [0, 1, 2, -1];
    List<ParsingResult> results = [];
    for (int i = 0; i < dayWords.length; i++) {
      if (text.contains(dayWords[i])) {
        DateTime date = ref.add(Duration(days: dayOffsets[i]));
        date = DateTime(date.year, date.month, date.day);
        results.add(ParsingResult(index: text.indexOf(dayWords[i]), text: dayWords[i], date: date));
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
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }

  List<ParsingResult> _parseWeekExpressions(String text, DateTime ref) {
    List<ParsingResult> results = [];
    final nextWeekPattern = RegExp(r'下周[星期周]?([一二三四五六天日])');
    var nextWeekMatch = nextWeekPattern.firstMatch(text);
    if (nextWeekMatch != null) {
      results.add(_parseWeekdayExpression(nextWeekMatch, ref, true));
    }
    final thisWeekPattern = RegExp(r'[星期周]([一二三四五六天日])');
    var thisWeekMatch = thisWeekPattern.firstMatch(text);
    if (thisWeekMatch != null) {
      results.add(_parseWeekdayExpression(thisWeekMatch, ref, false));
    }
    return results;
  }

  ParsingResult _parseWeekdayExpression(RegExpMatch match, DateTime ref, bool isNextWeek) {
    int target = ChineseParserBase.weekdayMap[match.group(1)!]!;
    int current = ref.weekday;
    int diff = target - current;
    if (isNextWeek) diff += 7;
    else if (diff < 0) diff += 7;
    DateTime date = ref.add(Duration(days: diff));
    date = DateTime(date.year, date.month, date.day);
    return ParsingResult(index: match.start, text: match.group(0)!, date: date);
  }

  void _parseWeekdayWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'[星期周]([一二三四五六天日])\s*(上午|中午|下午|晚上|早上)?\s*(\d{1,2})(?:[点时])(?:\s*(\d{1,2})分)?', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      int target = ChineseParserBase.weekdayMap[match.group(1)!]!;
      int diff = (target - ref.weekday + 7) % 7;
      if (diff == 0) diff = 7;
      DateTime base = ref.add(Duration(days: diff));
      int hour = int.parse(match.group(3)!);
      int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      if (match.group(2) != null) {
        hour = getHourWithPeriod(hour, match.group(2));
      }
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }
}

/// Parser for absolute expressions in Chinese.
class ZhAbsoluteParser extends ChineseParserBase {
  static final RegExp _fullDatePattern = RegExp(
      r'(?:(明年|去年|今年))?(\d{1,2})月(\d{1,2})[日号](?:\s*(上午|中午|下午|晚上))?(?:\s*(\d{1,2})(?::(\d{2}))?(?:分)?)?'
  );

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    final ref = context.referenceDate;
    _parseFullDates(text, ref, results);
    _parseKanjiDates(text, ref, results);
    _parseRelativeMonthDay(text, ref, results);
    _parseDayOnly(text, ref, results);
    // 对于“◯月”（仅月数字）表达的支持，如 "2月"、"3月"
    final RegExp monthOnly = RegExp(r'([0-9一二三四五六七八九十]+)月(?![日号])');
    for (final match in monthOnly.allMatches(text)) {
      int month = ChineseNumberUtil.parse(match.group(1)!);
      int year = ref.year;
      DateTime candidate = DateTime(year, month, 1);
      if (candidate.isBefore(ref)) {
        year++;
        candidate = DateTime(year, month, 1);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate, rangeType: "month"));
    }
    return results;
  }

  void _parseFullDates(String text, DateTime ref, List<ParsingResult> results) {
    for (final match in _fullDatePattern.allMatches(text)) {
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int year = ref.year;
      String? prefix = match.group(1);
      if (prefix != null) {
        if (prefix == "明年") year++;
        else if (prefix == "去年") year--;
      }
      DateTime date = DateTime(year, month, day);
      if (match.group(5) != null) {
        int hour = int.parse(match.group(5)!);
        int minute = match.group(6) != null ? int.parse(match.group(6)!) : 0;
        if (match.group(4) != null) {
          hour = getHourWithPeriod(hour, match.group(4));
        }
        date = DateTime(year, month, day, hour, minute);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseKanjiDates(String text, DateTime ref, List<ParsingResult> results) {
    final pattern = RegExp(r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)[日号]');
    for (final match in pattern.allMatches(text)) {
      int month = ChineseNumberUtil.parse(match.group(1)!);
      int day = ChineseNumberUtil.parse(match.group(2)!);
      DateTime date = DateTime(ref.year, month, day);
      date = adjustToFuture(date, ref);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseRelativeMonthDay(String text, DateTime ref, List<ParsingResult> results) {
    final exp = RegExp(r'下个月(\d{1,2})[日号]');
    RegExpMatch? match = exp.firstMatch(text);
    if (match != null) {
      int day = int.parse(match.group(1)!);
      DateTime date = DateTime(ref.year, ref.month + 1, day);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseDayOnly(String text, DateTime ref, List<ParsingResult> results) {
    final exp = RegExp(r'(\d{1,2})[日号]');
    RegExpMatch? match = exp.firstMatch(text);
    if (match != null) {
      int day = int.parse(match.group(1)!);
      DateTime candidate = DateTime(ref.year, ref.month, day);
      if (!candidate.isAfter(DateTime(ref.year, ref.month, ref.day, 0, 0, 0))) {
        candidate = DateTime(ref.year, ref.month + 1, day);
        if (candidate.month == 13) candidate = DateTime(ref.year + 1, 1, day);
      }
      candidate = adjustToFuture(candidate, ref);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }
}

/// Parser for time-only expressions in Chinese.
class ZhTimeOnlyParser extends ChineseParserBase {
  static final RegExp _timeReg = RegExp(
      r'([一二三四五六七八九十]+月[一二三四五六七八九十]+号)?\s*(上午|中午|下午|晚上|早上)?\s*(\d{1,2}|[一二三四五六七八九十]+)\s*[点时](?:\s*(\d{1,2}|[一二三四五六七八九十]+))?分?'
  );

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    for (final match in _timeReg.allMatches(text)) {
      ParsingResult? result = _parseTimeMatch(match, context.referenceDate);
      if (result != null) results.add(result);
    }
    return results;
  }

  ParsingResult? _parseTimeMatch(RegExpMatch match, DateTime refDate) {
    String? monthDayStr = match.group(1);
    String? periodStr = match.group(2);
    String hourStr = match.group(3)!;
    String? minuteStr = match.group(4);
    int month = refDate.month;
    int day = refDate.day;
    if (monthDayStr != null) {
      RegExp mdReg = RegExp(r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)号');
      RegExpMatch? mdMatch = mdReg.firstMatch(monthDayStr);
      if (mdMatch != null) {
        month = ChineseNumberUtil.parse(mdMatch.group(1)!);
        day = ChineseNumberUtil.parse(mdMatch.group(2)!);
      }
    }
    int hour = ChineseNumberUtil.parse(hourStr);
    int minute = minuteStr != null ? ChineseNumberUtil.parse(minuteStr) : 0;
    if (periodStr != null) {
      hour = getHourWithPeriod(hour, periodStr);
    }
    DateTime candidate = DateTime(refDate.year, month, day, hour, minute);
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

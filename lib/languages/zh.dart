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
    // Try parsing as regular number first
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
      return (numberMap[input[0]] ?? 0) * 10 + (numberMap[input[1]] ?? 0); // e.g., 二十, 二十一
    }

    if (input.length == 3 && input[1] == '十') { // Handle cases like "二十一" to "九十九"
      return (numberMap[input[0]] ?? 0) * 10 + (numberMap[input[2]] ?? 0);
    }

    return 0; // Handle other cases with "十" if needed, or return 0 as default for unsupported cases.
  }


  static int _parseSimpleNumber(String input) {
    int result = 0;
    for (String char in input.split('')) {
      result = result * 10 + (numberMap[char] ?? 0);
    }
    return result;
  }
}

/// Base class for Chinese date/time parsing
abstract class ChineseParserBase extends BaseParser {
  static const Map<String, int> weekdayMap = {
    "一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6,
    "日": 7, "天": 7,
  };

  DateTime adjustToFuture(DateTime date, DateTime reference) {
    if (!date.isAfter(reference)) {
      return DateTime(date.year + 1, date.month, date.day,
          date.hour, date.minute);
    }
    return date;
  }

  int getHourWithPeriod(int hour, String? period) {
    if (period == null) return hour;

    if (period.contains("下午") || period.contains("晚上")) {
      return hour < 12 ? hour + 12 : hour;
    }
    if (period.contains("中午")) {
      return 12;
    }
    return hour;
  }
}

/// Parser for relative expressions like "今天", "明天", "后天", etc.
class ZhRelativeParser extends ChineseParserBase {
  static final RegExp _combinedPattern = RegExp(
      r'^(今天|明天|后天|昨天)(?:\s*(上午|中午|下午|晚上))?\s*(\d{1,2})点(?:\s*(\d{1,2})分)?$');

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];

    // Parse combined patterns (e.g., "明天上午9点")
    var combinedMatch = _combinedPattern.firstMatch(text);
    if (combinedMatch != null) {
      results.add(_parseCombinedDateTime(combinedMatch, context.referenceDate));
    } else {
      results.addAll(_parseSimpleDayExpressions(text, context.referenceDate));
      results.addAll(_parseDayOffset(text, context.referenceDate));
      results.addAll(_parseWeekExpressions(text, context.referenceDate));
    }

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

    return ParsingResult(
        index: match.start,
        text: match.group(0)!,
        date: date
    );
  }

  List<ParsingResult> _parseSimpleDayExpressions(String text, DateTime ref) {
    final dayWords = ["今天", "明天", "后天", "昨天"];
    final dayOffsets = [0, 1, 2, -1];
    List<ParsingResult> results = [];

    for (int i = 0; i < dayWords.length; i++) {
      if (text.contains(dayWords[i])) {
        DateTime date = ref.add(Duration(days: dayOffsets[i]));
        date = DateTime(date.year, date.month, date.day);
        results.add(ParsingResult(
            index: text.indexOf(dayWords[i]),
            text: dayWords[i],
            date: date
        ));
      }
    }
    return results;
  }

  List<ParsingResult> _parseDayOffset(String text, DateTime ref) {
    final RegExp pattern = RegExp(r'(\d+|[零一二三四五六七八九十]+)天(后|前)');
    List<ParsingResult> results = [];

    for (var match in pattern.allMatches(text)) {
      int days = ChineseNumberUtil.parse(match.group(1)!);
      bool isForward = match.group(2) == "后";

      DateTime date = isForward
          ? ref.add(Duration(days: days))
          : ref.subtract(Duration(days: days));

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date
      ));
    }
    return results;
  }

  List<ParsingResult> _parseWeekExpressions(String text, DateTime ref) {
    List<ParsingResult> results = [];

    // Parse "下周X"
    final nextWeekPattern = RegExp(r'下周[星期周]?([一二三四五六天日])');
    var nextWeekMatch = nextWeekPattern.firstMatch(text);
    if (nextWeekMatch != null) {
      results.add(_parseWeekdayExpression(nextWeekMatch, ref, true));
    }

    // Parse "周X" or "星期X"
    final thisWeekPattern = RegExp(r'[星期周]([一二三四五六天日])');
    var thisWeekMatch = thisWeekPattern.firstMatch(text);
    if (thisWeekMatch != null) {
      results.add(_parseWeekdayExpression(thisWeekMatch, ref, false));
    }

    return results;
  }

  ParsingResult _parseWeekdayExpression(RegExpMatch match, DateTime ref, bool isNextWeek) {
    int targetDay = ChineseParserBase.weekdayMap[match.group(1)!]!;
    int currentDay = ref.weekday;
    int offset = targetDay - currentDay;

    if (isNextWeek) {
      offset += 7;
    } else if (offset < 0) {
      offset += 7;
    }

    DateTime date = ref.add(Duration(days: offset));
    date = DateTime(date.year, date.month, date.day);

    return ParsingResult(
        index: match.start,
        text: match.group(0)!,
        date: date
    );
  }
}

/// Parser for absolute expressions like "4月26号", "2028年5月1号", etc.
class ZhAbsoluteParser extends ChineseParserBase {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    results.addAll(_parseFullDateTime(text, ref));
    results.addAll(_parseKanjiDateTime(text, ref));
    results.addAll(_parseRelativeMonthDay(text, ref));
    results.addAll(_parseDayOnly(text, ref));

    return results;
  }

  List<ParsingResult> _parseFullDateTime(String text, DateTime ref) {
    final pattern = RegExp(
        r'(?:(明年|去年|今年))?(\d{1,2})月(\d{1,2})号(?:\s*(\d{1,2})时(?:\s*(\d{1,2})分)?)?'
    );
    List<ParsingResult> results = [];

    for (var match in pattern.allMatches(text)) {
      String? yearPrefix = match.group(1);
      int year = ref.year;

      switch (yearPrefix) {
        case "明年": year++; break;
        case "去年": year--; break;
      }

      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;

      DateTime date = DateTime(year, month, day, hour, minute);
      if (yearPrefix == null) {
        date = adjustToFuture(date, ref);
      }

      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date
      ));
    }

    return results;
  }

  List<ParsingResult> _parseKanjiDateTime(String text, DateTime ref) {
    final pattern = RegExp(r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)[号]');
    List<ParsingResult> results = [];

    for (var match in pattern.allMatches(text)) {
      int month = ChineseNumberUtil.parse(match.group(1)!);
      int day = ChineseNumberUtil.parse(match.group(2)!);
      DateTime date = DateTime(ref.year, month, day);
      date = adjustToFuture(date, ref);

      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }

  List<ParsingResult> _parseRelativeMonthDay(String text, DateTime ref) {
    List<ParsingResult> results = [];

    // Process "下个月X号"
    ParsingResult? nextMonthResult = _parseMonthDay(text, RegExp(r'下个月(\d{1,2})[号]'), 1, ref);
    if (nextMonthResult != null) {
      results.add(nextMonthResult);
    }

    // Process "上个月X号"
    ParsingResult? lastMonthResult = _parseMonthDay(text, RegExp(r'上个月(\d{1,2})[号]'), -1, ref);
    if (lastMonthResult != null) {
      results.add(lastMonthResult);
    }

    return results;
  }

  ParsingResult? _parseMonthDay(String text, RegExp exp, int monthOffset, DateTime ref) {
    RegExpMatch? match = exp.firstMatch(text);
    if (match != null) {
      int day = int.parse(match.group(1)!);
      DateTime targetMonth = DateTime(ref.year, ref.month + monthOffset, 1);
      DateTime date = DateTime(targetMonth.year, targetMonth.month, day);
      return ParsingResult(index: match.start, text: match.group(0)!, date: date);
    }
    return null;
  }


  List<ParsingResult> _parseDayOnly(String text, DateTime ref) {
    List<ParsingResult> results = [];

    // Process "X号" (numeric)
    ParsingResult? numberDayResult = _parseSingleDay(text, RegExp(r'(\d{1,2})[号]'), ref);
    if (numberDayResult != null) {
      results.add(numberDayResult);
    }

    // Process "X号" (kanji)
    ParsingResult? kanjiDayResult = _parseSingleDay(text, RegExp(r'([一二三四五六七八九十]+)[号]'), ref);
    if (kanjiDayResult != null) {
      results.add(kanjiDayResult);
    }

    return results;
  }


  ParsingResult? _parseSingleDay(String text, RegExp exp, DateTime ref) {
    RegExpMatch? dayMatch = exp.firstMatch(text);
    if (dayMatch != null) {
      int day = exp == RegExp(r'(\d{1,2})[号]') ? int.parse(dayMatch.group(1)!) : ChineseNumberUtil.parse(dayMatch.group(1)!);
      DateTime candidate = DateTime(ref.year, ref.month, day);

      if (!candidate.isAfter(DateTime(ref.year, ref.month, ref.day, 0, 0, 0))) { // If candidate is not after reference date (ignoring time)
        candidate = DateTime(ref.year, ref.month + 1, day);
        if (candidate.month == 13) { // Handle December to January case
          candidate = DateTime(ref.year + 1, 1, day);
        }
      }
      candidate = adjustToFuture(candidate, ref); // Adjust to future if necessary
      return ParsingResult(index: dayMatch.start, text: dayMatch.group(0)!, date: candidate);
    }
    return null;
  }
}

/// Parser for time-only expressions in Chinese.
class ZhTimeOnlyParser extends ChineseParserBase {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];

    // Regex to capture date (optional), period (optional), hour, and minute (optional)
    final regExp = RegExp(
        r'([一二三四五六七八九十]+月[一二三四五六七八九十]+号)?\s*(上午|中午|下午|晚上)?\s*(\d{1,2}|[一二三四五六七八九十]+)\s*点(?:\s*(\d{1,2}|[一二三四五六七八九十]+))?分?');

    for (var match in regExp.allMatches(text)) {
      ParsingResult? result = _parseTimeMatch(match, context.referenceDate);
      if (result != null) {
        results.add(result);
      }
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
      RegExp monthDayRegExp = RegExp(r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)号');
      RegExpMatch? mdMatch = monthDayRegExp.firstMatch(monthDayStr);
      if (mdMatch != null) {
        month = ChineseNumberUtil.parse(mdMatch.group(1)!);
        day = ChineseNumberUtil.parse(mdMatch.group(2)!);
      }
    }

    int hour = ChineseNumberUtil.parse(hourStr);
    int minute = minuteStr != null ? ChineseNumberUtil.parse(minuteStr) : 0;

    hour = getHourWithPeriod(hour, periodStr);

    DateTime candidate = DateTime(refDate.year, month, day, hour, minute);

    return ParsingResult(
        index: match.start, text: match.group(0)!, date: candidate);
  }
}


/// 中文解析器集合
class ZhParsers {
  static final List<BaseParser> parsers = [
    ZhRelativeParser(),
    ZhAbsoluteParser(),
    ZhTimeOnlyParser(),
  ];
}
// lib/languages/zh.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 中文相对表达式解析器
/// （例如：“今天”，“明天”，“后天”，“2天后”，“3天前”，“下周四”等）
class ZhRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    // “今天”
    if (text.contains("今天")) {
      results.add(ParsingResult(
          index: text.indexOf("今天"),
          text: "今天",
          date: DateTime(ref.year, ref.month, ref.day, 0, 0, 0)));
    }
    // “明天”
    if (text.contains("明天")) {
      DateTime tomorrow = DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("明天"),
          text: "明天",
          date: tomorrow));
    }
    // “后天”
    if (text.contains("后天")) {
      DateTime dayAfterTomorrow = DateTime(ref.year, ref.month, ref.day).add(Duration(days: 2));
      results.add(ParsingResult(
          index: text.indexOf("后天"),
          text: "后天",
          date: dayAfterTomorrow));
    }
    // “昨天”
    if (text.contains("昨天")) {
      DateTime yesterday = DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("昨天"),
          text: "昨天",
          date: yesterday));
    }
    // 解析“2天后”、“3天前”等
    RegExp regDay = RegExp(r'(\d+|[零一二三四五六七八九十]+)天(后|前)');
    Iterable<RegExpMatch> matches = regDay.allMatches(text);
    for (var match in matches) {
      String numStr = match.group(1)!;
      int value = _parseChineseNumber(numStr);
      String dir = match.group(2)!;
      DateTime target = (dir == "后") ? ref.add(Duration(days: value)) : ref.subtract(Duration(days: value));
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: target));
    }
    // 解析“下周四”等星期表达式
    Map<String, int> weekdayMap = {
      "周一": 1,
      "星期一": 1,
      "周二": 2,
      "星期二": 2,
      "周三": 3,
      "星期三": 3,
      "周四": 4,
      "星期四": 4,
      "周五": 5,
      "星期五": 5,
      "周六": 6,
      "星期六": 6,
      "周日": 7,
      "星期日": 7,
      "周天": 7,
    };
    RegExp regWeek = RegExp(r'下周\s*([周星期][一二三四五六日天])');
    RegExpMatch? mWeek = regWeek.firstMatch(text);
    if (mWeek != null) {
      String wd = mWeek.group(1)!;
      int? targetWeekday = weekdayMap[wd];
      if (targetWeekday != null) {
        DateTime base = ref.add(Duration(days: 7));
        int currentWeekday = base.weekday;
        int addDays = (targetWeekday - currentWeekday + 7) % 7;
        DateTime targetDate = DateTime(base.year, base.month, base.day).add(Duration(days: addDays));
        results.add(ParsingResult(
            index: mWeek.start,
            text: mWeek.group(0)!,
            date: targetDate));
      }
    }
    return results;
  }

  // 简单解析中文数字（仅支持零到十）
  int _parseChineseNumber(String s) {
    Map<String, int> map = {
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
    int? value = int.tryParse(s);
    if (value != null) return value;
    int result = 0;
    for (int i = 0; i < s.length; i++) {
      result = result * 10 + (map[s[i]] ?? 0);
    }
    return result;
  }
}

/// 中文绝对表达式解析器
/// （例如：“4月26日4时8分”、“2028年5月1日”、“今年12月31日”等）
class ZhAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 支持带有年份的表达式，“2028年5月1日”或“不带年份的，如4月26日”
    RegExp regExp = RegExp(
      r'(?:(\d{2,4}|今年|明年|去年)年)?\s*(\d{1,2})月(\d{1,2})[日号]',
    );
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      String? yearStr = match.group(1);
      int year;
      if (yearStr == null) {
        year = context.referenceDate.year;
      } else if (yearStr == "明年") {
        year = context.referenceDate.year + 1;
      } else if (yearStr == "去年") {
        year = context.referenceDate.year - 1;
      } else if (yearStr == "今年") {
        year = context.referenceDate.year;
      } else {
        year = int.parse(yearStr);
      }
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      DateTime parsedDate = DateTime(year, month, day);
      if (yearStr == null && parsedDate.isBefore(context.referenceDate)) {
        parsedDate = DateTime(year + 1, month, day);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: parsedDate));
    }
    return results;
  }
}

/// 中文时刻表达式解析器
/// （例如：“明天上午9点”，“后天晚上8点”，“昨天中午12点”等）
class ZhTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 处理“上午”、“中午”、“下午”、“晚上”
    RegExp regExp = RegExp(r'(上午|中午|下午|晚上)?\s*(\d{1,2})点');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      String period = match.group(1) ?? "";
      int hour = int.parse(match.group(2)!);
      // 如果包含“下午”或“晚上”，则加12（但12点不再加）
      if ((period.contains("下午") || period.contains("晚上")) && hour < 12) {
        hour += 12;
      }
      DateTime candidate = DateTime(context.referenceDate.year, context.referenceDate.month, context.referenceDate.day, hour, 0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
    return results;
  }
}

/// 中文混合表达式解析器，处理“下个月15号”、“上个月20号”等
class ZhMixedParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;
    // 处理“下个月15号”
    RegExp regNextMonth = RegExp(r'下个月\s*(\d{1,2})号');
    RegExpMatch? mNext = regNextMonth.firstMatch(text);
    if (mNext != null) {
      int day = int.parse(mNext.group(1)!);
      int newMonth = ref.month + 1;
      int newYear = ref.year;
      if (newMonth > 12) {
        newMonth -= 12;
        newYear += 1;
      }
      DateTime target = DateTime(newYear, newMonth, day);
      results.add(ParsingResult(index: mNext.start, text: mNext.group(0)!, date: target));
    }
    // 处理“上个月20号”
    RegExp regLastMonth = RegExp(r'上个月\s*(\d{1,2})号');
    RegExpMatch? mLast = regLastMonth.firstMatch(text);
    if (mLast != null) {
      int day = int.parse(mLast.group(1)!);
      int newMonth = ref.month - 1;
      int newYear = ref.year;
      if (newMonth < 1) {
        newMonth += 12;
        newYear -= 1;
      }
      DateTime target = DateTime(newYear, newMonth, day);
      results.add(ParsingResult(index: mLast.start, text: mLast.group(0)!, date: target));
    }
    return results;
  }
}

/// 中文解析器集合（包含相对、绝对、时刻和混合表达式解析器）
class ZhParsers {
  static final List<BaseParser> parsers = [
    ZhRelativeParser(),
    ZhAbsoluteParser(),
    ZhTimeOnlyParser(),
    ZhMixedParser(),
  ];
}

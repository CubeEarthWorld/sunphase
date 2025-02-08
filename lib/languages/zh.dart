// lib/languages/zh.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// 中文相对表达式解析器
/// （例如：“今天”，“明天”，“后天”，“昨天”，“2天后”，“3天前”，“下周四”等）
class ZhRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    if (text.contains("今天")) {
      results.add(ParsingResult(
          index: text.indexOf("今天"),
          text: "今天",
          date: DateTime(ref.year, ref.month, ref.day, 0, 0, 0)));
    }
    if (text.contains("明天")) {
      DateTime tomorrow =
      DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("明天"), text: "明天", date: tomorrow));
    }
    if (text.contains("后天")) {
      DateTime dayAfterTomorrow =
      DateTime(ref.year, ref.month, ref.day).add(Duration(days: 2));
      results.add(ParsingResult(
          index: text.indexOf("后天"), text: "后天", date: dayAfterTomorrow));
    }
    if (text.contains("昨天")) {
      DateTime yesterday =
      DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("昨天"), text: "昨天", date: yesterday));
    }
    // 处理类似“2天后”、“3天前”的表达
    RegExp regDay = RegExp(r'(\d+|[零一二三四五六七八九十]+)天(后|前)');
    Iterable<RegExpMatch> matches = regDay.allMatches(text);
    for (var match in matches) {
      String numStr = match.group(1)!;
      int value = _parseChineseNumber(numStr);
      String dir = match.group(2)!;
      DateTime target =
      (dir == "后") ? ref.add(Duration(days: value)) : ref.subtract(Duration(days: value));
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: target));
    }
    // 处理“下周”＋星期（例如“下周四”）
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
    };
    RegExp regWeek = RegExp(r'下周\s*([周星期][一二三四五六日])');
    RegExpMatch? mWeek = regWeek.firstMatch(text);
    if (mWeek != null) {
      String wd = mWeek.group(1)!;
      int? target = weekdayMap[wd];
      if (target != null) {
        DateTime base = ref.add(Duration(days: 7));
        int current = base.weekday;
        int addDays = (target - current + 7) % 7;
        DateTime targetDate = DateTime(base.year, base.month, base.day)
            .add(Duration(days: addDays));
        results.add(ParsingResult(index: mWeek.start, text: mWeek.group(0)!, date: targetDate));
      }
    }
    return results;
  }

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
/// （例如：“4月26日4时8分”，“2028年5月1日”，“今年12月31日”等）
class ZhAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    RegExp regExp = RegExp(r'(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})时(?:\s*(\d{1,2})分)?)?');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      int hour = 0, minute = 0;
      if (match.group(3) != null && match.group(3)!.isNotEmpty) {
        hour = int.parse(match.group(3)!);
      }
      if (match.group(4) != null && match.group(4)!.isNotEmpty) {
        minute = int.parse(match.group(4)!);
      }
      int year = context.referenceDate.year;
      DateTime parsedDate = DateTime(year, month, day, hour, minute);
      if (parsedDate.isBefore(context.referenceDate)) {
        parsedDate = DateTime(year + 1, month, day, hour, minute);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: parsedDate));
    }
    return results;
  }
}

/// 中文时刻表达式解析器
/// （例如：“明天上午9点”，“后天晚上8点”，“昨天中午12点”）
class ZhTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    RegExp regExp = RegExp(r'(上午|中午|下午|晚上)?\s*(\d{1,2})点(?:\s*(\d{1,2})分)?');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      String period = match.group(1) ?? "";
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      if ((period.contains("下午") || period.contains("晚上")) && hour < 12) {
        hour += 12;
      } else if (period.contains("中午")) {
        hour = 12;
      }
      DateTime candidate = DateTime(context.referenceDate.year, context.referenceDate.month,
          context.referenceDate.day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
    return results;
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

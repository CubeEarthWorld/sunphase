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

    // 合成模式：例如 "明天上午9点", "后天晚上8点", "昨天12点"
    RegExp combined = RegExp(
        r'^(今天|明天|后天|昨天)(?:\s*(上午|中午|下午|晚上))?\s*(\d{1,2})点(?:\s*(\d{1,2})分)?$');
    RegExpMatch? mCombined = combined.firstMatch(text);
    if (mCombined != null) {
      String dayWord = mCombined.group(1)!;
      int offset = 0;
      if (dayWord == "今天")
        offset = 0;
      else if (dayWord == "明天")
        offset = 1;
      else if (dayWord == "后天")
        offset = 2;
      else if (dayWord == "昨天") offset = -1;
      DateTime candidate = ref.add(Duration(days: offset));
      int hour = int.parse(mCombined.group(3)!);
      int minute =
      mCombined.group(4) != null ? int.parse(mCombined.group(4)!) : 0;
      String? period = mCombined.group(2);
      if (period != null) {
        if ((period.contains("下午") || period.contains("晚上")) && hour < 12) {
          hour += 12;
        } else if (period.contains("中午")) {
          hour = 12;
        }
      }
      candidate =
          DateTime(candidate.year, candidate.month, candidate.day, hour, minute);
      results.add(ParsingResult(
          index: mCombined.start, text: mCombined.group(0)!, date: candidate));
    } else {
      // 分别处理简单表达
      if (text.contains("今天")) {
        results.add(ParsingResult(
            index: text.indexOf("今天"),
            text: "今天",
            date: DateTime(ref.year, ref.month, ref.day, 0, 0, 0)));
      }
      if (text.contains("明天")) {
        DateTime tomorrow =
        DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1));
        results.add(
            ParsingResult(index: text.indexOf("明天"), text: "明天", date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0)));
      }
      if (text.contains("后天")) {
        DateTime dayAfterTomorrow =
        DateTime(ref.year, ref.month, ref.day).add(Duration(days: 2));
        results.add(ParsingResult(
            index: text.indexOf("后天"), text: "后天", date: DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day, 0, 0, 0)));
      }
      if (text.contains("昨天")) {
        DateTime yesterday =
        DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1));
        results.add(ParsingResult(
            index: text.indexOf("昨天"), text: "昨天", date: DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0)));
      }
    }

    // 处理类似“2天后”、“3天前”
    RegExp regDay = RegExp(r'(\d+|[零一二三四五六七八九十]+)天(后|前)');
    Iterable<RegExpMatch> matches = regDay.allMatches(text);
    for (var match in matches) {
      String numStr = match.group(1)!;
      int value = _parseChineseNumber(numStr);
      String dir = match.group(2)!;
      DateTime target = (dir == "后")
          ? ref.add(Duration(days: value))
          : ref.subtract(Duration(days: value));
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: target));
    }

    // 处理“下周”＋星期（例如 “下周四”）
    Map<String, int> wdMap = {
      "一": 1,
      "二": 2,
      "三": 3,
      "四": 4,
      "五": 5,
      "六": 6,
      "日": 7,
      "天": 7, // 兼容“星期天”
    };
    RegExp regNextWeek = RegExp(r'下周[星期周]?([一二三四五六天日])');
    RegExpMatch? mNextWeek = regNextWeek.firstMatch(text);
    if (mNextWeek != null) {
      String wd = mNextWeek.group(1)!;
      int targetWd = wdMap[wd]!;
      int currentWd = ref.weekday;
      int offset = targetWd - currentWd;
      offset = (offset + 7) % 7; // Ensure offset is positive
      if (offset == 0) offset = 7;
      DateTime candidate = ref.add(Duration(days: offset )); // Calculate the target date.
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0); // 時刻を0時0分0秒に設定

      results.add(ParsingResult(
          index: mNextWeek.start, text: mNextWeek.group(0)!, date: candidate));
    }


    // 处理“周”+ 星期 （例如 “周三”, “星期天”）
    RegExp regThisWeek = RegExp(r'[星期周]([一二三四五六天日])');
    RegExpMatch? mThisWeek = regThisWeek.firstMatch(text);
    if (mThisWeek != null) {
      String wd = mThisWeek.group(1)!;
      int targetWd = wdMap[wd]!;
      int currentWd = ref.weekday; // ref 是 referenceDate
      int offset = targetWd - currentWd;
      if (offset < 0) {
        offset = offset + 7;
      }
      DateTime candidate = ref.add(Duration(days: offset));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0); // 時刻を0時0分0秒に設定
      results.add(ParsingResult(
          index: mThisWeek.start, text: mThisWeek.group(0)!, date: candidate));
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
/// （例如：“4月26号4时8分”，“2028年5月1号”，“今年12月31号”，“三月四号”等）
/// 同时支持 "明年1月1号" 以及 "下个月15号"、"上个月20号"
class ZhAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 支持带年份前缀的形式，例如 "明年1月1号"
    RegExp regExp = RegExp(
        r'(?:(明年|去年|今年))?(\d{1,2})月(\d{1,2})号(?:\s*(\d{1,2})时(?:\s*(\d{1,2})分)?)?');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = 0,
          minute = 0;
      if (match.group(4) != null && match.group(4)!.isNotEmpty) {
        hour = int.parse(match.group(4)!);
      }
      if (match.group(5) != null && match.group(5)!.isNotEmpty) {
        minute = int.parse(match.group(5)!);
      }
      int year;
      if (match.group(1) != null) {
        String prefix = match.group(1)!;
        if (prefix == "明年") {
          year = context.referenceDate.year + 1;
        } else if (prefix == "去年") {
          year = context.referenceDate.year - 1;
        } else if (prefix == "今年") {
          year = context.referenceDate.year;
        } else {
          year = context.referenceDate.year;
        }
      } else {
        year = context.referenceDate.year;
        DateTime candidate = DateTime(year, month, day, hour, minute);
        if (!candidate.isAfter(context.referenceDate)) {
          year += 1;
        }
      }
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(year, month, day, hour, minute)));
    }
    // 漢字形式：例如 "三月四号"
    RegExp regKanji = RegExp(
        r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)[号]');
    Iterable<RegExpMatch> kanjiMatches = regKanji.allMatches(text);
    for (var match in kanjiMatches) {
      int month = _parseChineseNumber(match.group(1)!);
      int day = _parseChineseNumber(match.group(2)!);
      int year = context.referenceDate.year;
      DateTime candidate = DateTime(year, month, day);
      if (!candidate.isAfter(context.referenceDate)) {
        candidate = DateTime(year + 1, month, day);
      }
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate));
    }
    // 处理 "下个月15号"
    if (text.contains("下个月")) {
      RegExp exp = RegExp(r'下个月(\d{1,2})[号]');
      RegExpMatch? m = exp.firstMatch(text);
      if (m != null) {
        int day = int.parse(m.group(1)!);
        DateTime nextMonthStart =
        DateTime(
            context.referenceDate.year, context.referenceDate.month + 1, 1);
        DateTime candidate =
        DateTime(nextMonthStart.year, nextMonthStart.month, day);
        results.add(ParsingResult(
            index: m.start, text: m.group(0)!, date: candidate));
      }
    }
    // 处理 "上个月20号"
    if (text.contains("上个月")) {
      RegExp exp = RegExp(r'上个月(\d{1,2})[号]');
      RegExpMatch? m = exp.firstMatch(text);
      if (m != null) {
        int day = int.parse(m.group(1)!);
        DateTime prevMonth = DateTime(
            context.referenceDate.year, context.referenceDate.month - 1, 1);
        DateTime candidate = DateTime(prevMonth.year, prevMonth.month, day);
        results.add(ParsingResult(
            index: m.start, text: m.group(0)!, date: candidate));
      }
    }

    // 处理 "6号" 这样的形式 (数字)
    RegExp dayOnly = RegExp(r'(\d{1,2})[号]');
    RegExpMatch? dayMatch = dayOnly.firstMatch(text);
    if (dayMatch != null) {
      int day = int.parse(dayMatch.group(1)!);
      DateTime candidate =
      DateTime(context.referenceDate.year, context.referenceDate.month, day);
      // 入力日が参照日より前の場合は来月と判断
      if (candidate.isBefore(context.referenceDate) ||
          candidate.month < context.referenceDate.month) {
        candidate =
            DateTime(
                context.referenceDate.year, context.referenceDate.month + 1,
                day);
        if (candidate.month == 1) {
          candidate = DateTime(context.referenceDate.year + 1, 1, day);
        }
      }
      results.add(ParsingResult(
          index: dayMatch.start, text: dayMatch.group(0)!, date: candidate));
    }

    // 处理 "六号" 这样的形式 (漢数字)
    RegExp kanjiDayOnly = RegExp(r'([一二三四五六七八九十]+)[号]');
    RegExpMatch? kanjiDayMatch = kanjiDayOnly.firstMatch(text);
    if (kanjiDayMatch != null) {
      int day = _parseChineseNumber(kanjiDayMatch.group(1)!);
      DateTime candidate =
      DateTime(context.referenceDate.year, context.referenceDate.month, day);
      // 入力日が参照日より前の場合は来月と判断
      if (candidate.isBefore(context.referenceDate) ||
          candidate.month < context.referenceDate.month) {
        candidate =
            DateTime(
                context.referenceDate.year, context.referenceDate.month + 1,
                day);
        if (candidate.month == 1) {
          candidate = DateTime(context.referenceDate.year + 1, 1, day);
        }
      }
      results.add(ParsingResult(
          index: kanjiDayMatch.start,
          text: kanjiDayMatch.group(0)!,
          date: candidate));
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

    if (s.contains("十")) {
      // Handle "十一", "十二", "十三", ..., "十九"
      if (s.length == 2) {
        if (s[0] == '十') {
          return int.parse("1${s[1]}");
        } else {
          return map[s[0]]! * 10 + map[s[1]]!;
        }
      }
      // Handle "二十" to "九十"
      return map[s[0]]! * 10;
    }

    int? value = int.tryParse(s);
    if (value != null) return value;

    int result = 0;
    for (int i = 0; i < s.length; i++) {
      result = result * 10 + (map[s[i]] ?? 0);
    }
    return result;
  }
}

/// 中文时刻表达式解析器
/// （例如：“明天上午9点”，“后天晚上8点”，“昨天中午12点”）
class ZhTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    RegExp regExp = RegExp(r'(上午|中午|下午|晚上)?\s*(\d{1,2}|[一二三四五六七八九十]+)\s*点(?:\s*(\d{1,2}|[一二三四五六七八九十]+))?分?');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      String period = match.group(1) ?? "";
      String hourStr = match.group(2)!;
      String minuteStr = match.group(3) ?? "0"; // Default minute is 0 if not provided

      int hour = ChineseNumberParser.parse(hourStr);
      int minute = ChineseNumberParser.parse(minuteStr);

      if ((period.contains("下午") || period.contains("晚上")) && hour < 12) {
        hour += 12;
      } else if (period.contains("中午")) {
        hour = 12;
      }

      DateTime candidate = DateTime(
          context.referenceDate.year,
          context.referenceDate.month,
          context.referenceDate.day,
          hour,
          minute);

      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate));
    }
    return results;
  }
}

class ChineseNumberParser {
  static int parse(String s) {
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

    if (s.contains("十")) {
      // Handle "十一", "十二", "十三", ..., "十九"
      if (s.length == 2) {
        if (s[0] == '十') {
          return int.parse("1${s[1]}");
        } else {
          return map[s[0]]! * 10 + map[s[1]]!;
        }
      }
      // Handle "二十" to "九十"
      return map[s[0]]! * 10;
    }

    int? value = int.tryParse(s);
    if (value != null) return value;

    int result = 0;
    for (int i = 0; i < s.length; i++) {
      result = result * 10 + (map[s[i]] ?? 0);
    }
    return result;
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
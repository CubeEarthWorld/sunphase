// lib/languages/zh.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 中文相对表达式解析器
/// （例如：“今天”，“明天”，“后天”，“昨天”，“2天后”，“3天前”，“下周四”等）
class ZhRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    // --- 组合模式：相对日期＋时刻（例如“明天上午9点”，“后天晚上8点”，“昨天中午12点”） ---
    RegExp combined = RegExp(r'(今天|明天|后天|昨天)(?:\s*(上午|中午|下午|晚上))?\s*(\d{1,2})点(?:\s*(\d{1,2})分)?');
    Iterable<RegExpMatch> combinedMatches = combined.allMatches(text);
    for (var m in combinedMatches) {
      String dayWord = m.group(1)!;
      int offset = 0;
      if (dayWord == "今天") offset = 0;
      else if (dayWord == "明天") offset = 1;
      else if (dayWord == "后天") offset = 2;
      else if (dayWord == "昨天") offset = -1;
      DateTime candidate = ref.add(Duration(days: offset));
      String? period = m.group(2);
      int hour = int.parse(m.group(3)!);
      int minute = m.group(4) != null ? int.parse(m.group(4)!) : 0;
      if (period != null) {
        if ((period.contains("下午") || period.contains("晚上")) && hour < 12) {
          hour += 12;
        } else if (period.contains("中午")) {
          hour = 12;
        }
      }
      candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, minute);
      // 若候选时刻不在未来，则加一天（通常不発生）
      if (!candidate.isAfter(ref)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(index: m.start, text: m.group(0)!, date: candidate));
    }

    // --- 如果未匹配带时刻的情况，则处理纯相对日期（例如“今天”“明天”“后天”“昨天”） ---
    RegExp plainRelative = RegExp(r'^(今天|明天|后天|昨天)$');
    if (plainRelative.hasMatch(text)) {
      String dayWord = plainRelative.firstMatch(text)!.group(1)!;
      int offset = 0;
      if (dayWord == "今天") offset = 0;
      else if (dayWord == "明天") offset = 1;
      else if (dayWord == "后天") offset = 2;
      else if (dayWord == "昨天") offset = -1;
      DateTime candidate = ref.add(Duration(days: offset));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      results.add(ParsingResult(index: text.indexOf(dayWord), text: dayWord, date: candidate));
    }

    // 处理“2天后”、“3天前”等表达
    RegExp regDay = RegExp(r'(\d+|[零一二三四五六七八九十]+)天(后|前)');
    Iterable<RegExpMatch> dayMatches = regDay.allMatches(text);
    for (var match in dayMatches) {
      String numStr = match.group(1)!;
      int value = _parseChineseNumber(numStr);
      String dir = match.group(2)!;
      DateTime target = (dir == "后") ? ref.add(Duration(days: value)) : ref.subtract(Duration(days: value));
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: target));
    }

    // 处理“下周”＋星期（例如“下周四”）【这里假设中文一周从周一开始】
    RegExp regWeek = RegExp(r'下周\s*([周星期][一二三四五六日])');
    RegExpMatch? mWeek = regWeek.firstMatch(text);
    if (mWeek != null) {
      String wdStr = mWeek.group(1)!; // e.g. "周四"或"星期四"
      Map<String, int> isoWeekdayMap = {
        "周一": 1, "星期一": 1,
        "周二": 2, "星期二": 2,
        "周三": 3, "星期三": 3,
        "周四": 4, "星期四": 4,
        "周五": 5, "星期五": 5,
        "周六": 6, "星期六": 6,
        "周日": 7, "星期日": 7,
      };
      int targetIso = isoWeekdayMap[wdStr]!;
      // 下周的起始日期：本周（从周一开始）的下一周的周一
      int daysToNextMonday = (8 - ref.weekday);
      if (daysToNextMonday <= 0) daysToNextMonday += 7;
      DateTime nextMonday = DateTime(ref.year, ref.month, ref.day).add(Duration(days: daysToNextMonday));
      DateTime candidate = nextMonday.add(Duration(days: (targetIso - 1)));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      results.add(ParsingResult(index: mWeek.start, text: mWeek.group(0)!, date: candidate));
    }

    return results;
  }

  int _parseChineseNumber(String s) {
    Map<String, int> map = {
      "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
      "五": 5, "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
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
    // 先匹配阿拉伯数字形式
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

    // 处理“今年”、“明年”、“去年”前缀的情况
    RegExp regExpYear = RegExp(r'(今年|明年|去年)(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})时(?:\s*(\d{1,2})分)?)?');
    Iterable<RegExpMatch> yearMatches = regExpYear.allMatches(text);
    for (var match in yearMatches) {
      String prefix = match.group(1)!;
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = 0, minute = 0;
      if (match.group(4) != null && match.group(4)!.isNotEmpty) {
        hour = int.parse(match.group(4)!);
      }
      if (match.group(5) != null && match.group(5)!.isNotEmpty) {
        minute = int.parse(match.group(5)!);
      }
      int year;
      if (prefix == "明年") {
        year = context.referenceDate.year + 1;
      } else if (prefix == "去年") {
        year = context.referenceDate.year - 1;
      } else { // "今年"
        year = context.referenceDate.year;
      }
      DateTime parsedDate = DateTime(year, month, day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: parsedDate));
    }

    // 匹配汉字形式：例如 "三月四号"
    RegExp regKanji = RegExp(r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)[日号]');
    Iterable<RegExpMatch> kanjiMatches = regKanji.allMatches(text);
    for (var match in kanjiMatches) {
      int month = _parseChineseNumber(match.group(1)!);
      int day = _parseChineseNumber(match.group(2)!);
      int year = context.referenceDate.year;
      DateTime parsedDate = DateTime(year, month, day);
      if (parsedDate.isBefore(context.referenceDate)) {
        parsedDate = DateTime(year + 1, month, day);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: parsedDate));
    }

    // --- 新增：处理“下个月15号”、“上个月20号” ---
    RegExp regRelMonth = RegExp(r'(下个?月|上个?月)(\d{1,2})[日号]');
    RegExpMatch? mRelMonth = regRelMonth.firstMatch(text);
    if (mRelMonth != null) {
      String prefix = mRelMonth.group(1)!;
      int day = int.parse(mRelMonth.group(2)!);
      int month = context.referenceDate.month;
      int year = context.referenceDate.year;
      if (prefix.startsWith("下")) {
        month += 1;
        if (month > 12) { month = 1; year += 1; }
      } else if (prefix.startsWith("上")) {
        month -= 1;
        if (month < 1) { month = 12; year -= 1; }
      }
      DateTime candidate = DateTime(year, month, day);
      results.add(ParsingResult(index: mRelMonth.start, text: mRelMonth.group(0)!, date: candidate));
    }

    return results;
  }

  int _parseChineseNumber(String s) {
    Map<String, int> map = {
      "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
      "五": 5, "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
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
      DateTime candidate = DateTime(context.referenceDate.year, context.referenceDate.month, context.referenceDate.day, hour, minute);
      if (!candidate.isAfter(context.referenceDate)) {
        candidate = candidate.add(Duration(days: 1));
      }
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

// lib/languages/zh.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 中国語の相対表現（例：「今天」「明天」「下周」など）に対応するパーサー。
class ZhRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    // "今天"
    if (text.contains("今天")) {
      results.add(ParsingResult(
          index: text.indexOf("今天"),
          text: "今天",
          date: DateTime(ref.year, ref.month, ref.day, 0, 0, 0)));
    }
    // "明天"
    if (text.contains("明天")) {
      DateTime tomorrow = DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("明天"),
          text: "明天",
          date: tomorrow));
    }
    // "昨天"
    if (text.contains("昨天")) {
      DateTime yesterday = DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("昨天"),
          text: "昨天",
          date: yesterday));
    }
    // "下周"
    if (text.contains("下周")) {
      DateTime nextWeek = ref.add(Duration(days: 7));
      results.add(ParsingResult(
          index: text.indexOf("下周"),
          text: "下周",
          date: nextWeek));
    }
    // "上周"
    if (text.contains("上周")) {
      DateTime lastWeek = ref.subtract(Duration(days: 7));
      results.add(ParsingResult(
          index: text.indexOf("上周"),
          text: "上周",
          date: lastWeek));
    }
    // "下个月"
    if (text.contains("下个月")) {
      DateTime nextMonth = DateTime(ref.year, ref.month + 1, ref.day);
      results.add(ParsingResult(
          index: text.indexOf("下个月"),
          text: "下个月",
          date: nextMonth));
    }
    // "上个月"
    if (text.contains("上个月")) {
      DateTime lastMonth = DateTime(ref.year, ref.month - 1, ref.day);
      results.add(ParsingResult(
          index: text.indexOf("上个月"),
          text: "上个月",
          date: lastMonth));
    }
    // "明年"
    if (text.contains("明年")) {
      DateTime nextYear = DateTime(ref.year + 1, ref.month, ref.day);
      results.add(ParsingResult(
          index: text.indexOf("明年"),
          text: "明年",
          date: nextYear));
    }
    // "今年"
    if (text.contains("今年")) {
      results.add(ParsingResult(
          index: text.indexOf("今年"),
          text: "今年",
          date: DateTime(ref.year, ref.month, ref.day)));
    }
    return results;
  }
}

/// 中国語の絶対表現（例：「4月26日」や「4月26日4时8分」）に対応するパーサー。
class ZhAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 正規表現で「4月26日」または「4月26日4时8分」形式を検出
    RegExp regExp = RegExp(r'(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})[时:：](?:\s*(\d{1,2})[分]?)?)?');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      int hour = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
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

/// 中国語パーサー群をまとめたクラス。
class ZhParsers {
  static final List<BaseParser> parsers = [
    ZhRelativeParser(),
    ZhAbsoluteParser(),
  ];
}

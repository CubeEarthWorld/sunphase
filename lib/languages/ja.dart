// lib/languages/ja.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 日本語の相対表現（例：「今日」「明日」「来週」など）に対応するパーサー。
class JaRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    // "今日"
    if (text.contains("今日")) {
      results.add(ParsingResult(
          index: text.indexOf("今日"),
          text: "今日",
          date: DateTime(ref.year, ref.month, ref.day, 0, 0, 0)));
    }
    // "明日"
    if (text.contains("明日")) {
      DateTime tomorrow = DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("明日"),
          text: "明日",
          date: tomorrow));
    }
    // "昨日"
    if (text.contains("昨日")) {
      DateTime yesterday = DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("昨日"),
          text: "昨日",
          date: yesterday));
    }
    // "来週"
    if (text.contains("来週")) {
      DateTime nextWeek = ref.add(Duration(days: 7));
      results.add(ParsingResult(
          index: text.indexOf("来週"),
          text: "来週",
          date: nextWeek));
    }
    // "先週"
    if (text.contains("先週")) {
      DateTime lastWeek = ref.subtract(Duration(days: 7));
      results.add(ParsingResult(
          index: text.indexOf("先週"),
          text: "先週",
          date: lastWeek));
    }
    // "来月"
    if (text.contains("来月")) {
      DateTime nextMonth = DateTime(ref.year, ref.month + 1, ref.day);
      results.add(ParsingResult(
          index: text.indexOf("来月"),
          text: "来月",
          date: nextMonth));
    }
    // "先月"
    if (text.contains("先月")) {
      DateTime lastMonth = DateTime(ref.year, ref.month - 1, ref.day);
      results.add(ParsingResult(
          index: text.indexOf("先月"),
          text: "先月",
          date: lastMonth));
    }
    // "来年"
    if (text.contains("来年")) {
      DateTime nextYear = DateTime(ref.year + 1, ref.month, ref.day);
      results.add(ParsingResult(
          index: text.indexOf("来年"),
          text: "来年",
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

/// 日本語の絶対表現（例：「4月26日」や「4月26日4時8分」）に対応するパーサー。
class JaAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 正規表現で「4月26日」または「4月26日4時8分」形式を検出
    RegExp regExp = RegExp(r'(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})時(?:\s*(\d{1,2})分)?)?');
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

/// 日本語の時刻のみの表現（例：「21時31分」「10時5分」）に対応するパーサー。
class JaTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    RegExp regExp = RegExp(r'(\d{1,2})時(?:\s*(\d{1,2})分)?');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      DateTime candidate = DateTime(context.referenceDate.year, context.referenceDate.month, context.referenceDate.day, hour, minute);
      if (candidate.isBefore(context.referenceDate)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
    return results;
  }
}

/// 日本語パーサー群をまとめたクラス。
class JaParsers {
  static final List<BaseParser> parsers = [
    JaRelativeParser(),
    JaAbsoluteParser(),
    JaTimeOnlyParser(),
  ];
}

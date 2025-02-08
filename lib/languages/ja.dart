// lib/languages/ja.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 日本語の相対表現を解析するパーサー
/// （例：「今日」「明日」「明後日」「来週」「土曜」「来週火曜」「2週間後」「三日後」など）
class JaRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    // 「今日」
    if (text.contains("今日")) {
      results.add(ParsingResult(
          index: text.indexOf("今日"),
          text: "今日",
          date: DateTime(ref.year, ref.month, ref.day, 0, 0, 0)));
    }
    // 「明日」
    if (text.contains("明日") && !text.contains("明後日")) {
      DateTime tomorrow = DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1));
      results.add(ParsingResult(
          index: text.indexOf("明日"),
          text: "明日",
          date: tomorrow));
    }
    // 「明後日」
    if (text.contains("明後日")) {
      DateTime dayAfterTomorrow = DateTime(ref.year, ref.month, ref.day).add(Duration(days: 2));
      results.add(ParsingResult(
          index: text.indexOf("明後日"),
          text: "明後日",
          date: dayAfterTomorrow));
    }
    // 曜日（単体）の指定、例：「土曜」
    Map<String, int> weekdayMap = {
      "月曜": 1,
      "火曜": 2,
      "水曜": 3,
      "木曜": 4,
      "金曜": 5,
      "土曜": 6,
      "日曜": 7,
    };
    for (var entry in weekdayMap.entries) {
      if (text.trim() == entry.key) {
        int currentWeekday = ref.weekday;
        int target = entry.value;
        int daysToAdd = (target - currentWeekday + 7) % 7;
        if (daysToAdd == 0) daysToAdd = 7; // 同じ曜日の場合は次の週
        DateTime targetDate = DateTime(ref.year, ref.month, ref.day).add(Duration(days: daysToAdd));
        results.add(ParsingResult(
            index: text.indexOf(entry.key),
            text: entry.key,
            date: targetDate));
      }
    }
    // 「来週」と曜日の組み合わせ（例：「来週火曜」）
    RegExp regWeekday = RegExp(r'来週\s*([月火水木金土日]曜)');
    RegExpMatch? mWeekday = regWeekday.firstMatch(text);
    if (mWeekday != null) {
      String weekdayStr = mWeekday.group(1)!;
      int? targetWeekday = weekdayMap[weekdayStr];
      if (targetWeekday != null) {
        DateTime base = ref.add(Duration(days: 7));
        int current = base.weekday;
        int addDays = (targetWeekday - current + 7) % 7;
        DateTime targetDate = DateTime(base.year, base.month, base.day).add(Duration(days: addDays));
        results.add(ParsingResult(
            index: mWeekday.start,
            text: mWeekday.group(0)!,
            date: targetDate));
      }
    }
    // 数値を含む相対表現（例：「2週間後」「三日後」「4日後」）
    RegExp regRelative = RegExp(r'([0-9一二三四五六七八九十]+)(日|週間|ヶ月)後');
    Iterable<RegExpMatch> matches = regRelative.allMatches(text);
    for (var match in matches) {
      String numStr = match.group(1)!;
      int value = _parseJapaneseNumber(numStr);
      String unit = match.group(2)!;
      DateTime target;
      if (unit == "日") {
        target = ref.add(Duration(days: value));
      } else if (unit == "週間") {
        target = ref.add(Duration(days: value * 7));
      } else if (unit == "ヶ月") {
        int newMonth = ref.month + value;
        int newYear = ref.year + ((newMonth - 1) ~/ 12);
        newMonth = ((newMonth - 1) % 12) + 1;
        target = DateTime(newYear, newMonth, ref.day);
      } else {
        continue;
      }
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: target));
    }
    return results;
  }

  // 簡易な漢数字およびアラビア数字の変換
  int _parseJapaneseNumber(String s) {
    int? value = int.tryParse(s);
    if (value != null) return value;
    Map<String, int> kanji = {
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
    int result = 0;
    for (int i = 0; i < s.length; i++) {
      result = result * 10 + (kanji[s[i]] ?? 0);
    }
    return result;
  }
}

/// 日本語の絶対表現を解析するパーサー
/// （例：「4月26日」、「4月26日4時8分」、「来年4月1日」、「2028年5月1日」、「三月六号十一点」など）
class JaAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 年の指定にも対応する正規表現（「2028年」や「来年」など）
    RegExp regExp = RegExp(
      r'(?:(\d{2,4}|来年|去年|今年)年)?\s*(\d{1,2})月(\d{1,2})[日号]',
    );
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      String? yearStr = match.group(1);
      int year;
      if (yearStr == null) {
        year = context.referenceDate.year;
      } else if (yearStr == "来年") {
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
      // 年未指定の場合、もし既に過ぎていれば翌年とする
      if (yearStr == null && parsedDate.isBefore(context.referenceDate)) {
        parsedDate = DateTime(year + 1, month, day);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: parsedDate));
    }
    return results;
  }
}

/// 日本語の時刻のみの表現を解析するパーサー
/// （例：「21時31分」「10時5分」など）
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

/// 日本語パーサー群の集合
class JaParsers {
  static final List<BaseParser> parsers = [
    JaRelativeParser(),
    JaAbsoluteParser(),
    JaTimeOnlyParser(),
  ];
}

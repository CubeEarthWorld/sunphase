// lib/languages/ja.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// 日本語の相対表現解析パーサー
/// （例：「今日」「明日」「明後日」「昨日」「来週火曜」「来週日曜11時」「2週間後」「5日以内」「三日以内」など）
class JaRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;

    // --- 「今日」「明日」「明後日」「昨日」＋任意の時刻指定の組み合わせ ---
    RegExp combined = RegExp(r'(今日|明日|明後日|昨日)(?:(\d{1,2})時)?');
    RegExpMatch? mCombined = combined.firstMatch(text);
    if (mCombined != null) {
      String dayWord = mCombined.group(1)!;
      int offset = 0;
      if (dayWord == "今日") offset = 0;
      else if (dayWord == "明日") offset = 1;
      else if (dayWord == "明後日") offset = 2;
      else if (dayWord == "昨日") offset = -1;
      DateTime candidate = ref.add(Duration(days: offset));
      if (mCombined.group(2) != null) {
        int hour = int.parse(mCombined.group(2)!);
        candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, 0, 0);
      } else {
        candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      }
      results.add(ParsingResult(index: mCombined.start, text: mCombined.group(0)!, date: candidate));
    }

    // --- 「来週」＋曜日（任意時刻指定）の場合（例：「来週火曜」「来週日曜11時」） ---
    RegExp regNextWeekday = RegExp(r'来週([月火水木金土日]曜)(?:(\d{1,2})時)?');
    RegExpMatch? mNextWeekday = regNextWeekday.firstMatch(text);
    if (mNextWeekday != null) {
      String weekdayStr = mNextWeekday.group(1)!;
      Map<String, int> weekdayMap = {
        "日曜": 1,
        "月曜": 2,
        "火曜": 3,
        "水曜": 4,
        "木曜": 5,
        "金曜": 6,
        "土曜": 7,
      };
      int targetDay = weekdayMap[weekdayStr]!;
      // 日本語では週の始まりを日曜とする（ref.weekday は月曜=1～日曜=7 なので変換）
      int currentJap = ((ref.weekday % 7) + 1);
      int diff = (targetDay - currentJap + 7) % 7;
      if (diff == 0) diff = 7;
      DateTime candidate = ref.add(Duration(days: diff));
      if (mNextWeekday.group(2) != null) {
        int hour = int.parse(mNextWeekday.group(2)!);
        candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, 0, 0);
      } else {
        candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      }
      results.add(ParsingResult(index: mNextWeekday.start, text: mNextWeekday.group(0)!, date: candidate));
    }

    // --- 「X日以内」など range 表現の場合（今日を含むので rangeDays = X+1） ---
    RegExp withinDays = RegExp(r'([0-9一二三四五六七八九十]+)日以内');
    RegExpMatch? mWithin = withinDays.firstMatch(text);
    if (mWithin != null) {
      int days = _parseJapaneseNumber(mWithin.group(1)!);
      results.add(ParsingResult(
          index: mWithin.start,
          text: mWithin.group(0)!,
          date: ref,
          rangeDays: days + 1));
    }

    // --- 数字を含む相対表現（例：「2週間後」「三日後」「4日後」「1ヶ月後」） ---
    RegExp regRelative = RegExp(r'([0-9一二三四五六七八九十]+)(日|週間|ヶ月)後');
    Iterable<RegExpMatch> matchesRel = regRelative.allMatches(text);
    for (var match in matchesRel) {
      String numStr = match.group(1)!;
      int value = _parseJapaneseNumber(numStr);
      String unit = match.group(2)!;
      DateTime candidate;
      if (unit == "日") {
        candidate = ref.add(Duration(days: value));
      } else if (unit == "週間") {
        candidate = ref.add(Duration(days: value * 7));
      } else if (unit == "ヶ月") {
        int newMonth = ref.month + value;
        int newYear = ref.year + ((newMonth - 1) ~/ 12);
        newMonth = ((newMonth - 1) % 12) + 1;
        candidate = DateTime(newYear, newMonth, ref.day);
      } else {
        continue;
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }

    // --- 固定表現 ---
    // 「来週」が単独の場合は、range_type = "week"（次週の初日から7日分）
    if (text.trim() == "来週") {
      int daysToSunday = (8 - ((ref.weekday % 7) + 1)) % 7;
      if (daysToSunday == 0) daysToSunday = 7;
      DateTime startOfWeek =
      DateTime(ref.year, ref.month, ref.day).add(Duration(days: daysToSunday));
      results.add(ParsingResult(
          index: text.indexOf("来週"),
          text: "来週",
          date: startOfWeek,
          rangeType: "week"));
    }
    if (text.contains("先週")) {
      DateTime lastWeek = ref.subtract(Duration(days: 7));
      results.add(ParsingResult(index: text.indexOf("先週"), text: "先週", date: lastWeek));
    }
    // 「来月」が単独の場合は、range_type = "month"（次月の1日からその月末まで）
    if (text.trim() == "来月") {
      DateTime nextMonthStart = DateTime(ref.year, ref.month + 1, 1);
      results.add(ParsingResult(
          index: text.indexOf("来月"),
          text: "来月",
          date: nextMonthStart,
          rangeType: "month"));
    }
    if (text.contains("先月")) {
      DateTime lastMonth = DateTime(ref.year, ref.month - 1, ref.day);
      results.add(ParsingResult(index: text.indexOf("先月"), text: "先月", date: lastMonth));
    }
    if (text.contains("来年")) {
      DateTime nextYear = DateTime(ref.year + 1, ref.month, ref.day);
      results.add(ParsingResult(index: text.indexOf("来年"), text: "来年", date: nextYear));
    }
    if (text.contains("今年")) {
      results.add(ParsingResult(
          index: text.indexOf("今年"),
          text: "今年",
          date: DateTime(ref.year, ref.month, ref.day)));
    }

    return results;
  }

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

/// Parser for absolute date expressions in Japanese.
class JaAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 阿拉伯数字形式：例 "4月26日4時8分"
    RegExp regExp = RegExp(r'(?:(今年|来年|去年))?(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})時(?:\s*(\d{1,2})分)?)?');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
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
      if (match.group(1) != null) {
        String prefix = match.group(1)!;
        if (prefix == "来年") {
          year = context.referenceDate.year + 1;
        } else if (prefix == "去年") {
          year = context.referenceDate.year - 1;
        } else {
          year = context.referenceDate.year;
        }
      } else {
        year = context.referenceDate.year;
        DateTime candidate = DateTime(year, month, day, hour, minute);
        if (candidate.isBefore(context.referenceDate)) {
          year += 1;
        }
      }
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(year, month, day, hour, minute)));
    }

    // 漢数字形式：例 "三月四号" または "三月六号十一点"
    RegExp regKanji = RegExp(r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)[日号](?:(\d{1,2})時)?(?:(\d{1,2})分)?');
    Iterable<RegExpMatch> kanjiMatches = regKanji.allMatches(text);
    for (var match in kanjiMatches) {
      int month = _parseJapaneseNumber(match.group(1)!);
      int day = _parseJapaneseNumber(match.group(2)!);
      int hour = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int year = context.referenceDate.year;
      DateTime candidate = DateTime(year, month, day, hour, minute);
      if (candidate.isBefore(context.referenceDate)) {
        year += 1;
        candidate = DateTime(year, month, day, hour, minute);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }

    return results;
  }

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

/// Parser for time-only expressions in Japanese.
class JaTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    RegExp regExp = RegExp(r'(\d{1,2})時(?:\s*(\d{1,2})分)?');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      DateTime candidate = DateTime(context.referenceDate.year, context.referenceDate.month,
          context.referenceDate.day, hour, minute);
      if (!candidate.isAfter(context.referenceDate)) {
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

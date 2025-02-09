// lib/languages/ja.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// 日本語の日時表現パターンを定義する定数クラス
class JaPatterns {
  static const Map<String, int> weekdayMap = {
    "月曜": 1, "火曜": 2, "水曜": 3, "木曜": 4,
    "金曜": 5, "土曜": 6, "日曜": 7,
    "月曜日": 1, "火曜日": 2, "水曜日": 3, "木曜日": 4, "金曜日": 5, "土曜日": 6, "日曜日": 7,
  };

  static const Map<String, int> kanjiNumbers = {
    "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
    "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
    "十": 10, "百": 100, "千": 1000
  };

  static const Map<String, int> relativeTimeOffsets = {
    "今日": 0,
    "明日": 1,
    "明後日": 2,
    "明々後日": 3,
    "昨日": -1
  };
}

/// 日本語の数値変換ユーティリティ
class JaNumberConverter {
  static int parse(String input) {
    int? value = int.tryParse(input);
    if (value != null) return value;
    int result = 0;
    int tempValue = 0;
    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      int? number = JaPatterns.kanjiNumbers[char];
      if (number != null) {
        if (char == "十") {
          tempValue = tempValue == 0 ? 10 : tempValue * 10;
        } else if (char == "百" || char == "千") {
          tempValue = tempValue == 0 ? number : tempValue * number;
        } else {
          if (tempValue == 0) {
            tempValue = number;
          } else {
            result += tempValue;
            tempValue = number;
          }
        }
      }
    }
    return result + tempValue;
  }
}

abstract class BaseJaParser extends BaseParser {
  DateTime adjustForPastDate(DateTime date, ParsingContext context) {
    if (date.isBefore(context.referenceDate)) {
      if (date.month < context.referenceDate.month) {
        return DateTime(date.year + 1, date.month, date.day, date.hour, date.minute);
      }
    }
    return date;
  }
  int parseKanjiOrArabicNumber(String text) {
    return JaNumberConverter.parse(text);
  }
}

/// 日本語の相対表現パーサー
class JaRelativeParser extends BaseJaParser {
  // 修正後の正規表現：キーワードの場合は末尾の「月」を含めてキャプチャ、数字の場合は「月」付きとなる
  static final RegExp _monthOnlyPattern = RegExp(
    r'^(?:(来月|今月|再来月|先月)|([0-9一二三四五六七八九十]+月))$',
    caseSensitive: false,
  );

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    if (!RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]').hasMatch(text)) {
      return [];
    }
    String trimmed = text.trim();
    List<ParsingResult> results = [];

    // 例：文中の相対語（明日、今日等）をすべて抽出（既存処理）
    RegExp relativeWordRegex = RegExp(r'(明日|今日|明後日|明々後日|昨日)', caseSensitive: false);
    for (final match in relativeWordRegex.allMatches(text)) {
      String token = match.group(0)!;
      if (JaPatterns.relativeTimeOffsets.containsKey(token)) {
        int offset = JaPatterns.relativeTimeOffsets[token]!;
        DateTime base = context.referenceDate;
        DateTime date = DateTime(base.year, base.month, base.day)
            .add(Duration(days: offset));
        results.add(ParsingResult(index: match.start, text: token, date: date));
      }
    }

    // 月単体の表現
    RegExpMatch? m = _monthOnlyPattern.firstMatch(trimmed);
    if (m != null) {
      int year = context.referenceDate.year;
      int month;
      String token;
      if (m.group(1) != null) {
        // キーワードの場合はグループ1に、例："来月", "再来月", "先月", "今月"
        token = m.group(1)!;
      } else if (m.group(2) != null) {
        // 数字表記の場合はグループ2に、例："十二月" や "3月" がキャプチャされるので末尾の "月" を除去
        token = m.group(2)!.replaceAll("月", "");
      } else {
        token = "";
      }
      if (token == "今月") {
        month = context.referenceDate.month;
      } else if (token == "来月") {
        month = context.referenceDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
      } else if (token == "再来月") {
        month = context.referenceDate.month + 2;
        if (month > 12) {
          month = ((month - 1) % 12) + 1;
          year += (context.referenceDate.month + 2 - 1) ~/ 12;
        }
      } else if (token == "先月") {
        month = context.referenceDate.month - 1;
        if (month < 1) {
          month = 12;
          year--;
        }
      } else {
        // 数字の場合
        month = JaNumberConverter.parse(token);
        if (month < context.referenceDate.month) {
          year++;
        }
      }
      // ※ここでは必ず1日を返す
      DateTime firstDay = DateTime(year, month, 1);
      // 翌月1日から1日引くことで対象月の最終日を取得
      DateTime lastDay = DateTime(year, month + 1, 1).subtract(Duration(days: 1));
      int rangeDays = lastDay.day;
      results.add(ParsingResult(
        index: m.start,
        text: m.group(0)!,
        date: firstDay,
        rangeType: "month",
        rangeDays: rangeDays,
      ));
      // もし入力全体が月単体の表現であれば、ここで return して他のパーサー処理はスキップ
      if (trimmed == m.group(0)!) {
        return results;
      }
    }

    // --- 以下、その他のパーサー処理（既存メソッドの呼び出し） ---
    _parseFullDate(text, results);
    _parseMonthDayTime(text, context, results);
    _parseMonthDay(text, context, results);
    _parseWeekExpression(text, context.referenceDate, results);
    _parseDayWithTime(text, context.referenceDate, results);
    _parseRelativeWithTime(text, context.referenceDate, results);
    _parseRelativeWithHour(text, context.referenceDate, results);
    _parseWeekdayWithTime(text, context.referenceDate, results);
    _parseNextWeekday(text, context.referenceDate, results);
    _parseSingleWeekday(text, context.referenceDate, results);
    _parseWithinDays(text, context.referenceDate, results);
    _parseRelativeExpressions(text, context.referenceDate, results);
    _parseFixedExpressions(text, context.referenceDate, results);
    _parseNextMonthWithTime(text, context, results);

    return results;
  }

  void _parseFullDate(String text, List<ParsingResult> results) {
    final yearMonthDay = RegExp(r'([0-9]{4})年([0-9一二三四五六七八九十]+)[日号]');
    for (var match in yearMonthDay.allMatches(text)) {
      int year = int.parse(match.group(1)!);
      int month = JaNumberConverter.parse(match.group(2)!);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(year, month, 1)));
    }
  }

  void _parseMonthDayTime(String text, ParsingContext context, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)[日号]\s*(\d{1,2})(?:[:：時])(\d{1,2})(?:分)?');
    for (var match in pattern.allMatches(text)) {
      int month = parseKanjiOrArabicNumber(match.group(1)!);
      int day = parseKanjiOrArabicNumber(match.group(2)!);
      int hour = int.parse(match.group(3)!);
      int minute = int.parse(match.group(4)!);
      DateTime date = DateTime(context.referenceDate.year, month, day, hour, minute);
      date = adjustForPastDate(date, context);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseMonthDay(String text, ParsingContext context, List<ParsingResult> results) {
    final monthDay = RegExp(r'([0-9一二三四五六七八九十]+)月([0-9一二三四五六七八九十]+)[日号]');
    for (var match in monthDay.allMatches(text)) {
      int month = JaNumberConverter.parse(match.group(1)!);
      int day = JaNumberConverter.parse(match.group(2)!);
      DateTime date = DateTime(context.referenceDate.year, month, day, 0, 0, 0);
      date = adjustForPastDate(date, context);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseWeekExpression(String text, DateTime ref, List<ParsingResult> results) {
    final weekPattern = RegExp(r'([0-9一二三四五六七八九十]+)週間後([月火水木金土日])曜');
    var match = weekPattern.firstMatch(text);
    if (match != null) {
      int weeks = parseKanjiOrArabicNumber(match.group(1)!);
      DateTime base = ref.add(Duration(days: weeks * 7));
      int targetWeekday = JaPatterns.weekdayMap[match.group(2)! + "曜"] ?? base.weekday;
      int diff = targetWeekday - base.weekday;
      if (diff <= 0) diff += 7;
      DateTime candidate = base.add(Duration(days: diff));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseDayWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)[日号](\d{1,2})時(\d{1,2})分');
    for (final match in pattern.allMatches(text)) {
      int day = parseKanjiOrArabicNumber(match.group(1)!);
      int hour = int.parse(match.group(2)!);
      int minute = int.parse(match.group(3)!);
      DateTime candidate = DateTime(ref.year, ref.month, day, hour, minute);
      if (!candidate.isAfter(DateTime(ref.year, ref.month, ref.day, 0, 0, 0))) {
        int newMonth = ref.month + 1;
        int newYear = ref.year;
        if (newMonth > 12) { newMonth = 1; newYear++; }
        candidate = DateTime(newYear, newMonth, day, hour, minute);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

// lib/languages/ja.dart 内 _parseRelativeWithTime の修正例
  void _parseRelativeWithTime(String text, DateTime ref, List<ParsingResult> results) {
      // 分が必須の場合のみマッチさせる
      final regex = RegExp(r'(明日|今日|明後日|昨日)\s*(\d{1,2})時\s*(\d{1,2})分', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
       // 万が一分の部分がキャプチャされていなければスキップ
       if (match.group(3) == null) continue;
    String dayWord = match.group(1)!;
    int hour = int.parse(match.group(2)!);
    int minute = int.parse(match.group(3)!);
       // このパーサー専用のマッピングがあれば利用（存在しなければスキップ）
       if (!JaPatterns.relativeTimeOffsets.containsKey(dayWord)) continue;
    int offset = JaPatterns.relativeTimeOffsets[dayWord]!;
    DateTime base = ref.add(Duration(days: offset));
    DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
    results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }
  void _parseRelativeWithHour(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(明日|今日|明後日|昨日)\s*(\d{1,2})時(?![0-9一二三四五六七八九十]*分)', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String dayWord = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int offset = JaPatterns.relativeTimeOffsets[dayWord] ?? 0;
      DateTime base = ref.add(Duration(days: offset));
      DateTime date = DateTime(base.year, base.month, base.day, hour, 0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseWeekdayWithTime(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'(月曜|火曜|水曜|木曜|金曜|土曜|日曜)(?:\s*(午前|午後))?\s*(\d{1,2})時(?:\s*(\d{1,2})分)?', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String weekdayStr = match.group(1)!;
      String? period = match.group(2); // "午前" または "午後" など
      int hour = int.parse(match.group(3)!);
      int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      // 午後指定の場合、12時未満なら12を加算
      if (period != null && period == "午後" && hour < 12) {
        hour += 12;
      }
      // 以降、曜日から対象日を計算（既存の diff 計算ロジック）
      int targetWeekday = JaPatterns.weekdayMap[weekdayStr]!;
      int diff = (targetWeekday - ref.weekday + 7) % 7;
      if (diff == 0) diff = 7;
      DateTime base = ref.add(Duration(days: diff));
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }

  }

  void _parseNextWeekday(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'来週([月火水木金土日]曜)(?:(\d{1,2})時)?', caseSensitive: false);
    RegExpMatch? match = regex.firstMatch(text);
    if (match != null) {
      String weekdayStr = match.group(1)!;
      int target = JaPatterns.weekdayMap[weekdayStr]!;
      int diff = (target - ref.weekday + 7) % 7;
      if (diff == 0) diff = 7;
      DateTime candidate = ref.add(Duration(days: diff));
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      if (match.group(2) != null) {
        int hour = int.parse(match.group(2)!);
        candidate = DateTime(candidate.year, candidate.month, candidate.day, hour, 0, 0);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate, rangeType: 'week'));
    }
  }

  void _parseSingleWeekday(String text, DateTime ref, List<ParsingResult> results) {
    JaPatterns.weekdayMap.forEach((key, value) {
      final regex = RegExp(RegExp.escape(key), caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        int diff = (value - ref.weekday + 7) % 7;
        if (diff == 0) diff = 7;
        DateTime candidate = ref.add(Duration(days: diff));
        candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
        results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
      }
    });
  }

  void _parseWithinDays(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)日以内');
    RegExpMatch? match = regex.firstMatch(text);
    if (match != null) {
      int days = JaNumberConverter.parse(match.group(1)!);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: ref, rangeDays: days + 1));
    }
  }

  void _parseRelativeExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'([0-9一二三四五六七八九十]+)(日|週間|ヶ月)後');
    for (final match in regex.allMatches(text)) {
      int value = JaNumberConverter.parse(match.group(1)!);
      String unit = match.group(2)!;
      DateTime candidate = ref;
      if (unit == "日") {
        candidate = ref.add(Duration(days: value));
      } else if (unit == "週間") {
        candidate = ref.add(Duration(days: value * 7));
      } else if (unit == "ヶ月") {
        int newMonth = ref.month + value;
        int newYear = ref.year + ((newMonth - 1) ~/ 12);
        newMonth = ((newMonth - 1) % 12) + 1;
        candidate = DateTime(newYear, newMonth, ref.day);
      }
      candidate = DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  void _parseFixedExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final Map<String, Function(DateTime)> fixedExpressions = {
      "来週": (date) {
        int diff = (7 - date.weekday + 1) % 7;
        if (diff == 0) diff = 7;
        return date.add(Duration(days: diff));
      },
      "先週": (date) => date.subtract(Duration(days: 7)),
      "来月": (date) {
        int year = date.year;
        int month = date.month + 1;
        if (month > 12) { month = 1; year++; }
        return DateTime(year, month, 1);
      },
      "先月": (date) {
        int year = date.year;
        int month = date.month - 1;
        if (month < 1) { month = 12; year--; }
        return DateTime(year, month, 1);
      },
      "再来月": (date) {
        int year = date.year;
        int month = date.month + 2;
        if (month > 12) {
          month = ((month - 1) % 12) + 1;
          year += (date.month + 2 - 1) ~/ 12;
        }
        return DateTime(year, month, 1);
      },
      "来年": (date) => DateTime(date.year + 1, date.month, date.day),
      "今年": (date) => DateTime(date.year, date.month, date.day),
      "週末": (date) {
        int diff = (7 - date.weekday) % 7;
        if (diff == 0) diff = 7;
        return date.add(Duration(days: diff));
      },
    };
    fixedExpressions.forEach((expression, dateCalculator) {
      final regex = RegExp(RegExp.escape(expression));
      for (final match in regex.allMatches(text)) {
        DateTime calculatedDate = dateCalculator(ref);
        calculatedDate = DateTime(calculatedDate.year, calculatedDate.month, calculatedDate.day, 0, 0, 0);
        String? rangeType;
        if (expression == "来月" || expression == "先月" || expression == "再来月") {
          rangeType = "month";
        }
        if (expression == "来週") rangeType = "week";
        results.add(ParsingResult(
            index: match.start,
            text: match.group(0)!,
            date: calculatedDate,
            rangeType: rangeType));
      }
    });
  }

  void _parseNextMonthWithTime(String text, ParsingContext context, List<ParsingResult> results) {
    final regex = RegExp(r'来月\s*([0-9一二三四五六七八九十]+)[日号]\s*(\d{1,2})時(?:\s*(\d{1,2})分)?', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      int day = JaNumberConverter.parse(match.group(1)!);
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int month = context.referenceDate.month + 1;
      int year = context.referenceDate.year;
      if (month > 12) { month = 1; year++; }
      DateTime date = DateTime(year, month, day, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }
}

/// 日本語の時刻のみ表現パーサー
class JaTimeOnlyParser extends BaseJaParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    _parseTimeMinute(text, context, results);
    _parseHourOnly(text, context, results);
    return results;
  }

  void _parseTimeMinute(String text, ParsingContext context, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)時([0-9一二三四五六七八九十]+)分');
    for (var match in pattern.allMatches(text)) {
      DateTime date = _createTimeDate(context.referenceDate,
          parseKanjiOrArabicNumber(match.group(1)!),
          parseKanjiOrArabicNumber(match.group(2)!));
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseHourOnly(String text, ParsingContext context, List<ParsingResult> results) {
    final pattern = RegExp(r'([0-9一二三四五六七八九十]+)時(?![0-9一二三四五六七八九十]+分)');
    for (var match in pattern.allMatches(text)) {
      DateTime date = _createTimeDate(context.referenceDate,
          parseKanjiOrArabicNumber(match.group(1)!),
          0);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  DateTime _createTimeDate(DateTime ref, int hour, int minute) {
    DateTime candidate = DateTime(ref.year, ref.month, ref.day, hour, minute);
    if (!candidate.isAfter(ref)) {
      candidate = candidate.add(Duration(days: 1));
    }
    return candidate;
  }
}

/// 日本語パーサー群
class JaParsers {
  static final List<BaseParser> parsers = [
    JaRelativeParser(),
    JaTimeOnlyParser(),
  ];
}

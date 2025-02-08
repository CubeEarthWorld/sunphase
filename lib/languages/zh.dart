// lib/languages/zh.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class ChineseLanguage implements Language {
  @override
  String get code => 'zh';

  // ★ 既存の中国語日付パーサ + 新しく中国語時刻パーサ
  @override
  List<Parser> get parsers => [
    ChineseDateParser(),
    ChineseTimeParser(), // ← 追加
  ];

  @override
  List<Refiner> get refiners => [ChineseRefiner()];
}

// -------------------------------------------------------
// 1) 既存の中国語「日付」パーサ (変更なし)
// -------------------------------------------------------
class ChineseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------
    // 相对日 "今天", "明天", "昨天"
    // ------------------------------
    final RegExp relativeDayPattern = RegExp(r'(今天|明天|昨天)');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == '今天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '明天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched == '昨天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(const Duration(days: 1));
      } else {
        date = referenceDate;
      }
      results.add(ParsingResult(
        index: match.start,
        text: matched,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 星期 (下周 星期一, 上周 周三, 本周 礼拜五 等)
    // ------------------------------
    final RegExp weekdayPattern =
    RegExp(r'(下周|上周|本周)?\s*(星期[一二三四五六日]|周[一二三四五六日]|礼拜[一二三四五六日])');
    for (final match in weekdayPattern.allMatches(text)) {
      String modifier = match.group(1) ?? '';
      String weekdayStr = match.group(2)!;
      int targetWeekday = _weekdayFromString(weekdayStr);
      DateTime date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 绝对日期 (2025年1月1日, 1月1日)
    // ------------------------------
    final RegExp absoluteDatePattern = RegExp(r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日');
    for (final match in absoluteDatePattern.allMatches(text)) {
      int year = (match.group(1) != null)
          ? int.parse(match.group(1)!)
          : referenceDate.year;
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      DateTime date = DateTime(year, month, day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 相对时间段 (下周, 上个月, 这个月, 明年, 去年, 今年)
    // ------------------------------
    final RegExp relativePeriodPattern =
    RegExp(r'(下周|上周|本周|下个月|上个月|这个月|明年|去年|今年)');
    for (final match in relativePeriodPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date = _getRelativePeriodDate(referenceDate, matched);
      results.add(ParsingResult(
        index: match.start,
        text: matched,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // (1) "X天前" / "X天后"
    // ------------------------------
    final RegExp relativeDayNumPattern = RegExp(r'([一二三四五六七八九十\d]+)天(前|后)');
    for (final match in relativeDayNumPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      String direction = match.group(2)!;
      int number = _cnNumberToInt(numStr);
      bool isFuture = (direction == '后');
      DateTime date = isFuture
          ? referenceDate.add(Duration(days: number))
          : referenceDate.subtract(Duration(days: number));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // (2) 单独 "X天" => 当月 or 下月の X日扱い (例: "5天" => 今月5日 or 来月5日)
    // ------------------------------
    final RegExp singleDayPatternForTian =
    RegExp(r'(?<!月)([一二三四五六七八九十\d]+)天(?!前|后)');
    for (final match in singleDayPatternForTian.allMatches(text)) {
      String numStr = match.group(1)!;
      int day = _cnNumberToInt(numStr);
      if (day <= 0) continue;

      DateTime current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(current.year, current.month, day);
      if (candidate.isBefore(current)) {
        int nextMonth = current.month + 1;
        int nextYear = current.year;
        if (nextMonth > 12) {
          nextMonth -= 12;
          nextYear += 1;
        }
        candidate = DateTime(nextYear, nextMonth, day);
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    // ------------------------------
    // 残りの "周|个月|月|年" + (前|后) -> 相対
    // ------------------------------
    final RegExp relativeNumPattern = RegExp(r'([一二三四五六七八九十\d]+)(周|个月|月|年)(前|后)?');
    for (final match in relativeNumPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      String unit = match.group(2)!;
      String? direction = match.group(3);
      int number = _cnNumberToInt(numStr);
      bool isFuture = (direction != '前'); // "前"が明示されていれば過去、なければ未来扱い

      int daysToMove = 0;
      if (unit.contains('周')) {
        daysToMove = number * 7;
      } else if (unit.contains('个月') || unit == '月') {
        daysToMove = number * 30;
      } else if (unit.contains('年')) {
        daysToMove = number * 365;
      }
      DateTime date = isFuture
          ? referenceDate.add(Duration(days: daysToMove))
          : referenceDate.subtract(Duration(days: daysToMove));
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // ------------------------------
    // ISO8601 等
    // ------------------------------
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate),
      ));
    } catch (_) {
      // 無視
    }

    // ------------------------------
    // 単独 "◯日" or "◯号" => 当月 or 来月の最近の日
    // ------------------------------
    final RegExp singleDayPattern = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDayPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      int day = _cnNumberToInt(numStr);
      if (day <= 0) continue;

      DateTime current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(current.year, current.month, day);
      if (candidate.isBefore(current)) {
        int nextMonth = current.month + 1;
        int nextYear = current.year;
        if (nextMonth > 12) {
          nextMonth -= 12;
          nextYear += 1;
        }
        candidate = DateTime(nextYear, nextMonth, day);
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    return results;
  }

  // ---------------------------------------
  // ユーティリティ
  // ---------------------------------------
  int _weekdayFromString(String weekday) {
    if (weekday.contains("一")) return DateTime.monday;
    if (weekday.contains("二")) return DateTime.tuesday;
    if (weekday.contains("三")) return DateTime.wednesday;
    if (weekday.contains("四")) return DateTime.thursday;
    if (weekday.contains("五")) return DateTime.friday;
    if (weekday.contains("六")) return DateTime.saturday;
    if (weekday.contains("日") || weekday.contains("天")) return DateTime.sunday;
    return DateTime.monday;
  }

  DateTime _getDateForWeekday(DateTime reference, int targetWeekday, String modifier) {
    DateTime current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier.isEmpty || modifier == '本周') {
      if (diff <= 0) {
        diff += 7;
      }
    } else if (modifier == '下周') {
      if (diff <= 0) {
        diff += 7;
      }
      diff += 7;
    } else if (modifier == '上周') {
      if (diff >= 0) {
        diff -= 7;
      }
    }
    return current.add(Duration(days: diff));
  }

  DateTime _getRelativePeriodDate(DateTime reference, String period) {
    if (period == '下周') {
      return reference.add(const Duration(days: 7));
    } else if (period == '上周') {
      return reference.subtract(const Duration(days: 7));
    } else if (period == '本周') {
      return reference;
    } else if (period == '下个月') {
      return DateTime(reference.year, reference.month + 1, reference.day);
    } else if (period == '上个月') {
      return DateTime(reference.year, reference.month - 1, reference.day);
    } else if (period == '这个月') {
      return reference;
    } else if (period == '明年') {
      return DateTime(reference.year + 1, reference.month, reference.day);
    } else if (period == '去年') {
      return DateTime(reference.year - 1, reference.month, reference.day);
    } else if (period == '今年') {
      return reference;
    }
    return reference;
  }

  int _cnNumberToInt(String cnNum) {
    // 半角数字ならそのまま
    if (RegExp(r'^\d+$').hasMatch(cnNum)) {
      final val = int.parse(cnNum);
      return (val >= 1 && val <= 31) ? val : 0;
    }

    int result = 0;
    if (cnNum.contains('十')) {
      final parts = cnNum.split('十');
      final front = parts[0];
      final back = parts.length > 1 ? parts[1] : '';

      int tens = 0;
      if (front.isEmpty) {
        tens = 1;
      } else {
        tens = _singleCnDigit(front);
      }

      int ones = 0;
      for (int i = 0; i < back.length; i++) {
        ones += _singleCnDigit(back[i]);
      }

      result = tens * 10 + ones;
    } else {
      for (int i = 0; i < cnNum.length; i++) {
        result += _singleCnDigit(cnNum[i]);
      }
    }
    return (result >= 1 && result <= 31) ? result : 0;
  }

  int _singleCnDigit(String ch) {
    switch (ch) {
      case '零':
        return 0;
      case '一':
        return 1;
      case '二':
        return 2;
      case '三':
        return 3;
      case '四':
        return 4;
      case '五':
        return 5;
      case '六':
        return 6;
      case '七':
        return 7;
      case '八':
        return 8;
      case '九':
        return 9;
      case '十':
        return 10;
      default:
        return 0;
    }
  }
}

// -------------------------------------------------------
// 2) 新規追加: 中国語「時刻」パーサ
// -------------------------------------------------------
class ChineseTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];
    final now = referenceDate;

    // --------------------------------
    // パターンA: "HH:MM" (24h)
    // --------------------------------
    final RegExp timeColon = RegExp(r'\b(\d{1,2}):(\d{1,2})\b');
    for (final match in timeColon.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      if (hour > 23 || minute > 59) continue;

      DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    // --------------------------------
    // パターンB: "HH点MM分" or "HH时MM分" / "HH点", "HH时" のみ
    // --------------------------------
    // 例: "16点24分", "16时24分", "16点", "16时"
    final RegExp timePattern = RegExp(r'(\d{1,2})[点时](\d{1,2})?分?');
    for (final match in timePattern.allMatches(text)) {
      final hourStr = match.group(1)!;
      final minuteStr = match.group(2); // null の場合あり

      final hour = int.parse(hourStr);
      int minute = 0;
      if (minuteStr != null && minuteStr.isNotEmpty) {
        minute = int.parse(minuteStr);
      }
      if (hour > 23 || minute > 59) continue;

      DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    return results;
  }
}

// -------------------------------------------------------
// 3) 既存の中国語リファイナ (変更なし)
// -------------------------------------------------------
class ChineseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

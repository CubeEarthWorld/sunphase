// lib/languages/ja.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class JapaneseLanguage implements Language {
  @override
  String get code => 'ja';

  // ★ 既存の日本語日付パーサ + 新しい日本語時刻パーサ
  @override
  List<Parser> get parsers => [
    JapaneseDateParser(),
    JapaneseTimeParser(), // ← 追加
  ];

  @override
  List<Refiner> get refiners => [JapaneseRefiner()];
}

// -------------------------------------------------------
// 1) 既存の日本語「日付」パーサ (変更なし)
// -------------------------------------------------------
class JapaneseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------
    // 相対表現 (今日, 明日, 明後日, 明々後日, 昨日)
    // ------------------------------
    final RegExp relativeDayPattern =
    RegExp(r'(今日(?!曜日)|明日(?!曜日)|明後日(?!曜日)|明々後日(?!曜日)|昨日(?!曜日))');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == '今日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '明日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched == '明後日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 2));
      } else if (matched == '明々後日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 3));
      } else if (matched == '昨日') {
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
    // 曜日の表現 (来週 月曜日, 先週 火曜日, 今週 金曜日, etc.)
    // ------------------------------
    final RegExp weekdayPattern =
    RegExp(r'(来週|先週|今週)?\s*((?:月曜日|月曜|火曜日|火曜|水曜日|水曜|木曜日|木曜|金曜日|金曜|土曜日|土曜|日曜日|日曜))');
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
    // 絶対日付 (YYYY年M月D日)
    // ------------------------------
    final RegExp absoluteDatePattern = RegExp(r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日');
    for (final match in absoluteDatePattern.allMatches(text)) {
      int year =
      (match.group(1) != null) ? int.parse(match.group(1)!) : referenceDate.year;
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
    // 相対期間 (来週, 先週, 今週, 来月, 先月, 今月, 来年, 去年, 今年)
    // ------------------------------
    final RegExp relativePeriodPattern =
    RegExp(r'(来週|先週|今週|来月|先月|今月|来年|去年|今年)');
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
    // 「X日前」「X日後」: (半角数字 or 漢数字) + "日(前|後)"
    // ------------------------------
    final RegExp relativeDayNumPattern = RegExp(r'([一二三四五六七八九十\d]+)日(前|後)');
    for (final match in relativeDayNumPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      String direction = match.group(2)!; // 前 or 後
      int number = _jaNumberToInt(numStr);
      bool isFuture = (direction == '後');
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
    // 「X週間前」「X週間後」「Xヶ月前」「Xヶ月後」
    // ------------------------------
    final RegExp relativeWeekPattern = RegExp(r'([一二三四五六七八九十\d]+)週間(前|後)');
    for (final match in relativeWeekPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      int number = _jaNumberToInt(numStr);
      String direction = match.group(2)!;
      bool isFuture = (direction == '後');
      int daysToMove = number * 7;
      DateTime date = isFuture
          ? referenceDate.add(Duration(days: daysToMove))
          : referenceDate.subtract(Duration(days: daysToMove));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    final RegExp relativeMonthPattern = RegExp(r'([一二三四五六七八九十\d]+)ヶ月(前|後)');
    for (final match in relativeMonthPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      int number = _jaNumberToInt(numStr);
      String direction = match.group(2)!;
      bool isFuture = (direction == '後');
      DateTime date = isFuture
          ? DateTime(referenceDate.year, referenceDate.month + number, referenceDate.day)
          : DateTime(referenceDate.year, referenceDate.month - number, referenceDate.day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 単独の「XX日」「XX号」(「月」が書かれていない) => 今月 or 来月の最も近いその日
    // ------------------------------
    final RegExp singleDayPattern = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDayPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      int day = _jaNumberToInt(numStr);
      if (day <= 0) {
        continue;
      }
      DateTime current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(current.year, current.month, day);
      if (current.day > day) {
        int nextMonth = current.month + 1;
        int nextYear = current.year;
        if (nextMonth > 12) {
          nextMonth -= 12;
          nextYear += 1;
        }
        candidate = DateTime(nextYear, nextMonth, day);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    return results;
  }

  // ---------------------------------------
  // ユーティリティ
  // ---------------------------------------
  int _weekdayFromString(String weekday) {
    if (weekday.contains("月")) return DateTime.monday;
    if (weekday.contains("火")) return DateTime.tuesday;
    if (weekday.contains("水")) return DateTime.wednesday;
    if (weekday.contains("木")) return DateTime.thursday;
    if (weekday.contains("金")) return DateTime.friday;
    if (weekday.contains("土")) return DateTime.saturday;
    if (weekday.contains("日")) return DateTime.sunday;
    return DateTime.monday;
  }

  DateTime _getDateForWeekday(DateTime reference, int targetWeekday, String modifier) {
    DateTime current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier.isEmpty || modifier == '今週') {
      if (diff <= 0) {
        diff += 7;
      }
    } else if (modifier == '来週') {
      if (diff <= 0) {
        diff += 7;
      }
      diff += 7;
    } else if (modifier == '先週') {
      if (diff >= 0) {
        diff -= 7;
      }
    }
    return current.add(Duration(days: diff));
  }

  DateTime _getRelativePeriodDate(DateTime reference, String period) {
    if (period == '来週') {
      return reference.add(const Duration(days: 7));
    } else if (period == '先週') {
      return reference.subtract(const Duration(days: 7));
    } else if (period == '今週') {
      return reference;
    } else if (period == '来月') {
      return DateTime(reference.year, reference.month + 1, reference.day);
    } else if (period == '先月') {
      return DateTime(reference.year, reference.month - 1, reference.day);
    } else if (period == '今月') {
      return reference;
    } else if (period == '来年') {
      return DateTime(reference.year + 1, reference.month, reference.day);
    } else if (period == '去年') {
      return DateTime(reference.year - 1, reference.month, reference.day);
    } else if (period == '今年') {
      return reference;
    }
    return reference;
  }

  // ------------------------------------------------
  // 漢数字を整数に変換 (一～三十一 まで対応)
  // ------------------------------------------------
  int _jaNumberToInt(String input) {
    // 半角数字ならパース
    if (RegExp(r'^\d+$').hasMatch(input)) {
      final val = int.parse(input);
      return (val >= 1 && val <= 31) ? val : 0;
    }

    int result = 0;
    if (input.contains('十')) {
      final parts = input.split('十');
      final front = parts[0];
      final back = parts.length > 1 ? parts[1] : '';

      int tens = 0;
      if (front.isEmpty) {
        tens = 1; // 「十」=> 10
      } else {
        tens = _singleKanjiDigit(front);
      }

      int ones = 0;
      for (int i = 0; i < back.length; i++) {
        ones += _singleKanjiDigit(back[i]);
      }
      result = tens * 10 + ones;
    } else {
      for (int i = 0; i < input.length; i++) {
        result += _singleKanjiDigit(input[i]);
      }
    }
    return (result >= 1 && result <= 31) ? result : 0;
  }

  int _singleKanjiDigit(String ch) {
    switch (ch) {
      case '〇':
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
// 2) 新規追加: 日本語「時刻」パーサ
// -------------------------------------------------------
class JapaneseTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];
    final now = referenceDate;

    // --------------------------------
    // パターンA: 「HH:MM」(コロン区切り)
    // --------------------------------
    // 日本語文章でも「16:24」などが書かれる場合があるため、こちらも拾う
    final RegExp timePatternColon = RegExp(r'(\d{1,2}):(\d{1,2})');
    for (final match in timePatternColon.allMatches(text)) {
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
    // パターンB: 「HH時MM分」 または 「HH時」だけ
    // --------------------------------
    // 例: "16時24分", "16時"
    // 分がないときは 00 とする
    final RegExp timePatternKanji = RegExp(r'(\d{1,2})時(\d{1,2})?分?');
    for (final match in timePatternKanji.allMatches(text)) {
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
// 3) 既存の日本語リファイナ (変更なし)
// -------------------------------------------------------
class JapaneseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

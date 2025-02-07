// lib/languages/en.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class EnglishLanguage implements Language {
  @override
  String get code => 'en';

  @override
  List<Parser> get parsers => [EnglishDateParser()];

  @override
  List<Refiner> get refiners => [EnglishRefiner()];
}

class EnglishDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------
    // 既存: 相対的な単語 (today, tomorrow, yesterday)
    // ------------------------------
    final RegExp relativeDayPattern =
    RegExp(r'\b(today|tomorrow|yesterday)\b', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched == 'today') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'tomorrow') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched == 'yesterday') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(const Duration(days: 1));
      } else {
        // 万が一ここに来ても参照日付を返す
        date = referenceDate;
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 既存: Weekdays ("next Monday", "last Tuesday", "this Friday" 等)
    // ------------------------------
    final RegExp weekdayPattern = RegExp(
      r'\b(?:(next|last|this)\s+)?(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b',
      caseSensitive: false,
    );
    for (final match in weekdayPattern.allMatches(text)) {
      String? modifier = match.group(1)?.toLowerCase();
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
    // 既存: 絶対日付の表現 (月名+日付, YYYY-MM-DD, M/D/YYYY)
    // ------------------------------
    final RegExp absoluteDatePattern = RegExp(
      r'\b(?:([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})|(\d{4})-(\d{2})-(\d{2})|(\d{1,2})/(\d{1,2})/(\d{4}))\b',
    );
    for (final match in absoluteDatePattern.allMatches(text)) {
      DateTime? date;
      if (match.group(1) != null) {
        // Format: MonthName day, year
        String monthStr = match.group(1)!;
        int day = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        int month = _monthFromString(monthStr);
        if (month > 0) {
          date = DateTime(year, month, day);
        }
      } else if (match.group(4) != null) {
        // Format: YYYY-MM-DD
        int year = int.parse(match.group(4)!);
        int month = int.parse(match.group(5)!);
        int day = int.parse(match.group(6)!);
        date = DateTime(year, month, day);
      } else if (match.group(7) != null) {
        // Format: M/D/YYYY
        int month = int.parse(match.group(7)!);
        int day = int.parse(match.group(8)!);
        int year = int.parse(match.group(9)!);
        date = DateTime(year, month, day);
      }
      if (date != null) {
        results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ));
      }
    }

    // ------------------------------
    // 追加: "17 August 2013" のように「日 月 年」の順番
    // ------------------------------
    final RegExp dayMonthYearPattern = RegExp(
      r'\b(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})\b',
    );
    for (final match in dayMonthYearPattern.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      String monthStr = match.group(2)!;
      int year = int.parse(match.group(3)!);
      int month = _monthFromString(monthStr);
      if (month > 0) {
        DateTime date = DateTime(year, month, day);
        results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ));
      }
    }

    // ------------------------------
    // 追加: 相対期間 "next week", "last month", "this year" (既存のもの)
    // ------------------------------
    final RegExp relativePeriodPattern =
    RegExp(r'\b(?:(next|last|this)\s+)(week|month|year)\b', caseSensitive: false);
    for (final match in relativePeriodPattern.allMatches(text)) {
      String modifier = match.group(1)!.toLowerCase();
      String period = match.group(2)!.toLowerCase();
      DateTime date = _getRelativePeriodDate(referenceDate, period, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 追加: "5 days ago", "2 weeks ago", "3 months from now", etc.
    // ------------------------------
    final RegExp relativeNumberPattern = RegExp(
      r'\b(\d+)\s+(day|week|month|year)s?\s+(ago|from\s+now)\b',
      caseSensitive: false,
    );
    for (final match in relativeNumberPattern.allMatches(text)) {
      int number = int.parse(match.group(1)!);
      String unit = match.group(2)!.toLowerCase(); // day, week, month, year
      String direction = match.group(3)!.toLowerCase(); // ago, from now
      DateTime date = _calculateRelativeDate(referenceDate, number, unit, direction);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 追加: 標準的な日付文字列のパース (Sat Aug 17 2013 18:40:39 GMT+0900 (JST) 等)
    //       もしくは ISO8601 (2014-11-30T08:15:30-05:30 等)
    // ------------------------------
    // テキスト全体がそうとは限らないので、単純に全体マッチを試みる
    // 一部に含まれるケースはここでは対応せず。必要なら別途工夫が必要。
    try {
      // trimしてパースできるか試す
      final parsedDate = DateTime.parse(text.trim());
      // 成功すれば結果に追加
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate),
      ));
    } catch (e) {
      // パースできなければ無視（エラー処理は省略）
    }

    return results;
  }

  // ------------------------------
  // ユーティリティ: 曜日文字列 -> int
  // ------------------------------
  int _weekdayFromString(String weekday) {
    switch (weekday.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
      // 分からない場合は強制的に月曜日とする
        return DateTime.monday;
    }
  }

  // ------------------------------
  // ユーティリティ: 修飾子なしの場合は必ず将来の該当曜日を返す
  // ------------------------------
  DateTime _getDateForWeekday(
      DateTime reference, int targetWeekday, String? modifier) {
    DateTime current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier == null || modifier.isEmpty || modifier == 'this') {
      if (diff <= 0) {
        diff += 7;
      }
    } else if (modifier == 'next') {
      if (diff <= 0) {
        diff += 7;
      }
      diff += 7;
    } else if (modifier == 'last') {
      if (diff >= 0) {
        diff -= 7;
      }
    }
    return current.add(Duration(days: diff));
  }

  // ------------------------------
  // ユーティリティ: 月名 -> int
  // ------------------------------
  int _monthFromString(String month) {
    switch (month.toLowerCase()) {
      case 'january':
      case 'jan':
        return 1;
      case 'february':
      case 'feb':
        return 2;
      case 'march':
      case 'mar':
        return 3;
      case 'april':
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'june':
      case 'jun':
        return 6;
      case 'july':
      case 'jul':
        return 7;
      case 'august':
      case 'aug':
        return 8;
      case 'september':
      case 'sep':
        return 9;
      case 'october':
      case 'oct':
        return 10;
      case 'november':
      case 'nov':
        return 11;
      case 'december':
      case 'dec':
        return 12;
      default:
      // 分からない場合は0
        return 0;
    }
  }

  // ------------------------------
  // ユーティリティ: "next week"等を扱う
  // ------------------------------
  DateTime _getRelativePeriodDate(
      DateTime reference, String period, String modifier) {
    switch (period) {
      case 'week':
        if (modifier == 'next') {
          return reference.add(const Duration(days: 7));
        } else if (modifier == 'last') {
          return reference.subtract(const Duration(days: 7));
        } else {
          return reference;
        }
      case 'month':
        if (modifier == 'next') {
          return DateTime(reference.year, reference.month + 1, reference.day);
        } else if (modifier == 'last') {
          return DateTime(reference.year, reference.month - 1, reference.day);
        } else {
          return reference;
        }
      case 'year':
        if (modifier == 'next') {
          return DateTime(reference.year + 1, reference.month, reference.day);
        } else if (modifier == 'last') {
          return DateTime(reference.year - 1, reference.month, reference.day);
        } else {
          return reference;
        }
      default:
        return reference;
    }
  }

  // ------------------------------
  // ユーティリティ: "5 days ago" などを扱う
  // ------------------------------
  DateTime _calculateRelativeDate(
      DateTime reference, int number, String unit, String direction) {
    // direction == 'ago' -> 過去
    // direction == 'from now' -> 未来
    bool isFuture = direction.contains('from now');

    int daysToAdd = 0;
    switch (unit) {
      case 'day':
        daysToAdd = number;
        break;
      case 'week':
        daysToAdd = number * 7;
        break;
      case 'month':
      // 簡易的に30日とする
        daysToAdd = number * 30;
        break;
      case 'year':
      // 簡易的に365日とする
        daysToAdd = number * 365;
        break;
      default:
        daysToAdd = 0;
    }
    return isFuture
        ? reference.add(Duration(days: daysToAdd))
        : reference.subtract(Duration(days: daysToAdd));
  }
}

class EnglishRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // 必要に応じた結果の統合や重複排除などの処理を記述可能
    // ここではそのまま返す
    return results;
  }
}

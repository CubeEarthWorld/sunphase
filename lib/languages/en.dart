// lib/languages/en.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class EnglishLanguage implements Language {
  @override
  String get code => 'en';

  @override
  List<Parser> get parsers => [
    EnglishDateParser(),
    EnglishTimeParser(), // ★追加
  ];

  @override
  List<Refiner> get refiners => [EnglishRefiner()];
}

class EnglishDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------
    // 相対的な単語 (today, tomorrow, yesterday)
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
        date = referenceDate;
      }
      // デフォルトで時刻は 0:00 として扱う
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // Weekdays ("next Monday", "last Tuesday", "this Friday", etc.)
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
    // 絶対日付の表現 (月名+日付, YYYY-MM-DD, M/D/YYYY)
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
    // "17 August 2013" のように日→月→年
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
    // 相対期間 "next week", "last month", "this year" など
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
    // "5 days ago", "2 weeks from now" のように数字+unit+ago/from now
    // ------------------------------
    final RegExp relativeNumberPattern = RegExp(
      r'\b(?:(\d+|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty))\s+(day|week|month|year)s?\s+(ago|from\s+now)\b',
      caseSensitive: false,
    );
    for (final match in relativeNumberPattern.allMatches(text)) {
      String numStr = match.group(1)!.toLowerCase();
      int number = _enNumberToInt(numStr);
      String unit = match.group(2)!.toLowerCase();
      String direction = match.group(3)!.toLowerCase(); // ago or from now
      DateTime date = _calculateRelativeDate(referenceDate, number, unit, direction);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 標準的な日付文字列 (ISO8601など) パース
    // ------------------------------
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate),
      ));
    } catch (_) {
      // パースできなければ無視
    }

    // ------------------------------
    // 単独の "6th", "21st" など => 今月 or 来月の最も近い日
    // ------------------------------
    final RegExp singleDayPattern = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)\b', caseSensitive: false);
    for (final match in singleDayPattern.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      DateTime current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

      DateTime candidate = DateTime(current.year, current.month, day);
      if (current.day > day) {
        // もう過ぎているなら翌月
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
        return DateTime.monday;
    }
  }

  DateTime _getDateForWeekday(DateTime reference, int targetWeekday, String? modifier) {
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
        return 0;
    }
  }

  DateTime _getRelativePeriodDate(DateTime reference, String period, String modifier) {
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

  DateTime _calculateRelativeDate(
      DateTime reference, int number, String unit, String direction) {
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
        daysToAdd = number * 30;
        break;
      case 'year':
        daysToAdd = number * 365;
        break;
      default:
        daysToAdd = 0;
    }
    return isFuture
        ? reference.add(Duration(days: daysToAdd))
        : reference.subtract(Duration(days: daysToAdd));
  }

  // ------------------------------------------------
  // 英単語を数値に変換するヘルパー関数
  // ------------------------------------------------
  int _enNumberToInt(String word) {
    // 数字そのままなら変換して返す
    if (RegExp(r'^\d+$').hasMatch(word)) {
      return int.parse(word);
    }
    switch (word) {
      case 'zero':
        return 0;
      case 'one':
        return 1;
      case 'two':
        return 2;
      case 'three':
        return 3;
      case 'four':
        return 4;
      case 'five':
        return 5;
      case 'six':
        return 6;
      case 'seven':
        return 7;
      case 'eight':
        return 8;
      case 'nine':
        return 9;
      case 'ten':
        return 10;
      case 'eleven':
        return 11;
      case 'twelve':
        return 12;
      case 'thirteen':
        return 13;
      case 'fourteen':
        return 14;
      case 'fifteen':
        return 15;
      case 'sixteen':
        return 16;
      case 'seventeen':
        return 17;
      case 'eighteen':
        return 18;
      case 'nineteen':
        return 19;
      case 'twenty':
        return 20;
      default:
        return 0;
    }
  }
}

///
/// 時刻用のパーサー (追加)
///
class EnglishTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // シンプルに HH:MM(:SS)? (24時間/AMPM) を狙う
    // 例: "16:24", "2:05 pm", "23:59:10" など
    // AM/PM は簡易的に対応
    final RegExp timePattern = RegExp(
      r'\b(\d{1,2})(?::(\d{1,2})(?::(\d{1,2}))?)?\s*(am|pm)?\b',
      caseSensitive: false,
    );

    for (final match in timePattern.allMatches(text)) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      int second = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      final ampm = match.group(4)?.toLowerCase(); // 'am' or 'pm' or null

      if (ampm == 'am' && hour == 12) {
        // 12 AM は 0 時
        hour = 0;
      } else if (ampm == 'pm' && hour != 12) {
        // 1 PM～11 PM は +12
        hour += 12;
      }

      // 日付指定がない場合、最も近い将来とする
      // （単に "time only" と仮定して、referenceDate の日にちと比較）
      final base = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
        hour,
        minute,
        second,
      );
      DateTime dateTime =
      (base.isBefore(referenceDate)) ? base.add(const Duration(days: 1)) : base;

      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: dateTime),
      ));
    }

    return results;
  }
}

class EnglishRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ここでは、"日付のみ" と "時刻のみ" の結果が同じテキスト付近にあれば合体して
    // 日付 + 時刻にする簡易ロジックを入れる例。
    //
    // ただし本サンプルコードでは、厳密な「テキスト上の近接」判断でなく、
    // 「もし結果が2つあり、indexが同じか近いなら合体」という簡易実装。
    // 実際の要件に合わせて拡張してください。
    //
    // また、複数日付や複数時刻がある場合の挙動は簡易的です。

    final merged = <ParsingResult>[];
    final used = <int>{};

    for (int i = 0; i < results.length; i++) {
      if (used.contains(i)) continue;

      final r1 = results[i];
      final date1 = r1.date;
      bool mergedThis = false;

      for (int j = i + 1; j < results.length; j++) {
        if (used.contains(j)) continue;
        final r2 = results[j];
        // index が近ければ合体する単純例
        if ((r2.index - r1.index).abs() < 10) {
          // どちらかを日付とみなし、もう片方を時刻とみなす
          // "日付" とは 0時0分近いかで判定… というのも雑なので、
          // このサンプルでは、単に r1 が先に見つかった方を日付優先とする
          final combined = _combineDateTime(r1, r2, referenceDate);
          merged.add(combined);
          used.add(i);
          used.add(j);
          mergedThis = true;
          break;
        }
      }

      if (!mergedThis) {
        // そのまま
        merged.add(r1);
        used.add(i);
      }
    }

    // ソートして返す
    merged.sort((a, b) => a.index.compareTo(b.index));
    return merged;
  }

  ParsingResult _combineDateTime(
      ParsingResult a, ParsingResult b, DateTime referenceDate) {
    // a の日付に b の時刻を合わせるか、その逆か。
    // a.date, b.date のうち、"時分秒が00:00:00でないほう" を時刻とみなす簡易実装
    // ※より洗練した方法は状況に応じて実装が必要
    final aHasTime = (a.date.hour != 0 || a.date.minute != 0 || a.date.second != 0);
    final bHasTime = (b.date.hour != 0 || b.date.minute != 0 || b.date.second != 0);

    DateTime newDate;
    if (aHasTime && !bHasTime) {
      // aが時刻、bが日付
      newDate = DateTime(
        b.date.year,
        b.date.month,
        b.date.day,
        a.date.hour,
        a.date.minute,
        a.date.second,
      );
      return ParsingResult(
        index: a.index,
        text: '${a.text} ${b.text}',
        component: ParsedComponent(date: newDate),
      );
    } else if (!aHasTime && bHasTime) {
      // bが時刻、aが日付
      newDate = DateTime(
        a.date.year,
        a.date.month,
        a.date.day,
        b.date.hour,
        b.date.minute,
        b.date.second,
      );
      return ParsingResult(
        index: a.index,
        text: '${a.text} ${b.text}',
        component: ParsedComponent(date: newDate),
      );
    } else {
      // 両方とも時刻あり or 両方とも時刻なし
      // シンプルに a を優先する (要件次第で調整)
      return a;
    }
  }
}

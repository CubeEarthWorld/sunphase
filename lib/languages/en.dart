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
    EnglishTimeParser(),
  ];

  @override
  List<Refiner> get refiners => [
    EnglishRefiner(),
  ];
}

// -------------------------------------------------------
// 1) 日付パーサ (英語固有表現)
//    ※ "YYYY-MM-DD" や "M/D/YYYY" などは not_language 側に任せる想定
// -------------------------------------------------------
class EnglishDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // (A) today, tomorrow, yesterday
    final RegExp relativeDayPattern =
    RegExp(r'\b(today|tomorrow|yesterday)\b', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      final matched = match.group(0)!.toLowerCase();
      late DateTime date;
      if (matched == 'today') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'tomorrow') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched == 'yesterday') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(const Duration(days: 1));
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // (B) Weekdays: next Monday, last Tuesday, this Friday, etc.
    final RegExp weekdayPattern = RegExp(
      r'\b(?:(next|last|this)\s+)?(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b',
      caseSensitive: false,
    );
    for (final match in weekdayPattern.allMatches(text)) {
      final modifier = match.group(1)?.toLowerCase();
      final weekdayStr = match.group(2)!;
      final targetWeekday = _weekdayFromString(weekdayStr);
      final date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // (C) MonthName day, year => "April 5, 2024"
    final RegExp monthNameDatePattern = RegExp(
      r'\b([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})\b',
    );
    for (final match in monthNameDatePattern.allMatches(text)) {
      final monthStr = match.group(1)!;
      final day = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final month = _monthFromString(monthStr);
      if (month > 0) {
        final date = DateTime(year, month, day);
        results.add(
          ParsingResult(
            index: match.start,
            text: match.group(0)!,
            component: ParsedComponent(date: date),
          ),
        );
      }
    }

    // (D) "17 August 2013"
    final RegExp dayMonthYearPattern = RegExp(
      r'\b(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})\b',
    );
    for (final match in dayMonthYearPattern.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!;
      final year = int.parse(match.group(3)!);
      final month = _monthFromString(monthStr);
      if (month > 0) {
        final date = DateTime(year, month, day);
        results.add(
          ParsingResult(
            index: match.start,
            text: match.group(0)!,
            component: ParsedComponent(date: date),
          ),
        );
      }
    }

    // (E) relative periods: next week, last month, this year, etc.
    final RegExp relativePeriodPattern = RegExp(
      r'\b(?:(next|last|this)\s+)(week|month|year)\b',
      caseSensitive: false,
    );
    for (final match in relativePeriodPattern.allMatches(text)) {
      final modifier = match.group(1)!.toLowerCase();
      final period = match.group(2)!.toLowerCase();
      final date = _getRelativePeriodDate(referenceDate, period, modifier);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // (F) "5 days ago", "2 weeks from now" ...
    final RegExp relativeNumberPattern = RegExp(
      r'\b(?:(\d+|zero|one|two|three|four|five|six|seven|eight|nine|ten|'
      r'eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|'
      r'nineteen|twenty))\s+(day|week|month|year)s?\s+(ago|from\s+now)\b',
      caseSensitive: false,
    );
    for (final match in relativeNumberPattern.allMatches(text)) {
      final numStr = match.group(1)!.toLowerCase();
      final number = _enNumberToInt(numStr);
      final unit = match.group(2)!.toLowerCase();
      final direction = match.group(3)!.toLowerCase(); // "ago" / "from now"
      final date = _calculateRelativeDate(referenceDate, number, unit, direction);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // (G) ISO8601 など (オマケ)
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(
        ParsingResult(
          index: 0,
          text: text,
          component: ParsedComponent(date: parsedDate),
        ),
      );
    } catch (_) {
      // ignore
    }

    // (H) "6th", "21st", etc.
    final RegExp singleDayPattern = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)\b',
      caseSensitive: false,
    );
    for (final match in singleDayPattern.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      var candidate = DateTime(current.year, current.month, day);
      if (current.day > day) {
        // move to next month
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

  // ---- Utilities ----
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
    final current = DateTime(reference.year, reference.month, reference.day);
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
      DateTime reference,
      int number,
      String unit,
      String direction,
      ) {
    final isFuture = direction.contains('from now');
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
    }
    return isFuture
        ? reference.add(Duration(days: daysToAdd))
        : reference.subtract(Duration(days: daysToAdd));
  }

  int _enNumberToInt(String word) {
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

// -------------------------------------------------------
// 2) 時刻パーサ (英語特有の時刻表現を入れる場合に使う)
//    - ここではサンプルとして空実装
//    - もし "4pm" や "8:30 pm" などに対応したいなら、ここで実装
// -------------------------------------------------------
class EnglishTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    // 今回は not_language.dart で 24h数値フォーマット (HH:MM) を扱うとして
    // こちらでは英語特有 ("4pm" など) を扱う。
    // 例示として "(\d{1,2})(am|pm)" などをパースするコードを入れてもOK。

    return [];
  }
}

// -------------------------------------------------------
// 3) EnglishRefiner
//    - 日付と時刻を同じ箇所で使っている場合は統合する
// -------------------------------------------------------
class EnglishRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return _mergeDateAndTimeResults(results, referenceDate);
  }

  /// 日付情報と時刻情報を統合して1つのParsingResultにする
  List<ParsingResult> _mergeDateAndTimeResults(
      List<ParsingResult> results, DateTime referenceDate) {
    // 1) dateとtimeでそれぞれ別のresultがある場合、text上で近接していれば結合
    // 2) timeのみの場合は「もっとも近い将来の日付」
    // 3) dateのみの場合は 0:00 として扱う

    // 下準備: Indexが小さい順にソート
    results.sort((a, b) => a.index.compareTo(b.index));

    // すでに使った result を除外するため、新たにまとめる
    final merged = <ParsingResult>[];
    final used = <int>{};

    for (int i = 0; i < results.length; i++) {
      if (used.contains(i)) continue;
      final rA = results[i];

      // rA が「既に時刻を含む」(hour, minuteがセット済み) の場合などの処理は
      // 本サンプルでは省略

      // 「dateだけ」「timeだけ」を区別するために isDateOnly / isTimeOnly を判定する
      final dateA = rA.date;
      final isSameDayA = (dateA.hour == 0 && dateA.minute == 0 && dateA.second == 0);
      // => hour/minute が 0:00 の場合を date-only とみなすかどうかは要件次第

      // timeの可能性(= parserが「もっとも近い将来」で日付調整した)かどうかを
      // 厳密に判定するには追加フラグが必要かもしれませんが、ここでは簡易実装

      // 近い範囲にある別の result が「date (0:00)」 or 「time(未来補正)」なら
      // 結合するかどうか判定
      bool mergedAny = false;

      for (int j = i + 1; j < results.length; j++) {
        if (used.contains(j)) continue;

        final rB = results[j];

        // 同じ言語かどうか(今回はEnglishRefinerなのでOK)
        // テキスト上で非常に離れているなら結合しない(適当な閾値を設定しても良い)
        // ここでは「rB.index が rA.index + rA.text.length の近辺なら結合する」など。
        final distance = rB.index - (rA.index + rA.text.length);
        if (distance.abs() > 3) {
          // 離れすぎなら結合しない、などの判定例
          continue;
        }

        final dateB = rB.date;
        // rA と rB のうち、片方が "date-only(0:00)" で片方が "time-only(別日かも)" であれば合体
        // ただし本サンプルでは "time-only" という明示フラグがないため、
        // 「日付と時刻が重複しない」単純条件で合体してみる

        final isSameDayB = (dateB.hour == 0 && dateB.minute == 0 && dateB.second == 0);

        // date + time ⇒ 合体
        if (isSameDayA && !isSameDayB) {
          // rAは日付-only、rBはtimeを含む => rBのhour/minuteをrAに合わせる
          final combined = _combineDateTime(rA, rB);
          merged.add(combined);
          used.add(i);
          used.add(j);
          mergedAny = true;
          break;
        } else if (!isSameDayA && isSameDayB) {
          // rBは日付-only、rAはtimeを含む
          final combined = _combineDateTime(rB, rA);
          merged.add(combined);
          used.add(i);
          used.add(j);
          mergedAny = true;
          break;
        }
      }

      if (!mergedAny) {
        // 結合が発生しなかった場合、
        // 時刻のみのものなら、参照日付を「もっとも近い将来」に補正するなど
        // あるいは日付のみなら 0:00 のまま
        // 既に rA は日付/時刻を決めているはずなのでそのまま追加
        merged.add(rA);
        used.add(i);
      }
    }

    return merged;
  }

  ParsingResult _combineDateTime(ParsingResult dateResult, ParsingResult timeResult) {
    // dateResult は hour/minute= 0:00 前提、
    // timeResult は referenceDate で補正済みの「hour:minute + (日付調整されているかも)」。
    // => dateResult の 年月日 に、timeResult の 時分秒 を合体させる

    final dDate = dateResult.date;
    final tDate = timeResult.date;

    final combined = DateTime(
      dDate.year,
      dDate.month,
      dDate.day,
      tDate.hour,
      tDate.minute,
      tDate.second,
      tDate.millisecond,
      tDate.microsecond,
    );
    // 新しい text は両方の text を結合(簡易)
    final newText = '${dateResult.text}${timeResult.text}';
    return ParsingResult(
      index: dateResult.index,
      text: newText,
      component: ParsedComponent(date: combined),
    );
  }
}

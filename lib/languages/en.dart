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
// 1) EnglishDateParser
//    - English-specific date expressions (today, tomorrow, etc.)
//      (Avoiding pure numeric forms like "2024-04-01" -> not_language に委譲)
// -------------------------------------------------------
class EnglishDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // ---------- (A) Relative words: today, tomorrow, yesterday ----------
    final RegExp relativeDayPattern = RegExp(
      r'\b(today|tomorrow|yesterday)\b',
      caseSensitive: false,
    );
    for (final match in relativeDayPattern.allMatches(text)) {
      final matched = match.group(0)!.toLowerCase();
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
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- (B) Weekdays ("next Monday", etc.) ----------
    final RegExp weekdayPattern = RegExp(
      r'\b(?:(next|last|this)\s+)?(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b',
      caseSensitive: false,
    );
    for (final match in weekdayPattern.allMatches(text)) {
      final modifier = match.group(1)?.toLowerCase();
      final weekdayStr = match.group(2)!;
      final targetWeekday = _weekdayFromString(weekdayStr);
      final date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- (C) "MonthName day, year" / "day MonthName year" ----------
    final RegExp monthDayYearPattern = RegExp(
      r'\b([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})\b',
    );
    for (final match in monthDayYearPattern.allMatches(text)) {
      final monthStr = match.group(1)!;
      final day = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final month = _monthFromString(monthStr);
      if (month > 0) {
        final date = DateTime(year, month, day);
        results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ));
      }
    }

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
        results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ));
      }
    }

    // ---------- (D) Relative periods: "next week", "last month", etc. ----------
    final RegExp relativePeriodPattern = RegExp(
      r'\b(?:(next|last|this)\s+)(week|month|year)\b',
      caseSensitive: false,
    );
    for (final match in relativePeriodPattern.allMatches(text)) {
      final modifier = match.group(1)!.toLowerCase();
      final period = match.group(2)!.toLowerCase();
      final date = _getRelativePeriodDate(referenceDate, period, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- (E) "5 days ago", "2 weeks from now", etc. ----------
    final RegExp relativeNumberPattern = RegExp(
      r'\b(?:(\d+|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty))\s+(day|week|month|year)s?\s+(ago|from\s+now)\b',
      caseSensitive: false,
    );
    for (final match in relativeNumberPattern.allMatches(text)) {
      final numStr = match.group(1)!.toLowerCase();
      final number = _enNumberToInt(numStr);
      final unit = match.group(2)!.toLowerCase();
      final direction = match.group(3)!.toLowerCase(); // "ago", "from now"
      final date = _calculateRelativeDate(referenceDate, number, unit, direction);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- (F) ISO8601 parse (optional) ----------
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate),
      ));
    } catch (_) {
      // ignore
    }

    // ---------- (G) Standalone "6th" etc. -> nearest day of this/next month ----------
    final RegExp singleDayPattern = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)\b',
      caseSensitive: false,
    );
    for (final match in singleDayPattern.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(current.year, current.month, day);
      if (current.day > day) {
        // next month
        var nextMonth = current.month + 1;
        var nextYear = current.year;
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
  // Utilities
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
    final current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier == null || modifier.isEmpty || modifier == 'this') {
      if (diff <= 0) diff += 7;
    } else if (modifier == 'next') {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier == 'last') {
      if (diff >= 0) diff -= 7;
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
      default:
        daysToAdd = 0;
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
// 2) EnglishTimeParser
//   - Recognize "HH:MM" (24h) => nearest future
//   - If you want "4pm" or "16pm" logic, you can expand here.
// -------------------------------------------------------
class EnglishTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];
    final now = referenceDate;

    // e.g. "16:00", "08:30", etc.
    final RegExp timePattern = RegExp(r'\b(\d{1,2}):(\d{1,2})\b');
    for (final match in timePattern.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);

      if (hour > 23 || minute > 59) {
        continue;
      }

      DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }

      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    return results;
  }
}

// -------------------------------------------------------
// 3) EnglishRefiner
//   - Merge date-only result + time-only result => single result
// -------------------------------------------------------
class EnglishRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ソート
    results.sort((a, b) => a.index.compareTo(b.index));

    final merged = <ParsingResult>[];
    int i = 0;
    while (i < results.length) {
      final current = results[i];
      if (i < results.length - 1) {
        final next = results[i + 1];
        if (_isDateOnly(current) && _isTimeOnly(next)) {
          // Merge
          final mergedDate = DateTime(
            current.date.year,
            current.date.month,
            current.date.day,
            next.date.hour,
            next.date.minute,
            next.date.second,
          );
          final mergedText = current.text + next.text;
          merged.add(ParsingResult(
            index: current.index,
            text: mergedText,
            component: ParsedComponent(date: mergedDate),
          ));
          i += 2;
          continue;
        }
      }
      merged.add(current);
      i++;
    }

    return merged;
  }

  bool _isDateOnly(ParsingResult r) {
    // "date-only" => hour/minute == 0
    return (r.date.hour == 0 && r.date.minute == 0 && r.date.second == 0);
  }

  bool _isTimeOnly(ParsingResult r) {
    // "time-only" => hour or minute != 0
    // (Even if it's day+1, we assume it's a time result if it has non-zero hour or minute)
    return (r.date.hour != 0 || r.date.minute != 0);
  }
}

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

    // Pattern 1: Relative day expressions: "today", "tomorrow", "yesterday"
    final RegExp relativeDayPattern = RegExp(r'\b(today|tomorrow|yesterday)\b', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched == 'today') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'tomorrow') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).add(Duration(days: 1));
      } else if (matched == 'yesterday') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).subtract(Duration(days: 1));
      } else {
        date = referenceDate;
      }
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date)));
    }

    // Pattern 2: Weekdays with optional modifier ("next", "last", "this")
    final RegExp weekdayPattern = RegExp(
        r'\b(?:(next|last|this)\s+)?(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b',
        caseSensitive: false);
    for (final match in weekdayPattern.allMatches(text)) {
      String? modifier = match.group(1)?.toLowerCase();
      String weekdayStr = match.group(2)!;
      int targetWeekday = _weekdayFromString(weekdayStr);
      DateTime date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date)));
    }

    // Pattern 3: Absolute date formats
    // Supports: "January 1, 2025", "Jan 1, 2025", "2025-01-01", "1/1/2025"
    final RegExp absoluteDatePattern = RegExp(
        r'\b(?:([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})|(\d{4})-(\d{2})-(\d{2})|(\d{1,2})/(\d{1,2})/(\d{4}))\b');
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
            component: ParsedComponent(date: date)));
      }
    }

    // Pattern 4: Relative period expressions: "next week", "last month", "next year", etc.
    final RegExp relativePeriodPattern = RegExp(r'\b(?:(next|last|this)\s+)(week|month|year)\b', caseSensitive: false);
    for (final match in relativePeriodPattern.allMatches(text)) {
      String modifier = match.group(1)!.toLowerCase();
      String period = match.group(2)!.toLowerCase();
      DateTime date = _getRelativePeriodDate(referenceDate, period, modifier);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date)));
    }

    return results;
  }

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

  // 修飾子がない場合は必ず将来の該当曜日を返す
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
          return reference.add(Duration(days: 7));
        } else if (modifier == 'last') {
          return reference.subtract(Duration(days: 7));
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
}

class EnglishRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // 必要に応じた結果の統合や補正処理を実装可能（ここではそのまま返す）
    return results;
  }
}

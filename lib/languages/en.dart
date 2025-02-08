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

    // ① 相対表現＋時刻（例："today 16:21"）
    RegExp relativeDayPattern = RegExp(
      r'\b(today|tomorrow|yesterday)(?:\s+(\d{1,2}):(\d{2}))?\b',
      caseSensitive: false,
    );
    for (final match in relativeDayPattern.allMatches(text)) {
      String word = match.group(1)!.toLowerCase();
      DateTime date;
      if (word == "today") {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (word == "tomorrow") {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 1));
      } else if (word == "yesterday") {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: 1));
      } else {
        date = referenceDate;
      }
      bool hasTime = false;
      if (match.group(2) != null && match.group(3) != null) {
        int hour = int.parse(match.group(2)!);
        int minute = int.parse(match.group(3)!);
        date = DateTime(date.year, date.month, date.day, hour, minute);
        hasTime = true;
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date, hasTime: hasTime),
      ));
    }

    // ② 曜日の表現（例："next Monday" など）
    RegExp weekdayPattern = RegExp(
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
        component: ParsedComponent(date: date, hasTime: false),
      ));
    }

    // ③ 絶対日付の表現（例："August 17, 2013", "2013-08-17", "8/17/2013"）
    RegExp absoluteDatePattern = RegExp(
        r'\b(?:([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})|(\d{4})-(\d{1,2})-(\d{1,2})|(\d{1,2})/(\d{1,2})/(\d{4}))\b'
    );
    for (final match in absoluteDatePattern.allMatches(text)) {
      DateTime? date;
      if (match.group(1) != null) {
        String monthStr = match.group(1)!;
        int day = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        int month = _monthFromString(monthStr);
        if (month > 0) {
          date = DateTime(year, month, day);
        }
      } else if (match.group(4) != null) {
        int year = int.parse(match.group(4)!);
        int month = int.parse(match.group(5)!);
        int day = int.parse(match.group(6)!);
        date = DateTime(year, month, day);
      } else if (match.group(7) != null) {
        int month = int.parse(match.group(7)!);
        int day = int.parse(match.group(8)!);
        int year = int.parse(match.group(9)!);
        date = DateTime(year, month, day);
      }
      if (date != null) {
        results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date, hasTime: false),
        ));
      }
    }

    // ④ "17 August 2013" のようなパターン
    RegExp dayMonthYearPattern = RegExp(
        r'\b(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})\b'
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
          component: ParsedComponent(date: date, hasTime: false),
        ));
      }
    }

    // ⑤ 相対期間（例："next week", "last month", "this year"）
    RegExp relativePeriodPattern = RegExp(
      r'\b(?:(next|last|this)\s+)(week|month|year)\b', caseSensitive: false,
    );
    for (final match in relativePeriodPattern.allMatches(text)) {
      String modifier = match.group(1)!.toLowerCase();
      String period = match.group(2)!.toLowerCase();
      DateTime date = _getRelativePeriodDate(referenceDate, period, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date, hasTime: false),
      ));
    }

    // ⑥ 数値＋単位の相対表現（例："5 days ago", "2 weeks from now"）
    RegExp relativeNumberPattern = RegExp(
      r'\b(?:(\d+|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty))\s+(day|week|month|year)s?\s+(ago|from\s+now)\b',
      caseSensitive: false,
    );
    for (final match in relativeNumberPattern.allMatches(text)) {
      String numStr = match.group(1)!.toLowerCase();
      int number = _enNumberToInt(numStr);
      String unit = match.group(2)!.toLowerCase();
      String direction = match.group(3)!.toLowerCase();
      DateTime date = _calculateRelativeDate(referenceDate, number, unit, direction);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date, hasTime: false),
      ));
    }

    // ⑦ ISO8601 など標準的な日付文字列
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate, hasTime: true),
      ));
    } catch (_) {}

    // ⑧ 単独の日付（例："6th"）→ 今月または来月の最も近いその日
    RegExp singleDayPattern = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)\b', caseSensitive: false);
    for (final match in singleDayPattern.allMatches(text)) {
      int day = int.parse(match.group(1)!);
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
        component: ParsedComponent(date: candidate, hasTime: false),
      ));
    }

    // ⑨ 追加：時刻のみのパターン（例："16:21"）→ 参照日時より未来の時刻
    RegExp timePattern = RegExp(r'(\d{1,2}):(\d{2})');
    for (final match in timePattern.allMatches(text)) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      DateTime candidate = DateTime(
          referenceDate.year, referenceDate.month, referenceDate.day, hour, minute
      );
      if (!candidate.isAfter(referenceDate)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate, hasTime: true),
      ));
    }

    return results;
  }

  // --- 内部ヘルパー ---
  int _weekdayFromString(String weekday) {
    switch (weekday.toLowerCase()) {
      case 'monday': return DateTime.monday;
      case 'tuesday': return DateTime.tuesday;
      case 'wednesday': return DateTime.wednesday;
      case 'thursday': return DateTime.thursday;
      case 'friday': return DateTime.friday;
      case 'saturday': return DateTime.saturday;
      case 'sunday': return DateTime.sunday;
      default: return DateTime.monday;
    }
  }

  DateTime _getDateForWeekday(
      DateTime reference, int targetWeekday, String? modifier) {
    DateTime current = DateTime(reference.year, reference.month, reference.day);
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

  DateTime _getRelativePeriodDate(
      DateTime reference, String period, String modifier) {
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

  int _enNumberToInt(String word) {
    if (RegExp(r'^\d+$').hasMatch(word)) return int.parse(word);
    switch (word) {
      case 'zero': return 0;
      case 'one': return 1;
      case 'two': return 2;
      case 'three': return 3;
      case 'four': return 4;
      case 'five': return 5;
      case 'six': return 6;
      case 'seven': return 7;
      case 'eight': return 8;
      case 'nine': return 9;
      case 'ten': return 10;
      case 'eleven': return 11;
      case 'twelve': return 12;
      case 'thirteen': return 13;
      case 'fourteen': return 14;
      case 'fifteen': return 15;
      case 'sixteen': return 16;
      case 'seventeen': return 17;
      case 'eighteen': return 18;
      case 'nineteen': return 19;
      case 'twenty': return 20;
      default: return 0;
    }
  }
}

class EnglishRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

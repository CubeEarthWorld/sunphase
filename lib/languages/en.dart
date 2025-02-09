// lib/languages/en.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// Shared constants and utilities for English date parsing
class EnglishDateUtils {
  static const Map<String, int> monthMap = {
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  static const Map<String, int> weekdayMap = {
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 7,
  };

  static const Map<String, int> numberWords = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
  };

  static DateTime adjustDateTimeWithTime(DateTime date, String text) {
    final timeRegExp = RegExp(r'(\d{1,2}):(\d{2})');
    final timeMatch = timeRegExp.firstMatch(text);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    return date;
  }

  static DateTime getNextOccurrence(DateTime reference, DateTime candidate) {
    return candidate.isBefore(reference)
        ? candidate.add(const Duration(days: 1))
        : candidate;
  }
}

/// Parser for relative expressions in English.
class EnRelativeParser extends BaseParser {
  static final RegExp _inDaysPattern =
  RegExp(r'in\s+(\d+)\s+days', caseSensitive: false);
  static final RegExp _relativePattern = RegExp(
      r'(\d+|[a-z]+)\s*(days|weeks)\s*(from now|later|ago)',
      caseSensitive: false);

  // Process expressions such as "tomorrow at 3:00"
  void _parseRelativeWithTime(
      String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(
        r'\b(tomorrow|today|yesterday)\s*(?:at\s*)?(\d{1,2})(?::(\d{2}))?\b',
        caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String word = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int offset;
      if (word.toLowerCase() == 'tomorrow') {
        offset = 1;
      } else if (word.toLowerCase() == 'yesterday') {
        offset = -1;
      } else {
        offset = 0;
      }
      DateTime base = ref.add(Duration(days: offset));
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    final results = <ParsingResult>[];
    final lowerText = text.toLowerCase();
    final ref = context.referenceDate;
    _parseInDays(lowerText, ref, results);
    _parseNextWeek(lowerText, ref, results);
    _parseThisWeek(lowerText, ref, results);   // <-- New: Handle "this week"
    _parseLastWeek(lowerText, ref, results);     // <-- New: Handle "last week"
    _parseFixedExpressions(lowerText, ref, results);
    _parseWeekdays(lowerText, ref, results);
    _parseRelativeExpressions(lowerText, ref, results);
    _parseRelativeWithTime(text, ref, results);
    return results;
  }

  void _parseInDays(String text, DateTime ref, List<ParsingResult> results) {
    final match = _inDaysPattern.firstMatch(text);
    if (match != null) {
      final days = int.parse(match.group(1)!);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: ref,
          rangeDays: days + 1));
    }
  }

  void _parseNextWeek(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'\bnext week\b', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      // Calculate next Monday: add enough days to reach the next Monday.
      int daysToNextMonday = (8 - ref.weekday) % 7;
      if (daysToNextMonday == 0) daysToNextMonday = 7;
      final nextMonday = DateTime(ref.year, ref.month, ref.day)
          .add(Duration(days: daysToNextMonday));
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: nextMonday,
          rangeType: 'week'));
    }
  }

  // New: Parse "this week" expressions.
  void _parseThisWeek(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'\bthis week\b', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      // Calculate the Monday of the current week.
      final monday = DateTime(ref.year, ref.month, ref.day)
          .subtract(Duration(days: ref.weekday - 1));
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: monday,
          rangeType: 'week'));
    }
  }

  // New: Parse "last week" expressions.
  void _parseLastWeek(String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(r'\blast week\b', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      // Calculate the Monday of the current week then subtract 7 days to get last week.
      final mondayThisWeek = DateTime(ref.year, ref.month, ref.day)
          .subtract(Duration(days: ref.weekday - 1));
      final mondayLastWeek = mondayThisWeek.subtract(Duration(days: 7));
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: mondayLastWeek,
          rangeType: 'week'));
    }
  }

  void _parseFixedExpressions(
      String text, DateTime ref, List<ParsingResult> results) {
    final fixedExpressions = {
      'today': () => DateTime(ref.year, ref.month, ref.day),
      'tomorrow': () =>
          DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1)),
      'yesterday': () =>
          DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1)),
      'next year': () => DateTime(
          ref.year + 1, ref.month, ref.day, ref.hour, ref.minute, ref.second),
      'last year': () => DateTime(
          ref.year - 1, ref.month, ref.day, ref.hour, ref.minute, ref.second),
    };

    fixedExpressions.forEach((key, valueFunc) {
      final regex =
      RegExp(r'\b' + RegExp.escape(key) + r'\b', caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        results.add(ParsingResult(
            index: match.start,
            text: match.group(0)!,
            date: valueFunc(),
            rangeType: key.contains('month') ? 'month' : null));
      }
    });

    final nextMonthRegex = RegExp(r'\bnext month\b', caseSensitive: false);
    for (final match in nextMonthRegex.allMatches(text)) {
      int month = ref.month + 1;
      int year = ref.year;
      if (month > 12) {
        month = 1;
        year++;
      }
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(year, month, 1),
          rangeType: 'month'));
    }

    final lastMonthRegex = RegExp(r'\blast month\b', caseSensitive: false);
    for (final match in lastMonthRegex.allMatches(text)) {
      int month = ref.month - 1;
      int year = ref.year;
      if (month < 1) {
        month = 12;
        year--;
      }
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(year, month, 1),
          rangeType: 'month'));
    }
  }

  void _parseWeekdays(String text, DateTime ref, List<ParsingResult> results) {
    EnglishDateUtils.weekdayMap.forEach((weekdayStr, weekdayValue) {
      final regex = RegExp(r'\b' + RegExp.escape(weekdayStr) + r'\b',
          caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        int diff = (weekdayValue - ref.weekday + 7) % 7;
        if (diff == 0) diff = 7;
        final targetDate =
        DateTime(ref.year, ref.month, ref.day).add(Duration(days: diff));
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: targetDate));
      }
    });
    for (final entry in EnglishDateUtils.weekdayMap.entries) {
      _parseNextLastWeekday(text, ref, entry.key, entry.value, results);
    }
  }

  void _parseNextLastWeekday(String text, DateTime ref, String weekday,
      int weekdayValue, List<ParsingResult> results) {
    final nextPhrase = 'next ' + weekday;
    final lastPhrase = 'last ' + weekday;
    final regexNext =
    RegExp(r'\b' + RegExp.escape(nextPhrase) + r'\b', caseSensitive: false);
    final regexLast =
    RegExp(r'\b' + RegExp.escape(lastPhrase) + r'\b', caseSensitive: false);
    for (final match in regexNext.allMatches(text)) {
      int current = ref.weekday;
      int target = weekdayValue;
      int days = (target - current + 7) % 7;
      int daysToAdjust = days == 0 ? 7 : days;
      final targetDate = DateTime(ref.year, ref.month, ref.day)
          .add(Duration(days: daysToAdjust));
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: targetDate));
    }
    for (final match in regexLast.allMatches(text)) {
      int current = ref.weekday;
      int target = weekdayValue;
      int days = ((current - target + 7) % 7);
      int daysToAdjust = days == 0 ? 7 : days;
      final targetDate = DateTime(ref.year, ref.month, ref.day)
          .subtract(Duration(days: daysToAdjust));
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: targetDate));
    }
  }

  void _parseRelativeExpressions(
      String text, DateTime ref, List<ParsingResult> results) {
    for (final match in _relativePattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final value =
          int.tryParse(numStr) ?? (EnglishDateUtils.numberWords[numStr] ?? 0);
      final unit = match.group(2)!;
      final direction = match.group(3)!;
      final delta = unit.startsWith('day')
          ? Duration(days: value)
          : Duration(days: value * 7);
      final resultDate =
      (direction == 'ago') ? ref.subtract(delta) : ref.add(delta);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: resultDate));
    }

    // Handle "two weeks ago"
    final twoWeeksAgoRegex =
    RegExp(r'(\d+)\s+weeks\s+ago', caseSensitive: false);
    for (final match in twoWeeksAgoRegex.allMatches(text)) {
      final weeks = int.parse(match.group(1)!);
      final resultDate = ref.subtract(Duration(days: weeks * 7));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        date: resultDate,
      ));
    }
  }
}

/// Parser for absolute date expressions in English.
class EnAbsoluteParser extends BaseParser {
  static final RegExp _fullDatePattern = RegExp(
      r'([a-z]+)[\s,]+(\d{1,2})(?:st|nd|rd|th)?(?:[\s,]+(\d{4}))?',
      caseSensitive: false);
  static final RegExp _ordinalPattern = RegExp(
      r'(\d{1,2})(?:st|nd|rd|th)(?:\s*,?\s*(\d{4}))?',
      caseSensitive: false);
  static final RegExp _slashYMDPattern = RegExp(
      r'\b(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})(?:\s*(?:at\s*)?(\d{1,2}:\d{2}(?::\d{2})?))?\b',
      caseSensitive: false);
  static final RegExp _slashMDPattern = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})(?:\s*(?:at\s*)?(\d{1,2}:\d{2}(?::\d{2})?))?\b',
      caseSensitive: false);
  static final RegExp _dmyPattern = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)\s+(\d{4})(?:\s*(?:at)?\s*(\d{1,2}:\d{2}(?::\d{2})?))?\b',
      caseSensitive: false);

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    final results = <ParsingResult>[];
    final lowerText = text.toLowerCase();
    _parseFullDates(lowerText, text, context, results);
    _parseOrdinalDates(lowerText, text, context, results);
    _parseSlashYMD(text, context, results);
    _parseSlashMD(text, context, results);
    _parseDmyDates(text, context, results);
    // 新規：月名単体の表現
    _parseMonthNameOnly(text, context, results);
    return results;
  }

  void _parseFullDates(String lowerText, String originalText,
      ParsingContext context, List<ParsingResult> results) {
    for (final match in _fullDatePattern.allMatches(lowerText)) {
      final monthStr = match.group(1)!;
      if (!EnglishDateUtils.monthMap.containsKey(monthStr.toLowerCase()))
        continue;
      final dateStr = match.group(0)!;
      final parsedDate = _parseEnglishDate(dateStr, context);
      if (parsedDate != null) {
        final adjustedDate =
        EnglishDateUtils.adjustDateTimeWithTime(parsedDate, originalText);
        results.add(ParsingResult(
            index: match.start, text: dateStr, date: adjustedDate));
      }
    }
  }

  void _parseOrdinalDates(String lowerText, String originalText,
      ParsingContext context, List<ParsingResult> results) {
    for (final match in _ordinalPattern.allMatches(lowerText)) {
      final dateStr = match.group(0)!;
      final parsedDate = _parseEnglishDate(dateStr, context);
      if (parsedDate != null) {
        final adjustedDate =
        EnglishDateUtils.adjustDateTimeWithTime(parsedDate, originalText);
        results.add(ParsingResult(
            index: match.start, text: dateStr, date: adjustedDate));
      }
    }
  }

  void _parseSlashYMD(
      String text, ParsingContext context, List<ParsingResult> results) {
    for (final match in _slashYMDPattern.allMatches(text)) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      DateTime date = DateTime(year, month, day);
      if (match.group(4) != null) {
        List<String> timeParts = match.group(4)!.split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        date = DateTime(year, month, day, hour, minute);
      }
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseSlashMD(
      String text, ParsingContext context, List<ParsingResult> results) {
    for (final match in _slashMDPattern.allMatches(text)) {
      if (_slashYMDPattern.hasMatch(match.group(0)!)) continue;
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      int year = context.referenceDate.year;
      DateTime date = DateTime(year, month, day);
      if (!date.isAfter(context.referenceDate)) {
        date = DateTime(year + 1, month, day);
      }
      if (match.group(3) != null) {
        List<String> timeParts = match.group(3)!.split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        date = DateTime(date.year, date.month, date.day, hour, minute);
      }
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseDmyDates(
      String text, ParsingContext context, List<ParsingResult> results) {
    for (final match in _dmyPattern.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      String monthStr = match.group(2)!;
      int month = EnglishDateUtils.monthMap[monthStr.toLowerCase()]!;
      int year = int.parse(match.group(3)!);
      DateTime date = DateTime(year, month, day);
      if (match.group(4) != null) {
        List<String> timeParts = match.group(4)!.split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        date = DateTime(year, month, day, hour, minute);
      }
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseMonthNameOnly(
      String text, ParsingContext context, List<ParsingResult> results) {
    final regex = RegExp(
        r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\b',
        caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      String monthStr = match.group(1)!;
      int month = EnglishDateUtils.monthMap[monthStr.toLowerCase()]!;
      int year = context.referenceDate.year;
      if (month < context.referenceDate.month) {
        year++;
      }
      DateTime date = DateTime(year, month, 1);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: date,
          rangeType: "month"));
    }
  }

  DateTime? _parseEnglishDate(String dateStr, ParsingContext context) {
    final lowerDateStr = dateStr.toLowerCase().trim();
    final fullMatch = _fullDatePattern.firstMatch(lowerDateStr);
    if (fullMatch != null) return _parseFullDateMatch(fullMatch, context);
    final ordinalMatch = _ordinalPattern.firstMatch(lowerDateStr);
    if (ordinalMatch != null) return _parseOrdinalMatch(ordinalMatch, context);
    return null;
  }

  DateTime? _parseFullDateMatch(RegExpMatch match, ParsingContext context) {
    final monthStr = match.group(1)!;
    final month = EnglishDateUtils.monthMap[monthStr];
    final day = int.parse(match.group(2)!);
    if (month == null) return null;
    final year = match.group(3) != null
        ? int.parse(match.group(3)!)
        : _inferYear(context.referenceDate, month, day);
    return DateTime(year, month, day);
  }

  DateTime? _parseOrdinalMatch(RegExpMatch match, ParsingContext context) {
    final day = int.parse(match.group(1)!);
    var month = context.referenceDate.month;
    var year = match.group(2) != null
        ? int.parse(match.group(2)!)
        : context.referenceDate.year;
    var candidate = DateTime(year, month, day);
    if (candidate.isBefore(context.referenceDate)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      candidate = DateTime(year, month, day);
    }
    return candidate;
  }

  int _inferYear(DateTime reference, int month, int day) {
    final year = reference.year;
    final candidate = DateTime(year, month, day);
    return candidate.isBefore(reference) ? year + 1 : year;
  }
}

/// Parser for time-only expressions in English.
class EnTimeOnlyParser extends BaseParser {
  static final RegExp _timePatternAmPm =
  RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)', caseSensitive: false);
  static final RegExp _timePattern =
  RegExp(r'(\d{1,2}):(\d{2})', caseSensitive: false);
  static final RegExp _fixedTimePattern =
  RegExp(r'\b(midnight|noon)\b', caseSensitive: false);

  void _parseFixedTime(String text, DateTime ref, List<ParsingResult> results) {
    for (final match in _fixedTimePattern.allMatches(text)) {
      final word = match.group(1)!.toLowerCase();
      if (word == 'midnight') {
        final candidate = DateTime(ref.year, ref.month, ref.day);
        final adjustedDate = EnglishDateUtils.getNextOccurrence(ref, candidate);
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: adjustedDate));
      } else if (word == 'noon') {
        final noonDate = DateTime(ref.year, ref.month, ref.day, 12);
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: noonDate));
      }
    }
  }

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    final results = <ParsingResult>[];
    final ref = context.referenceDate;

    _parseFixedTime(text, ref, results);

    for (final match in _timePatternAmPm.allMatches(text)) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      String period = match.group(3)!.toLowerCase();
      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      DateTime candidate = DateTime(ref.year, ref.month, ref.day, hour, minute);
      candidate = EnglishDateUtils.getNextOccurrence(ref, candidate);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate));
    }

    for (final match in _timePattern.allMatches(text)) {
      bool overlap = results.any((r) =>
      match.start >= r.index && match.start < (r.index + r.text.length));
      if (!overlap) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        DateTime candidate =
        DateTime(ref.year, ref.month, ref.day, hour, minute);
        candidate = EnglishDateUtils.getNextOccurrence(ref, candidate);
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: candidate));
      }
    }
    return results;
  }
}

/// English parsers collection.
class EnParsers {
  static final List<BaseParser> parsers = [
    EnRelativeParser(),
    EnAbsoluteParser(),
    EnTimeOnlyParser(),
  ];
}

// lib/languages/en.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 英語パーサーで共通のユーティリティ
class EnglishDateUtils {
  static const Map<String, int> monthMap = {
    'january': 1, 'jan': 1,
    'february': 2, 'feb': 2,
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

  static const Map<String, int> weekdayMap = {
    'monday': 1, 'tuesday': 2, 'wednesday': 3,
    'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
  };

  static const Map<String, int> numberWords = {
    'one': 1, 'two': 2, 'three': 3,
    'four': 4, 'five': 5, 'six': 6,
    'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
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
}

/// 英語の相対表現パーサー
class EnRelativeParser extends BaseParser {
  static final RegExp _inDaysPattern =
  RegExp(r'in\s+(\d+)\s+days', caseSensitive: false);
  static final RegExp _relativePattern = RegExp(
      r'(\d+|[a-z]+)\s*(days|weeks)\s*(from now|later|ago)',
      caseSensitive: false);
  static final RegExp _fixedTimePattern = RegExp(
      r'\b(tomorrow|today|yesterday)\s*(?:at\s*)?(\d{1,2})(?::(\d{2}))?\b',
      caseSensitive: false);

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    final results = <ParsingResult>[];
    final baseRef = DateTime(context.referenceDate.year,
        context.referenceDate.month, context.referenceDate.day);
    final ref = context.referenceDate;
    _parseInDays(text.toLowerCase(), baseRef, results);
    _parseNextWeek(text.toLowerCase(), baseRef, results);
    _parseThisWeek(text.toLowerCase(), baseRef, results);
    _parseLastWeek(text.toLowerCase(), baseRef, results);
    _parseFixedExpressions(text.toLowerCase(), ref, results);
    _parseWeekdays(text.toLowerCase(), baseRef, results);
    EnglishDateUtils.weekdayMap.forEach((key, value) {
      _parseNextLastWeekday(text, baseRef, key, value, results);
    });
    _parseRelativeExpressions(text.toLowerCase(), ref, results);
    _parseRelativeWithTime(text, ref, results);
    return results;
  }

  void _parseInDays(String text, DateTime baseRef, List<ParsingResult> results) {
    final match = _inDaysPattern.firstMatch(text);
    if (match != null) {
      final days = int.parse(match.group(1)!);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: baseRef,
          rangeDays: days + 1));
    }
  }

  void _parseNextWeek(String text, DateTime baseRef, List<ParsingResult> results) {
    final regex = RegExp(r'\bnext week\b', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      int daysToNextMonday = (8 - baseRef.weekday) % 7;
      daysToNextMonday = daysToNextMonday == 0 ? 7 : daysToNextMonday;
      final nextMonday = baseRef.add(Duration(days: daysToNextMonday));
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: nextMonday,
          rangeType: 'week'));
    }
  }

  void _parseThisWeek(String text, DateTime baseRef, List<ParsingResult> results) {
    final regex = RegExp(r'\bthis week\b', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      final monday = DateUtils.firstDayOfWeek(baseRef);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: monday,
          rangeType: 'week'));
    }
  }

  void _parseLastWeek(String text, DateTime baseRef, List<ParsingResult> results) {
    final regex = RegExp(r'\blast week\b', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      final mondayThisWeek = DateUtils.firstDayOfWeek(baseRef);
      final mondayLastWeek = mondayThisWeek.subtract(Duration(days: 7));
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: mondayLastWeek,
          rangeType: 'week'));
    }
  }

  void _parseFixedExpressions(String text, DateTime ref, List<ParsingResult> results) {
    final fixedExpressions = {
      'today': () => DateTime(ref.year, ref.month, ref.day),
      'tomorrow': () =>
          DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1)),
      'yesterday': () =>
          DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1)),
      'next year': () =>
          DateTime(ref.year + 1, ref.month, ref.day, ref.hour, ref.minute, ref.second),
      'last year': () =>
          DateTime(ref.year - 1, ref.month, ref.day, ref.hour, ref.minute, ref.second),
    };

    fixedExpressions.forEach((key, func) {
      final regex = RegExp(r'\b' + RegExp.escape(key) + r'\b', caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        results.add(ParsingResult(
            index: match.start,
            text: match.group(0)!,
            date: func(),
            rangeType: key.contains('month') ? 'month' : null));
      }
    });

    final nextMonthRegex = RegExp(r'\bnext month\b', caseSensitive: false);
    for (final match in nextMonthRegex.allMatches(text)) {
      final nextMonth = DateUtils.firstDayOfNextMonth(ref);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: nextMonth,
          rangeType: 'month'));
    }

    final lastMonthRegex = RegExp(r'\blast month\b', caseSensitive: false);
    for (final match in lastMonthRegex.allMatches(text)) {
      final lastMonth = DateUtils.firstDayOfPreviousMonth(ref);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: lastMonth,
          rangeType: 'month'));
    }
  }

  void _parseWeekdays(String text, DateTime baseRef, List<ParsingResult> results) {
    EnglishDateUtils.weekdayMap.forEach((weekdayStr, weekdayValue) {
      final regex = RegExp(r'\b' + RegExp.escape(weekdayStr) + r'\b', caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        int diff = (weekdayValue - baseRef.weekday + 7) % 7;
        diff = diff == 0 ? 7 : diff;
        final targetDate = baseRef.add(Duration(days: diff));
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: targetDate));
      }
    });
  }

  void _parseNextLastWeekday(String text, DateTime baseRef, String weekday, int weekdayValue, List<ParsingResult> results) {
    final regexNext = RegExp(r'\bnext ' + RegExp.escape(weekday) + r'\b', caseSensitive: false);
    final regexLast = RegExp(r'\blast ' + RegExp.escape(weekday) + r'\b', caseSensitive: false);
    for (final match in regexNext.allMatches(text)) {
      int days = (weekdayValue - baseRef.weekday + 7) % 7;
      final targetDate = baseRef.add(Duration(days: days == 0 ? 0 : days));
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: targetDate));
    }
    for (final match in regexLast.allMatches(text)) {
      int days = (baseRef.weekday - weekdayValue + 7) % 7;
      final targetDate = baseRef.subtract(Duration(days: days == 0 ? 7 : days));
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: targetDate));
    }
  }

  void _parseRelativeExpressions(String text, DateTime ref, List<ParsingResult> results) {
    for (final match in _relativePattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final value = int.tryParse(numStr) ?? (EnglishDateUtils.numberWords[numStr] ?? 0);
      final unit = match.group(2)!;
      final direction = match.group(3)!;
      final delta = unit.startsWith('day') ? Duration(days: value) : Duration(days: value * 7);
      final resultDate = (direction == 'ago') ? ref.subtract(delta) : ref.add(delta);
      final normalized = DateTime(resultDate.year, resultDate.month, resultDate.day);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: normalized));
    }
  }

  void _parseRelativeWithTime(String text, DateTime ref, List<ParsingResult> results) {
    for (final match in _fixedTimePattern.allMatches(text)) {
      String word = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int offset = word.toLowerCase() == 'tomorrow'
          ? 1
          : (word.toLowerCase() == 'yesterday' ? -1 : 0);
      DateTime base = ref.add(Duration(days: offset));
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
  }
}

/// 英語の絶対表現パーサー
class EnAbsoluteParser extends BaseParser {
  static final RegExp _fullDatePattern = RegExp(
      r'([a-z]+)[\s,]+(\d{1,2})(?:st|nd|rd|th)?(?:[\s,]+(\d{4}))?(?:\s+(\d{1,2}:\d{2}(?::\d{2})?))?',
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
        results.add(ParsingResult(
            index: match.start, text: dateStr, date: parsedDate));
      }
    }
  }

  void _parseOrdinalDates(String lowerText, String originalText,
      ParsingContext context, List<ParsingResult> results) {
    for (final match in _ordinalPattern.allMatches(lowerText)) {
      final dateStr = match.group(0)!;
      final parsedDate = _parseEnglishDate(dateStr, context);
      if (parsedDate != null) {
        results.add(ParsingResult(
            index: match.start, text: dateStr, date: parsedDate));
      }
    }
  }

  void _parseSlashYMD(String text, ParsingContext context, List<ParsingResult> results) {
    for (final match in _slashYMDPattern.allMatches(text)) {
      DateTime? date = DateUtils.parseDate(match.group(0)!,
          reference: context.referenceDate);
      if (date != null) {
        if (match.group(4) != null) {
          List<String> timeParts = match.group(4)!.split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          date = DateTime(date.year, date.month, date.day, hour, minute);
        }
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: date));
      }
    }
  }

  void _parseSlashMD(String text, ParsingContext context, List<ParsingResult> results) {
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
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseDmyDates(String text, ParsingContext context, List<ParsingResult> results) {
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
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseMonthNameOnly(String text, ParsingContext context, List<ParsingResult> results) {
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
          index: match.start, text: match.group(0)!, date: date, rangeType: "month"));
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
    DateTime date = DateTime(year, month, day);
    if (match.group(4) != null) {
      final timeStr = match.group(4)!;
      List<String> parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      date = DateTime(year, month, day, hour, minute);
    }
    return date;
  }

  DateTime? _parseOrdinalMatch(RegExpMatch match, ParsingContext context) {
    final day = int.parse(match.group(1)!);
    int month = context.referenceDate.month;
    int year = match.group(2) != null
        ? int.parse(match.group(2)!)
        : context.referenceDate.year;
    DateTime candidate = DateTime(year, month, day);
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

/// 英語の時刻表現パーサー
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
      DateTime candidate = word == 'midnight'
          ? DateUtils.nextOccurrenceTime(ref, 0, 0)
          : DateUtils.nextOccurrenceTime(ref, 12, 0);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate));
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
      DateTime candidate = DateUtils.nextOccurrenceTime(ref, hour, minute);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate));
    }
    for (final match in _timePattern.allMatches(text)) {
      bool overlap = results.any((r) =>
      match.start >= r.index &&
          match.start < (r.index + r.text.length));
      if (!overlap) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        DateTime candidate = DateUtils.nextOccurrenceTime(ref, hour, minute);
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: candidate));
      }
    }
    return results;
  }
}

class EnParsers {
  static final List<BaseParser> parsers = [
    EnRelativeParser(),
    EnAbsoluteParser(),
    EnTimeOnlyParser(),
  ];
}

// lib/languages/en_def.dart
import '../core/number_parser.dart';
import 'lang_def.dart';

class EnDefinitions {
  static const arabicParser = ArabicNumberParser();
  static const Map<String, int> months = {
    'january': 1, 'jan': 1, 'february': 2, 'feb': 2, 'march': 3, 'mar': 3,
    'april': 4, 'apr': 4, 'may': 5, 'june': 6, 'jun': 6, 'july': 7, 'jul': 7,
    'august': 8, 'aug': 8, 'september': 9, 'sep': 9, 'october': 10, 'oct': 10,
    'november': 11, 'nov': 11, 'december': 12, 'dec': 12,
  };

  static const Map<String, int> weekdays = {
    'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
    'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7,
  };

  static const Map<String, int> relativeDays = {
    'today': 0, 'tomorrow': 1, 'yesterday': -1,
  };

  static final patterns = [
    // Universal pattern: time colon (HH:MM)
    UniversalPatterns.timeColon,
    // In X days: "in \d+ days"
    PatternDef(
      name: 'en_inDays',
      regex: RegExp(r'in\s+(\d+)\s+days', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        rangeDays: int.parse(match.group(1)!) + 1, day: ref.day, month: ref.month, year: ref.year,
      ),
    ),

    // X days/weeks from now/later/ago
    PatternDef(
      name: 'en_relativeOffset',
      regex: RegExp(r'(\d+|[a-z]+)\s*(days|weeks)\s*(from now|later|ago)', caseSensitive: false),
      extract: (match, np, ref) {
        final numStr = match.group(1)!;
        final value = int.tryParse(numStr) ?? 1;
        final unit = match.group(2)!;
        final dir = match.group(3)!;
        final isAgo = dir == 'ago';
        final isWeek = unit.startsWith('week');
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          dayOffset: isWeek ? null : (isAgo ? -value : value),
          weekOffset: isWeek ? (isAgo ? -value : value) : null,
        );
      },
    ),

    // Fixed relative days with time: "tomorrow at 3pm"
    PatternDef(
      name: 'en_relativeDayWithTime',
      regex: RegExp(r'\b(today|tomorrow|yesterday)\s*(?:at\s*)?(\d{1,2})(?::(\d{2}))?(am|pm)?\b', caseSensitive: false),
      extract: (match, np, ref) {
        final word = match.group(1)!.toLowerCase();
        final hour = int.parse(match.group(2)!);
        final minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
        final period = match.group(4)?.toLowerCase();
        int h = hour;
        if (period == 'pm' && h < 12) h += 12;
        if (period == 'am' && h == 12) h = 0;
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          dayOffset: relativeDays[word], hour: h, minute: minute,
        );
      },
    ),

    // Fixed expressions: today, tomorrow, yesterday, next/last year
    PatternDef(
      name: 'en_fixedDays',
      regex: RegExp(r'\b(today|tomorrow|yesterday)\b', caseSensitive: false),
      extract: (match, np, ref) {
        final word = match.group(1)!.toLowerCase();
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: word,
          dayOffset: relativeDays[word]!,
        );
      },
    ),

    PatternDef(
      name: 'en_yearExpressions',
      regex: RegExp(r'\b(next|last) year\b', caseSensitive: false),
      extract: (match, np, ref) {
        final dir = match.group(1)!.toLowerCase();
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          yearOffset: dir == 'next' ? 1 : -1,
        );
      },
    ),

    // Month only: "march", "next month", "last month"
    PatternDef(
      name: 'en_monthOnly',
      regex: RegExp(r'\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\b', caseSensitive: false),
      extract: (match, np, ref) {
        final name = match.group(1)!.toLowerCase();
        final month = months[name]!;
        int year = ref.year;
        if (month < ref.month) year++;
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: year, month: month, day: 1, rangeType: 'month',
        );
      },
    ),

    PatternDef(
      name: 'en_relativeMonth',
      regex: RegExp(r'\b(next|last) month\b', caseSensitive: false),
      extract: (match, np, ref) {
        final dir = match.group(1)!.toLowerCase();
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          monthOffset: dir == 'next' ? 1 : -1, rangeType: 'month',
        );
      },
    ),

    // Week expressions: "next week", "this week", "last week"
    PatternDef(
      name: 'en_weekExpressions',
      regex: RegExp(r'\b(next|this|last) week\b', caseSensitive: false),
      extract: (match, np, ref) {
        final expr = match.group(1)!.toLowerCase();
        int offset = expr == 'last' ? -1 : (expr == 'next' ? 1 : 0);
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          weekOffset: offset, rangeType: 'week',
        );
      },
    ),

    // Weekday: "monday", "tuesday", etc.
    PatternDef(
      name: 'en_weekday',
      regex: RegExp(r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\b', caseSensitive: false),
      extract: (match, np, ref) {
        final name = match.group(1)!.toLowerCase();
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: name,
          weekday: weekdays[name]!,
        );
      },
    ),

    // Next/last weekday: "next monday", "last friday"
    PatternDef(
      name: 'en_nextLastWeekday',
      regex: RegExp(r'\b(next|last) (monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false),
      extract: (match, np, ref) {
        final dir = match.group(1)!.toLowerCase();
        final name = match.group(2)!.toLowerCase();
        final weekday = weekdays[name]!;
        final isLast = dir == 'last';
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          weekday: weekday, weekOffset: isLast ? -7 : 0,
        );
      },
    ),

    // Full date: "March 14, 2025 14:30" or "March 14th 2025"
    PatternDef(
      name: 'en_fullDate',
      regex: RegExp(r'([a-z]+)[\s,]+(\d{1,2})(?:st|nd|rd|th)?(?:[\s,]+(\d{4}))?(?:\s+(\d{1,2}:\d{2}(?::\d{2})?))?', caseSensitive: false),
      extract: (match, np, ref) {
        final monthStr = match.group(1)!.toLowerCase();
        final month = months[monthStr];
        if (month == null) return null;
        final day = int.parse(match.group(2)!);
        final yearStr = match.group(3);
        final timeStr = match.group(4);
        int year = yearStr != null ? int.parse(yearStr) : ref.year;
        if (yearStr == null) {
          final candidate = DateTime(year, month, day);
          if (candidate.isBefore(DateTime(ref.year, ref.month, ref.day))) year++;
        }
        int hour = 0, minute = 0;
        if (timeStr != null) {
          final parts = timeStr.split(':');
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1]);
        }
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: year, month: month, day: day, hour: hour, minute: minute,
        );
      },
    ),

    // Ordinal with time: "on the 20th at 3pm", "the 20th at 3:30pm"
    PatternDef(
      name: 'en_ordinalWithTime',
      regex: RegExp(r'(?:on\s+)?(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)\s+at\s+(\d{1,2})(?::(\d{2}))?(am|pm)?', caseSensitive: false),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        var hour = int.parse(match.group(2)!);
        final minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
        final period = match.group(4)?.toLowerCase();
        if (period == 'pm' && hour < 12) hour += 12;
        if (period == 'am' && hour == 12) hour = 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          day: day,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Ordinal: "16th", "3rd" (day only)
    PatternDef(
      name: 'en_ordinal',
      regex: RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)\b'),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          day: day,
        );
      },
    ),

    // Slash date: YYYY/MM/DD or MM/DD/YYYY
    PatternDef(
      name: 'en_slashDate',
      regex: RegExp(r'\b(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})(?:\s*(?:at\s*)?(\d{1,2}:\d{2}(?::\d{2})?))?\b'),
      extract: (match, np, ref) {
        final g1 = match.group(1)!, g2 = match.group(2)!, g3 = match.group(3)!;
        final timeStr = match.group(4);
        int? y, m, d;
        if (g1.length == 4) { y = int.parse(g1); m = int.parse(g2); d = int.parse(g3); }
        else if (g3.length == 4) { m = int.parse(g1); d = int.parse(g2); y = int.parse(g3); }
        else { m = int.parse(g1); d = int.parse(g2); y = ref.year; }
        int hour = 0, minute = 0;
        if (timeStr != null) {
          final parts = timeStr.split(':');
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1]);
        }
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: y, month: m, day: d, hour: hour, minute: minute,
        );
      },
    ),

    // Time with AM/PM: "3pm", "3:30 pm"
    PatternDef(
      name: 'en_timeAmPm',
      regex: RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)', caseSensitive: false),
      extract: (match, np, ref) {
        var hour = int.parse(match.group(1)!);
        final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
        final period = match.group(3)!.toLowerCase();
        if (period == 'pm' && hour < 12) hour += 12;
        if (period == 'am' && hour == 12) hour = 0;
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          hour: hour, minute: minute,
        );
      },
    ),

    // Fixed times: midnight, noon
    PatternDef(
      name: 'en_fixedTimes',
      regex: RegExp(r'\b(midnight|noon)\b', caseSensitive: false),
      extract: (match, np, ref) {
        final word = match.group(1)!.toLowerCase();
        final isMidnight = word == 'midnight';
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: word,
          hour: isMidnight ? 0 : 12, minute: 0,
        );
      },
    ),
  ];

  static final definition = LanguageDefinition(
    code: 'en',
    numberParser: arabicParser,
    patterns: patterns,
  );
}

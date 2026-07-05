// lib/src/language/en.dart
//
// English: space-separated, preposition-marked ("on the 21st at 3pm"),
// prefix anchors ("next", "last"), suffix ordinals ("21st"). The
// prepositions live in the glue set, so "next month on the 21st at 2pm"
// composes from three tokens.

import '../core/component.dart';
import 'language.dart';
import 'numbers.dart';

class EnLanguage {
  static const Map<String, int> _months = {
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

  static const Map<String, int> _weekdays = {
    'monday': 1, 'mon': 1,
    'tuesday': 2, 'tue': 2,
    'wednesday': 3, 'wed': 3,
    'thursday': 4, 'thu': 4,
    'friday': 5, 'fri': 5,
    'saturday': 6, 'sat': 6,
    'sunday': 7, 'sun': 7,
  };

  static const _wdAlt =
      '(monday|tuesday|wednesday|thursday|friday|saturday|sunday'
      '|mon|tue|wed|thu|fri|sat|sun)';

  static const Map<String, DateComponent> _relativeDays = {
    'today': RelativeDay(0),
    'tomorrow': RelativeDay(1),
    'yesterday': RelativeDay(-1),
  };

  static const Map<String, DateComponent> _anchors = {
    'next year': YearAnchor(1),
    'last year': YearAnchor(-1),
    'next month': MonthAnchor(1),
    'this month': MonthAnchor(0),
    'last month': MonthAnchor(-1),
    'next week': WeekAnchor(1, calendar: true),
    'this week': WeekAnchor(0, calendar: true),
    'last week': WeekAnchor(-1, calendar: true),
  };

  static const Map<String, DateComponent> _fixedTimes = {
    'noon': ClockTime(12, 0),
    'midnight': ClockTime(0, 0),
  };

  static String _lower(String s) => s.toLowerCase();

  static final LanguageSpec spec = LanguageSpec(
    code: 'en',
    numbers: const AsciiNumberReader(),
    glue: RegExp(r'^(?:[\s,]|on|at|the|of|in)+$', caseSensitive: false),
    patterns: [
      vocab('en_relativeDay', _relativeDays,
          wrap: latinWord, normalize: _lower, caseSensitive: false),
      vocab('en_anchor', _anchors,
          wrap: latinWord, normalize: _lower, caseSensitive: false),
      vocab('en_fixedTime', _fixedTimes,
          wrap: latinWord, normalize: _lower, caseSensitive: false),

      // "in 3 days", "in 2 weeks", "in 4 months"
      TokenPattern(
        name: 'en_in',
        regex: RegExp(r'in\s+(\d+)\s+(days?|weeks?|months?|years?)',
            caseSensitive: false),
        build: (m, ctx) => _offset(int.parse(m.group(1)!), m.group(2)!),
      ),

      // "4 days later", "2 weeks from now", "5 days ago"
      TokenPattern(
        name: 'en_offset',
        regex: RegExp(
            r'(\d+)\s+(days?|weeks?|months?|years?)\s+(from\s+now|later|ago)',
            caseSensitive: false),
        build: (m, ctx) {
          final n = int.parse(m.group(1)!);
          final ago = m.group(3)!.toLowerCase() == 'ago';
          return _offset(ago ? -n : n, m.group(2)!);
        },
      ),

      // "next Tuesday", "last friday" → anchored weekday (non-calendar:
      // next/most-recent occurrence).
      TokenPattern(
        name: 'en_nextLastWeekday',
        regex: RegExp(latinWord('(next|last)\\s+$_wdAlt'),
            caseSensitive: false),
        build: (m, ctx) => [
          WeekAnchor(m.group(1)!.toLowerCase() == 'next' ? 1 : -1,
              calendar: false),
          WeekdayRef(_weekdays[m.group(2)!.toLowerCase()]!),
        ],
      ),

      vocab(
        'en_weekday',
        {for (final e in _weekdays.entries) e.key: WeekdayRef(e.value)},
        wrap: latinWord,
        normalize: _lower,
        caseSensitive: false,
      ),

      // "March 14", "march 7", "March 14, 2025"
      TokenPattern(
        name: 'en_monthDay',
        regex: RegExp(
          latinWord('${alternation(_months.keys)}'
              r'\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?'),
          caseSensitive: false,
        ),
        build: (m, ctx) {
          final month = _months[m.group(1)!.toLowerCase()];
          final day = asDay(int.parse(m.group(2)!));
          if (month == null || day == null) return null;
          return [
            MonthValue(month),
            DayOfMonth(day),
            if (m.group(3) != null) YearValue(int.parse(m.group(3)!)),
          ];
        },
      ),

      vocab(
        'en_month',
        {for (final e in _months.entries) e.key: MonthValue(e.value)},
        wrap: latinWord,
        normalize: _lower,
        caseSensitive: false,
      ),

      // "the 21st", "16th"
      TokenPattern(
        name: 'en_ordinalDay',
        regex: RegExp(r'(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)(?![a-z])',
            caseSensitive: false),
        build: (m, ctx) {
          final day = asDay(int.parse(m.group(1)!));
          return day == null ? null : [DayOfMonth(day)];
        },
      ),

      // YYYY/MM/DD or MM/DD/YYYY
      TokenPattern(
        name: 'en_slashDate',
        regex: RegExp(r'(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})'),
        build: (m, ctx) {
          final a = m.group(1)!, b = m.group(2)!, c = m.group(3)!;
          int year, month, day;
          if (a.length == 4) {
            year = int.parse(a);
            month = int.parse(b);
            day = int.parse(c);
          } else if (c.length == 4) {
            month = int.parse(a);
            day = int.parse(b);
            year = int.parse(c);
          } else {
            month = int.parse(a);
            day = int.parse(b);
            year = ctx.referenceDate.year;
          }
          if (asMonth(month) == null || asDay(day) == null) return null;
          return [YearValue(year), MonthValue(month), DayOfMonth(day)];
        },
      ),

      // "2:30pm", "3 pm"
      TokenPattern(
        name: 'en_timeAmPm',
        regex: RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)(?![a-z])',
            caseSensitive: false),
        build: (m, ctx) => [
          ClockTime(
            int.parse(m.group(1)!),
            m.group(2) == null ? null : int.parse(m.group(2)!),
            m.group(3)!.toLowerCase() == 'pm' ? Meridiem.pm : Meridiem.am,
          ),
        ],
      ),

      colonTime('en_colonTime'),
    ],
  );

  static List<DateComponent>? _offset(int n, String unit) =>
      switch (unit.toLowerCase()) {
        'day' || 'days' => [RelativeDay(n)],
        'week' || 'weeks' => [WeekAnchor(n, calendar: false)],
        'month' || 'months' => [MonthAnchor(n)],
        _ => [YearAnchor(n)],
      };
}

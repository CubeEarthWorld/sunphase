// lib/src/language/hi.dart
//
// Hindi: space-separated, postposition-marked (को, बाद, पहले), prefix
// anchors (अगले/पिछले). Time words require an explicit marker (बजे or a
// colon), which is what prevents "2 सप्ताह बाद" from being misread as
// "2 o'clock".

import '../core/component.dart';
import 'language.dart';
import 'numbers.dart';

class HiLanguage {
  static const Map<String, int> _months = {
    'जनवरी': 1,
    'फरवरी': 2,
    'फ़रवरी': 2,
    'मार्च': 3,
    'अप्रैल': 4,
    'मई': 5,
    'जून': 6,
    'जुलाई': 7,
    'अगस्त': 8,
    'सितंबर': 9,
    'अक्टूबर': 10,
    'नवंबर': 11,
    'दिसंबर': 12,
  };

  static const Map<String, int> _weekdays = {
    'सोमवार': 1,
    'मंगलवार': 2,
    'बुधवार': 3,
    'गुरुवार': 4,
    'शुक्रवार': 5,
    'शनिवार': 6,
    'रविवार': 7,
  };

  static const _week = r'(?:सप्ताह|हफ़्ते|हफ्ते|हफ्ता)';

  static final LanguageSpec spec = LanguageSpec(
    code: 'hi',
    numbers: const AsciiNumberReader(),
    glue: RegExp(r'^(?:[\s,]|को|के|की)+$'),
    patterns: [
      vocab(
        'hi_relativeDay',
        const {
          'आज': RelativeDay(0),
          'कल': RelativeDay(1),
          'परसों': RelativeDay(2),
          'नरसों': RelativeDay(3),
        },
        wrap: devanagariWord,
      ),

      vocab(
        'hi_meridiem',
        const {
          'सुबह': MeridiemMarker(Meridiem.am),
          'दोपहर': MeridiemMarker(Meridiem.pm),
          'शाम': MeridiemMarker(Meridiem.pm),
          'रात': MeridiemMarker(Meridiem.pm),
        },
        wrap: devanagariWord,
      ),

      // अगले हफ्ते / पिछले सप्ताह / इस हफ्ते
      TokenPattern(
        name: 'hi_weekAnchor',
        regex: RegExp('(अगले|पिछले|इस)\\s+$_week'),
        build: (m, ctx) => [
          WeekAnchor(
            switch (m.group(1)!) {
              'अगले' => 1,
              'पिछले' => -1,
              _ => 0,
            },
            calendar: true,
          ),
        ],
      ),

      // अगले महीने / पिछले महीने
      TokenPattern(
        name: 'hi_monthAnchor',
        regex: RegExp(r'(अगले|पिछले|इस)\s+(?:महीने|महीना)'),
        build: (m, ctx) => [
          MonthAnchor(
            switch (m.group(1)!) {
              'अगले' => 1,
              'पिछले' => -1,
              _ => 0,
            },
          ),
        ],
      ),

      // अगले साल / पिछले साल
      TokenPattern(
        name: 'hi_yearAnchor',
        regex: RegExp(r'(अगले|पिछले|इस)\s+(?:साल|वर्ष)'),
        build: (m, ctx) => [
          YearAnchor(
            switch (m.group(1)!) {
              'अगले' => 1,
              'पिछले' => -1,
              _ => 0,
            },
          ),
        ],
      ),

      // अगले सोमवार / पिछले शुक्रवार
      TokenPattern(
        name: 'hi_nextLastWeekday',
        regex: RegExp('(अगले|पिछले)\\s+${alternation(_weekdays.keys)}'),
        build: (m, ctx) => [
          WeekAnchor(m.group(1)! == 'अगले' ? 1 : -1, calendar: false),
          WeekdayRef(_weekdays[m.group(2)!]!),
        ],
      ),

      vocab(
        'hi_weekday',
        {for (final e in _weekdays.entries) e.key: WeekdayRef(e.value)},
        wrap: devanagariWord,
      ),

      // N दिन बाद/पहले, N सप्ताह बाद/पहले
      TokenPattern(
        name: 'hi_offset',
        regex: RegExp('(\\d+)\\s*(दिन|$_week|महीने|साल)\\s*(बाद|पहले)'),
        build: (m, ctx) {
          final n = int.parse(m.group(1)!);
          final value = m.group(3)! == 'बाद' ? n : -n;
          return switch (m.group(2)!) {
            'दिन' => [RelativeDay(value)],
            'महीने' => [MonthAnchor(value)],
            'साल' => [YearAnchor(value)],
            _ => [WeekAnchor(value, calendar: false)],
          };
        },
      ),

      // 14 मार्च (2025)
      TokenPattern(
        name: 'hi_dayMonth',
        regex: RegExp(
          '(\\d{1,2})\\s+${alternation(_months.keys)}(?![ऀ-ॿ])'
          r'(?:\s+(\d{4}))?',
        ),
        build: (m, ctx) {
          final day = asDay(int.parse(m.group(1)!));
          final month = _months[m.group(2)!];
          if (day == null || month == null) return null;
          return [
            DayOfMonth(day),
            MonthValue(month),
            if (m.group(3) != null) YearValue(int.parse(m.group(3)!)),
          ];
        },
      ),

      vocab(
        'hi_month',
        {for (final e in _months.entries) e.key: MonthValue(e.value)},
        wrap: devanagariWord,
      ),

      // 15 तारीख
      TokenPattern(
        name: 'hi_day',
        regex: RegExp(r'(\d{1,2})\s*तारीख'),
        build: (m, ctx) {
          final day = asDay(int.parse(m.group(1)!));
          return day == null ? null : [DayOfMonth(day)];
        },
      ),

      // 15 बजे (o'clock)
      TokenPattern(
        name: 'hi_baje',
        regex: RegExp(r'(\d{1,2})\s*बजे'),
        build: (m, ctx) => [ClockTime(int.parse(m.group(1)!))],
      ),

      colonTime('hi_colonTime'),
    ],
  );
}

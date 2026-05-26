// lib/languages/hi_def.dart
//
// Hindi language definition for Sunphase.
//
// Recognised expression types:
//   - Relative days      : आज (today), कल (tomorrow/yesterday by context),
//                          परसों (day after tomorrow / day before yesterday)
//   - Relative offsets   : 3 दिन बाद, 2 हफ्ते बाद, अगले महीने
//   - Named weekdays     : सोमवार, मंगलवार, … (with अगले/पिछले prefix)
//   - Week expressions   : इस हफ्ते, अगले हफ्ते, पिछले हफ्ते
//   - Month expressions  : जनवरी, फरवरी, … अगला महीना, पिछला महीना
//   - Time expressions   : 10:30, सुबह 9 बजे, शाम 3 बजे
//
// Uses plain ASCII digit parsing.

import '../core/number_parser.dart';
import 'lang_def.dart';

class HiDefinitions {
  static const Map<String, int> months = {
    'जनवरी': 1,
    'फरवरी': 2,
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

  static const Map<String, int> weekdays = {
    'सोमवार': 1,
    'मंगलवार': 2,
    'बुधवार': 3,
    'गुरुवार': 4,
    'शुक्रवार': 5,
    'शनिवार': 6,
    'रविवार': 7,
  };

  static const Map<String, int> relativeDays = {'आज': 0, 'कल': 1, 'परसों': 2};

  static const Map<String, int> timePeriods = {
    'सुबह': 0,
    'दोपहर': 12,
    'शाम': 12,
    'रात': 12,
  };

  static const arabicParser = ArabicNumberParser();

  static final patterns = [
    // Relative days: आज, कल, परसों
    PatternDef(
      name: 'hi_relativeDay',
      regex: RegExp(r'(आज|कल|परसों)'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start,
        endIndex: match.end,
        text: match.group(0)!,
        dayOffset: relativeDays[match.group(1)!]!,
      ),
    ),

    // N दिन पहले/बाद
    PatternDef(
      name: 'hi_dayOffset',
      regex: RegExp(r'(\d+)\s*दिन\s*(पहले|बाद)'),
      extract: (match, np, ref) {
        final days = int.parse(match.group(1)!);
        final dir = match.group(2)!;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: dir == 'बाद' ? days : -days,
        );
      },
    ),

    // N सप्ताह/हफ्ते पहले/बाद
    PatternDef(
      name: 'hi_weekOffset',
      regex: RegExp(r'(\d+)\s*([^\s\d]+)\s*(पहले|बाद)'),
      extract: (match, np, ref) {
        final weeks = int.parse(match.group(1)!);
        final unit = match.group(2)!;
        if (!['सप्ताह', 'हफ्ते', 'हफ्ता', 'हफ़्ते'].contains(unit)) {
          return null;
        }
        final dir = match.group(3)!;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekOffset: dir == 'बाद' ? weeks : -weeks,
        );
      },
    ),

    // Full datetime: DD month YYYY (period) HH:MM
    PatternDef(
      name: 'hi_fullDateTime',
      regex: RegExp(
        r'(\d{1,2})\s+([^\s\d]+)\s+(\d{4})\s*(?:को)?\s*(सुबह|दोपहर|शाम|रात)?\s*(\d{1,2}):(\d{2})',
      ),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final month = months[monthStr];
        if (month == null) return null;
        final year = int.parse(match.group(3)!);
        final period = match.group(4);
        var hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        if (period != null && timePeriods.containsKey(period)) {
          final offset = timePeriods[period]!;
          if (offset == 12 && hour < 12) hour += 12;
        }
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // DD MM (YYYY) - "14 मार्च 2025" or "14 मार्च"
    PatternDef(
      name: 'hi_dayMonth',
      regex: RegExp(r'(\d{1,2})\s+([^\s\d]+)(?:\s+(\d{4}))?'),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final month = months[monthStr];
        if (month == null) return null;
        final yearStr = match.group(3);
        int year = yearStr != null ? int.parse(yearStr) : ref.year;
        if (yearStr == null &&
            DateTime(
              year,
              month,
              day,
            ).isBefore(DateTime(ref.year, ref.month, ref.day))) {
          year++;
        }
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: yearStr == null ? null : year,
          month: month,
          day: day,
        );
      },
    ),

    // Time: (सुबह|दोपहर|शाम|रात) HH:MM?
    PatternDef(
      name: 'hi_timeWithPeriod',
      regex: RegExp(r'(सुबह|दोपहर|शाम|रात)?\s*(\d{1,2})(?::(\d{2}))?'),
      extract: (match, np, ref) {
        final period = match.group(1);
        var hour = int.parse(match.group(2)!);
        final minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
        if (period != null && timePeriods.containsKey(period)) {
          final offset = timePeriods[period]!;
          if (offset == 12 && hour < 12) hour += 12;
        }
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Day only: NN तारीख
    PatternDef(
      name: 'hi_dayOnly',
      regex: RegExp(r'(\d{1,2})\s*तारीख'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start,
        endIndex: match.end,
        text: match.group(0)!,
        day: int.parse(match.group(1)!),
      ),
    ),

    // अगले सप्ताह/हफ्ते + weekday
    PatternDef(
      name: 'hi_nextWeekWeekday',
      regex: RegExp(
        r'अगले\s+(?:सप्ताह|हफ्ते|हफ्ता)\s+(सोमवार|मंगलवार|बुधवार|गुरुवार|शुक्रवार|शनिवार|रविवार)',
      ),
      extract: (match, np, ref) {
        final day = match.group(1)!;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekdays[day] ?? 1,
          weekOffset: 1,
          calendarWeek: true,
        );
      },
    ),

    // Weekday only
    PatternDef(
      name: 'hi_weekday',
      regex: RegExp(r'(सोमवार|मंगलवार|बुधवार|गुरुवार|शुक्रवार|शनिवार|रविवार)'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start,
        endIndex: match.end,
        text: match.group(0)!,
        weekday: weekdays[match.group(1)!]!,
      ),
    ),

    // अगले महीने
    PatternDef(
      name: 'hi_nextMonth',
      regex: RegExp(r'अगले\s+महीने'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start,
        endIndex: match.end,
        text: match.group(0)!,
        monthOffset: 1,
        rangeType: 'month',
      ),
    ),

    // Next / last weekday: अगले सोमवार, पिछले शुक्रवार, etc.
    PatternDef(
      name: 'hi_nextLastWeekday',
      regex: RegExp(
        r'(अगले|पिछले)\s+(सोमवार|मंगलवार|बुधवार|गुरुवार|शुक्रवार|शनिवार|रविवार)',
      ),
      extract: (match, np, ref) {
        final dir = match.group(1)!;
        final day = match.group(2)!;
        final weekday = weekdays[day] ?? 1;
        final isLast = dir == 'पिछले';
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekday,
          weekOffset: isLast ? -7 : 0,
        );
      },
    ),
  ];

  static final definition = LanguageDefinition(
    code: 'hi',
    numberParser: arabicParser,
    patterns: patterns,
  );
}

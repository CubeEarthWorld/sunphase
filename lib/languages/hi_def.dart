// lib/languages/hi_def.dart
import '../core/number_parser.dart';
import 'lang_def.dart';

class HiDefinitions {
  static const Map<String, int> months = {
    'जनवरी': 1, 'फरवरी': 2, 'मार्च': 3, 'अप्रैल': 4, 'मई': 5,
    'जून': 6, 'जुलाई': 7, 'अगस्त': 8, 'सितंबर': 9, 'अक्टूबर': 10, 'नवंबर': 11, 'दिसंबर': 12,
  };

  static const Map<String, int> weekdays = {
    'सोमवार': 1, 'मंगलवार': 2, 'बुधवार': 3, 'गुरुवार': 4, 'शुक्रवार': 5, 'शनिवार': 6, 'रविवार': 7,
  };

  static const Map<String, int> relativeDays = {'आज': 0, 'कल': 1, 'परसों': 2};

  static const Map<String, int> timePeriods = {'सुबह': 0, 'दोपहर': 12, 'शाम': 12, 'रात': 12};

  static const arabicParser = ArabicNumberParser();

  static final patterns = [
    // Relative days: आज, कल, परसों
    PatternDef(
      name: 'hi_relativeDay',
      regex: RegExp(r'(आज|कल|परसों)'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
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
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          dayOffset: dir == 'बाद' ? days : -days,
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
        if (yearStr == null && DateTime(year, month, day).isBefore(DateTime(ref.year, ref.month, ref.day))) {
          year++;
        }
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: yearStr == null ? null : year, month: month, day: day,
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
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          hour: hour, minute: minute,
        );
      },
    ),

    // Day only: NN तारीख
    PatternDef(
      name: 'hi_dayOnly',
      regex: RegExp(r'(\d{1,2})\s*तारीख'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        day: int.parse(match.group(1)!),
      ),
    ),

    // Weekday only
    PatternDef(
      name: 'hi_weekday',
      regex: RegExp(r'(सोमवार|मंगलवार|बुधवार|गुरुवार|शुक्रवार|शनिवार|रविवार)'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        weekday: weekdays[match.group(1)!]!,
      ),
    ),

    // अगले महीने
    PatternDef(
      name: 'hi_nextMonth',
      regex: RegExp(r'अगले\s+महीने'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        monthOffset: 1, rangeType: 'month',
      ),
    ),

    // पिछले शुक्रवार (last Friday)
    PatternDef(
      name: 'hi_lastFriday',
      regex: RegExp(r'पिछले\s+शुक्रवार'),
      extract: (match, np, ref) {
        // Find previous Friday
        int diff = (ref.weekday - 5 + 7) % 7;
        diff = diff == 0 ? 7 : diff;
        DateTime lastFri = ref.subtract(Duration(days: diff));
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: lastFri.year, month: lastFri.month, day: lastFri.day,
        );
      },
    ),

    // 2 सप्ताह बाद (2 weeks later)
    PatternDef(
      name: 'hi_weeksLater',
      regex: RegExp(r'2\s+सप्ताह\s+बाद'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        dayOffset: 14, // 2 weeks = 14 days
      ),
    ),

    // अगले सोमवार
    PatternDef(
      name: 'hi_nextMonday',
      regex: RegExp(r'अगले\s+सोमवार'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        weekday: 1, weekOffset: 0,
      ),
    ),
  ];

  static final definition = LanguageDefinition(
    code: 'hi',
    numberParser: arabicParser,
    patterns: patterns,
  );
}

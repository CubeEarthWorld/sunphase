// lib/languages/lang_def.dart
import '../core/number_parser.dart';

/// Intermediate match extracted from text before date resolution
class RawMatch {
  final int startIndex;
  final int endIndex;
  final String text;
  final int? year;
  final int? month;
  final int? day;
  final int? hour;
  final int? minute;
  final int? weekday; // 1=Mon..7=Sun
  final int? dayOffset; // 0=today, 1=tomorrow, -1=yesterday
  final int? monthOffset; // 1=next month, -1=last month
  final int? yearOffset; // 1=next year, -1=last year
  final int? weekOffset; // 1=next week, 2=two weeks later
  final bool pmFlag;
  final String? rangeType; // "week" or "month"
  final int? rangeDays;

  const RawMatch({
    required this.startIndex,
    required this.endIndex,
    required this.text,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.weekday,
    this.dayOffset,
    this.monthOffset,
    this.yearOffset,
    this.weekOffset,
    this.pmFlag = false,
    this.rangeType,
    this.rangeDays,
  });

  int get specificity {
    int s = 0;
    if (year != null) s += 4;
    if (month != null) s += 3;
    if (day != null) s += 3;
    if (hour != null) s += 2;
    if (minute != null) s += 1;
    if (weekday != null) s += 3;
    if (dayOffset != null) s += 3;
    if (monthOffset != null) s += 3;
    if (yearOffset != null) s += 3;
    if (weekOffset != null) s += 2;
    return s;
  }

  bool overlaps(RawMatch other) {
    return startIndex < other.endIndex && other.startIndex < endIndex;
  }

  bool get hasDateInfo =>
      year != null ||
      month != null ||
      day != null ||
      dayOffset != null ||
      weekday != null ||
      monthOffset != null ||
      yearOffset != null ||
      weekOffset != null;
}

/// A regex-based pattern definition with extraction logic
class PatternDef {
  final String name;
  final RegExp regex;
  final RawMatch? Function(RegExpMatch match, NumberParser np, DateTime ref)
      extract;

  const PatternDef({
    required this.name,
    required this.regex,
    required this.extract,
  });
}

/// Language definition: vocabulary data + pattern definitions
class LanguageDefinition {
  final String code;
  final NumberParser numberParser;
  final List<PatternDef> patterns;

  const LanguageDefinition({
    required this.code,
    required this.numberParser,
    required this.patterns,
  });
}

/// Universal patterns that can be shared across languages
class UniversalPatterns {
  // Time colon format: HH:MM (used by most languages)
  static final timeColon = PatternDef(
    name: 'universal_timeColon',
    regex: RegExp(r'(\d{1,2}):(\d{2})'),
    extract: (match, np, ref) => RawMatch(
      startIndex: match.start,
      endIndex: match.end,
      text: match.group(0)!,
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    ),
  );
}

// lib/languages/lang_def.dart
//
// Core data structures shared by every language definition.
//
// A language definition is modelled as:
//   LanguageDefinition
//     ├── code           — ISO-639-1 language code
//     ├── numberParser   — converts digit strings for this language
//     └── patterns[]     — ordered list of PatternDef entries
//
// A PatternDef combines a compiled `RegExp` with an `extract` function
// that converts a `RegExpMatch` into a `RawMatch`. A `RawMatch` stores
// the raw extracted fields (year, month, day, hour, …) *before* the
// calendar logic in `DateResolver` turns them into a concrete `DateTime`.
//
// Having an intermediate `RawMatch` step makes it easy to share
// resolution rules across languages: patterns only need to know "what
// was said", not "what date that means".

import '../core/number_parser.dart';

// ---------------------------------------------------------------------------
// RawMatch
// ---------------------------------------------------------------------------

/// Intermediate, partially-resolved representation of a matched
/// date/time expression, before calendar arithmetic is applied.
///
/// Every field is nullable so that patterns can express partial
/// information (e.g. "time only" or "weekday only"). The `DateResolver`
/// infers missing fields from the reference date.
class RawMatch {
  /// Start character offset of the matched text inside the original input.
  final int startIndex;

  /// Exclusive end character offset of the matched text.
  final int endIndex;

  /// The exact matched substring.
  final String text;

  // --- Absolute calendar fields ---

  /// Four-digit year extracted from the match (e.g. `2025`), if any.
  final int? year;

  /// Month number 1–12, if any.
  final int? month;

  /// Day-of-month 1–31, if any.
  final int? day;

  /// Hour 0–23, if any.
  final int? hour;

  /// Minute 0–59, if any.
  final int? minute;

  // --- Relative / inferential fields ---

  /// ISO weekday 1 (Monday) – 7 (Sunday), if the expression named a
  /// weekday (e.g. "Monday", "月曜日").
  final int? weekday;

  /// Offset in days from the reference date (0 = today, 1 = tomorrow,
  /// -1 = yesterday, 3 = three days from now, etc.).
  final int? dayOffset;

  /// Offset in calendar months from the reference date
  /// (1 = next month, -1 = last month).
  final int? monthOffset;

  /// Offset in calendar years from the reference date
  /// (1 = next year, -1 = last year).
  final int? yearOffset;

  /// Offset in whole weeks from the reference date
  /// (1 = next week, -1 = last week). When combined with [weekday],
  /// this shifts the entire search window by that many weeks.
  final int? weekOffset;

  /// When true, [weekday] + [weekOffset] resolves inside the named
  /// calendar week instead of using the next/previous weekday occurrence.
  ///
  /// This distinguishes expressions like "next week Sunday" from
  /// duration-like expressions such as "1 week later Sunday".
  final bool calendarWeek;

  /// Set to `true` when the pattern recognised a "pm" marker, so the
  /// resolver can add 12 to hours < 12.
  final bool pmFlag;

  // --- Range / span fields ---

  /// For span expressions: the kind of span (`"week"` or `"month"`).
  /// `null` for point-in-time results.
  final String? rangeType;

  /// For span expressions with an explicit length: number of days the
  /// span covers (e.g. "in 3 days" stores 4 so that the expansion
  /// includes day 0 through day 3).
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
    this.calendarWeek = false,
    this.pmFlag = false,
    this.rangeType,
    this.rangeDays,
  });

  /// A numeric score representing how many date/time fields are
  /// populated. Higher specificity wins in overlap resolution.
  ///
  /// Weights are chosen so that calendar-precision fields (year, month,
  /// day, weekday) outscore time-precision fields (hour, minute).
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
    if (weekOffset != null) s += 3;
    return s;
  }

  /// Returns `true` when [other] shares at least one character position
  /// with this match.
  bool overlaps(RawMatch other) {
    return startIndex < other.endIndex && other.startIndex < endIndex;
  }

  /// Returns `true` when this match contains at least one date-level
  /// field (as opposed to a time-only match).
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

// ---------------------------------------------------------------------------
// PatternDef
// ---------------------------------------------------------------------------

/// A single regex pattern together with the extraction logic that
/// converts a `RegExpMatch` into a `RawMatch`.
///
/// Patterns are listed inside a `LanguageDefinition.patterns` list. The
/// `UnifiedParser` tries every pattern in every requested language and
/// collects all non-null results from `extract`.
class PatternDef {
  /// Human-readable name used for debugging (e.g. `"en_fullDate"`).
  final String name;

  /// The compiled regular expression to run against the input text.
  final RegExp regex;

  /// Converts a regex match into a [RawMatch], or returns `null` to
  /// signal that the match should be discarded (e.g. the captured
  /// month name was not in the vocabulary).
  ///
  /// Receives the raw [RegExpMatch], the language's [NumberParser] for
  /// numeric group conversion, and [ref] (the reference date) in case
  /// the extraction logic needs to compute a relative year.
  final RawMatch? Function(RegExpMatch match, NumberParser np, DateTime ref)
  extract;

  const PatternDef({
    required this.name,
    required this.regex,
    required this.extract,
  });
}

// ---------------------------------------------------------------------------
// LanguageDefinition
// ---------------------------------------------------------------------------

/// Bundles all the data that defines how a single language is parsed.
///
/// Each supported language has one `const LanguageDefinition` instance
/// (e.g. `EnDefinitions.definition`) registered in `UnifiedParser.languages`.
class LanguageDefinition {
  /// ISO-639-1 code identifying this language (e.g. `"en"`, `"ja"`).
  final String code;

  /// Number parser appropriate for this language's digit system.
  final NumberParser numberParser;

  /// Ordered list of patterns to try against the input text.
  ///
  /// Patterns are tried in the order given; specificity-based filtering
  /// in `ResultRanker` later discards lower-quality overlapping matches.
  final List<PatternDef> patterns;

  const LanguageDefinition({
    required this.code,
    required this.numberParser,
    required this.patterns,
  });
}

// ---------------------------------------------------------------------------
// UniversalPatterns
// ---------------------------------------------------------------------------

/// Reusable pattern fragments shared across multiple language definitions.
///
/// Adding a pattern here (instead of duplicating it in every language
/// file) keeps the pattern list compact and ensures consistent behaviour.
class UniversalPatterns {
  /// Matches colon-separated time values: `HH:MM` (e.g. `"10:30"`).
  ///
  /// Accepted by most language definitions because this format is
  /// recognisable regardless of locale.
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

// ---------------------------------------------------------------------------
// Vocabulary helpers
// ---------------------------------------------------------------------------

/// Escapes the regex metacharacters in [s] so an arbitrary vocabulary word
/// can be embedded safely inside a larger pattern.
String escapeRegExp(String s) =>
    s.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');

/// Builds a single capturing-group regex alternation from [words], escaping
/// each word and ordering them **longest-first**.
///
/// ## Why this exists
/// Relative-day vocabularies — *today*, *tomorrow*, *the day after
/// tomorrow*, *the day after that*, … — used to be hand-written as a
/// separate alternation inside every pattern that referenced them (the
/// "word only" pattern, the "word + hour" pattern, the "word + hour +
/// minute" pattern, and so on). Those parallel lists inevitably drifted out
/// of sync with the authoritative `relativeDays` map.
///
/// For example, Japanese `明々後日` ("the day after the day after tomorrow")
/// was present in the map and in the "+ minutes" pattern, but missing from
/// the "+ hour" pattern — so `明々後日16時` failed to combine into a single
/// datetime while `明後日16時` worked. This was not a missing-word problem so
/// much as a missing-*single-source-of-truth* problem.
///
/// By deriving the alternation from the map's keys at construction time, the
/// map becomes the one place a word is declared: add it once and every
/// pattern that uses `buildAlternation(map.keys)` recognises it.
///
/// Longest-first ordering guarantees that a longer word (e.g. `明々後日`,
/// `послезавтра`, `pasado mañana`) is attempted before any shorter word that
/// could otherwise shadow it in the alternation.
String buildAlternation(Iterable<String> words) {
  final sorted = words.toSet().toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  return '(${sorted.map(escapeRegExp).join('|')})';
}

// lib/core/parser_manager.dart
//
// High-level orchestration of a parse request.
//
// The `ParserManager.parse` method is the single entry point that the
// public `parse` function in `sunphase.dart` delegates to. It wires up
// the reference date, chooses the set of language parsers to run,
// invokes them through the `UnifiedParser`, runs the language-agnostic
// `UniversalParser` for ISO-style formats, and then either picks the
// single best match or expands ranges depending on `rangeMode`.

import 'parsing_context.dart';
import 'result.dart';
import 'unified_parser.dart';
import '../languages/universal.dart' as old_universal;
import '../modes/range_mode.dart';
import '../utils/timezone_utils.dart';
import '../utils/date_utils.dart';

/// Top-level parse pipeline. All members are static — this class exists
/// only as a namespace.
class ParserManager {
  /// Parses [text] into a list of [ParsingResult]s. See the public
  /// `parse` function in `lib/sunphase.dart` for a full description of
  /// the parameters.
  static List<ParsingResult> parse(
    String text, {
    DateTime? referenceDate,
    List<String>? languages,
    bool rangeMode = false,
    String? timezone,
    int weekStartsOn = DateTime.sunday,
  }) {
    if (weekStartsOn != DateTime.sunday && weekStartsOn != DateTime.monday) {
      throw ArgumentError.value(
        weekStartsOn,
        'weekStartsOn',
        'Use DateTime.sunday or DateTime.monday.',
      );
    }

    // 0. Normalise full-width digits (U+FF10–U+FF19) to ASCII so that
    //    every regex pattern and number parser works uniformly.
    text = DateUtils.normalizeFullWidthDigits(text);

    // 1. Anchor every relative expression to a single reference moment.
    //    When the caller does not provide one we fall back to "now".
    DateTime ref = referenceDate ?? DateTime.now();
    ParsingContext context = ParsingContext(
      referenceDate: ref,
      timezoneOffset: timezone != null
          ? TimezoneUtils.offsetFromString(timezone)
          : Duration.zero,
      weekStartsOn: weekStartsOn,
    );

    // 2. Decide which language parsers to run. When the caller passes
    //    `null` or an empty list we default to English + Japanese +
    //    Chinese so mixed-language input works out of the box.
    List<String> langs = languages ?? ['en', 'ja', 'zh'];
    if (langs.isEmpty) {
      langs = ['en', 'ja', 'zh'];
    }

    // 3. Run the selected language parsers through the unified pipeline.
    UnifiedParser unified = UnifiedParser(langs);
    List<ParsingResult> results = unified.parse(text, context);

    // 4. Run the language-agnostic universal parser for ISO 8601 and
    //    similar machine-readable date formats. Its matches are added
    //    to whatever the language parsers already produced.
    old_universal.UniversalParser universal = old_universal.UniversalParser();
    List<ParsingResult> universalResults = universal.parse(text, context);
    results.addAll(universalResults);

    if (results.isEmpty) return [];

    if (!rangeMode) {
      // In point-in-time mode, return only the longest match — a rough
      // but effective proxy for "the most specific expression".
      results.sort((a, b) => b.text.length.compareTo(a.text.length));
      results = [results.first];
    } else {
      // In range mode, expand span expressions (week/month/"in N days")
      // into one result per day in the span.
      List<ParsingResult> rangeResults = RangeMode.generate(results, context);
      results = rangeResults.isNotEmpty ? rangeResults : results;
    }

    // 5. Finally, shift the resolved dates by the caller-supplied
    //    timezone offset (a no-op when none was given).
    results = TimezoneUtils.applyTimezone(results, context.timezoneOffset);
    return results;
  }
}

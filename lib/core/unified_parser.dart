// lib/core/unified_parser.dart
//
// Runs every pattern from every requested language definition against
// the input text, filters overlapping matches down to the highest-
// specificity ones, and converts each surviving `RawMatch` into a
// final `ParsingResult` via the `DateResolver`.

import 'parsing_context.dart';
import 'result.dart';
import 'resolver.dart';
import 'ranker.dart';
import '../languages/lang_def.dart';
import '../languages/ja_def.dart';
import '../languages/zh_def.dart';
import '../languages/en_def.dart';
import '../languages/es_def.dart';
import '../languages/hi_def.dart';
import '../languages/ko_def.dart';
import '../languages/ru_def.dart';

/// Runs all pattern definitions for the requested set of languages.
class UnifiedParser {
  /// Registry mapping each supported ISO-639-1 code to its
  /// `LanguageDefinition`. Adding a new language means adding an entry
  /// here (plus the matching `*_def.dart` file under `lib/languages/`).
  static final Map<String, LanguageDefinition> languages = {
    'ja': JaDefinitions.definition,
    'zh': ZhDefinitions.definition,
    'en': EnDefinitions.definition,
    'es': EsDefinitions.definition,
    'hi': HiDefinitions.definition,
    'ko': KoDefinitions.definition,
    'ru': RuDefinitions.definition,
  };

  /// Language codes to actually run against the input, in the order
  /// given by the caller.
  final List<String> languageCodes;

  UnifiedParser(this.languageCodes);

  /// Runs every pattern in every requested language against [text] and
  /// returns a list of resolved [ParsingResult]s.
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<RawMatch> allMatches = [];

    // Collect raw matches from every pattern across every selected
    // language. Patterns are free to return `null` to reject a match
    // (e.g. when a regex accidentally matches something that turns out
    // to be invalid after closer inspection).
    for (String code in languageCodes) {
      final langDef = languages[code];
      if (langDef == null) continue;

      for (final pattern in langDef.patterns) {
        for (final match in pattern.regex.allMatches(text)) {
          final raw = pattern.extract(
            match,
            langDef.numberParser,
            context.referenceDate,
          );
          if (raw != null) {
            allMatches.add(raw);
          }
        }
      }
    }

    // Multiple patterns often match overlapping regions of the same
    // text — e.g. "March 7 10:10" matches both a full-date pattern and
    // a bare-time pattern. Keep only the most informative non-
    // overlapping subset.
    final filtered = ResultRanker.filterOverlapping<RawMatch>(
      allMatches,
      (m) => m.startIndex,
      (m) => m.endIndex,
      (m) => m.specificity,
      (m) => m.text.length,
    );

    // Turn each surviving `RawMatch` into a concrete `DateTime`.
    List<ParsingResult> results = filtered
        .map((m) => DateResolver.resolve(m, context.referenceDate))
        .toList();

    return results;
  }
}

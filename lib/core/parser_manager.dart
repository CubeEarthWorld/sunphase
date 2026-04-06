// lib/core/parser_manager.dart
import 'parsing_context.dart';
import 'result.dart';
import 'unified_parser.dart';
import '../languages/universal.dart' as old_universal;
import '../modes/range_mode.dart';
import '../utils/timezone_utils.dart';

class ParserManager {
  static List<ParsingResult> parse(String text,
      {DateTime? referenceDate,
        List<String>? languages,
        bool rangeMode = false,
        String? timezone}) {
    DateTime ref = referenceDate ?? DateTime.now();
    ParsingContext context = ParsingContext(
      referenceDate: ref,
      timezoneOffset: timezone != null
          ? TimezoneUtils.offsetFromString(timezone)
          : Duration.zero,
    );

    // Determine languages to use
    List<String> langs = languages ?? ['en', 'ja', 'zh'];
    if (langs.isEmpty) {
      langs = ['en', 'ja', 'zh'];
    }

    // Run unified parser
    UnifiedParser unified = UnifiedParser(langs);
    List<ParsingResult> results = unified.parse(text, context);

    // Run universal parser for ISO formats
    old_universal.UniversalParser universal = old_universal.UniversalParser();
    List<ParsingResult> universalResults = universal.parse(text, context);
    results.addAll(universalResults);

    if (results.isEmpty) return [];

    // In non-range mode, select single best result
    if (!rangeMode) {
      results.sort((a, b) => b.text.length.compareTo(a.text.length));
      results = [results.first];
    } else {
      // Expand ranges
      List<ParsingResult> rangeResults = RangeMode.generate(results, context);
      results = rangeResults.isNotEmpty ? rangeResults : results;
    }

    // Apply timezone
    results = TimezoneUtils.applyTimezone(results, context.timezoneOffset);
    return results;
  }
}

// lib/core/unified_parser.dart
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

class UnifiedParser {
  static final Map<String, LanguageDefinition> languages = {
    'ja': JaDefinitions.definition,
    'zh': ZhDefinitions.definition,
    'en': EnDefinitions.definition,
    'es': EsDefinitions.definition,
    'hi': HiDefinitions.definition,
  };

  final List<String> languageCodes;

  UnifiedParser(this.languageCodes);

  List<ParsingResult> parse(String text, ParsingContext context) {
    List<RawMatch> allMatches = [];

    for (String code in languageCodes) {
      final langDef = languages[code];
      if (langDef == null) continue;

      for (final pattern in langDef.patterns) {
        for (final match in pattern.regex.allMatches(text)) {
          final raw = pattern.extract(match, langDef.numberParser, context.referenceDate);
          if (raw != null) {
            allMatches.add(raw);
          }
        }
      }
    }

    // Filter overlapping matches
    final filtered = ResultRanker.filterOverlapping<RawMatch>(
      allMatches,
      (m) => m.startIndex,
      (m) => m.endIndex,
      (m) => m.specificity,
      (m) => m.text.length,
    );

    // Resolve to ParsingResult
    List<ParsingResult> results = filtered.map((m) => DateResolver.resolve(m, context.referenceDate)).toList();

    return results;
  }
}

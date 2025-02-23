// lib/core/parser_manager.dart
import 'base_parser.dart';
import 'parsing_context.dart';
import 'result.dart';
import '../languages/en.dart';
import '../languages/ja.dart';
import '../languages/zh.dart';
import '../languages/es.dart';
import '../languages/hi.dart';
import '../languages/universal.dart';
import '../modes/range_mode.dart';
import '../utils/timezone_utils.dart';

class ParserManager {
  static final Map<String, List<BaseParser>> languageParsers = {
    'en': EnParsers.parsers,
    'ja': JaParsers.parsers,
    'zh': ZhParsers.parsers,
    'es': EsParsers.parsers,
    'hi': HiParsers.parsers,
  };

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

    List<BaseParser> parsers = _getParsersForLanguages(languages);
    List<ParsingResult> results = [];
    for (var parser in parsers) {
      results.addAll(parser.parse(text, context));
    }

    if (rangeMode) {
      List<ParsingResult> rangeResults = RangeMode.generate(results, context);
      results = rangeResults.isNotEmpty ? rangeResults : results;
    } else {
      if (results.isNotEmpty) {
        ParsingResult merged =
        results.reduce((a, b) => a.text.length >= b.text.length ? a : b);
        results = [merged];
      }
    }

    results = TimezoneUtils.applyTimezone(results, context.timezoneOffset);
    return results;
  }

  static List<BaseParser> _getParsersForLanguages(List<String>? languages) {
    List<BaseParser> parsers = [];
    if (languages == null || languages.isEmpty) {
      // デフォルトは英語、日本語、中国語
      parsers.addAll(EnParsers.parsers);
      parsers.addAll(JaParsers.parsers);
      parsers.addAll(ZhParsers.parsers);
    } else {
      for (String lang in languages) {
        if (languageParsers.containsKey(lang)) {
          parsers.addAll(languageParsers[lang]!);
        }
      }
    }
    // 共通パーサーを追加
    parsers.addAll(UniversalParsers.parsers);
    return parsers;
  }
}

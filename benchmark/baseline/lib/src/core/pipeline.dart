// lib/src/core/pipeline.dart
//
// Orchestrates a parse request:
//
//   normalize → tokenize (per language) → compose → resolve → select
//   → [range expand] → timezone shift
//
// The language-agnostic "universal" spec (ISO 8601 etc.) always runs in
// addition to the requested languages.

import '../../utils/date_utils.dart';
import '../language/language.dart';
import '../language/registry.dart';
import '../result.dart';
import 'composer.dart';
import 'range_expander.dart';
import 'resolver.dart';
import 'selector.dart';
import 'tokenizer.dart';

class Pipeline {
  static const _defaultLanguages = ['en', 'ja', 'zh'];

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

    final normalized = DateUtils.normalizeFullWidthDigits(text);
    final ref = referenceDate ?? DateTime.now();
    final codes = (languages == null || languages.isEmpty)
        ? _defaultLanguages
        : languages;

    final specs = <LanguageSpec>[
      for (final code in codes)
        if (LanguageRegistry.byCode(code) case final spec?) spec,
      LanguageRegistry.universal,
    ];

    final resolver = Resolver(ref, weekStartsOn: weekStartsOn);
    final candidates = <Resolved>[];
    for (final spec in specs) {
      final tokens = Tokenizer(spec).tokenize(normalized, ref);
      for (final expr in Composer(spec).compose(normalized, tokens)) {
        final resolved = resolver.resolve(expr);
        if (resolved != null) candidates.add(resolved);
      }
    }
    if (candidates.isEmpty) return [];

    final selected =
        const Selector().select(candidates, single: !rangeMode);

    var results = [
      for (final r in selected)
        ParsingResult(
          index: r.start,
          text: normalized.substring(r.start, r.end),
          date: r.date,
          rangeType: r.rangeType,
          rangeDays: r.rangeDays,
        ),
    ];

    if (rangeMode) {
      results = const RangeExpander().expand(results);
    }

    return _applyTimezone(results, timezone);
  }

  /// Shifts result dates by a UTC offset given in minutes (e.g. "480"
  /// for UTC+8). No-op when [timezone] is absent or unparsable.
  static List<ParsingResult> _applyTimezone(
    List<ParsingResult> results,
    String? timezone,
  ) {
    final minutes = timezone == null ? 0 : (int.tryParse(timezone) ?? 0);
    if (minutes == 0) return results;
    final offset = Duration(minutes: minutes);
    return [
      for (final r in results)
        ParsingResult(
          index: r.index,
          text: r.text,
          date: r.date.add(offset),
          rangeType: r.rangeType,
          rangeDays: r.rangeDays,
        ),
    ];
  }
}

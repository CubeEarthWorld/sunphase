// lib/src/language/universal.dart
//
// Machine-readable formats that are unambiguous regardless of locale.
// Modelled as just another LanguageSpec so a single pipeline handles
// both natural language and ISO input.

import '../core/component.dart';
import 'language.dart';
import 'numbers.dart';

class UniversalLanguage {
  static final LanguageSpec spec = LanguageSpec(
    code: 'universal',
    numbers: const AsciiNumberReader(),
    glue: RegExp(r'^[\s,]+$'),
    patterns: [
      // ISO 8601 datetime: 2025-03-07T10:00:00Z, 2025-03-07 10:00:00+09:00
      TokenPattern(
        name: 'universal_iso',
        regex: RegExp(
          r'\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(?:\.\d+)?'
          r'(?:Z|[+\-]\d{2}:?\d{2})?',
        ),
        build: (m, ctx) {
          final parsed = DateTime.tryParse(m.group(0)!);
          return parsed == null ? null : [AbsoluteInstant(parsed)];
        },
      ),

      // RFC-style (JavaScript Date.toString()) — accepted when the Dart
      // SDK can parse it.
      TokenPattern(
        name: 'universal_rfc',
        regex: RegExp(
          r'\w{3}\s+\w{3}\s+\d{1,2}\s+\d{4}\s+\d{2}:\d{2}:\d{2}'
          r'\s+GMT[+\-]\d{4}(?:\s*\(.*\))?',
        ),
        build: (m, ctx) {
          final parsed = DateTime.tryParse(m.group(0)!);
          return parsed == null ? null : [AbsoluteInstant(parsed)];
        },
      ),

      // Plain date: 2025-03-07 or 2025/03/07 (components, so an adjacent
      // time can compose).
      TokenPattern(
        name: 'universal_date',
        regex: RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'),
        build: (m, ctx) {
          final month = asMonth(int.parse(m.group(2)!));
          final day = asDay(int.parse(m.group(3)!));
          if (month == null || day == null) return null;
          return [
            YearValue(int.parse(m.group(1)!)),
            MonthValue(month),
            DayOfMonth(day),
          ];
        },
      ),

      colonTime('universal_colonTime'),
    ],
  );
}

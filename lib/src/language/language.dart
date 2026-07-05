// lib/src/language/language.dart
//
// The complete contract between a language and the parsing engine.
//
// A language is pure data: a number reader for its numeral system, a
// glue pattern describing which connective text may sit between two
// components of one expression (の, "at", "de", "в", whitespace…), and a
// list of token patterns that each recognise ONE small component (a
// relative-day word, a month anchor, a clock time, …).
//
// Languages never describe combinations — the language-neutral composer
// derives all valid combinations from slot compatibility. Adding a word
// to a vocabulary map makes it work in every composition automatically.

import '../core/component.dart';
import 'numbers.dart';

/// Context handed to token builders.
class TokenContext {
  final NumberReader numbers;
  final DateTime referenceDate;
  const TokenContext(this.numbers, this.referenceDate);
}

/// One regex that recognises one semantic component (or one fused group
/// of components for scripts that write them as a single word, e.g.
/// 下周二 = next-week + Tuesday).
class TokenPattern {
  /// Debug name, e.g. `ja_time`.
  final String name;

  final RegExp regex;

  /// Converts a match into components, or returns `null` to reject it
  /// (e.g. captured word not in vocabulary, number out of range).
  final List<DateComponent>? Function(RegExpMatch match, TokenContext ctx)
  build;

  const TokenPattern({
    required this.name,
    required this.regex,
    required this.build,
  });
}

/// Everything the engine needs to know about one language.
class LanguageSpec {
  /// ISO-639-1 code ("ja", "en", …) or "universal".
  final String code;

  final NumberReader numbers;

  /// Matches an ENTIRE inter-token gap that should not break an
  /// expression (must be anchored `^…$`).
  final RegExp glue;

  final List<TokenPattern> patterns;

  const LanguageSpec({
    required this.code,
    required this.numbers,
    required this.glue,
    required this.patterns,
  });
}

// ---------------------------------------------------------------------------
// Shared pattern-building helpers
// ---------------------------------------------------------------------------

/// Escapes regex metacharacters in [s].
String escapeRegExp(String s) =>
    s.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');

/// Builds a capturing alternation from [words], longest-first so longer
/// words are never shadowed by their prefixes (明々後日 before 明後日).
String alternation(Iterable<String> words) {
  final sorted = words.toSet().toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  return '(${sorted.map(escapeRegExp).join('|')})';
}

/// A vocabulary token: each word maps directly to one component.
///
/// [wrap] optionally wraps the alternation with script-appropriate word
/// boundaries; [normalize] canonicalises the matched word before lookup
/// (lowercasing, accent folding).
TokenPattern vocab(
  String name,
  Map<String, DateComponent> table, {
  String Function(String)? wrap,
  String Function(String)? normalize,
  bool caseSensitive = true,
}) {
  final body = alternation(table.keys);
  final source = wrap != null ? wrap(body) : body;
  return TokenPattern(
    name: name,
    regex: RegExp(source, caseSensitive: caseSensitive),
    build: (m, ctx) {
      var word = m.group(1)!;
      if (normalize != null) word = normalize(word);
      final component = table[word];
      return component == null ? null : [component];
    },
  );
}

/// The universal HH:MM clock time, recognised in every language.
TokenPattern colonTime(String name) => TokenPattern(
  name: name,
  regex: RegExp(r'(\d{1,2}):(\d{2})'),
  build: (m, ctx) => [
    ClockTime(int.parse(m.group(1)!), int.parse(m.group(2)!)),
  ],
);

/// Latin-script word boundaries (ASCII + Western European accents).
String latinWord(String body) => '(?<![a-zA-ZáéíóúüñÁÉÍÓÚÜÑ])'
    '$body'
    '(?![a-zA-ZáéíóúüñÁÉÍÓÚÜÑ])';

/// Cyrillic-script word boundaries.
String cyrillicWord(String body) => '(?<![а-яёА-ЯЁ])$body(?![а-яёА-ЯЁ])';

/// Devanagari-script word boundaries.
String devanagariWord(String body) =>
    '(?<![ऀ-ॿ])$body(?![ऀ-ॿ])';

/// Validates a month number, returning it or null.
int? asMonth(int? v) => (v != null && v >= 1 && v <= 12) ? v : null;

/// Validates a day-of-month number, returning it or null.
int? asDay(int? v) => (v != null && v >= 1 && v <= 31) ? v : null;

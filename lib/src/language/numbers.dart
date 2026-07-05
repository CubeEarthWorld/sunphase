// lib/src/language/numbers.dart
//
// Numeral-system abstraction. Languages differ in how numbers appear in
// text (ASCII digits everywhere; kanji/hanzi/hangul-hanja digits with
// positional 十/百/千 in CJK), so each `LanguageSpec` carries the reader
// appropriate for its script. Full-width digits are normalised to ASCII
// before tokenization, so readers never see them.

/// Converts a numeric string captured by a token pattern into an `int`.
abstract class NumberReader {
  const NumberReader();

  /// Returns the numeric value of [input], or `null` if it is not a
  /// number in this reader's numeral system.
  int? read(String input);
}

/// Plain ASCII digit strings ("42").
class AsciiNumberReader extends NumberReader {
  const AsciiNumberReader();

  @override
  int? read(String input) => int.tryParse(input.trim());
}

/// CJK numerals mixed with ASCII digits.
///
/// Handles positional units (十/百/千) correctly at any magnitude used in
/// dates — 十四 → 14, 二十三 → 23, 百五 → 105 — as well as plain
/// digit-concatenation strings such as 二〇二五 → 2025.
class CjkNumberReader extends NumberReader {
  /// Maps digit characters (一..九, 〇/零/영…) to 0–9 and unit characters
  /// (十/百/千) to 10/100/1000.
  final Map<String, int> charValues;

  const CjkNumberReader(this.charValues);

  @override
  int? read(String input) {
    if (input.isEmpty) return null;

    final ascii = int.tryParse(input);
    if (ascii != null) return ascii;

    int total = 0;
    int current = 0;
    for (final ch in input.split('')) {
      final v = charValues[ch] ?? (int.tryParse(ch));
      if (v == null) return null;
      if (v >= 10) {
        // Positional unit: 十/百/千. A bare unit means 1 of it (十 → 10).
        total += (current == 0 ? 1 : current) * v;
        current = 0;
      } else {
        // Digit: accumulate as decimal concatenation (二〇二五 → 2025).
        current = current * 10 + v;
      }
    }
    return total + current;
  }
}

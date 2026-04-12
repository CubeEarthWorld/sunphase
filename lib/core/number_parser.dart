// lib/core/number_parser.dart
//
// Number-parsing abstraction used by language pattern definitions.
//
// Different language parsers represent numbers differently in text:
// English uses only ASCII digits, while CJK languages mix kanji/hanzi
// digits with ASCII digits. Rather than duplicating conversion logic in
// every pattern, each `LanguageDefinition` carries the appropriate
// `NumberParser` implementation, and patterns call `np.tryParse(...)` to
// convert a captured group into an integer.

/// Common interface for converting a numeric string to an `int`.
abstract class NumberParser {
  /// Tries to parse [input] as an integer, returning `null` on failure.
  int? tryParse(String input);
}

/// Parses plain ASCII/Arabic digit strings (e.g. `"42"`).
///
/// Used by languages whose patterns only capture ASCII digit runs.
class ArabicNumberParser implements NumberParser {
  const ArabicNumberParser();

  @override
  int? tryParse(String input) => int.tryParse(input.trim());
}

/// Parses CJK digit strings (一二三…十) as well as ASCII digits.
///
/// The digit characters to recognise are supplied via [digitMap] so the
/// same class can serve both Japanese (uses 十 for "ten") and Chinese
/// (uses the same character set). Examples:
/// - `"三"` → 3
/// - `"十四"` → 14  (十 + four)
/// - `"二十三"` → 23 (two × ten + three)
/// - `"14"` → 14  (ASCII digits are also accepted)
class CJKNumberParser implements NumberParser {
  /// Maps each recognised CJK digit character to its numeric value.
  final Map<String, int> digitMap;

  const CJKNumberParser(this.digitMap);

  @override
  int? tryParse(String input) {
    if (input.isEmpty) return null;

    // Fast path: plain ASCII integer.
    int? value = int.tryParse(input);
    if (value != null) return value;

    // Reject any character not in the digit map.
    if (!input.split('').every((c) => digitMap.containsKey(c))) return null;

    // Handle expressions that include the "tens" kanji (十).
    if (input.contains('十')) {
      if (input == '十') return 10;
      if (input.length == 2) {
        if (input.startsWith('十')) {
          // e.g. 十四 → 14
          return 10 + (digitMap[input[1]] ?? 0);
        }
        if (input.endsWith('十')) {
          // e.g. 二十 → 20
          return (digitMap[input[0]] ?? 0) * 10;
        }
        // e.g. would not normally occur for 2-char without 十
        return (digitMap[input[0]] ?? 0) * 10 + (digitMap[input[1]] ?? 0);
      }
      if (input.length == 3 && input[1] == '十') {
        // e.g. 二十三 → 23
        return (digitMap[input[0]] ?? 0) * 10 + (digitMap[input[2]] ?? 0);
      }
    }

    // Single kanji digit.
    if (input.length == 1) return digitMap[input];

    // Multi-character sequence treated as a decimal number built from
    // individual digit characters (e.g. 三四 → 34).
    int result = 0;
    for (var c in input.split('')) {
      result = result * 10 + (digitMap[c] ?? 0);
    }
    return result;
  }
}

// lib/core/number_parser.dart

/// Abstract number parser interface
abstract class NumberParser {
  int? tryParse(String input);
}

/// Parses Arabic numerals only
class ArabicNumberParser implements NumberParser {
  const ArabicNumberParser();

  @override
  int? tryParse(String input) => int.tryParse(input.trim());
}

/// Parses CJK numerals (一二三...十) and Arabic numerals
class CJKNumberParser implements NumberParser {
  final Map<String, int> digitMap;

  const CJKNumberParser(this.digitMap);

  @override
  int? tryParse(String input) {
    if (input.isEmpty) return null;
    int? value = int.tryParse(input);
    if (value != null) return value;
    if (!input.split('').every((c) => digitMap.containsKey(c))) return null;

    if (input.contains('十')) {
      if (input == '十') return 10;
      if (input.length == 2) {
        if (input.startsWith('十')) return 10 + (digitMap[input[1]] ?? 0);
        if (input.endsWith('十')) return (digitMap[input[0]] ?? 0) * 10;
        return (digitMap[input[0]] ?? 0) * 10 + (digitMap[input[1]] ?? 0);
      }
      if (input.length == 3 && input[1] == '十') {
        return (digitMap[input[0]] ?? 0) * 10 + (digitMap[input[2]] ?? 0);
      }
    }

    if (input.length == 1) return digitMap[input];

    int result = 0;
    for (var c in input.split('')) {
      result = result * 10 + (digitMap[c] ?? 0);
    }
    return result;
  }
}

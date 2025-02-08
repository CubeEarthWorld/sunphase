// lib/languages/universal.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// Parser for language-independent date expressions (e.g., ISO 8601).
class UniversalParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // ISO 8601 format detection
    RegExp isoExp = RegExp(
        r'\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+\-]\d{2}:?\d{2})?');
    Iterable<RegExpMatch> isoMatches = isoExp.allMatches(text);
    for (var match in isoMatches) {
      String dateStr = match.group(0)!;
      try {
        DateTime dt = DateTime.parse(dateStr);
        results.add(ParsingResult(index: match.start, text: dateStr, date: dt));
      } catch (e) {
        // Ignore errors.
      }
    }

    // Alternative format: "Sat Aug 17 2013 18:40:39 GMT+0900 (JST)"
    RegExp altExp = RegExp(r'\w{3}\s+\w{3}\s+\d{1,2}\s+\d{4}\s+\d{2}:\d{2}:\d{2}\s+GMT[+\-]\d{4}(?:\s*\(.*\))?');
    Iterable<RegExpMatch> altMatches = altExp.allMatches(text);
    for (var match in altMatches) {
      String dateStr = match.group(0)!;
      try {
        DateTime dt = DateTime.parse(dateStr);
        results.add(ParsingResult(index: match.start, text: dateStr, date: dt));
      } catch (e) {
        // Ignore.
      }
    }



    // Range expression: e.g., "17 August 2013 - 19 August 2013"
    RegExp rangeExp = RegExp(
        r'(\d{1,2}\s*(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)[\s,]+\d{4})\s*-\s*(\d{1,2}\s*(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)[\s,]+\d{4})',
        caseSensitive: false);
    Iterable<RegExpMatch> rangeMatches = rangeExp.allMatches(text);
    for (var match in rangeMatches) {
      String startStr = match.group(1)!;
      String endStr = match.group(2)!;
      DateTime? startDate = _parseEnglishDate(startStr);
      DateTime? endDate = _parseEnglishDate(endStr);
      if (startDate != null && endDate != null) {
        int diff = endDate.difference(startDate).inDays;
        for (int i = 0; i <= diff; i++) {
          DateTime d = startDate.add(Duration(days: i));
          results.add(ParsingResult(index: match.start, text: "${match.group(0)} (Day ${i+1})", date: d));
        }
      }
    }

    return results;
  }

  DateTime? _parseEnglishDate(String dateStr) {
    Map<String, int> monthMap = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    dateStr = dateStr.toLowerCase().trim();
    RegExp pattern = RegExp(r'^(\d{1,2})\s*([a-z]+)\s*(\d{4})$');
    RegExpMatch? m = pattern.firstMatch(dateStr);
    if (m != null) {
      int day = int.parse(m.group(1)!);
      String monthStr = m.group(2)!;
      int? month = monthMap[monthStr];
      int year = int.parse(m.group(3)!);
      if (month != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}

/// Universal parsers collection.
class UniversalParsers {
  static final List<BaseParser> parsers = [
    UniversalParser(),
  ];
}

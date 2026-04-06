// lib/languages/universal.dart
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

class UniversalParser {
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];

    // ISO 8601 format detection
    RegExp isoExp = RegExp(
        r'\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+\-]\d{2}:?\d{2})?');
    for (var match in isoExp.allMatches(text)) {
      String dateStr = match.group(0)!;
      try {
        DateTime dt = DateTime.parse(dateStr);
        results.add(ParsingResult(index: match.start, text: dateStr, date: dt));
      } catch (e) {}
    }

    // Alternative RFC format detection
    RegExp altExp = RegExp(
        r'\w{3}\s+\w{3}\s+\d{1,2}\s+\d{4}\s+\d{2}:\d{2}:\d{2}\s+GMT[+\-]\d{4}(?:\s*\(.*\))?');
    for (var match in altExp.allMatches(text)) {
      String dateStr = match.group(0)!;
      try {
        DateTime dt = DateTime.parse(dateStr);
        results.add(ParsingResult(index: match.start, text: dateStr, date: dt));
      } catch (e) {}
    }

    // Language-agnostic date format detection (YYYY-MM-DD or YYYY/MM/DD)
    RegExp dateExp = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
    for (var match in dateExp.allMatches(text)) {
      DateTime? date = DateUtils.parseDate(match.group(0)!,
          reference: context.referenceDate);
      if (date != null) {
        results.add(ParsingResult(
            index: match.start, text: match.group(0)!, date: date));
      }
    }

    return results;
  }
}

class UniversalParsers {
  static final parsers = [UniversalParser()];
}

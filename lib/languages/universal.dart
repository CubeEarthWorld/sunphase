// lib/languages/universal.dart
//
// Language-agnostic parser for machine-readable date formats.
//
// This parser runs in addition to the language-specific ones and handles
// formats that are unambiguous regardless of locale:
//   - ISO 8601 datetime strings  (e.g. "2025-03-07T10:00:00Z")
//   - RFC-style datetime strings (e.g. "Fri Mar 07 2025 10:00:00 GMT+0900")
//   - Plain ISO date strings     (e.g. "2025-03-07" or "2025/03/07")
//
// Parsing is delegated to `DateTime.parse` so the supported subset
// exactly matches whatever the Dart SDK accepts.

import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// Parses ISO/RFC machine-readable date formats from free text.
class UniversalParser {
  /// Scans [text] for known machine-readable date patterns and returns
  /// a [ParsingResult] for each successful match.
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];

    // ISO 8601 full datetime: "2025-03-07T10:00:00Z",
    //   "2025-03-07 10:00:00.000", "2025-03-07T10:00:00+09:00", etc.
    RegExp isoExp = RegExp(
      r'\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(?:\.\d+)?'
      r'(?:Z|[+\-]\d{2}:?\d{2})?',
    );
    for (var match in isoExp.allMatches(text)) {
      String dateStr = match.group(0)!;
      try {
        DateTime dt = DateTime.parse(dateStr);
        results.add(ParsingResult(index: match.start, text: dateStr, date: dt));
      } catch (_) {
        // `DateTime.parse` rejected this string; skip it.
      }
    }

    // RFC-style datetime as produced by JavaScript's `Date.toString()`:
    // "Fri Mar 07 2025 10:00:00 GMT+0900 (Japan Standard Time)"
    RegExp altExp = RegExp(
      r'\w{3}\s+\w{3}\s+\d{1,2}\s+\d{4}\s+\d{2}:\d{2}:\d{2}'
      r'\s+GMT[+\-]\d{4}(?:\s*\(.*\))?',
    );
    for (var match in altExp.allMatches(text)) {
      String dateStr = match.group(0)!;
      try {
        DateTime dt = DateTime.parse(dateStr);
        results.add(ParsingResult(index: match.start, text: dateStr, date: dt));
      } catch (_) {}
    }

    // Plain ISO date: "2025-03-07" or "2025/03/07" (no time component).
    RegExp dateExp = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
    for (var match in dateExp.allMatches(text)) {
      DateTime? date = DateUtils.parseDate(
        match.group(0)!,
        reference: context.referenceDate,
      );
      if (date != null) {
        results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date),
        );
      }
    }

    return results;
  }
}

/// Convenience holder so the rest of the codebase can refer to
/// `UniversalParsers.parsers` if they need to iterate over instances.
class UniversalParsers {
  static final parsers = [UniversalParser()];
}

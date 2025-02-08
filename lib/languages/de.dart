// lib/languages/de.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// Kommentare auf Deutsch
/// ----------------------
/// Diese Klasse verarbeitet Datumsangaben auf Deutsch.
/// Sie erkennt relative Ausdrücke (heute, morgen, gestern) und absolute Daten.

class GermanLanguage implements Language {
  @override
  String get code => 'de';

  @override
  List<Parser> get parsers => [GermanDateParser()];

  @override
  List<Refiner> get refiners => [GermanRefiner()];
}

class GermanDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // --------------------------------
    // Relative Ausdrücke: heute, morgen, gestern
    // --------------------------------
    final RegExp relativeDayPattern = RegExp(r'\b(heute|morgen|gestern)\b', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched == 'heute') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'morgen') {
        date = referenceDate.add(const Duration(days: 1));
      } else if (matched == 'gestern') {
        date = referenceDate.subtract(const Duration(days: 1));
      } else {
        date = referenceDate;
      }

      results.add(
        ParsingResult(
          index: match.start,
          text: matched,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // --------------------------------
    // Absolutes Datum: dd.mm.yyyy
    // --------------------------------
    final RegExp absoluteDatePattern = RegExp(r'\b(\d{1,2})\.(\d{1,2})\.(\d{4})\b');
    for (final match in absoluteDatePattern.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);
      DateTime date = DateTime(year, month, day);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // --------------------------------
    // Versuche DateTime.parse
    // --------------------------------
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(
        ParsingResult(
          index: 0,
          text: text,
          component: ParsedComponent(date: parsedDate),
        ),
      );
    } catch (_) {
      // ignoriere
    }

    return results;
  }
}

class GermanRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ------------------------------------------------
    // Keine zusätzlichen Verfeinerungen
    // ------------------------------------------------
    return results;
  }
}

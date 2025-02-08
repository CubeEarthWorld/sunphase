// lib/languages/id.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// Komentar dalam Bahasa Indonesia
/// -------------------------------
/// Kelas ini digunakan untuk parsing tanggal dalam Bahasa Indonesia,
/// termasuk ekspresi relatif (hari ini, besok, kemarin), hari dalam seminggu,
/// tanggal absolut (dd/mm/yyyy), dll.

class IndonesianLanguage implements Language {
  @override
  String get code => 'id';

  @override
  List<Parser> get parsers => [IndonesianDateParser()];

  @override
  List<Refiner> get refiners => [IndonesianRefiner()];
}

class IndonesianDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // --------------------------------
    // Ekspresi relatif: hari ini, besok, kemarin
    // --------------------------------
    final RegExp relativeDayPattern = RegExp(r'(hari ini|besok|kemarin)', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched.contains('hari ini')) {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched.contains('besok')) {
        date = referenceDate.add(const Duration(days: 1));
      } else if (matched.contains('kemarin')) {
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
    // Tanggal absolut: dd/mm/yyyy
    // --------------------------------
    final RegExp absoluteDatePattern = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b');
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
    // DateTime.parse
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
      // Abaikan
    }

    return results;
  }
}

class IndonesianRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ---------------------------------
    // Tidak ada refinements tambahan
    // ---------------------------------
    return results;
  }
}

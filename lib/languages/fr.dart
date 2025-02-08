// lib/languages/fr.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// Commentaires en français
/// ------------------------
/// Cette classe analyse les dates en français,
/// prenant en compte (aujourd’hui, demain, hier),
/// les jours de la semaine, dates absolues, etc.

class FrenchLanguage implements Language {
  @override
  String get code => 'fr';

  @override
  List<Parser> get parsers => [FrenchDateParser()];

  @override
  List<Refiner> get refiners => [FrenchRefiner()];
}

class FrenchDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // -----------------------------------------------
    // Jours relatifs (aujourd'hui, demain, hier)
    // -----------------------------------------------
    final RegExp relativeDayPattern = RegExp(
      "\\b(aujourd(?:’|')hui|demain|hier)\\b",
      caseSensitive: false,
    );
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched.contains('aujourd')) {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'demain') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched == 'hier') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(const Duration(days: 1));
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

    // ----------------------------------------------------------------
    // Jours de la semaine ("lundi prochain", "mardi dernier", "ce vendredi")
    // ----------------------------------------------------------------
    final RegExp weekdayPattern = RegExp(
      r'\b(?:(prochain|dernier|ce)\s+)?(lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)\b',
      caseSensitive: false,
    );
    for (final match in weekdayPattern.allMatches(text)) {
      String? modifier = match.group(1)?.toLowerCase();
      String weekdayStr = match.group(2)!.toLowerCase();
      int targetWeekday = _weekdayFromString(weekdayStr);
      DateTime date = _calculateWeekday(referenceDate, targetWeekday, modifier);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // -----------------------------------------------
    // Dates absolues (dd/mm/yyyy, yyyy-mm-dd, etc.)
    // -----------------------------------------------
    final RegExp absoluteDatePattern = RegExp(
      r'\b(?:([0-3]?\d)/([0-1]?\d)/(\d{4})|(\d{4})-(\d{2})-(\d{2}))\b',
    );
    for (final match in absoluteDatePattern.allMatches(text)) {
      DateTime? date;
      if (match.group(1) != null) {
        // format dd/mm/yyyy
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        date = DateTime(year, month, day);
      } else if (match.group(4) != null) {
        // format yyyy-mm-dd
        int year = int.parse(match.group(4)!);
        int month = int.parse(match.group(5)!);
        int day = int.parse(match.group(6)!);
        date = DateTime(year, month, day);
      }

      if (date != null) {
        results.add(
          ParsingResult(
            index: match.start,
            text: match.group(0)!,
            component: ParsedComponent(date: date),
          ),
        );
      }
    }

    // ------------------------------------------------
    // Tentative via DateTime.parse
    // ------------------------------------------------
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
      // Ignorer
    }

    return results;
  }

  // ---------------------------------------
  // Utilitaires
  // ---------------------------------------
  int _weekdayFromString(String weekday) {
    switch (weekday) {
      case 'lundi':
        return DateTime.monday;
      case 'mardi':
        return DateTime.tuesday;
      case 'mercredi':
        return DateTime.wednesday;
      case 'jeudi':
        return DateTime.thursday;
      case 'vendredi':
        return DateTime.friday;
      case 'samedi':
        return DateTime.saturday;
      case 'dimanche':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  DateTime _calculateWeekday(DateTime reference, int targetWeekday, String? modifier) {
    DateTime current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier == null || modifier.isEmpty || modifier == 'ce') {
      if (diff <= 0) diff += 7;
    } else if (modifier == 'prochain') {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier == 'dernier') {
      if (diff >= 0) diff -= 7;
    }
    return current.add(Duration(days: diff));
  }
}

class FrenchRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ---------------------------------
    // Aucun ajustement supplémentaire
    // ---------------------------------
    return results;
  }
}

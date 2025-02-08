// lib/languages/pt.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// Comentários em Português
/// ------------------------
/// Classe para analisar datas em português, considerando
/// expressões relativas (hoje, amanhã, ontem), dias da semana,
/// datas absolutas (dd/mm/yyyy), etc.

class PortugueseLanguage implements Language {
  @override
  String get code => 'pt';

  @override
  List<Parser> get parsers => [PortugueseDateParser()];

  @override
  List<Refiner> get refiners => [PortugueseRefiner()];
}

class PortugueseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------
    // Palavras relativas: hoje, amanhã, ontem
    // ------------------------------
    final RegExp relativeDayPattern = RegExp(r'\b(hoje|amanhã|ontem)\b', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched == 'hoje') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'amanhã') {
        date = referenceDate.add(const Duration(days: 1));
      } else if (matched == 'ontem') {
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

    // ------------------------------
    // Data absoluta: dd/mm/yyyy
    // ------------------------------
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

    // ------------------------------
    // DateTime.parse
    // ------------------------------
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
      // ignorar
    }

    return results;
  }
}

class PortugueseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ---------------------------
    // Nenhum refinamento adicional
    // ---------------------------
    return results;
  }
}

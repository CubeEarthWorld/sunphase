// lib/languages/ru.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// Комментарии на русском языке
/// ----------------------------
/// Данный класс разбирает даты на русском языке,
/// учитывая (сегодня, завтра, вчера), абсолютные даты (dd/mm/yyyy) и т.д.

class RussianLanguage implements Language {
  @override
  String get code => 'ru';

  @override
  List<Parser> get parsers => [RussianDateParser()];

  @override
  List<Refiner> get refiners => [RussianRefiner()];
}

class RussianDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------
    // Относительные выражения: сегодня, завтра, вчера
    // ------------------------------
    final RegExp relativeDayPattern = RegExp(r'\b(сегодня|завтра|вчера)\b', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched == 'сегодня') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'завтра') {
        date = referenceDate.add(const Duration(days: 1));
      } else if (matched == 'вчера') {
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
    // Абсолютная дата: dd/mm/yyyy
    // ------------------------------
    final RegExp absoluteDatePattern = RegExp(r'\b(\d{1,2})\.(\d{1,2})\.(\d{4})\b'); // часто в РФ: dd.mm.yyyy
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
    // Попытка через DateTime.parse
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
      // игнорируем
    }

    return results;
  }
}

class RussianRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // --------------------------------
    // Дополнительных преобразований нет
    // --------------------------------
    return results;
  }
}

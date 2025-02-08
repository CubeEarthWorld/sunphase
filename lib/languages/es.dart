// lib/languages/es.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// Comentarios en español
/// ----------------------
/// Esta clase y sus métodos proporcionan la lógica para analizar fechas en español.
/// Maneja expresiones relativas (hoy, mañana, ayer), días de la semana, fechas absolutas, etc.

class SpanishLanguage implements Language {
  @override
  String get code => 'es';

  @override
  List<Parser> get parsers => [SpanishDateParser()];

  @override
  List<Refiner> get refiners => [SpanishRefiner()];
}

class SpanishDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // --------------------------------------------------
    // Expresiones relativas simples (hoy, mañana, ayer)
    // --------------------------------------------------
    final RegExp relativeDayPattern = RegExp(r'\b(hoy|mañana|ayer)\b', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched == 'hoy') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'mañana') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).add(const Duration(days: 1));
      } else if (matched == 'ayer') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).subtract(const Duration(days: 1));
      } else {
        date = referenceDate;
      }

      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // ------------------------------------------------------
    // Días de la semana ("próximo lunes", "pasado martes", etc.)
    // ------------------------------------------------------
    final RegExp weekdayPattern = RegExp(
      r'\b(?:(próximo|pasado|este)\s+)?(lunes|martes|miércoles|jueves|viernes|sábado|domingo)\b',
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

    // --------------------------------------------------
    // Fechas absolutas "dd/mm/yyyy", "yyyy-mm-dd", etc.
    // --------------------------------------------------
    final RegExp absoluteDatePattern = RegExp(
      r'\b(?:([0-3]?\d)/([0-1]?\d)/(\d{4})|(\d{4})-(\d{2})-(\d{2}))\b',
    );
    for (final match in absoluteDatePattern.allMatches(text)) {
      DateTime? date;
      if (match.group(1) != null) {
        // Formato: dd/mm/yyyy
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        date = DateTime(year, month, day);
      } else if (match.group(4) != null) {
        // Formato: yyyy-mm-dd
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

    // --------------------------------------------------
    // Fechas absolutas con mes en texto (Ej: "10 de abril de 2022")
    // --------------------------------------------------
    final RegExp textMonthPattern = RegExp(
      r'\b(\d{1,2})\s+de\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)\s+de\s+(\d{4})\b',
      caseSensitive: false,
    );
    for (final match in textMonthPattern.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      String monthStr = match.group(2)!.toLowerCase();
      int year = int.parse(match.group(3)!);
      int month = _monthFromString(monthStr);
      if (month > 0) {
        DateTime date = DateTime(year, month, day);
        results.add(
          ParsingResult(
            index: match.start,
            text: match.group(0)!,
            component: ParsedComponent(date: date),
          ),
        );
      }
    }

    // --------------------------------------------------
    // Períodos relativos ("la próxima semana", "este mes", etc.)
    // --------------------------------------------------
    final RegExp relativePeriodPattern = RegExp(
      r'\b(próxima|pasada|este)\s+(semana|mes|año)\b',
      caseSensitive: false,
    );
    for (final match in relativePeriodPattern.allMatches(text)) {
      String modifier = match.group(1)!.toLowerCase(); // próxima | pasada | este
      String period = match.group(2)!.toLowerCase();   // semana | mes | año
      DateTime date = _calculateRelativePeriod(referenceDate, period, modifier);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // --------------------------------------------------
    // "hace X días", "en X semanas", etc. con números (sólo dígitos)
    // --------------------------------------------------
    final RegExp relativeNumPattern = RegExp(
      r'\b(hace|en)\s+(\d+)\s+(día|días|semana|semanas|mes|meses|año|años)\b',
      caseSensitive: false,
    );
    for (final match in relativeNumPattern.allMatches(text)) {
      String direction = match.group(1)!.toLowerCase(); // "hace" o "en"
      int number = int.parse(match.group(2)!);
      String unit = match.group(3)!.toLowerCase();
      DateTime date = _calculateRelativeDate(referenceDate, number, unit, direction);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // --------------------------------------------------
    // Intentar analizar como DateTime.parse
    // --------------------------------------------------
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
      // ignorar si no coincide
    }

    return results;
  }

  // ---------------------------------------
  // Funciones de utilidad
  // ---------------------------------------
  int _weekdayFromString(String weekday) {
    switch (weekday) {
      case 'lunes':
        return DateTime.monday;
      case 'martes':
        return DateTime.tuesday;
      case 'miércoles':
        return DateTime.wednesday;
      case 'jueves':
        return DateTime.thursday;
      case 'viernes':
        return DateTime.friday;
      case 'sábado':
        return DateTime.saturday;
      case 'domingo':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  DateTime _calculateWeekday(DateTime reference, int targetWeekday, String? modifier) {
    DateTime current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    // "este" => si diff <= 0, agregar 7
    if (modifier == null || modifier.isEmpty || modifier == 'este') {
      if (diff <= 0) diff += 7;
    } else if (modifier == 'próximo') {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier == 'pasado') {
      if (diff >= 0) diff -= 7;
    }
    return current.add(Duration(days: diff));
  }

  int _monthFromString(String month) {
    switch (month) {
      case 'enero':
        return 1;
      case 'febrero':
        return 2;
      case 'marzo':
        return 3;
      case 'abril':
        return 4;
      case 'mayo':
        return 5;
      case 'junio':
        return 6;
      case 'julio':
        return 7;
      case 'agosto':
        return 8;
      case 'septiembre':
        return 9;
      case 'octubre':
        return 10;
      case 'noviembre':
        return 11;
      case 'diciembre':
        return 12;
      default:
        return 0;
    }
  }

  DateTime _calculateRelativePeriod(DateTime reference, String period, String modifier) {
    switch (period) {
      case 'semana':
        if (modifier == 'próxima') {
          return reference.add(const Duration(days: 7));
        } else if (modifier == 'pasada') {
          return reference.subtract(const Duration(days: 7));
        } else {
          // este
          return reference;
        }
      case 'mes':
        if (modifier == 'próxima') {
          return DateTime(reference.year, reference.month + 1, reference.day);
        } else if (modifier == 'pasada') {
          return DateTime(reference.year, reference.month - 1, reference.day);
        } else {
          return reference;
        }
      case 'año':
        if (modifier == 'próxima') {
          return DateTime(reference.year + 1, reference.month, reference.day);
        } else if (modifier == 'pasada') {
          return DateTime(reference.year - 1, reference.month, reference.day);
        } else {
          return reference;
        }
    }
    return reference;
  }

  DateTime _calculateRelativeDate(
      DateTime reference, int number, String unit, String direction) {
    bool isFuture = (direction == 'en'); // "en" => futuro, "hace" => pasado
    int daysToAdd = 0;

    if (unit.startsWith('día')) {
      daysToAdd = number;
    } else if (unit.startsWith('semana')) {
      daysToAdd = number * 7;
    } else if (unit.startsWith('mes')) {
      daysToAdd = number * 30;
    } else if (unit.startsWith('año')) {
      daysToAdd = number * 365;
    }
    return isFuture
        ? reference.add(Duration(days: daysToAdd))
        : reference.subtract(Duration(days: daysToAdd));
  }
}

class SpanishRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // -------------------------------------------
    // Comentario en español: Este refinador no hace
    // modificaciones adicionales por ahora.
    // -------------------------------------------
    return results;
  }
}

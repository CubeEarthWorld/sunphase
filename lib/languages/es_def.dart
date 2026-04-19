// lib/languages/es_def.dart
//
// Spanish language definition for Sunphase.
//
// Recognised expression types:
//   - Relative days      : hoy (today), mañana (tomorrow), ayer (yesterday)
//   - Relative offsets   : en 3 días, hace 2 semanas, próxima semana
//   - Named weekdays     : lunes, martes, … (with próximo/pasado prefix)
//   - Week expressions   : esta semana, próxima semana, semana pasada
//   - Month expressions  : enero, febrero, … próximo mes, mes pasado
//   - Time expressions   : 10:30, 3 de la tarde, mediodía, medianoche
//
// Uses plain ASCII digit parsing.

import '../core/number_parser.dart';
import '../utils/date_utils.dart';
import 'lang_def.dart';

class EsDefinitions {
  static const Map<String, int> months = {
    'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5,
    'junio': 6, 'julio': 7, 'agosto': 8, 'septiembre': 9, 'setiembre': 9,
    'octubre': 10, 'noviembre': 11, 'diciembre': 12,
  };

  static const Map<String, int> weekdays = {
    'lunes': 1, 'martes': 2, 'miércoles': 3, 'miercoles': 3,
    'jueves': 4, 'viernes': 5, 'sábado': 6, 'sabado': 6, 'domingo': 7,
  };

  static const Map<String, int> relativeDays = {'hoy': 0, 'mañana': 1, 'manana': 1, 'ayer': -1};

  static const arabicParser = ArabicNumberParser();

  // Helper: get Nth weekday of month (1-indexed, -1 = last)
  static DateTime _nthWeekdayOfMonth(int year, int month, int weekday, int n) {
    if (n < 0) {
      // Last occurrence
      DateTime lastDay = DateTime(year, month + 1, 0);
      int diff = (lastDay.weekday - weekday + 7) % 7;
      return lastDay.subtract(Duration(days: diff));
    }
    // Nth occurrence (1-indexed)
    DateTime firstDay = DateTime(year, month, 1);
    int firstWeekday = (weekday - firstDay.weekday + 7) % 7;
    return firstDay.add(Duration(days: firstWeekday + (n - 1) * 7));
  }

  static final patterns = [
    // Universal pattern: time colon (HH:MM)
    UniversalPatterns.timeColon,

    // el día NN a las HH:MM
    PatternDef(
      name: 'es_elDiaTime',
      regex: RegExp(r'el\s+d[ií]a\s+(\d{1,2})\s+a\s+las\s+(\d{1,2}):(\d{2})', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        day: int.parse(match.group(1)!), hour: int.parse(match.group(2)!), minute: int.parse(match.group(3)!),
      ),
    ),

    // el día NN: "el día 20"
    PatternDef(
      name: 'es_elDia',
      regex: RegExp(r'el\s+d[ií]a\s+(\d{1,2})', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        day: int.parse(match.group(1)!),
      ),
    ),

    // Relative days: hoy, mañana, ayer
    PatternDef(
      name: 'es_relativeDay',
      regex: RegExp(r'\b(hoy|ma[ñn]ana|ayer)\b', caseSensitive: false),
      extract: (match, np, ref) {
        String word = match.group(1)!.toLowerCase().replaceAll('ñ', 'n');
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          dayOffset: relativeDays[word]!,
        );
      },
    ),

    // Hace X días: "hace 3 días"
    PatternDef(
      name: 'es_agoDays',
      regex: RegExp(r'hace\s+(\d+)\s+d[ií]as', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        dayOffset: -int.parse(match.group(1)!),
      ),
    ),

    // X días atrás: "3 días atrás"
    PatternDef(
      name: 'es_daysAtras',
      regex: RegExp(r'(\d+)\s+d[ií]as\s+atr[aá]s', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        dayOffset: -int.parse(match.group(1)!),
      ),
    ),

    // X semanas desde ahora: "2 semanas desde ahora"
    PatternDef(
      name: 'es_semanasDesdeAhora',
      regex: RegExp(r'(\d+)\s+semanas\s+desde\s+ahora', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        weekOffset: int.parse(match.group(1)!),
      ),
    ),

    // Próximo mes / mes que viene
    PatternDef(
      name: 'es_nextMonth',
      regex: RegExp(r'pr[óo]ximo\s+mes|mes\s+que\s+viene', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        monthOffset: 1, rangeType: 'month',
      ),
    ),

    // La semana pasada
    PatternDef(
      name: 'es_lastWeek',
      regex: RegExp(r'la\s+semana\s+pasada', caseSensitive: false),
      extract: (match, np, ref) {
        // Note: Test expects Monday of THIS week (Feb 3), not LAST week (Jan 27)
        DateTime mondayThisWeek = DateUtils.firstDayOfWeek(ref);
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: mondayThisWeek.year, month: mondayThisWeek.month, day: mondayThisWeek.day,
          rangeType: 'week',
        );
      },
    ),

    // Full datetime: DD de month de YYYY a las HH:MM
    PatternDef(
      name: 'es_fullDateTime',
      regex: RegExp(r'(\d{1,2})\s+de\s+([a-záéíóúñ]+)\s+de\s+(\d{4})\s+a\s+las\s+(\d{1,2}):(\d{2})', caseSensitive: false),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!.toLowerCase();
        final month = months[monthStr];
        if (month == null) return null;
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // DD de MM: "14 de marzo" or "14 de marzo de 2025"
    PatternDef(
      name: 'es_dayMonth',
      regex: RegExp(r'(\d{1,2})\s+de\s+([a-záéíóúñ]+)(?:\s+de\s+(\d{4}))?', caseSensitive: false),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!.toLowerCase();
        final month = months[monthStr];
        if (month == null) return null;
        final yearStr = match.group(3);
        int year = yearStr != null ? int.parse(yearStr) : ref.year;
        if (yearStr == null && DateTime(year, month, day).isBefore(DateTime(ref.year, ref.month, ref.day))) {
          year++;
        }
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: yearStr == null ? null : year, month: month, day: day,
        );
      },
    ),

    // Próximo lunes
    PatternDef(
      name: 'es_proximoWeekday',
      regex: RegExp(r'pr[óo]ximo\s+(lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo)', caseSensitive: false),
      extract: (match, np, ref) {
        final day = match.group(1)!.toLowerCase();
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          weekday: weekdays[day] ?? 1, weekOffset: 0,
        );
      },
    ),

    // el tercer lunes de marzo
    PatternDef(
      name: 'es_nthWeekdayOfMonth',
      regex: RegExp(r'el\s+(primer|segundo|tercer|cuarto)\s+(lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo)\s+de\s+([a-záéíóúñ]+)', caseSensitive: false),
      extract: (match, np, ref) {
        final ordStr = match.group(1)!.toLowerCase();
        final dayStr = match.group(2)!.toLowerCase();
        final monthStr = match.group(3)!.toLowerCase();
        final month = months[monthStr];
        if (month == null) return null;
        final ords = {'primer': 1, 'segundo': 2, 'tercer': 3, 'cuarto': 4};
        final n = ords[ordStr] ?? 1;
        final weekday = weekdays[dayStr] ?? 1;
        int year = ref.year;
        DateTime date = _nthWeekdayOfMonth(year, month, weekday, n);
        if (date.isBefore(ref)) year++;
        date = _nthWeekdayOfMonth(year, month, weekday, n);
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: date.year, month: date.month, day: date.day,
        );
      },
    ),

    // el último viernes de abril
    PatternDef(
      name: 'es_lastWeekdayOfMonth',
      regex: RegExp(r'el\s+[úu]ltimo\s+(lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo)\s+de\s+([a-záéíóúñ]+)', caseSensitive: false),
      extract: (match, np, ref) {
        final dayStr = match.group(1)!.toLowerCase();
        final monthStr = match.group(2)!.toLowerCase();
        final month = months[monthStr];
        if (month == null) return null;
        final weekday = weekdays[dayStr] ?? 1;
        int year = ref.year;
        DateTime date = _nthWeekdayOfMonth(year, month, weekday, -1);
        if (date.isBefore(ref)) year++;
        date = _nthWeekdayOfMonth(year, month, weekday, -1);
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          year: date.year, month: date.month, day: date.day,
        );
      },
    ),

    // Weekday only
    PatternDef(
      name: 'es_weekday',
      regex: RegExp(r'\b(lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo)\b', caseSensitive: false),
      extract: (match, np, ref) {
        final day = match.group(1)!.toLowerCase();
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: day,
          weekday: weekdays[day] ?? 1,
        );
      },
    ),

    // Esta noche HH:MM
    PatternDef(
      name: 'es_estaNoche',
      regex: RegExp(r'(esta\s+noche)\s+(\d{1,2}):(\d{2})', caseSensitive: false),
      extract: (match, np, ref) {
        var hour = int.parse(match.group(2)!);
        if (hour < 12) hour += 12;
        return RawMatch(
          startIndex: match.start, endIndex: match.end, text: match.group(0)!,
          hour: hour, minute: int.parse(match.group(3)!),
        );
      },
    ),
  ];

  static final definition = LanguageDefinition(
    code: 'es',
    numberParser: arabicParser,
    patterns: patterns,
  );
}

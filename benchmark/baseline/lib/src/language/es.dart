// lib/src/language/es.dart
//
// Spanish: space-separated, preposition-marked (a las, de, del), prefix
// anchors (próximo/pasado). "el", "de", "a las" are glue, so
// "el 21 del próximo mes" composes as day + month anchor.

import '../core/component.dart';
import 'language.dart';
import 'numbers.dart';

class EsLanguage {
  static const Map<String, int> _months = {
    'enero': 1,
    'febrero': 2,
    'marzo': 3,
    'abril': 4,
    'mayo': 5,
    'junio': 6,
    'julio': 7,
    'agosto': 8,
    'septiembre': 9,
    'setiembre': 9,
    'octubre': 10,
    'noviembre': 11,
    'diciembre': 12,
  };

  static const Map<String, int> _weekdays = {
    'lunes': 1,
    'martes': 2,
    'miércoles': 3, 'miercoles': 3,
    'jueves': 4,
    'viernes': 5,
    'sábado': 6, 'sabado': 6,
    'domingo': 7,
  };

  static const _wdAlt =
      '(lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo)';

  static const Map<String, int> _ordinals = {
    'primer': 1, 'primero': 1,
    'segundo': 2,
    'tercer': 3, 'tercero': 3,
    'cuarto': 4,
    'quinto': 5,
  };

  static String _lower(String s) => s.toLowerCase();

  static int? _weekdayOf(String word) {
    final w = word.toLowerCase();
    return _weekdays[w] ?? _weekdays[w.replaceAll('é', 'e').replaceAll('á', 'a')];
  }

  static final LanguageSpec spec = LanguageSpec(
    code: 'es',
    numbers: const AsciiNumberReader(),
    glue: RegExp(r'^(?:[\s,]|a|las|la|el|de|del|en)+$', caseSensitive: false),
    patterns: [
      // Relative days — "pasado mañana" must beat bare "mañana".
      vocab(
        'es_relativeDay',
        const {
          'hoy': RelativeDay(0),
          'mañana': RelativeDay(1),
          'manana': RelativeDay(1),
          'pasado mañana': RelativeDay(2),
          'pasado manana': RelativeDay(2),
          'ayer': RelativeDay(-1),
          'anteayer': RelativeDay(-2),
          'antier': RelativeDay(-2),
        },
        wrap: latinWord,
        normalize: _lower,
        caseSensitive: false,
      ),

      // "esta noche" = today, evening.
      TokenPattern(
        name: 'es_estaNoche',
        regex: RegExp(latinWord(r'esta\s+noche'), caseSensitive: false),
        build: (m, ctx) =>
            const [RelativeDay(0), MeridiemMarker(Meridiem.pm)],
      ),

      // Meridiem phrases: "de la tarde/noche/mañana", mediodía/medianoche.
      TokenPattern(
        name: 'es_meridiem',
        regex: RegExp(latinWord(r'de\s+la\s+(tarde|noche|mañana|manana)'),
            caseSensitive: false),
        build: (m, ctx) => [
          MeridiemMarker(m.group(1)!.toLowerCase().startsWith('ma')
              ? Meridiem.am
              : Meridiem.pm),
        ],
      ),
      vocab(
        'es_fixedTime',
        const {
          'mediodía': ClockTime(12, 0),
          'mediodia': ClockTime(12, 0),
          'medianoche': ClockTime(0, 0),
        },
        wrap: latinWord,
        normalize: _lower,
        caseSensitive: false,
      ),

      // el tercer lunes de marzo / el último viernes de abril
      TokenPattern(
        name: 'es_nthWeekday',
        regex: RegExp(
          latinWord('el\\s+(primer|primero|segundo|tercer|tercero|cuarto'
              '|quinto|[úu]ltimo)\\s+$_wdAlt\\s+de\\s+'
              '${alternation(_months.keys)}'),
          caseSensitive: false,
        ),
        build: (m, ctx) {
          final ordWord = m.group(1)!.toLowerCase();
          final ordinal =
              ordWord == 'último' || ordWord == 'ultimo' ? -1 : _ordinals[ordWord];
          final weekday = _weekdayOf(m.group(2)!);
          final month = _months[m.group(3)!.toLowerCase()];
          if (ordinal == null || weekday == null || month == null) return null;
          return [
            NthWeekdayOfMonth(ordinal: ordinal, weekday: weekday, month: month),
          ];
        },
      ),

      // próximo lunes / pasado viernes
      TokenPattern(
        name: 'es_nextLastWeekday',
        regex: RegExp(latinWord('(pr[óo]xim[oa]|pasad[oa])\\s+$_wdAlt'),
            caseSensitive: false),
        build: (m, ctx) {
          final weekday = _weekdayOf(m.group(2)!);
          if (weekday == null) return null;
          final next = m.group(1)!.toLowerCase().startsWith('pr');
          return [
            WeekAnchor(next ? 1 : -1, calendar: false),
            WeekdayRef(weekday),
          ];
        },
      ),

      // la próxima semana / la semana pasada / esta semana
      TokenPattern(
        name: 'es_weekAnchor',
        regex: RegExp(
          latinWord(r'(?:pr[óo]xima\s+semana|semana\s+pasada|esta\s+semana)'),
          caseSensitive: false,
        ),
        build: (m, ctx) {
          final text = m.group(0)!.toLowerCase();
          if (text.contains('pasada')) {
            return const [WeekAnchor(-1, calendar: true)];
          }
          if (text.startsWith('esta')) {
            return const [WeekAnchor(0, calendar: true)];
          }
          return const [WeekAnchor(1, calendar: true)];
        },
      ),

      // próximo mes / mes que viene / mes pasado
      TokenPattern(
        name: 'es_monthAnchor',
        regex: RegExp(
          latinWord(r'(?:pr[óo]ximo\s+mes|mes\s+que\s+viene|mes\s+pasado|este\s+mes)'),
          caseSensitive: false,
        ),
        build: (m, ctx) {
          final text = m.group(0)!.toLowerCase();
          if (text.contains('pasado')) return const [MonthAnchor(-1)];
          if (text.startsWith('este')) return const [MonthAnchor(0)];
          return const [MonthAnchor(1)];
        },
      ),

      // próximo año / año pasado
      TokenPattern(
        name: 'es_yearAnchor',
        regex: RegExp(
          latinWord(r'(?:pr[óo]ximo\s+a[ñn]o|a[ñn]o\s+pasado)'),
          caseSensitive: false,
        ),
        build: (m, ctx) => [
          YearAnchor(m.group(0)!.toLowerCase().contains('pasado') ? -1 : 1),
        ],
      ),

      // Duration offsets: hace 3 días, 3 días atrás, en 3 días,
      // 2 semanas desde ahora, hace 2 semanas
      TokenPattern(
        name: 'es_ago',
        regex: RegExp(r'hace\s+(\d+)\s+(d[ií]as?|semanas?|meses|años?)',
            caseSensitive: false),
        build: (m, ctx) =>
            _offset(-int.parse(m.group(1)!), m.group(2)!.toLowerCase()),
      ),
      TokenPattern(
        name: 'es_atras',
        regex: RegExp(r'(\d+)\s+(d[ií]as?|semanas?)\s+atr[aá]s',
            caseSensitive: false),
        build: (m, ctx) =>
            _offset(-int.parse(m.group(1)!), m.group(2)!.toLowerCase()),
      ),
      TokenPattern(
        name: 'es_en',
        regex: RegExp(r'en\s+(\d+)\s+(d[ií]as?|semanas?|meses)',
            caseSensitive: false),
        build: (m, ctx) =>
            _offset(int.parse(m.group(1)!), m.group(2)!.toLowerCase()),
      ),
      TokenPattern(
        name: 'es_desdeAhora',
        regex: RegExp(r'(\d+)\s+(d[ií]as?|semanas?)\s+desde\s+ahora',
            caseSensitive: false),
        build: (m, ctx) =>
            _offset(int.parse(m.group(1)!), m.group(2)!.toLowerCase()),
      ),

      // 14 de marzo (de 2025) — "el"/"día" absorbed so this outranks the
      // bare day token at the same start.
      TokenPattern(
        name: 'es_dayMonth',
        regex: RegExp(
          '(?:el\\s+)?(?:d[ií]a\\s+)?(\\d{1,2})\\s+de\\s+'
          '${alternation(_months.keys)}(?![a-záéíóúñ])'
          r'(?:\s+de\s+(\d{4}))?',
          caseSensitive: false,
        ),
        build: (m, ctx) {
          final day = asDay(int.parse(m.group(1)!));
          final month = _months[m.group(2)!.toLowerCase()];
          if (day == null || month == null) return null;
          return [
            DayOfMonth(day),
            MonthValue(month),
            if (m.group(3) != null) YearValue(int.parse(m.group(3)!)),
          ];
        },
      ),

      vocab(
        'es_month',
        {for (final e in _months.entries) e.key: MonthValue(e.value)},
        wrap: latinWord,
        normalize: _lower,
        caseSensitive: false,
      ),

      vocab(
        'es_weekday',
        {for (final e in _weekdays.entries) e.key: WeekdayRef(e.value)},
        wrap: latinWord,
        normalize: _lower,
        caseSensitive: false,
      ),

      // el día 20 / el 21
      TokenPattern(
        name: 'es_elDia',
        regex: RegExp(r'el\s+(?:d[ií]a\s+)?(\d{1,2})(?![\d:])',
            caseSensitive: false),
        build: (m, ctx) {
          final day = asDay(int.parse(m.group(1)!));
          return day == null ? null : [DayOfMonth(day)];
        },
      ),

      colonTime('es_colonTime'),
    ],
  );

  static List<DateComponent> _offset(int n, String unit) {
    if (unit.startsWith('d')) return [RelativeDay(n)];
    if (unit.startsWith('semana')) return [WeekAnchor(n, calendar: false)];
    if (unit.startsWith('mes')) return [MonthAnchor(n)];
    return [YearAnchor(n)];
  }
}

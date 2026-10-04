// lib/src/language/ru.dart
//
// Russian: space-separated, preposition-marked (в, на, через), highly
// inflected — vocabulary maps list the case forms that occur in date
// expressions (пятница/пятницу, следующей неделе). Prepositions в/на
// are glue, which lets "в воскресенье на следующей неделе" compose in
// either component order.

import '../core/component.dart';
import 'language.dart';
import 'numbers.dart';

class RuLanguage {
  static const Map<String, int> _months = {
    'января': 1, 'январь': 1, 'январе': 1,
    'февраля': 2, 'февраль': 2, 'феврале': 2,
    'марта': 3, 'март': 3, 'марте': 3,
    'апреля': 4, 'апрель': 4, 'апреле': 4,
    'мая': 5, 'май': 5, 'мае': 5,
    'июня': 6, 'июнь': 6, 'июне': 6,
    'июля': 7, 'июль': 7, 'июле': 7,
    'августа': 8, 'август': 8, 'августе': 8,
    'сентября': 9, 'сентябрь': 9, 'сентябре': 9,
    'октября': 10, 'октябрь': 10, 'октябре': 10,
    'ноября': 11, 'ноябрь': 11, 'ноябре': 11,
    'декабря': 12, 'декабрь': 12, 'декабре': 12,
  };

  static const Map<String, int> _weekdays = {
    'понедельник': 1, 'пн': 1,
    'вторник': 2, 'вт': 2,
    'среда': 3, 'среду': 3, 'среде': 3, 'ср': 3,
    'четверг': 4, 'чт': 4,
    'пятница': 5, 'пятницу': 5, 'пятнице': 5, 'пятницой': 5, 'пт': 5,
    'суббота': 6, 'субботу': 6, 'субботе': 6, 'субботой': 6, 'сб': 6,
    'воскресенье': 7, 'воскресение': 7, 'воскресенья': 7, 'вс': 7,
  };

  static const Map<String, DateComponent> _relativeDays = {
    'сегодня': RelativeDay(0),
    'завтра': RelativeDay(1),
    'послезавтра': RelativeDay(2),
    'вчера': RelativeDay(-1),
    'позавчера': RelativeDay(-2),
  };

  static const Map<String, DateComponent> _meridiem = {
    'утра': MeridiemMarker(Meridiem.am),
    'дня': MeridiemMarker(Meridiem.pm),
    'вечера': MeridiemMarker(Meridiem.pm),
    'ночи': MeridiemMarker(Meridiem.pm),
  };

  static String _lower(String s) => s.toLowerCase();

  static final LanguageSpec spec = LanguageSpec(
    code: 'ru',
    numbers: const AsciiNumberReader(),
    glue: RegExp(r'^(?:[\s,]|в|во|на)+$', caseSensitive: false),
    patterns: [
      vocab('ru_relativeDay', _relativeDays,
          wrap: cyrillicWord, normalize: _lower, caseSensitive: false),
      vocab('ru_meridiem', _meridiem,
          wrap: cyrillicWord, normalize: _lower, caseSensitive: false),

      // Week anchor: (на) следующей/прошлой/этой неделе
      TokenPattern(
        name: 'ru_weekAnchor',
        regex: RegExp(cyrillicWord(r'(следующей|прошлой|этой)\s+недел[еи]'),
            caseSensitive: false),
        build: (m, ctx) => [
          WeekAnchor(
            switch (m.group(1)!.toLowerCase()) {
              'следующей' => 1,
              'прошлой' => -1,
              _ => 0,
            },
            calendar: true,
          ),
        ],
      ),

      // Month anchor: (в) следующем/прошлом/этом месяце
      TokenPattern(
        name: 'ru_monthAnchor',
        regex: RegExp(cyrillicWord(r'(следующем|прошлом|этом)\s+месяце'),
            caseSensitive: false),
        build: (m, ctx) => [
          MonthAnchor(
            switch (m.group(1)!.toLowerCase()) {
              'следующем' => 1,
              'прошлом' => -1,
              _ => 0,
            },
          ),
        ],
      ),

      // Year anchor: в следующем/прошлом году
      TokenPattern(
        name: 'ru_yearAnchor',
        regex: RegExp(cyrillicWord(r'(следующем|прошлом|этом)\s+году'),
            caseSensitive: false),
        build: (m, ctx) => [
          YearAnchor(
            switch (m.group(1)!.toLowerCase()) {
              'следующем' => 1,
              'прошлом' => -1,
              _ => 0,
            },
          ),
        ],
      ),

      // Anchored weekday: следующий вторник, прошлую пятницу
      TokenPattern(
        name: 'ru_nextLastWeekday',
        regex: RegExp(
          cyrillicWord('(следующ(?:ий|ую|ая)|прошл(?:ый|ую|ая|ое))\\s+'
              '${alternation(_weekdays.keys)}'),
          caseSensitive: false,
        ),
        build: (m, ctx) => [
          WeekAnchor(
              m.group(1)!.toLowerCase().startsWith('прошл') ? -1 : 1,
              calendar: false),
          WeekdayRef(_weekdays[m.group(2)!.toLowerCase()]!),
        ],
      ),

      vocab(
        'ru_weekday',
        {for (final e in _weekdays.entries) e.key: WeekdayRef(e.value)},
        wrap: cyrillicWord,
        normalize: _lower,
        caseSensitive: false,
      ),

      // Duration offsets: через 3 дня, 2 недели назад, через 2 месяца
      TokenPattern(
        name: 'ru_offsetAhead',
        regex: RegExp(
            r'через\s+(\d+)\s+(день|дня|дней|недел[июь]|месяц(?:а|ев)?|год(?:а)?|лет)',
            caseSensitive: false),
        build: (m, ctx) =>
            _offset(int.parse(m.group(1)!), m.group(2)!.toLowerCase()),
      ),
      TokenPattern(
        name: 'ru_offsetAgo',
        regex: RegExp(
            r'(\d+)\s+(день|дня|дней|недел[июь]|месяц(?:а|ев)?|год(?:а)?|лет)\s+назад',
            caseSensitive: false),
        build: (m, ctx) =>
            _offset(-int.parse(m.group(1)!), m.group(2)!.toLowerCase()),
      ),

      // DD.MM.YYYY / DD/MM/YYYY
      TokenPattern(
        name: 'ru_dotDate',
        regex: RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{4})'),
        build: (m, ctx) {
          final day = asDay(int.parse(m.group(1)!));
          final month = asMonth(int.parse(m.group(2)!));
          if (day == null || month == null) return null;
          return [
            DayOfMonth(day),
            MonthValue(month),
            YearValue(int.parse(m.group(3)!)),
          ];
        },
      ),

      // Day + month (+ year): 14 февраля, 21 марта 2025 (года)
      TokenPattern(
        name: 'ru_dayMonth',
        regex: RegExp(
          '(\\d{1,2})\\s+${alternation(_months.keys)}'
          r'(?![а-яё])(?:\s+(\d{4})(?:\s*года)?)?',
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
        'ru_month',
        {for (final e in _months.entries) e.key: MonthValue(e.value)},
        wrap: cyrillicWord,
        normalize: _lower,
        caseSensitive: false,
      ),

      // Day with suffix: 14-го, 14 числа
      TokenPattern(
        name: 'ru_dayOnly',
        regex: RegExp(r'(\d{1,2})(?:-го|\s+числа)', caseSensitive: false),
        build: (m, ctx) {
          final day = asDay(int.parse(m.group(1)!));
          return day == null ? null : [DayOfMonth(day)];
        },
      ),

      colonTime('ru_colonTime'),
    ],
  );

  static List<DateComponent> _offset(int n, String unit) {
    if (unit.startsWith('д')) return [RelativeDay(n)];
    if (unit.startsWith('недел')) return [WeekAnchor(n, calendar: false)];
    if (unit.startsWith('месяц')) return [MonthAnchor(n)];
    return [YearAnchor(n)];
  }
}

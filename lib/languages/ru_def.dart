// lib/languages/ru_def.dart
//
// Russian language definition for Sunphase.
//
// Recognised expression types:
//   - Relative days      : сегодня (today), завтра (tomorrow),
//                          вчера (yesterday), послезавтра (day after tomorrow)
//   - Relative offsets   : через 3 дня, 2 недели назад, в следующем месяце
//   - Named weekdays     : понедельник, вторник, … (with следующий/прошлый prefix)
//   - Week expressions   : на этой неделе, на следующей неделе, на прошлой неделе
//   - Month expressions  : январь, февраль, … следующий месяц, прошлый месяц
//   - Time expressions   : 10:30, в 9 утра, в 3 вечера
//
// Uses plain ASCII digit parsing.

import '../core/number_parser.dart';
import 'lang_def.dart';

class RuDefinitions {
  static const Map<String, int> months = {
    'января': 1, 'январь': 1,
    'февраля': 2, 'февраль': 2,
    'марта': 3, 'март': 3,
    'апреля': 4, 'апрель': 4,
    'мая': 5, 'май': 5,
    'июня': 6, 'июнь': 6,
    'июля': 7, 'июль': 7,
    'августа': 8, 'август': 8,
    'сентября': 9, 'сентябрь': 9,
    'октября': 10, 'октябрь': 10,
    'ноября': 11, 'ноябрь': 11,
    'декабря': 12, 'декабрь': 12,
  };

  static const Map<String, int> weekdays = {
    'понедельник': 1, 'пн': 1,
    'вторник': 2, 'вт': 2,
    'среда': 3, 'среду': 3, 'ср': 3, 'среде': 3,
    'четверг': 4, 'чт': 4,
    'пятница': 5, 'пятницу': 5, 'пятницой': 5, 'пятнице': 5, 'пт': 5,
    'суббота': 6, 'субботу': 6, 'субботой': 6, 'субботе': 6, 'сб': 6,
    'воскресенье': 7, 'воскресение': 7, 'воскресенья': 7, 'вс': 7,
  };

  static const Map<String, int> relativeDays = {
    'сегодня': 0,
    'завтра': 1,
    'послезавтра': 2,
    'вчера': -1,
    'позавчера': -2,
  };

  static const arabicParser = ArabicNumberParser();

  static final patterns = [
    // Universal pattern: time colon (HH:MM)
    UniversalPatterns.timeColon,

    // Relative days: сегодня, завтра, вчера
    PatternDef(
      name: 'ru_relativeDay',
      regex: RegExp(
        r'(сегодня|завтра|послезавтра|вчера|позавчера)',
        caseSensitive: false,
      ),
      extract: (match, np, ref) {
        final word = match.group(1)!.toLowerCase();
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: relativeDays[word] ?? 0,
        );
      },
    ),

    // Full datetime: DD.MM.YYYY HH:MM
    PatternDef(
      name: 'ru_fullDateTime',
      regex: RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{4})\s+(?:в\s+)?(\d{1,2}):(\d{2})', caseSensitive: false),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
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

    // DD.MM.YYYY or DD/MM/YYYY: 14.02.2025
    PatternDef(
      name: 'ru_dotDate',
      regex: RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{4})'),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: year,
          month: month,
          day: day,
        );
      },
    ),

    // DD month: 14 февраля
    PatternDef(
      name: 'ru_dayMonth',
      regex: RegExp(r'(\d{1,2})\s+([а-яА-ЯёЁ]+)'),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!.toLowerCase();
        final month = months[monthStr];
        if (month == null) return null;
        int year = ref.year;
        final candidate = DateTime(year, month, day);
        if (candidate.isBefore(DateTime(ref.year, ref.month, ref.day))) {
          year++;
        }
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: year,
          month: month,
          day: day,
        );
      },
    ),

    // Day only (with suffix): 14-го
    PatternDef(
      name: 'ru_dayOnly',
      regex: RegExp(r'(\d{1,2})(?:-го)?'),
      extract: (match, np, ref) {
        final day = int.parse(match.group(1)!);
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          day: day,
        );
      },
    ),

    // Weekday: понедельник, вторник, etc.
    PatternDef(
      name: 'ru_weekday',
      regex: RegExp(
        r'(понедельник|вторник|среда|четверг|пятница|суббота|воскресенье|пн|вт|ср|чт|пт|сб|вс|пятницу|среду|субботу)',
        caseSensitive: false,
      ),
      extract: (match, np, ref) {
        final word = match.group(1)!.toLowerCase();
        final weekday = weekdays[word] ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: word,
          weekday: weekday,
        );
      },
    ),

    // Next/last weekday: следующий понедельник, прошлую пятницу
    PatternDef(
      name: 'ru_nextLastWeekday',
      regex: RegExp(
        r'(следующий|следущая|прошлый|прошлую|прошлая|прошлое)\s+(понедельник|вторник|среду|четверг|пятницу|субботу|воскресенье)',
        caseSensitive: false,
      ),
      extract: (match, np, ref) {
        final dir = match.group(1)!.toLowerCase();
        final day = match.group(2)!.toLowerCase();
        // Map accusative forms back to nominative
        final dayMap = {
          'среду': 'среда', 'пятницу': 'пятница', 'субботу': 'суббота',
          'воскресенье': 'воскресенье',
        };
        final nominativeDay = dayMap[day] ?? day;
        final weekday = weekdays[nominativeDay] ?? weekdays[day] ?? 1;
        final isLast = dir.startsWith('прошл');
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekday,
          weekOffset: isLast ? -7 : 0,
        );
      },
    ),

    // Time: HH:MM (with period words): в 15:30
    PatternDef(
      name: 'ru_timePreposition',
      regex: RegExp(r'в\s+(\d{1,2}):(\d{2})'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        hour: int.parse(match.group(1)!), minute: int.parse(match.group(2)!),
      ),
    ),

    // Time period + HH:MM: в 15:30 вечера
    PatternDef(
      name: 'ru_periodTime',
      regex: RegExp(r'(утра|дня|вечера|ночи)\s+(\d{1,2}):(\d{2})'),
      extract: (match, np, ref) {
        final period = match.group(1)!;
        var hour = int.parse(match.group(2)!);
        final minute = int.parse(match.group(3)!);
        // Adjust for afternoon/evening
        if (period == 'дня' || period == 'вечера' || period == 'ночи') {
          if (hour < 12) hour += 12;
        }
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // X days later/ago: через 3 дня, 3 дня назад
    PatternDef(
      name: 'ru_dayOffset',
      regex: RegExp(r'через\s+(\d+)\s+дня?|дн[ея]?\s+назад\s+(\d+)|(\d+)\s+дн[ея]?\s+назад'),
      extract: (match, np, ref) {
        int? days;
        bool isAhead = true;
        if (match.group(1) != null) {
          days = int.parse(match.group(1)!);
          isAhead = true;
        } else if (match.group(2) != null) {
          days = int.parse(match.group(2)!);
          isAhead = false;
        } else if (match.group(3) != null) {
          days = int.parse(match.group(3)!);
          isAhead = false;
        } else {
          days = 1;
        }
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: isAhead ? (days ?? 1) : -(days ?? 1),
        );
      },
    ),

    // X weeks later/ago: через 2 недели, 2 недели назад
    PatternDef(
      name: 'ru_weekOffset',
      regex: RegExp(r'через\s+(\d+)\s+недел[ьи]|недел[иьюю]\s+назад\s+(\d+)|(\d+)\s+недел[иьюю]\s+назад'),
      extract: (match, np, ref) {
        int? weeks;
        bool isAhead = true;
        if (match.group(1) != null) {
          weeks = int.parse(match.group(1)!);
          isAhead = true;
        } else if (match.group(2) != null) {
          weeks = int.parse(match.group(2)!);
          isAhead = false;
        } else if (match.group(3) != null) {
          weeks = int.parse(match.group(3)!);
          isAhead = false;
        } else {
          weeks = 1;
        }
        // Convert weeks to days (for "через 2 недели" = 14 days later)
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: isAhead ? ((weeks ?? 1) * 7) : -((weeks ?? 1) * 7),
        );
      },
    ),

    // Next/last week: следующей неделе, на прошлой неделе
    PatternDef(
      name: 'ru_weekExpression',
      regex: RegExp(r'(?:на\s+)?(следующей|прошлой|этой)\s+недел[еи]',
        caseSensitive: false,
      ),
      extract: (match, np, ref) {
        final expr = match.group(1)!.toLowerCase();
        int offset = 0;
        if (expr == 'следующей') offset = 1;
        else if (expr == 'прошлой') offset = -1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekOffset: offset,
          rangeType: 'week',
        );
      },
    ),

    // Next month: в следующем месяце
    PatternDef(
      name: 'ru_nextMonth',
      regex: RegExp(r'(?:в\s+)?следующем\s+месяце', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        monthOffset: 1, rangeType: 'month',
      ),
    ),

    // Last month: в прошлом месяце
    PatternDef(
      name: 'ru_lastMonth',
      regex: RegExp(r'(?:в\s+)?прошлом\s+месяце', caseSensitive: false),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        monthOffset: -1, rangeType: 'month',
      ),
    ),

    // Month only: в марте, в сентябре
    PatternDef(
      name: 'ru_monthOnly',
      regex: RegExp(r'(?:в\s+)?([а-яА-ЯёЁ]+)(?:е|ме)', caseSensitive: false),
      extract: (match, np, ref) {
        final monthStr = match.group(1)!.toLowerCase();
        final month = months[monthStr];
        if (month == null) return null;
        int year = ref.year;
        if (month < ref.month) year++;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: year,
          month: month,
          day: 1,
          rangeType: 'month',
        );
      },
    ),
  ];

  static final definition = LanguageDefinition(
    code: 'ru',
    numberParser: arabicParser,
    patterns: patterns,
  );
}

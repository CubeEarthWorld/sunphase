// lib/languages/ja_def.dart
//
// Japanese language definition for Sunphase.
//
// Recognised expression types:
//   - Absolute dates     : 2025年3月7日, 3月7日, 7日
//   - Relative days      : 今日, 明日, 明後日, 昨日, 一昨日
//   - Relative offsets   : 3日後, 2週間後, 1ヶ月後, 来年
//   - Named weekdays     : 月曜日, 火曜, 土 (with 来週/先週 prefix)
//   - Week expressions   : 今週, 来週, 先週, 週末
//   - Month expressions  : 来月, 先月
//   - Time expressions   : 午前10時30分, 午後3時, 22時, 10:30
//   - Special            : 野獣先輩 (easter egg — resolves to Aug 10 11:45:14)
//
// Supports kanji digits (一二三…十) via `CJKNumberParser`.

import '../core/number_parser.dart';
import 'lang_def.dart';

class JaDefinitions {
  static const Map<String, int> kanjiDigits = {
    '零': 0,
    '〇': 0,
    '一': 1,
    '二': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
    '十': 10,
  };

  static const Map<String, int> weekdays = {
    '月曜': 1,
    '火曜': 2,
    '水曜': 3,
    '木曜': 4,
    '金曜': 5,
    '土曜': 6,
    '日曜': 7,
    '月': 1,
    '火': 2,
    '水': 3,
    '木': 4,
    '金': 5,
    '土': 6,
    '日': 7,
    '月曜日': 1,
    '火曜日': 2,
    '水曜日': 3,
    '木曜日': 4,
    '金曜日': 5,
    '土曜日': 6,
    '日曜日': 7,
  };

  // Authoritative vocabulary for relative-day words. This map is the single
  // source of truth: every relative-day pattern below derives its regex
  // alternation from these keys via `buildAlternation`, so adding a word
  // here makes it recognised everywhere (word-only, word + hour, and
  // word + hour + minute forms alike).
  static const Map<String, int> relativeDays = {
    '今日': 0,
    '本日': 0,
    '明日': 1,
    '明後日': 2,
    '明々後日': 3,
    '明明後日': 3,
    '昨日': -1,
    '一昨日': -2,
    '一昨々日': -3,
    '一昨昨日': -3,
  };

  static const _n = r'([0-9一二三四五六七八九十]+)';

  // Weekday base kanji + 曜 with optional 日 suffix.
  // Captures the base kanji; extract function appends '曜' for lookup.
  static const _wd = r'([月火水木金土日])曜(?:日)?';

  // Longest-first alternation of 曜 and 曜日 forms (no bare kanji).
  static const _wdAlt =
      r'(月曜日|火曜日|水曜日|木曜日|金曜日|土曜日|日曜日'
      r'|月曜|火曜|水曜|木曜|金曜|土曜|日曜)';

  static final numberParser = CJKNumberParser(kanjiDigits);

  static final patterns = [
    // Special case
    PatternDef(
      name: 'ja_special',
      regex: RegExp(r'野獣先輩'),
      extract: (match, np, ref) {
        int year = ref.year;
        DateTime target = DateTime(year, 8, 10, 11, 45, 14);
        if (ref.isAfter(target)) year++;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: year,
          month: 8,
          day: 10,
          hour: 11,
          minute: 45,
        );
      },
    ),

    // Full datetime: YYYY年MM月DD日HH時MM分
    PatternDef(
      name: 'ja_fullDateTime',
      regex: RegExp(
        r'(\d{4})年' + _n + r'月' + _n + r'[日号]\s*' + _n + r'時' + _n + r'分',
      ),
      extract: (match, np, ref) {
        int year = int.parse(match.group(1)!);
        int month = np.tryParse(match.group(2)!) ?? 1;
        int day = np.tryParse(match.group(3)!) ?? 1;
        int hour = np.tryParse(match.group(4)!) ?? 0;
        int minute = np.tryParse(match.group(5)!) ?? 0;
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

    // Full date: YYYY年MM月DD日
    PatternDef(
      name: 'ja_fullDate',
      regex: RegExp(r'(\d{4})年' + _n + r'月' + _n + r'[日号]'),
      extract: (match, np, ref) {
        int year = int.parse(match.group(1)!);
        int month = np.tryParse(match.group(2)!) ?? 1;
        int day = np.tryParse(match.group(3)!) ?? 1;
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

    // Optional year prefix + MM月DD日HH時MM分
    PatternDef(
      name: 'ja_monthDayTimeJa',
      regex: RegExp(
        r'(来年|去年|今年)?' + _n + r'月' + _n + r'[日号]\s*' + _n + r'時' + _n + r'分',
      ),
      extract: (match, np, ref) {
        String? prefix = match.group(1);
        int year = ref.year;
        if (prefix == '来年')
          year++;
        else if (prefix == '去年')
          year--;
        int month = np.tryParse(match.group(2)!) ?? 1;
        int day = np.tryParse(match.group(3)!) ?? 1;
        int hour = np.tryParse(match.group(4)!) ?? 0;
        int minute = np.tryParse(match.group(5)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: prefix == null ? null : year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Optional year prefix + MM月DD日HH時 (no minute)
    PatternDef(
      name: 'ja_monthDayHour',
      regex: RegExp(
        r'(来年|去年|今年)?' + _n + r'月' + _n + r'[日号]\s*' + _n + r'時(?!\d)',
      ),
      extract: (match, np, ref) {
        String? prefix = match.group(1);
        int year = ref.year;
        if (prefix == '来年')
          year++;
        else if (prefix == '去年')
          year--;
        int month = np.tryParse(match.group(2)!) ?? 1;
        int day = np.tryParse(match.group(3)!) ?? 1;
        int hour = np.tryParse(match.group(4)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: prefix == null ? null : year,
          month: month,
          day: day,
          hour: hour,
        );
      },
    ),

    // MM月DD日 time HH:MM (colon)
    PatternDef(
      name: 'ja_monthDayTimeColon',
      regex: RegExp(_n + r'月' + _n + r'[日号]\s*(\d{1,2}):(\d{2})'),
      extract: (match, np, ref) {
        int month = np.tryParse(match.group(1)!) ?? 1;
        int day = np.tryParse(match.group(2)!) ?? 1;
        int hour = int.parse(match.group(3)!);
        int minute = int.parse(match.group(4)!);
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // MM月DD日
    PatternDef(
      name: 'ja_monthDay',
      regex: RegExp(r'(来年|去年|今年)?' + _n + r'月' + _n + r'[日号]'),
      extract: (match, np, ref) {
        String? prefix = match.group(1);
        int year = ref.year;
        if (prefix == '来年')
          year++;
        else if (prefix == '去年')
          year--;
        int month = np.tryParse(match.group(2)!) ?? 1;
        int day = np.tryParse(match.group(3)!) ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          year: prefix == null ? null : year,
          month: month,
          day: day,
        );
      },
    ),

    // N週間後 + weekday
    PatternDef(
      name: 'ja_weeksLaterWeekday',
      regex: RegExp(_n + r'週間後' + _wd),
      extract: (match, np, ref) {
        int weeks = np.tryParse(match.group(1)!) ?? 1;
        String weekday = match.group(2)!;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekdays[weekday + '曜'] ?? 1,
          weekOffset: weeks,
        );
      },
    ),

    // Day + time: NN日HH時MM分 or NN日 HH時MM分
    PatternDef(
      name: 'ja_dayTimeJa',
      regex: RegExp(_n + r'[日号]\s*' + _n + r'時' + _n + r'分'),
      extract: (match, np, ref) {
        int day = np.tryParse(match.group(1)!) ?? 1;
        int hour = np.tryParse(match.group(2)!) ?? 0;
        int minute = np.tryParse(match.group(3)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          day: day,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Day + hour only: NN日HH時
    PatternDef(
      name: 'ja_dayHour',
      regex: RegExp(_n + r'[日号]\s*' + _n + r'時(?!\d)'),
      extract: (match, np, ref) {
        int day = np.tryParse(match.group(1)!) ?? 1;
        int hour = np.tryParse(match.group(2)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          day: day,
          hour: hour,
        );
      },
    ),

    // Relative day + time: (明日|今日|明後日|昨日)HH時MM分
    PatternDef(
      name: 'ja_relativeDayTime',
      regex: RegExp(
        buildAlternation(relativeDays.keys) + r'\s*' + _n + r'時\s*' + _n + r'分',
      ),
      extract: (match, np, ref) {
        String word = match.group(1)!;
        int hour = np.tryParse(match.group(2)!) ?? 0;
        int minute = np.tryParse(match.group(3)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: relativeDays[word],
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Relative day + hour only: (明日|今日|明後日|昨日)HH時
    PatternDef(
      name: 'ja_relativeDayHour',
      regex: RegExp(
        buildAlternation(relativeDays.keys) + r'\s*' + _n + r'時(?!\d)',
      ),
      extract: (match, np, ref) {
        String word = match.group(1)!;
        int hour = np.tryParse(match.group(2)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: relativeDays[word],
          hour: hour,
        );
      },
    ),

    // Weekday + period + time: 月曜日(午前|午後)HH時(MM分)?
    PatternDef(
      name: 'ja_weekdayPeriodTime',
      regex: RegExp(
        _wdAlt + r'(?:\s*(午前|午後))?\s*' + _n + r'時(?:\s*' + _n + r'分)?',
      ),
      extract: (match, np, ref) {
        String weekday = match.group(1)!;
        String? period = match.group(2);
        int hour = np.tryParse(match.group(3)!) ?? 0;
        int minute = match.group(4) != null
            ? (np.tryParse(match.group(4)!) ?? 0)
            : 0;
        bool pm = period == '午後';
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekdays[weekday],
          hour: hour,
          minute: minute,
          pmFlag: pm,
        );
      },
    ),

    // Next next weekday: 再来週[曜日]
    PatternDef(
      name: 'ja_nextNextWeekday',
      regex: RegExp(r'再来週' + _wd),
      extract: (match, np, ref) {
        String weekday = match.group(1)!;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekdays[weekday + '曜'] ?? 1,
          weekOffset: 2,
          calendarWeek: true,
        );
      },
    ),

    // Next / last weekday: 来週[曜日] / 先週[曜日]
    PatternDef(
      name: 'ja_nextLastWeekday',
      regex: RegExp(r'(来週|先週)' + _wd),
      extract: (match, np, ref) {
        String prefix = match.group(1)!;
        String weekday = match.group(2)!;
        int weekOffset = prefix == '来週' ? 1 : -1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekdays[weekday + '曜'] ?? 1,
          weekOffset: weekOffset,
          calendarWeek: prefix == '来週',
        );
      },
    ),

    // Weekday only (all forms)
    PatternDef(
      name: 'ja_weekdayOnly',
      regex: RegExp(_wdAlt),
      extract: (match, np, ref) {
        String word = match.group(1)!;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: word,
          weekday: weekdays[word] ?? 1,
        );
      },
    ),

    // Next month + day: 来月NN日
    PatternDef(
      name: 'ja_nextMonthDay',
      regex: RegExp(r'来月' + _n + r'[日号]'),
      extract: (match, np, ref) {
        int day = np.tryParse(match.group(1)!) ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          monthOffset: 1,
          day: day,
        );
      },
    ),

    // Day only: NN日 or NN号
    PatternDef(
      name: 'ja_dayOnly',
      regex: RegExp(_n + r'[日号]'),
      extract: (match, np, ref) {
        int day = np.tryParse(match.group(1)!) ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          day: day,
        );
      },
    ),

    // Relative day words
    PatternDef(
      name: 'ja_relativeDay',
      regex: RegExp(buildAlternation(relativeDays.keys)),
      extract: (match, np, ref) {
        String word = match.group(1)!;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: word,
          dayOffset: relativeDays[word]!,
        );
      },
    ),

    // Time: HH時MM分
    PatternDef(
      name: 'ja_timeJa',
      regex: RegExp(_n + r'時' + _n + r'分'),
      extract: (match, np, ref) {
        int hour = np.tryParse(match.group(1)!) ?? 0;
        int minute = np.tryParse(match.group(2)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Time: HH時 (hour only)
    PatternDef(
      name: 'ja_hourOnlyJa',
      regex: RegExp(_n + r'時(?!\d)'),
      extract: (match, np, ref) {
        int hour = np.tryParse(match.group(1)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          hour: hour,
        );
      },
    ),

    // Relative offset: NN(日|週間|ヶ月|年)後
    PatternDef(
      name: 'ja_relativeOffset',
      regex: RegExp(_n + r'(日|週間|ヶ月|年)後'),
      extract: (match, np, ref) {
        int value = np.tryParse(match.group(1)!) ?? 1;
        String unit = match.group(2)!;
        if (unit == '日') {
          return RawMatch(
            startIndex: match.start,
            endIndex: match.end,
            text: match.group(0)!,
            dayOffset: value,
          );
        } else if (unit == '週間') {
          return RawMatch(
            startIndex: match.start,
            endIndex: match.end,
            text: match.group(0)!,
            weekOffset: value,
          );
        } else if (unit == '年') {
          return RawMatch(
            startIndex: match.start,
            endIndex: match.end,
            text: match.group(0)!,
            yearOffset: value,
          );
        } else {
          return RawMatch(
            startIndex: match.start,
            endIndex: match.end,
            text: match.group(0)!,
            monthOffset: value,
          );
        }
      },
    ),

    // Month only expressions: 来月, 今月, 再来月, 先月, etc.
    PatternDef(
      name: 'ja_monthOnly',
      regex: RegExp(r'(再来年|今月|来月|再来月|先月|来週|今週|先週|来年|今年|週末)'),
      extract: (match, np, ref) {
        String word = match.group(1)!;
        switch (word) {
          case '今月':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              rangeType: 'month',
            );
          case '来月':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              monthOffset: 1,
              rangeType: 'month',
            );
          case '再来月':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              monthOffset: 2,
              rangeType: 'month',
            );
          case '先月':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              monthOffset: -1,
            );
          case '来週':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              weekOffset: 1,
              rangeType: 'week',
            );
          case '今週':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              weekOffset: 0,
              rangeType: 'week',
            );
          case '先週':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              weekOffset: -1,
            );
          case '再来年':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              yearOffset: 2,
            );
          case '来年':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              yearOffset: 1,
            );
          case '今年':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
            );
          case '週末':
            return RawMatch(
              startIndex: match.start,
              endIndex: match.end,
              text: word,
              weekday: 7,
              weekOffset: -7,
            );
          default:
            return null;
        }
      },
    ),

    // NN日以内
    PatternDef(
      name: 'ja_withinDays',
      regex: RegExp(_n + r'日以内'),
      extract: (match, np, ref) {
        int days = np.tryParse(match.group(1)!) ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          rangeDays: days + 1,
        );
      },
    ),
  ];

  static final definition = LanguageDefinition(
    code: 'ja',
    numberParser: numberParser,
    patterns: patterns,
  );
}

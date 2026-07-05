// lib/src/language/ja.dart
//
// Japanese: agglutinative, scriptio continua, suffix-marked units
// (年/月/日/時/分), kanji numerals, prefix anchors (来/再来/先/今).
// Everything here is vocabulary + minimal component recognisers; all
// combinations (来月21日14時, 再来週火曜14時31分, …) are derived by the
// composer.

import '../core/component.dart';
import 'language.dart';
import 'numbers.dart';

class JaLanguage {
  static const Map<String, int> _digits = {
    '零': 0, '〇': 0,
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
    '六': 6, '七': 7, '八': 8, '九': 9,
    '十': 10, '百': 100, '千': 1000,
  };

  /// Number sub-pattern: ASCII digits and kanji numerals.
  static const _n = r'([0-9〇零一二三四五六七八九十百千]+)';

  static const Map<String, DateComponent> _relativeDays = {
    '今日': RelativeDay(0),
    '本日': RelativeDay(0),
    '明日': RelativeDay(1),
    '明後日': RelativeDay(2),
    '明々後日': RelativeDay(3),
    '明明後日': RelativeDay(3),
    '昨日': RelativeDay(-1),
    '一昨日': RelativeDay(-2),
    '一昨々日': RelativeDay(-3),
    '一昨昨日': RelativeDay(-3),
  };

  static const Map<String, DateComponent> _anchors = {
    // Years
    '再来年': YearAnchor(2),
    '来年': YearAnchor(1),
    '今年': YearAnchor(0),
    '去年': YearAnchor(-1),
    '昨年': YearAnchor(-1),
    // Months
    '再来月': MonthAnchor(2),
    '来月': MonthAnchor(1),
    '今月': MonthAnchor(0),
    '先月': MonthAnchor(-1),
    // Weeks (named → calendar semantics)
    '再来週': WeekAnchor(2, calendar: true),
    '来週': WeekAnchor(1, calendar: true),
    '今週': WeekAnchor(0, calendar: true),
    '先週': WeekAnchor(-1, calendar: true),
    // Weekend
    '週末': Weekend(),
  };

  static const Map<String, DateComponent> _meridiem = {
    '午前': MeridiemMarker(Meridiem.am),
    '午後': MeridiemMarker(Meridiem.pm),
  };

  static const Map<String, int> _weekdays = {
    '月': 1, '火': 2, '水': 3, '木': 4, '金': 5, '土': 6, '日': 7,
  };

  static final LanguageSpec spec = LanguageSpec(
    code: 'ja',
    numbers: const CjkNumberReader(_digits),
    glue: RegExp(r'^(?:[\s、,]|の|に|は)+$'),
    patterns: [
      // Easter egg: 野獣先輩 → next Aug 10, 11:45:14.
      TokenPattern(
        name: 'ja_special',
        regex: RegExp('野獣先輩'),
        build: (m, ctx) {
          final ref = ctx.referenceDate;
          var year = ref.year;
          if (ref.isAfter(DateTime(year, 8, 10, 11, 45, 14))) year++;
          return [AbsoluteInstant(DateTime(year, 8, 10, 11, 45, 14))];
        },
      ),

      // 3日以内 — must be declared so maximal munch beats bare 3日.
      TokenPattern(
        name: 'ja_withinDays',
        regex: RegExp('$_n日以内'),
        build: (m, ctx) {
          final days = ctx.numbers.read(m.group(1)!);
          return days == null ? null : [WithinDays(days)];
        },
      ),

      // Relative offsets: N日後/前, N週間後/前, Nヶ月後/前, N年後/前.
      TokenPattern(
        name: 'ja_offset',
        regex: RegExp('$_n(日|週間|[ヶケか]月|年)(後|前)'),
        build: (m, ctx) {
          final n = ctx.numbers.read(m.group(1)!);
          if (n == null) return null;
          final value = m.group(3) == '後' ? n : -n;
          return switch (m.group(2)!) {
            '日' => [RelativeDay(value)],
            '週間' => [WeekAnchor(value, calendar: false)],
            '年' => [YearAnchor(value)],
            _ => [MonthAnchor(value)],
          };
        },
      ),

      vocab('ja_relativeDay', _relativeDays),
      vocab('ja_anchor', _anchors),
      vocab('ja_meridiem', _meridiem),

      // Weekday: 月曜 / 月曜日 (bare kanji alone is too ambiguous).
      TokenPattern(
        name: 'ja_weekday',
        regex: RegExp('([月火水木金土日])曜日?'),
        build: (m, ctx) => [WeekdayRef(_weekdays[m.group(1)!]!)],
      ),

      // Year: 2025年
      TokenPattern(
        name: 'ja_year',
        regex: RegExp(r'(\d{4})年'),
        build: (m, ctx) => [YearValue(int.parse(m.group(1)!))],
      ),

      // Month: 3月 (not 月曜)
      TokenPattern(
        name: 'ja_month',
        regex: RegExp('$_n月(?!曜)'),
        build: (m, ctx) {
          final month = asMonth(ctx.numbers.read(m.group(1)!));
          return month == null ? null : [MonthValue(month)];
        },
      ),

      // Day of month: 21日 / 21号
      TokenPattern(
        name: 'ja_day',
        regex: RegExp('$_n[日号]'),
        build: (m, ctx) {
          final day = asDay(ctx.numbers.read(m.group(1)!));
          return day == null ? null : [DayOfMonth(day)];
        },
      ),

      // Time: 14時31分 / 14時
      TokenPattern(
        name: 'ja_time',
        regex: RegExp('$_n時(?:\\s*$_n分)?'),
        build: (m, ctx) {
          final hour = ctx.numbers.read(m.group(1)!);
          if (hour == null) return null;
          final minute =
              m.group(2) == null ? null : ctx.numbers.read(m.group(2)!);
          return [ClockTime(hour, minute)];
        },
      ),

      colonTime('ja_colonTime'),
    ],
  );
}

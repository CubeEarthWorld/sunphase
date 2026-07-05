// lib/src/language/ko.dart
//
// Korean: agglutinative with optional spacing, suffix-marked units
// (년/월/일/시/분), prefix anchors (다음/지난) that may be separated by a
// space (다음 주). Sino-Korean numerals accepted alongside ASCII digits.

import '../core/component.dart';
import 'language.dart';
import 'numbers.dart';

class KoLanguage {
  static const Map<String, int> _digits = {
    '영': 0, '零': 0,
    '일': 1, '一': 1,
    '이': 2, '二': 2,
    '삼': 3, '三': 3,
    '사': 4, '四': 4,
    '오': 5, '五': 5,
    '육': 6, '六': 6,
    '칠': 7, '七': 7,
    '팔': 8, '八': 8,
    '구': 9, '九': 9,
    '십': 10, '十': 10,
  };

  static const _n = r'([0-9零一二三四五六七八九十]+)';

  static const Map<String, int> _weekdayChars = {
    '월': 1, '화': 2, '수': 3, '목': 4, '금': 5, '토': 6, '일': 7,
  };

  static const Map<String, DateComponent> _relativeDays = {
    '오늘': RelativeDay(0),
    '금일': RelativeDay(0),
    '내일': RelativeDay(1),
    '명일': RelativeDay(1),
    '모레': RelativeDay(2),
    '어제': RelativeDay(-1),
    '그제': RelativeDay(-1),
    '그끄제': RelativeDay(-2),
  };

  static const Map<String, DateComponent> _meridiem = {
    '오전': MeridiemMarker(Meridiem.am),
    '오후': MeridiemMarker(Meridiem.pm),
  };

  static final LanguageSpec spec = LanguageSpec(
    code: 'ko',
    numbers: const CjkNumberReader(_digits),
    glue: RegExp(r'^(?:[\s,]|에)+$'),
    patterns: [
      vocab('ko_relativeDay', _relativeDays),
      vocab('ko_meridiem', _meridiem),
      vocab('ko_weekend', const {'주말': Weekend()}),

      // Week anchor: 다음 주, 다다음주, 지난 주, 이번 주
      TokenPattern(
        name: 'ko_weekAnchor',
        regex: RegExp(r'(다다음|다음|이번|저번|지난)\s*주(?!말)'),
        build: (m, ctx) => [
          WeekAnchor(
            switch (m.group(1)!) {
              '다다음' => 2,
              '다음' => 1,
              '지난' || '저번' => -1,
              _ => 0,
            },
            calendar: true,
          ),
        ],
      ),

      // Anchored weekday without 주: 다음 월요일, 지난 금요일
      TokenPattern(
        name: 'ko_nextLastWeekday',
        regex: RegExp(r'(다음|지난|저번)\s*([월화수목금토일])요일'),
        build: (m, ctx) => [
          WeekAnchor(m.group(1)! == '다음' ? 1 : -1, calendar: false),
          WeekdayRef(_weekdayChars[m.group(2)!]!),
        ],
      ),

      // Month anchor: 다음 달, 지난 달
      TokenPattern(
        name: 'ko_monthAnchor',
        regex: RegExp(r'(다음|이번|지난|저번)\s*(?:달|월)(?![요0-9])'),
        build: (m, ctx) => [
          MonthAnchor(
            switch (m.group(1)!) {
              '다음' => 1,
              '지난' || '저번' => -1,
              _ => 0,
            },
          ),
        ],
      ),

      // Year anchors
      vocab('ko_yearAnchor', const {
        '내년': YearAnchor(1),
        '올해': YearAnchor(0),
        '작년': YearAnchor(-1),
        '내후년': YearAnchor(2),
      }),

      // Duration offsets: 3일 후, 2주 후, 1개월 전, 2년 후
      TokenPattern(
        name: 'ko_offset',
        regex: RegExp('$_n\\s*(일|주|개월|달|년)\\s*(후|뒤|전)'),
        build: (m, ctx) {
          final n = ctx.numbers.read(m.group(1)!);
          if (n == null) return null;
          final value = m.group(3) == '전' ? -n : n;
          return switch (m.group(2)!) {
            '일' => [RelativeDay(value)],
            '주' => [WeekAnchor(value, calendar: false)],
            '년' => [YearAnchor(value)],
            _ => [MonthAnchor(value)],
          };
        },
      ),

      // Weekday: 월요일 … 일요일
      TokenPattern(
        name: 'ko_weekday',
        regex: RegExp('([월화수목금토일])요일'),
        build: (m, ctx) => [WeekdayRef(_weekdayChars[m.group(1)!]!)],
      ),

      // Year: 2025년
      TokenPattern(
        name: 'ko_year',
        regex: RegExp(r'(\d{4})년'),
        build: (m, ctx) => [YearValue(int.parse(m.group(1)!))],
      ),

      // Month: 2월
      TokenPattern(
        name: 'ko_month',
        regex: RegExp('$_n월'),
        build: (m, ctx) {
          final month = asMonth(ctx.numbers.read(m.group(1)!));
          return month == null ? null : [MonthValue(month)];
        },
      ),

      // Day: 14일 (but not 일요일)
      TokenPattern(
        name: 'ko_day',
        regex: RegExp('$_n일(?!요일)'),
        build: (m, ctx) {
          final day = asDay(ctx.numbers.read(m.group(1)!));
          return day == null ? null : [DayOfMonth(day)];
        },
      ),

      // Time: 3시 30분 / 14시
      TokenPattern(
        name: 'ko_time',
        regex: RegExp('$_n시(?:\\s*$_n분)?'),
        build: (m, ctx) {
          final hour = ctx.numbers.read(m.group(1)!);
          if (hour == null) return null;
          final minute =
              m.group(2) == null ? null : ctx.numbers.read(m.group(2)!);
          return [ClockTime(hour, minute)];
        },
      ),

      colonTime('ko_colonTime'),
    ],
  );
}

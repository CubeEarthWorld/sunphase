// lib/src/language/zh.dart
//
// Chinese (Simplified): scriptio continua, suffix-marked units
// (年/月/号/日/点/时/分), hanzi numerals, prefix anchors (下/上/这/本).
// Week anchors fuse with weekdays in writing (下周二), so that pair is
// recognised as one fused token; everything else composes.

import '../core/component.dart';
import 'language.dart';
import 'numbers.dart';

class ZhLanguage {
  static const Map<String, int> _digits = {
    '零': 0, '〇': 0,
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
    '六': 6, '七': 7, '八': 8, '九': 9,
    '十': 10, '百': 100, '千': 1000,
  };

  static const _n = r'([0-9〇零一二三四五六七八九十百千]+)';

  static const Map<String, int> _weekdayChars = {
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7,
  };

  static const Map<String, int> _weekOffsets = {
    '下下': 2, '下': 1, '这': 0, '本': 0, '上': -1,
  };

  static const Map<String, DateComponent> _relativeDays = {
    '今天': RelativeDay(0),
    '今日': RelativeDay(0),
    '明天': RelativeDay(1),
    '后天': RelativeDay(2),
    '大后天': RelativeDay(3),
    '昨天': RelativeDay(-1),
    '前天': RelativeDay(-2),
    '大前天': RelativeDay(-3),
  };

  static const Map<String, DateComponent> _yearAnchors = {
    '后年': YearAnchor(2),
    '明年': YearAnchor(1),
    '今年': YearAnchor(0),
    '去年': YearAnchor(-1),
    '前年': YearAnchor(-2),
  };

  static const Map<String, DateComponent> _meridiem = {
    '上午': MeridiemMarker(Meridiem.am),
    '早上': MeridiemMarker(Meridiem.am),
    '凌晨': MeridiemMarker(Meridiem.am),
    '中午': MeridiemMarker(Meridiem.am),
    '下午': MeridiemMarker(Meridiem.pm),
    '晚上': MeridiemMarker(Meridiem.pm),
    '夜里': MeridiemMarker(Meridiem.pm),
  };

  static final LanguageSpec spec = LanguageSpec(
    code: 'zh',
    numbers: const CjkNumberReader(_digits),
    glue: RegExp(r'^(?:[\s、,]|的)+$'),
    patterns: [
      vocab('zh_relativeDay', _relativeDays),
      vocab('zh_yearAnchor', _yearAnchors),
      vocab('zh_meridiem', _meridiem),

      // Weekend
      vocab('zh_weekend', const {'周末': Weekend()}),

      // Fused (anchor +) weekday: 下周二, 星期天, 周日, 这礼拜五
      TokenPattern(
        name: 'zh_weekday',
        regex: RegExp('(下下|下|这|本|上)?(?:个)?(?:星期|礼拜|周)([一二三四五六日天])'),
        build: (m, ctx) {
          final anchor = m.group(1);
          return [
            if (anchor != null)
              WeekAnchor(_weekOffsets[anchor]!, calendar: true),
            WeekdayRef(_weekdayChars[m.group(2)!]!),
          ];
        },
      ),

      // Bare week anchor: 下周, 上个星期
      TokenPattern(
        name: 'zh_weekAnchor',
        regex: RegExp('(下下|下|这|本|上)(?:个)?(?:星期|礼拜|周)(?![一二三四五六日天])'),
        build: (m, ctx) =>
            [WeekAnchor(_weekOffsets[m.group(1)!]!, calendar: true)],
      ),

      // Month anchor: 下个月, 上个月
      TokenPattern(
        name: 'zh_monthAnchor',
        regex: RegExp('(下下|下|这|本|上)个月'),
        build: (m, ctx) => [MonthAnchor(_weekOffsets[m.group(1)!]!)],
      ),

      // Duration offsets: 3天后, 2周前, 1个月后, 2年后
      TokenPattern(
        name: 'zh_offset',
        regex: RegExp('$_n(天|(?:个)?(?:星期|礼拜|周)|个月|年)(后|前)'),
        build: (m, ctx) {
          final n = ctx.numbers.read(m.group(1)!);
          if (n == null) return null;
          final value = m.group(3) == '后' ? n : -n;
          final unit = m.group(2)!;
          if (unit == '天') return [RelativeDay(value)];
          if (unit == '个月') return [MonthAnchor(value)];
          if (unit == '年') return [YearAnchor(value)];
          return [WeekAnchor(value, calendar: false)];
        },
      ),

      // Year: 2025年
      TokenPattern(
        name: 'zh_year',
        regex: RegExp(r'(\d{4})年'),
        build: (m, ctx) => [YearValue(int.parse(m.group(1)!))],
      ),

      // Month: 3月
      TokenPattern(
        name: 'zh_month',
        regex: RegExp('$_n月'),
        build: (m, ctx) {
          final month = asMonth(ctx.numbers.read(m.group(1)!));
          return month == null ? null : [MonthValue(month)];
        },
      ),

      // Day: 21号 / 21日
      TokenPattern(
        name: 'zh_day',
        regex: RegExp('$_n[号日]'),
        build: (m, ctx) {
          final day = asDay(ctx.numbers.read(m.group(1)!));
          return day == null ? null : [DayOfMonth(day)];
        },
      ),

      // Time: 14点31分 / 14点 / 14时30分
      TokenPattern(
        name: 'zh_time',
        regex: RegExp('$_n[点时](?:\\s*$_n分)?'),
        build: (m, ctx) {
          final hour = ctx.numbers.read(m.group(1)!);
          if (hour == null) return null;
          final minute =
              m.group(2) == null ? null : ctx.numbers.read(m.group(2)!);
          return [ClockTime(hour, minute)];
        },
      ),

      colonTime('zh_colonTime'),
    ],
  );
}

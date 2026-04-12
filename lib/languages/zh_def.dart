// lib/languages/zh_def.dart
//
// Chinese (Simplified) language definition for Sunphase.
//
// Recognised expression types:
//   - Absolute dates     : 2025年3月7号, 3月7号, 7号
//   - Relative days      : 今天, 明天, 后天, 昨天, 前天
//   - Relative offsets   : 3天后, 2周后, 1个月后, 明年
//   - Named weekdays     : 星期一, 周三, 礼拜五 (with 下周/上周 prefix)
//   - Week expressions   : 本周, 下周, 上周, 周末
//   - Month expressions  : 下个月, 上个月
//   - Time expressions   : 上午9点, 下午3点半, 凌晨2点, 10:30
//
// Supports Chinese digit characters (一二三…十) via `CJKNumberParser`.

import '../core/number_parser.dart';
import 'lang_def.dart';

class ZhDefinitions {
  static const Map<String, int> chineseDigits = {
    '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
    '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
  };

  static const Map<String, int> weekdays = {
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '天': 7, '日': 7,
    '星期一': 1, '星期二': 2, '星期三': 3, '星期四': 4, '星期五': 5, '星期六': 6, '星期日': 7, '星期天': 7,
    '周一': 1, '周二': 2, '周三': 3, '周四': 4, '周五': 5, '周六': 6, '周日': 7, '周天': 7,
  };

  static const Map<String, int> relativeDays = {
    '今天': 0, '明天': 1, '后天': 2, '昨天': -1,
  };

  static const Map<String, int> timePeriods = {
    '上午': 0, '中午': 0, '早上': 0,
    '下午': 12, '晚上': 12, '夜里': 12,
  };

  static const _n = r'([0-9零一二三四五六七八九十]+)';

  static final numberParser = CJKNumberParser(chineseDigits);

  static final patterns = [
    // Universal pattern: time colon (HH:MM)
    UniversalPatterns.timeColon,

    // YYYY年MM月DD日: "明年2月14日"
    PatternDef(
      name: 'zh_yearMonthDay',
      regex: RegExp(r'(明年|去年|今年)?(?:' + _n + r'年)?' + _n + r'月' + _n + r'日'),
      extract: (match, np, ref) {
        String? yearPrefix = match.group(1);
        String? yearStr = match.group(2);
        int month = np.tryParse(match.group(3)!) ?? 1;
        int day = np.tryParse(match.group(4)!) ?? 1;
        int year = ref.year;
        if (yearPrefix == '明年') year++;
        else if (yearPrefix == '去年') year--;
        else if (yearStr != null) year = int.parse(yearStr!);
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

    // Relative day + Chinese time: 明天十一时三十四分
    PatternDef(
      name: 'zh_relativeDayChineseTime',
      regex: RegExp(r'(今天|明天|后天|昨天)\s*' + _n + r'时\s*' + _n + r'分'),
      extract: (match, np, ref) {
        String word = match.group(1)!;
        int hour = np.tryParse(match.group(2)!) ?? 0;
        int minute = np.tryParse(match.group(3)!) ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: relativeDays[word]!,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Month + day + period + time: 3月5日下午2点
    PatternDef(
      name: 'zh_monthDayPeriodTime',
      regex: RegExp(_n + r'月' + _n + r'[号日]\s*(上午|中午|下午|晚上|早上)\s*' + _n + r'点'),
      extract: (match, np, ref) {
        int month = np.tryParse(match.group(1)!) ?? 1;
        int day = np.tryParse(match.group(2)!) ?? 1;
        String? period = match.group(3);
        int hour = np.tryParse(match.group(4)!) ?? 0;
        int pmOffset = 0;
        if (period != null && timePeriods.containsKey(period)) {
          pmOffset = timePeriods[period]!;
        }
        if (pmOffset == 12 && hour < 12) hour += 12;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          month: month,
          day: day,
          hour: hour,
        );
      },
    ),

    // Time period + time with period word: 中午12点, 下午3点
    PatternDef(
      name: 'zh_periodWordTime',
      regex: RegExp(r'(上午|中午|下午|晚上|早上|夜里)\s*' + _n + r'点'),
      extract: (match, np, ref) {
        String period = match.group(1)!;
        int hour = np.tryParse(match.group(2)!) ?? 0;
        int pmOffset = timePeriods[period] ?? 0;
        if (pmOffset == 12 && hour < 12) hour += 12;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          hour: hour,
        );
      },
    ),

    // Time only with Chinese characters: 十一时三十四分
    PatternDef(
      name: 'zh_timeChineseOnly',
      regex: RegExp(_n + r'时\s*' + _n + r'分(?![0-9零一二三四五六七八九十])'),
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

    // Full date: YYYY年MM月DD[号日]
    PatternDef(
      name: 'zh_fullDate',
      regex: RegExp(r'(\d{4})年' + _n + r'月' + _n + r'[号日]'),
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

    // Relative day + time: (今天|明天|后天|昨天)HH:MM
    PatternDef(
      name: 'zh_relativeDayTime',
      regex: RegExp(r'(今天|明天|后天|昨天)\s*(\d{1,2}):(\d{2})'),
      extract: (match, np, ref) {
        String word = match.group(1)!;
        int hour = int.parse(match.group(2)!);
        int minute = int.parse(match.group(3)!);
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: relativeDays[word]!,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Next week + weekday: 下周[一|二|...]
    PatternDef(
      name: 'zh_nextWeekWeekday',
      regex: RegExp(r'(下周|上周|这周|本周)[星期周]?([一二三四五六天日])'),
      extract: (match, np, ref) {
        String week = match.group(1)!;
        String day = match.group(2)!;
        int offset = 0;
        if (week == '下周') offset = 1;
        else if (week == '上周') offset = -1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekdays[day] ?? 1,
          weekOffset: offset,
          rangeType: offset == 0 ? 'week' : null,
        );
      },
    ),

    // Day offset: NN天(后|前)
    PatternDef(
      name: 'zh_dayOffset',
      regex: RegExp(_n + r'天(后|前)'),
      extract: (match, np, ref) {
        int days = np.tryParse(match.group(1)!) ?? 1;
        bool forward = match.group(2) == '后';
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: forward ? days : -days,
        );
      },
    ),

    // Month only: NN月
    PatternDef(
      name: 'zh_monthOnly',
      regex: RegExp(_n + r'月'),
      extract: (match, np, ref) {
        int month = np.tryParse(match.group(1)!) ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          month: month,
          rangeType: 'month',
        );
      },
    ),

    // Week expressions: 下周, 上周
    PatternDef(
      name: 'zh_weekOnly',
      regex: RegExp(r'(下周|上周|这周|本周)'),
      extract: (match, np, ref) {
        String week = match.group(1)!;
        int offset = 0;
        if (week == '下周') offset = 1;
        else if (week == '上周') offset = -1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: week,
          weekOffset: offset,
          rangeType: 'week',
        );
      },
    ),

    // Month + day + time: MM月DD[号日]HH:MM
    PatternDef(
      name: 'zh_monthDayTimeColon',
      regex: RegExp(_n + r'月' + _n + r'[号日]\s*(\d{1,2}):(\d{2})'),
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

    // Month + day with kanji: (NN月)NN[号日]
    PatternDef(
      name: 'zh_monthDayKanji',
      regex: RegExp(r'(?:([零一二三四五六七八九十]+)月)?([零一二三四五六七八九十]+)[号日]'),
      extract: (match, np, ref) {
        int? month = match.group(1) != null ? (np.tryParse(match.group(1)!) ?? 1) : null;
        int day = np.tryParse(match.group(2)!) ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          month: month,
          day: day,
        );
      },
    ),

    // Relative month + day: (上|下)个月NN[号日]
    PatternDef(
      name: 'zh_relativeMonthDay',
      regex: RegExp(r'(上|下)个月' + _n + r'[号日]'),
      extract: (match, np, ref) {
        bool next = match.group(1) == '下';
        int day = np.tryParse(match.group(2)!) ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          monthOffset: next ? 1 : -1,
          day: day,
        );
      },
    ),

    // Day only: NN[号日]
    PatternDef(
      name: 'zh_dayOnly',
      regex: RegExp(r'(\d{1,2})[号日]'),
      extract: (match, np, ref) {
        int day = int.parse(match.group(1)!);
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          day: day,
        );
      },
    ),

    // Weekday + period + time: [星期周][N](上午|下午)HH点
    PatternDef(
      name: 'zh_weekdayPeriodTime',
      regex: RegExp(r'[星期周]([一二三四五六天日])\s*(上午|中午|下午|晚上|早上)?\s*' + _n + r'(?:点|时|:：)(?:\s*' + _n + r'分)?'),
      extract: (match, np, ref) {
        String day = match.group(1)!;
        String? period = match.group(2);
        int hour = np.tryParse(match.group(3)!) ?? 0;
        int minute = match.group(4) != null ? (np.tryParse(match.group(4)!) ?? 0) : 0;
        int pmOffset = 0;
        if (period != null && timePeriods.containsKey(period)) {
          pmOffset = timePeriods[period]!;
        }
        if (pmOffset == 12 && hour < 12) hour += 12;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekdays[day] ?? 1,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Time period + time: (上午|下午)HH:MM
    PatternDef(
      name: 'zh_periodTimeColon',
      regex: RegExp(r'(上午|中午|下午|晚上|早上)\s*(\d{1,2}):(\d{2})'),
      extract: (match, np, ref) {
        String period = match.group(1)!;
        int hour = int.parse(match.group(2)!);
        int minute = int.parse(match.group(3)!);
        int pmOffset = timePeriods[period] ?? 0;
        if (pmOffset == 12 && hour < 12) hour += 12;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Day + period + time: 20号下午3点
    PatternDef(
      name: 'zh_dayPeriodTime',
      regex: RegExp(_n + r'[号日]\s*(上午|中午|下午|晚上|早上)\s*' + _n + r'点(?:\s*' + _n + r'分)?'),
      extract: (match, np, ref) {
        int day = np.tryParse(match.group(1)!) ?? 1;
        String? period = match.group(2);
        int hour = np.tryParse(match.group(3)!) ?? 0;
        int minute = match.group(4) != null ? (np.tryParse(match.group(4)!) ?? 0) : 0;
        int pmOffset = 0;
        if (period != null && timePeriods.containsKey(period)) {
          pmOffset = timePeriods[period]!;
        }
        if (pmOffset == 12 && hour < 12) hour += 12;
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

    // Time period + HH点MM分
    PatternDef(
      name: 'zh_periodTimeDian',
      regex: RegExp(r'(上午|中午|下午|晚上|早上)\s*' + _n + r'点(?:\s*' + _n + r'分)?'),
      extract: (match, np, ref) {
        String period = match.group(1)!;
        int hour = np.tryParse(match.group(2)!) ?? 0;
        int minute = match.group(3) != null ? (np.tryParse(match.group(3)!) ?? 0) : 0;
        int pmOffset = timePeriods[period] ?? 0;
        if (pmOffset == 12 && hour < 12) hour += 12;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Relative day words: 今天|明天|后天|昨天
    PatternDef(
      name: 'zh_relativeDay',
      regex: RegExp(r'(今天|明天|后天|昨天)'),
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

    // Weekday only
    PatternDef(
      name: 'zh_weekdayOnly',
      regex: RegExp(r'(星期[一二三四五六天日]|周[一二三四五六天日]|周一|周二|周三|周四|周五|周六|周日|周天)'),
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

    // Time with 点: NN点NN分
    PatternDef(
      name: 'zh_timeDian',
      regex: RegExp(_n + r'(?:点|时|:：)' + _n + r'分'),
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

    // Time with 点 only (no minute): NN点
    PatternDef(
      name: 'zh_timeDianOnly',
      regex: RegExp(_n + r'点(?![0-9零一二三四五六七八九十])'),
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

    // Day + 点 time: NN号NN点
    PatternDef(
      name: 'zh_dayTimeDian',
      regex: RegExp(_n + r'[号日]\s*' + _n + r'点(?![0-9零一二三四五六七八九十])'),
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
  ];

  static final definition = LanguageDefinition(
    code: 'zh',
    numberParser: numberParser,
    patterns: patterns,
  );
}

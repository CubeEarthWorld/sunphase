// lib/languages/ko_def.dart
import '../core/number_parser.dart';
import 'lang_def.dart';

class KoDefinitions {
  static const Map<String, int> months = {
    '1월': 1, '일월': 1, '한달': 1,
    '2월': 2, '이월': 2,
    '3월': 3, '삼월': 3,
    '4월': 4, '사월': 4,
    '5월': 5, '오월': 5,
    '6월': 6, '유월': 6,
    '7월': 7, '칠월': 7,
    '8월': 8, '팔월': 8,
    '9월': 9, '구월': 9,
    '10월': 10, '시월': 10,
    '11월': 11, '십일월': 11,
    '12월': 12, '십이월': 12,
  };

  static const Map<String, int> weekdays = {
    '월요일': 1, '월': 1,
    '화요일': 2, '화': 2,
    '수요일': 3, '수': 3,
    '목요일': 4, '목': 4,
    '금요일': 5, '금': 5,
    '토요일': 6, '토': 6,
    '일요일': 7, '일': 7,
  };

  static const Map<String, int> relativeDays = {
    '오늘': 0, '금일': 0,
    '내일': 1, '명일': 1,
    '모레': 2,
    '그제': -1, '어제': -1,
    '그끄제': -2,
  };

  static const Map<String, int> koreanDigits = {
    '영': 0, '零': 0, '일': 1, '一': 1, '이': 2, '二': 2,
    '삼': 3, '三': 3, '사': 4, '四': 4, '오': 5, '五': 5,
    '육': 6, '六': 6, '칠': 7, '七': 7, '팔': 8, '八': 8,
    '구': 9, '九': 9, '십': 10, '十': 10,
  };

  static final _n = r'([0-9零一二三四五六七八九十]+)';
  static final numberParser = CJKNumberParser(koreanDigits);

  static final patterns = [
    // Universal pattern: time colon (HH:MM)
    UniversalPatterns.timeColon,

    // Relative days: 오늘, 내일, 어제
    PatternDef(
      name: 'ko_relativeDay',
      regex: RegExp(r'(오늘|내일|명일|모레|어제|그제|그끄제|금일)'),
      extract: (match, np, ref) {
        final word = match.group(0)!;
        final mappedWord = _mapRelativeDay(word);
        final offset = relativeDays[mappedWord] ?? 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: offset,
        );
      },
    ),

    // YYYY년MM월DD일: 2025년2월14일
    PatternDef(
      name: 'ko_fullDate',
      regex: RegExp(r'(\d{4})년' + _n + r'월' + _n + r'일'),
      extract: (match, np, ref) {
        final year = int.parse(match.group(1)!);
        final month = np.tryParse(match.group(2)!) ?? 1;
        final day = np.tryParse(match.group(3)!) ?? 1;
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

    // MM월DD일: 2월14일
    PatternDef(
      name: 'ko_monthDay',
      regex: RegExp(_n + r'월' + _n + r'일'),
      extract: (match, np, ref) {
        final month = np.tryParse(match.group(1)!) ?? 1;
        final day = np.tryParse(match.group(2)!) ?? 1;
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

    // DD일 (day only): 14일
    PatternDef(
      name: 'ko_dayOnly',
      regex: RegExp(_n + r'일'),
      extract: (match, np, ref) {
        final day = np.tryParse(match.group(1)!) ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          day: day,
        );
      },
    ),

    // Weekday: 월요일, 화요일, etc.
    PatternDef(
      name: 'ko_weekday',
      regex: RegExp(r'(월요일|화요일|수요일|목요일|금요일|토요일|일요일|월|화|수|목|금|토|일)'),
      extract: (match, np, ref) {
        final word = match.group(1)!;
        final weekday = weekdays[word] ?? 1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: word,
          weekday: weekday,
        );
      },
    ),

    // Next/last weekday: 다음 월요일, 지난 금요일
    PatternDef(
      name: 'ko_nextLastWeekday',
      regex: RegExp(r'(다음|지난|저번)\s*(월요일|화요일|수요일|목요일|금요일|토요일|일요일)'),
      extract: (match, np, ref) {
        final dir = match.group(1)!;
        final day = match.group(2)!;
        final weekday = weekdays[day] ?? 1;
        final isLast = dir == '지난' || dir == '저번';
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekday: weekday,
          weekOffset: isLast ? -7 : 0,
        );
      },
    ),

    // Time: HH시MM분 or HH시
    PatternDef(
      name: 'ko_time',
      regex: RegExp(_n + r'시(?:\s*' + _n + r'분)?'),
      extract: (match, np, ref) {
        final hour = np.tryParse(match.group(1)!) ?? 0;
        final minute = match.group(2) != null
            ? (np.tryParse(match.group(2)!) ?? 0)
            : 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Relative day + time: 내일 3시
    PatternDef(
      name: 'ko_relativeDayTime',
      regex: RegExp(r'(오늘|내일|어제)\s*' + _n + r'시(?:\s*' + _n + r'분)?'),
      extract: (match, np, ref) {
        final word = match.group(1)!;
        final mappedWord = _mapRelativeDay(word);
        final offset = relativeDays[mappedWord] ?? 0;
        final hour = np.tryParse(match.group(2)!) ?? 0;
        final minute = match.group(3) != null
            ? (np.tryParse(match.group(3)!) ?? 0)
            : 0;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: offset,
          hour: hour,
          minute: minute,
        );
      },
    ),

    // Day + time: 14일 3시
    PatternDef(
      name: 'ko_dayTime',
      regex: RegExp(_n + r'일\s*' + _n + r'시(?:\s*' + _n + r'분)?'),
      extract: (match, np, ref) {
        final day = np.tryParse(match.group(1)!) ?? 1;
        final hour = np.tryParse(match.group(2)!) ?? 0;
        final minute = match.group(3) != null
            ? (np.tryParse(match.group(3)!) ?? 0)
            : 0;
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

    // X일 후/전 (X days after/before): 3일 후, 7일 전
    PatternDef(
      name: 'ko_dayOffset',
      regex: RegExp(_n + r'일\s*(후|전)'),
      extract: (match, np, ref) {
        final days = np.tryParse(match.group(1)!) ?? 1;
        final dir = match.group(2)!;
        final offset = dir == '후' ? days : -days;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          dayOffset: offset,
        );
      },
    ),

    // X주 후/전 (X weeks after/before): 2주 후
    PatternDef(
      name: 'ko_weekOffset',
      regex: RegExp(_n + r'주\s*(후|전)'),
      extract: (match, np, ref) {
        final weeks = np.tryParse(match.group(1)!) ?? 1;
        final dir = match.group(2)!;
        final offset = dir == '후' ? weeks : -weeks;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekOffset: offset,
        );
      },
    ),

    // Next/last week: 다음 주, 지난 주
    PatternDef(
      name: 'ko_weekExpression',
      regex: RegExp(r'(다음|지난|이번)\s*주'),
      extract: (match, np, ref) {
        final expr = match.group(1)!;
        int offset = 0;
        if (expr == '다음') offset = 1;
        else if (expr == '지난') offset = -1;
        return RawMatch(
          startIndex: match.start,
          endIndex: match.end,
          text: match.group(0)!,
          weekOffset: offset,
          rangeType: 'week',
        );
      },
    ),

    // Next month: 다음 달, 다음 월
    PatternDef(
      name: 'ko_nextMonth',
      regex: RegExp(r'다음\s*(달|월)'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        monthOffset: 1, rangeType: 'month',
      ),
    ),

    // Last month: 지난 달, 지난 월
    PatternDef(
      name: 'ko_lastMonth',
      regex: RegExp(r'지난\s*(달|월)'),
      extract: (match, np, ref) => RawMatch(
        startIndex: match.start, endIndex: match.end, text: match.group(0)!,
        monthOffset: -1, rangeType: 'month',
      ),
    ),
  ];

  static final definition = LanguageDefinition(
    code: 'ko',
    numberParser: numberParser,
    patterns: patterns,
  );

  // Helper for mapping relative day variations
  static String _mapRelativeDay(String word) {
    const map = {
      '금일': '오늘',
      '명일': '내일',
      '그제': '어제',
    };
    return map[word] ?? word;
  }
}

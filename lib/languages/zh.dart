// lib/languages/zh.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// Utility class for Chinese number parsing
class ChineseNumberUtil {
  static const Map<String, int> numberMap = {
    "零": 0,
    "一": 1,
    "二": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
    "七": 7,
    "八": 8,
    "九": 9,
    "十": 10,
  };

  static int parse(String input) {
    int? value = int.tryParse(input);
    if (value != null) return value;
    if (input.contains("十")) {
      return _parseWithTen(input);
    }
    return _parseSimpleNumber(input);
  }

  static int _parseWithTen(String input) {
    if (input == "十") return 10;
    if (input.length == 2) {
      if (input.startsWith("十")) {
        return 10 + (numberMap[input[1]] ?? 0);
      }
      return (numberMap[input[0]] ?? 0) * 10 + (numberMap[input[1]] ?? 0);
    }
    if (input.length == 3 && input[1] == '十') {
      return (numberMap[input[0]] ?? 0) * 10 + (numberMap[input[2]] ?? 0);
    }
    return 0;
  }

  static int _parseSimpleNumber(String input) {
    int result = 0;
    for (String char in input.split('')) {
      result = result * 10 + (numberMap[char] ?? 0);
    }
    return result;
  }
}

abstract class ChineseParserBase extends BaseParser {
  static const Map<String, int> weekdayMap = {
    "一": 1,
    "二": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
    "天": 7,
  };

  DateTime adjustToFuture(DateTime date, DateTime reference) {
    if (!date.isAfter(reference)) {
      return DateTime(
          date.year + 1, date.month, date.day, date.hour, date.minute);
    }
    return date;
  }

  int getHourWithPeriod(int hour, String? period) {
    if (period == null) return hour;
    if (period.contains("下午") || period.contains("晚上")) {
      return hour < 12 ? hour + 12 : hour;
    } else if (period.contains("上午") || period.contains("早上")) {
      // "上午" or "早上" の場合は時間を変更しない
      return hour;
    }
    return hour;
  }

  int parseKanjiOrArabicNumber(String text) {
    return ChineseNumberUtil.parse(text);
  }
}

/// Parser for relative expressions like "今天", "明天", "后天", "昨天"
class ZhRelativeParser extends ChineseParserBase {
  static final RegExp _combinedPattern = RegExp(
      r'(今天|明天|后天|昨天|这周|下周|上周)(?:\s*(上午|中午|下午|晚上))?\s*(\d{1,2}|[一二三四五六七八九十]+)(?:[点时:：])(?:\s*(\d{1,2}|[一二三四五六七八九十]+)(?:分)?)?'
  );

  static final RegExp _monthOnlyPattern =
  RegExp(r'(下月|上月|[0-9一二三四五六七八九十]+)月', caseSensitive: false);



  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    String trimmed = text.trim();
    // 单体相对词（今天、明天、后天、昨天）
    Map<String, int> dayOffsets = {"今天": 0, "明天": 1, "后天": 2, "昨天": -1};
    if (dayOffsets.containsKey(trimmed)) {
      DateTime base = context.referenceDate;
      DateTime date = DateTime(base.year, base.month, base.day)
          .add(Duration(days: dayOffsets[trimmed]!));
      return [ParsingResult(index: 0, text: trimmed, date: date)];
    }

    if (trimmed == "这周" || trimmed == "本周") {
      // 假设以周一作为一周的开始
      int daysFromMonday = context.referenceDate.weekday - 1;
      DateTime start = DateTime(
        context.referenceDate.year,
        context.referenceDate.month,
        context.referenceDate.day,
      ).subtract(Duration(days: daysFromMonday));
      return [ParsingResult(index: 0, text: trimmed, date: start, rangeType: "week")];
    }


    // 单体"下周"：返回下周整周的起始日期（range_type: week）
    if (trimmed == "下周") {
      int daysToNextMonday = (8 - context.referenceDate.weekday) % 7;
      if (daysToNextMonday == 0) daysToNextMonday = 7;
      DateTime start = DateTime(context.referenceDate.year,
              context.referenceDate.month, context.referenceDate.day)
          .add(Duration(days: daysToNextMonday));
      return [
        ParsingResult(index: 0, text: "下周", date: start, rangeType: "week")
      ];
    }
    // 单体"上周"：返回上周整周的起始日期（range_type: week）
    if (trimmed == "上周") {
      int daysToLastMonday = (context.referenceDate.weekday + 6) % 7;
      if (daysToLastMonday == 0) daysToLastMonday = 7;
      DateTime start = DateTime(context.referenceDate.year,
              context.referenceDate.month, context.referenceDate.day)
          .subtract(Duration(days: daysToLastMonday));
      return [
        ParsingResult(index: 0, text: "上周", date: start, rangeType: "week")
      ];
    }
    // 单体月表达，如"下月"或"上月"或"2月"/"3月"：返回指定月份的第一天，并设置 range_type "month"
    RegExpMatch? m = _monthOnlyPattern.firstMatch(trimmed);
    if (m != null) {
      int month;
      int year = context.referenceDate.year;
      if (m.group(1) == "下月") {
        month = context.referenceDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        return [
          ParsingResult(
              index: m.start,
              text: m.group(0)!,
              date: DateTime(year, month, 1),
              rangeType: "month")
        ];
      } else if (m.group(1) == "上月") {
        month = context.referenceDate.month - 1;
        if (month < 1) {
          month = 12;
          year--;
        }
      } else {
        month = ChineseNumberUtil.parse(m.group(1)!);
        DateTime candidate = DateTime(year, month, 1);
        if (candidate.isBefore(context.referenceDate)) {
          year++;
          candidate = DateTime(year, month, 1);
        }
      }
      return [
        ParsingResult(
            index: m.start,
            text: m.group(0)!,
            date: DateTime(year, month, 1),
            rangeType: "month")
      ];
    }

    List<ParsingResult> results = [];
    DateTime ref = context.referenceDate;
    var combinedMatch = _combinedPattern.firstMatch(text);
    if (combinedMatch != null) {
      results.add(_parseCombinedDateTime(combinedMatch, ref));
    } else {
      results.addAll(_parseSimpleDayExpressions(text, ref));
      results.addAll(_parseDayOffset(text, ref));
      results.addAll(_parseWeekExpressions(text, ref));
    }
    _parseWeekdayWithTime(text, ref, results);
    return results;
  }

  ParsingResult _parseCombinedDateTime(RegExpMatch match, DateTime ref) {
    final dayOffsets = {"今天": 0, "明天": 1, "后天": 2, "昨天": -1};
    final weekOffsets = {"这周": 0, "下周": 1, "上周": -1};

    String? dayGroup = match.group(1);
    int offset = 0;
    bool isWeek = false;

    if (dayOffsets.containsKey(dayGroup)) {
      offset = dayOffsets[dayGroup] ?? 0;
    } else if (weekOffsets.containsKey(dayGroup)) {
      isWeek = true;
      offset = weekOffsets[dayGroup] ?? 0;
      // 找到下周一的日期
      int daysToNextMonday = (8 - ref.weekday) % 7;
      if (daysToNextMonday == 0) daysToNextMonday = 7; // 如果今天是周一，则加7天
      ref = ref.add(Duration(days: daysToNextMonday + (offset * 7)));
    }

    DateTime date;

    if (isWeek) {
      date = ref; // 对于周，已经计算了日期
    } else {
      date = ref.add(Duration(days: offset)); // 对于天，添加偏移量
    }

    int hour = int.tryParse(match.group(3) ?? "") ?? 0;
    if (hour == 0) {
      hour = ChineseNumberUtil.parse(match.group(3)!);
    }
    int minute = int.tryParse(match.group(4) ?? "") ?? 0;
    if (minute == 0) {
      minute = ChineseNumberUtil.parse(match.group(4) ?? "0");
    }
    hour = getHourWithPeriod(hour, match.group(2));
    date = DateTime(date.year, date.month, date.day, hour, minute);
    return ParsingResult(index: match.start, text: match.group(0)!, date: date);
  }

  List<ParsingResult> _parseSimpleDayExpressions(String text, DateTime ref) {
    final dayWords = ["今天", "明天", "后天", "昨天"];
    final dayOffsets = [0, 1, 2, -1];
    List<ParsingResult> results = [];
    for (int i = 0; i < dayWords.length; i++) {
      if (text.contains(dayWords[i])) {
        DateTime date = ref.add(Duration(days: dayOffsets[i]));
        date = DateTime(date.year, date.month, date.day);
        results.add(ParsingResult(
            index: text.indexOf(dayWords[i]), text: dayWords[i], date: date));
      }
    }
    return results;
  }

  List<ParsingResult> _parseDayOffset(String text, DateTime ref) {
    final regex = RegExp(r'(\d+|[零一二三四五六七八九十]+)天(后|前)');
    List<ParsingResult> results = [];
    for (var match in regex.allMatches(text)) {
      int days = ChineseNumberUtil.parse(match.group(1)!);
      bool isForward = match.group(2) == "后";
      DateTime date = isForward
          ? ref.add(Duration(days: days))
          : ref.subtract(Duration(days: days));
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }

  List<ParsingResult> _parseWeekExpressions(String text, DateTime ref) {
    List<ParsingResult> results = [];
    final weekPattern = RegExp(r'(下|上|本|这)周[星期周]?([一二三四五六天])');
    for (var match in weekPattern.allMatches(text)) {
      bool isNext = match.group(1) == '下';
      bool isLast = match.group(1) == '上';
      int weekDay = ChineseParserBase.weekdayMap[match.group(2)!]!;

      int diff;
      if (isNext) {
        diff = 7 - ref.weekday + weekDay;
      } else if (isLast) {
        diff = -ref.weekday - (7 - weekDay);
      } else {
        diff = weekDay - ref.weekday;
      }

      DateTime date = ref.add(Duration(days: diff));
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(date.year, date.month, date.day)));
    }
    return results;
  }

  void _parseWeekdayWithTime(
      String text, DateTime ref, List<ParsingResult> results) {
    final regex = RegExp(
        r'[星期周]([一二三四五六天])\s*(上午|中午|下午|晚上|早上)?\s*(\d{1,2}|[一二三四五六七八九十]+)(?:[点时])(?:\s*(\d{1,2}|[一二三四五六七八九十]+))?分?',
        caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      int target = ChineseParserBase.weekdayMap[match.group(1)!]!;
      int diff = (target - ref.weekday + 7) % 7;
      // if (diff == 0) diff = 7; // 当天
      DateTime base = ref.add(Duration(days: diff));
      int hour = int.tryParse(match.group(3) ?? "") ?? 0;
      if (hour == 0) {
        hour = ChineseNumberUtil.parse(match.group(3)!);
      }
      int minute = int.tryParse(match.group(4) ?? "") ?? 0;
      if (minute == 0) {
        minute = ChineseNumberUtil.parse(match.group(4) ?? "0");
      }
      if (match.group(2) != null) {
        hour = getHourWithPeriod(hour, match.group(2));
      }
      DateTime date = DateTime(base.year, base.month, base.day, hour, minute);
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }
}

/// Parser for absolute expressions in Chinese.
class ZhAbsoluteParser extends ChineseParserBase {
  static final RegExp _fullDatePattern = RegExp(
      r'(?:(明年|去年|今年))?([一二三四五六七八九十]+|\d{1,2})月([一二三四五六七八九十]+|\d{1,2})[号日](?:\s*(上午|中午|下午|晚上))?(?:\s*(\d{1,2}|[一二三四五六七八九十]+)(?::(\d{1,2}|[一二三四五六七八九十]+))?(?:分)?)?');

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    final ref = context.referenceDate;
    _parseMonthDayAndTime(text, ref, results);
    _parseFullDates(text, ref, results);
    _parseKanjiDates(text, ref, results);
    _parseRelativeMonthDay(text, ref, results);
    _parseDayOnly(text, ref, results);

    // 对于“◯月”（仅月数字）表达的支持，如 "2月"、"3月"
    final RegExp monthOnly = RegExp(r'(下月|上月|[0-9一二三四五六七八九十]+)月', caseSensitive: false);
    for (final m in monthOnly.allMatches(text)) {
      int month;
      int year = context.referenceDate.year;
      String token = m.group(1)!;
      if (token == "下月") {
        month = context.referenceDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
      } else if (token == "上月") {
        month = context.referenceDate.month - 1;
        if (month < 1) {
          month = 12;
          year--;
        }
      } else {
        // token は数字または数字の漢数字
        month = ChineseNumberUtil.parse(token);
        DateTime candidate = DateTime(year, month, 1);
        if (candidate.isBefore(context.referenceDate)) {
          year++;
          candidate = DateTime(year, month, 1);
        }
      }
      // ここで得られた候補の先頭日（1日）を返し、range_mode で月全体に展開される
      results.add(
        ParsingResult(
          index: m.start,
          text: m.group(0)!,
          date: DateTime(year, month, 1),
          rangeType: "month",
        ),
      );
    }

    final RegExp weekPattern = RegExp(r'(下周|上周)');
    for (final m in weekPattern.allMatches(text)) {
      String token = m.group(0)!;
      DateTime base;
      if (token == "下周") {
        // 次週の月曜日を求める
        int daysToNextMonday = (8 - context.referenceDate.weekday) % 7;
        if (daysToNextMonday == 0) daysToNextMonday = 7;
        base = DateTime(context.referenceDate.year,
            context.referenceDate.month, context.referenceDate.day)
            .add(Duration(days: daysToNextMonday));
      } else {
        // 上周の場合（同様に上週の月曜日などを求める）
        int daysToLastMonday = (context.referenceDate.weekday + 6) % 7;
        if (daysToLastMonday == 0) daysToLastMonday = 7;
        base = DateTime(context.referenceDate.year,
            context.referenceDate.month, context.referenceDate.day)
            .subtract(Duration(days: daysToLastMonday));
      }
      results.add(
        ParsingResult(
          index: m.start,
          text: m.group(0)!,
          date: base,
          rangeType: "week",
        ),
      );
    }

    return results;
  }

  void _parseFullDates(String text, DateTime ref, List<ParsingResult> results) {
    for (final match in _fullDatePattern.allMatches(text)) {
      int month = int.tryParse(match.group(2)!) ??
          ChineseNumberUtil.parse(match.group(2)!);
      int day = int.tryParse(match.group(3)!) ??
          ChineseNumberUtil.parse(match.group(3)!);
      int year = ref.year;
      String? prefix = match.group(1);
      if (prefix != null) {
        if (prefix == "明年") {
          year++;
        } else if (prefix == "去年") {
          year--;
        }
      }
      DateTime date = DateTime(year, month, day);
      if (match.group(5) != null) {
        int hour = int.tryParse(match.group(5)!) ??
            ChineseNumberUtil.parse(match.group(5)!);
        int minute = int.tryParse(match.group(6) ?? "0") ??
            ChineseNumberUtil.parse(match.group(6) ?? "0");
        if (match.group(4) != null) {
          hour = getHourWithPeriod(hour, match.group(4));
        }
        date = DateTime(year, month, day, hour, minute);
      }
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseKanjiDates(String text, DateTime ref,
      List<ParsingResult> results) {
    final pattern = RegExp(
        r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)[号日]');
    for (final match in pattern.allMatches(text)) {
      int month = ChineseNumberUtil.parse(match.group(1)!);
      int day = ChineseNumberUtil.parse(match.group(2)!);
      DateTime date = DateTime(ref.year, month, day);
      date = adjustToFuture(date, ref);
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseRelativeMonthDay(String text, DateTime ref,
      List<ParsingResult> results) {
    final exp = RegExp(r'(上|下)个月(\d{1,2})[号日]');
    RegExpMatch? match = exp.firstMatch(text);
    if (match != null) {
      int day = int.parse(match.group(2)!);
      int monthOffset = match.group(1) == '下' ? 1 : -1;
      DateTime date = DateTime(ref.year, ref.month + monthOffset, day);
      results.add(
          ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
  }

  void _parseDayOnly(String text, DateTime ref, List<ParsingResult> results) {
    final exp = RegExp(r'(\d{1,2})[号日]');
    RegExpMatch? match = exp.firstMatch(text);
    if (match != null) {
      int day = int.parse(match.group(1)!);
      DateTime candidate = DateTime(ref.year, ref.month, day);
      if (candidate.isBefore(ref)) {
        candidate = DateTime(ref.year, ref.month + 1, day);
      }
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: candidate));
    }
  }

  // "四号一点" (4日1時) のような表現に対応 (日と時刻のみのケース)
  void _parseMonthDayAndTime(String text, DateTime ref,
      List<ParsingResult> results) {
    // 修正: 月の部分をオプショナルなグループとして扱う
    final exp = RegExp(
        r'(?:([一二三四五六七八九十]+)月)?([一二三四五六七八九十]+)[号日]\s*([一二三四五六七八九十]+)点');
    for (final match in exp.allMatches(text)) {
      int year = ref.year;
      int month;
      // 第1グループが存在する場合は月として解析、なければ現在の月を使用
      if (match.group(1) != null) {
        month = ChineseNumberUtil.parse(match.group(1)!);
        // 明示的に月が指定されている場合は「月」と「日」で比較
        int day = ChineseNumberUtil.parse(match.group(2)!);
        int hour = ChineseNumberUtil.parse(match.group(3)!);
        // もし指定された月日が参照日より前なら、来年として解釈
        if (month < ref.month || (month == ref.month && day < ref.day)) {
          year++;
        }
        DateTime date = DateTime(year, month, day, hour, 0);
        results.add(
            ParsingResult(
                index: match.start, text: match.group(0)!, date: date));
      } else {
        // 月が指定されていない場合は、現在の月で解釈
        month = ref.month;
        int day = ChineseNumberUtil.parse(match.group(2)!);
        int hour = ChineseNumberUtil.parse(match.group(3)!);
        DateTime candidate = DateTime(year, month, day, hour, 0);
        // もし候補日時が参照日時より前の場合は、次の月へ移行（必要に応じて年も調整）
        if (candidate.isBefore(ref)) {
          month = ref.month + 1;
          if (month > 12) {
            month = 1;
            year++;
          }
          candidate = DateTime(year, month, day, hour, 0);
        }
        results.add(
            ParsingResult(
                index: match.start, text: match.group(0)!, date: candidate));
      }
    }
  }
}

/// Parser for time-only expressions in Chinese.
class ZhTimeOnlyParser extends ChineseParserBase {
  static final RegExp _timeReg = RegExp(
      r'((?:[一二三四五六七八九十]+月[一二三四五六七八九十]+[号日])|(?:明天|今天|后天|昨天))?\s*(上午|中午|下午|晚上|早上)?\s*(\d{1,2}|[一二三四五六七八九十]+)(?:[点时:：])(?:\s*(\d{1,2}|[一二三四五六七八九十]+))?(?:分)?'
  );

  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    for (final match in _timeReg.allMatches(text)) {
      ParsingResult? result =
          _parseTimeMatch(match, context.referenceDate, context);
      if (result != null) results.add(result);
    }
    return results;
  }

  ParsingResult? _parseTimeMatch(
      RegExpMatch match, DateTime refDate, ParsingContext context) {
    String? monthDayStr = match.group(1);
    String? periodStr = match.group(2);
    String hourStr = match.group(3)!;
    String? minuteStr = match.group(4);

    int month = refDate.month;
    int day = refDate.day;
    int year = refDate.year;

    // 日付部分の解析
    if (monthDayStr != null) {
      if (RegExp(r'(明天|今天|后天|昨天)').hasMatch(monthDayStr)) {
        // "明天", "今天", "后天", "昨天" の処理
        final dayOffsets = {"今天": 0, "明天": 1, "后天": 2, "昨天": -1};
        day = refDate.day + dayOffsets[monthDayStr]!;
      } else {
        // "N月N日" の形式
        RegExp mdReg = RegExp(r'([一二三四五六七八九十]+)月([一二三四五六七八九十]+)[号日]');
        RegExpMatch? mdMatch = mdReg.firstMatch(monthDayStr);
        if (mdMatch != null) {
          month = ChineseNumberUtil.parse(mdMatch.group(1)!);
          day = ChineseNumberUtil.parse(mdMatch.group(2)!);
        }
      }
      // 年の調整: 指定された日付が参照日より前の場合は年をインクリメント
      DateTime tempDate = DateTime(year, month, day);
      if (tempDate.isBefore(refDate)) {
        year++;
      }
    }
    // 年の調整: 月日が参照日より前の場合は年をインクリメント
    if (month < refDate.month ||
        (month == refDate.month && day < refDate.day)) {
      year++;
    }

    int hour = ChineseNumberUtil.parse(hourStr);
    int minute = minuteStr != null ? ChineseNumberUtil.parse(minuteStr) : 0;
    if (periodStr != null) {
      hour = getHourWithPeriod(hour, periodStr);
    }
    DateTime candidate = DateTime(year, month, day, hour, minute);
    return ParsingResult(
        index: match.start, text: match.group(0)!, date: candidate);
  }
}

class ZhParsers {
  static final List<BaseParser> parsers = [
    ZhRelativeParser(),
    ZhAbsoluteParser(),
    ZhTimeOnlyParser(),
  ];
}

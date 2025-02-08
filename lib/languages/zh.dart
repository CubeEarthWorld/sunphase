// lib/languages/zh.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class ChineseLanguage implements Language {
  @override
  String get code => 'zh';

  @override
  List<Parser> get parsers => [ChineseDateParser()];

  @override
  List<Refiner> get refiners => [ChineseRefiner()];
}

class ChineseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------
    // 相对日 "今天", "明天", "昨天"
    // ------------------------------
    final RegExp relativeDayPattern = RegExp(r'(今天|明天|昨天)');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == '今天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '明天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched == '昨天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(const Duration(days: 1));
      } else {
        date = referenceDate;
      }
      results.add(ParsingResult(
        index: match.start,
        text: matched,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 星期 (下周 星期一, 上周 周三, 本周 礼拜五 等)
    // ------------------------------
    final RegExp weekdayPattern =
    RegExp(r'(下周|上周|本周)?\s*(星期[一二三四五六日]|周[一二三四五六日]|礼拜[一二三四五六日])');
    for (final match in weekdayPattern.allMatches(text)) {
      String modifier = match.group(1) ?? '';
      String weekdayStr = match.group(2)!;
      int targetWeekday = _weekdayFromString(weekdayStr);
      DateTime date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 绝对日期 (YYYY年M月D日, 或 1月1日)
    // ------------------------------
    final RegExp absoluteDatePattern = RegExp(r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日');
    for (final match in absoluteDatePattern.allMatches(text)) {
      int year = (match.group(1) != null)
          ? int.parse(match.group(1)!)
          : referenceDate.year;
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      DateTime date = DateTime(year, month, day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 相对时间段 (下周, 上个月, 这个月, 明年, 去年, 今年)
    // ------------------------------
    final RegExp relativePeriodPattern =
    RegExp(r'(下周|上周|本周|下个月|上个月|这个月|明年|去年|今年)');
    for (final match in relativePeriodPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date = _getRelativePeriodDate(referenceDate, matched);
      results.add(ParsingResult(
        index: match.start,
        text: matched,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // "X天前" / "X天后"
    // ------------------------------
    final RegExp relativeDayNumPattern = RegExp(r'([一二三四五六七八九十\d]+)天(前|后)');
    for (final match in relativeDayNumPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      String direction = match.group(2)!;
      int number = _cnNumberToInt(numStr);
      bool isFuture = (direction == '后');
      DateTime date = isFuture
          ? referenceDate.add(Duration(days: number))
          : referenceDate.subtract(Duration(days: number));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // "X天" (不含前后) 作为单独日期 (如：当月或下月最近的日期)
    // ------------------------------
    final RegExp singleDayPatternForTian =
    RegExp(r'(?<!月)([一二三四五六七八九十\d]+)天(?!前|后)');
    for (final match in singleDayPatternForTian.allMatches(text)) {
      String numStr = match.group(1)!;
      int day = _cnNumberToInt(numStr);
      if (day <= 0) continue;
      DateTime current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(current.year, current.month, day);
      if (current.day > day) {
        int nextMonth = current.month + 1;
        int nextYear = current.year;
        if (nextMonth > 12) {
          nextMonth -= 12;
          nextYear += 1;
        }
        candidate = DateTime(nextYear, nextMonth, day);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ------------------------------
    // 剩余的相对单位 (周, 个月, 月, 年) + 可选前后
    // ------------------------------
    final RegExp relativeNumPattern =
    RegExp(r'([一二三四五六七八九十\d]+)(周|个月|月|年)(前|后)?');
    for (final match in relativeNumPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      String unit = match.group(2)!;
      String? direction = match.group(3);
      int number = _cnNumberToInt(numStr);
      bool isFuture = (direction != '前');
      int daysToMove = 0;
      if (unit.contains('周')) {
        daysToMove = number * 7;
      } else if (unit.contains('个月') || unit == '月') {
        daysToMove = number * 30;
      } else if (unit.contains('年')) {
        daysToMove = number * 365;
      }
      DateTime date = isFuture
          ? referenceDate.add(Duration(days: daysToMove))
          : referenceDate.subtract(Duration(days: daysToMove));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // ISO8601 等标准日期字符串
    // ------------------------------
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate),
      ));
    } catch (_) {
      // 解析失败则忽略
    }

    // ------------------------------
    // 单独的 "◯日" 或 "◯号" => 当月/下月最近的日期
    // ------------------------------
    final RegExp singleDayPattern = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDayPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      int day = _cnNumberToInt(numStr);
      if (day <= 0) continue;
      DateTime current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(current.year, current.month, day);
      if (current.day > day) {
        int nextMonth = current.month + 1;
        int nextYear = current.year;
        if (nextMonth > 12) {
          nextMonth -= 12;
          nextYear += 1;
        }
        candidate = DateTime(nextYear, nextMonth, day);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ------------------------------
    // 相对日与时刻组合 (例如: "明天16:40" 或 "明天16点40分")
    // ------------------------------
    final RegExp relativeTimePattern = RegExp(
      r'(今天|明天|昨天)\s*(\d{1,2})(?:[:：点])(?:(\d{1,2}))?(?:分)?',
    );
    for (final match in relativeTimePattern.allMatches(text)) {
      String dayWord = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      DateTime date;
      if (dayWord == '今天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, minute);
      } else if (dayWord == '明天') {
        DateTime base = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 1));
        date = DateTime(base.year, base.month, base.day, hour, minute);
      } else if (dayWord == '昨天') {
        DateTime base = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: 1));
        date = DateTime(base.year, base.month, base.day, hour, minute);
      } else {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, minute);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 仅时刻的表达 (例如: "16:40" 或 "16点40分" 或 "16点")
    // ------------------------------
    final RegExp timeOnlyPattern = RegExp(
      r'(?<!\d)(\d{1,2})(?:[:：点])(?:(\d{1,2}))?(?:分)?(?!\d)',
    );
    for (final match in timeOnlyPattern.allMatches(text)) {
      String matchText = match.group(0)!;
      if (matchText.contains('今天') || matchText.contains('明天') || matchText.contains('昨天')) continue;
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      DateTime candidate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, minute);
      if (!candidate.isAfter(referenceDate)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(
        index: match.start,
        text: matchText,
        component: ParsedComponent(date: candidate),
      ));
    }

    return results;
  }

  // ---------------------------------------
  // 工具函数
  // ---------------------------------------
  int _weekdayFromString(String weekday) {
    if (weekday.contains("一")) return DateTime.monday;
    if (weekday.contains("二")) return DateTime.tuesday;
    if (weekday.contains("三")) return DateTime.wednesday;
    if (weekday.contains("四")) return DateTime.thursday;
    if (weekday.contains("五")) return DateTime.friday;
    if (weekday.contains("六")) return DateTime.saturday;
    if (weekday.contains("日") || weekday.contains("天")) return DateTime.sunday;
    return DateTime.monday;
  }

  DateTime _getDateForWeekday(DateTime reference, int targetWeekday, String modifier) {
    DateTime current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier.isEmpty || modifier == '本周') {
      if (diff <= 0) diff += 7;
    } else if (modifier == '下周') {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier == '上周') {
      if (diff >= 0) diff -= 7;
    }
    return current.add(Duration(days: diff));
  }

  DateTime _getRelativePeriodDate(DateTime reference, String period) {
    if (period == '下周') {
      return reference.add(Duration(days: 7));
    } else if (period == '上周') {
      return reference.subtract(Duration(days: 7));
    } else if (period == '本周') {
      return reference;
    } else if (period == '下个月') {
      return DateTime(reference.year, reference.month + 1, reference.day);
    } else if (period == '上个月') {
      return DateTime(reference.year, reference.month - 1, reference.day);
    } else if (period == '这个月') {
      return reference;
    } else if (period == '明年') {
      return DateTime(reference.year + 1, reference.month, reference.day);
    } else if (period == '去年') {
      return DateTime(reference.year - 1, reference.month, reference.day);
    } else if (period == '今年') {
      return reference;
    }
    return reference;
  }

  int _cnNumberToInt(String cnNum) {
    if (RegExp(r'^\d+$').hasMatch(cnNum)) {
      final val = int.parse(cnNum);
      return (val >= 1 && val <= 31) ? val : 0;
    }
    int result = 0;
    if (cnNum.contains('十')) {
      final parts = cnNum.split('十');
      final front = parts[0];
      final back = parts.length > 1 ? parts[1] : '';
      int tens = front.isEmpty ? 1 : _singleCnDigit(front);
      int ones = 0;
      for (int i = 0; i < back.length; i++) {
        ones += _singleCnDigit(back[i]);
      }
      result = tens * 10 + ones;
    } else {
      for (int i = 0; i < cnNum.length; i++) {
        result += _singleCnDigit(cnNum[i]);
      }
    }
    return (result >= 1 && result <= 31) ? result : 0;
  }

  int _singleCnDigit(String ch) {
    switch (ch) {
      case '零':
        return 0;
      case '一':
        return 1;
      case '二':
        return 2;
      case '三':
        return 3;
      case '四':
        return 4;
      case '五':
        return 5;
      case '六':
        return 6;
      case '七':
        return 7;
      case '八':
        return 8;
      case '九':
        return 9;
      case '十':
        return 10;
      default:
        return 0;
    }
  }
}

class ChineseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

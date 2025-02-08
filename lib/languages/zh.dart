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

    // ① 相对日＋时刻（例："今天16时24分", "明天08时"）
    RegExp relativeDayPattern = RegExp(
        r'(今天|明天|昨天)(?:\s*(\d{1,2})时(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in relativeDayPattern.allMatches(text)) {
      String word = match.group(1)!;
      DateTime date;
      if (word == '今天')
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      else if (word == '明天')
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 1));
      else if (word == '昨天')
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: 1));
      else
        date = referenceDate;
      bool hasTime = false;
      if (match.group(2) != null) {
        int hour = int.parse(match.group(2)!);
        int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
        date = DateTime(date.year, date.month, date.day, hour, minute);
        hasTime = true;
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date, hasTime: hasTime),
      ));
    }

    // ② 星期表达（例："下周星期一", "周三", "礼拜五"）
    RegExp weekdayPattern = RegExp(
        r'(下周|上周|本周)?\s*(星期[一二三四五六日]|周[一二三四五六日]|礼拜[一二三四五六日])'
    );
    for (final match in weekdayPattern.allMatches(text)) {
      String modifier = match.group(1) ?? '';
      String weekdayStr = match.group(2)!;
      int targetWeekday = _weekdayFromString(weekdayStr);
      DateTime date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date, hasTime: false),
      ));
    }

    // ③ 绝对日期＋时刻（例："2025年1月1日 16时31分"）
    RegExp absoluteDatePattern = RegExp(
        r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})时(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in absoluteDatePattern.allMatches(text)) {
      int year = match.group(1) != null ? int.parse(match.group(1)!) : referenceDate.year;
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      DateTime date = DateTime(year, month, day, hour, minute);
      bool hasTime = match.group(4) != null;
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date, hasTime: hasTime),
      ));
    }

    // ④ 相对期间表达（例："下周", "上个月", "今年"）
    RegExp relativePeriodPattern = RegExp(r'(下周|上周|本周|下个月|上个月|这个月|明年|去年|今年)');
    for (final match in relativePeriodPattern.allMatches(text)) {
      String word = match.group(0)!;
      DateTime date = _getRelativePeriodDate(referenceDate, word);
      results.add(ParsingResult(
        index: match.start,
        text: word,
        component: ParsedComponent(date: date, hasTime: false),
      ));
    }

    // ⑤ “X天前”或“X天后”
    RegExp relativeDayNumPattern = RegExp(r'([一二三四五六七八九十\d]+)天(前|后)');
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
        component: ParsedComponent(date: date, hasTime: false),
      ));
    }

    // ⑥ 其他相对数字表达（如 "X周", "X个月", "X年"）
    RegExp relativeNumPattern = RegExp(r'([一二三四五六七八九十\d]+)(周|个月|月|年)(前|后)?');
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
        component: ParsedComponent(date: date, hasTime: false),
      ));
    }

    // ⑦ ISO8601 标准日期字符串
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate, hasTime: true),
      ));
    } catch (_) {}

    // ⑧ 单独的日期表达（例："◯日" 或 "◯号"）→ 当月或下月的最近日期
    RegExp singleDayPattern = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
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
        component: ParsedComponent(date: candidate, hasTime: false),
      ));
    }

    // ⑨ 时刻表达（例："16时41分" 或 "16时"）→ 取最近将来的该时刻
    RegExp timeOnlyPattern = RegExp(r'(\d{1,2})时(?:\s*(\d{1,2})分)?');
    for (final match in timeOnlyPattern.allMatches(text)) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      DateTime candidate = DateTime(
          referenceDate.year, referenceDate.month, referenceDate.day, hour, minute
      );
      if (!candidate.isAfter(referenceDate)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate, hasTime: match.group(2) != null),
      ));
    }

    return results;
  }

  // --- 内部辅助函数 ---
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
    if (period == '下周')
      return reference.add(Duration(days: 7));
    else if (period == '上周')
      return reference.subtract(Duration(days: 7));
    else if (period == '本周')
      return reference;
    else if (period == '下个月')
      return DateTime(reference.year, reference.month + 1, reference.day);
    else if (period == '上个月')
      return DateTime(reference.year, reference.month - 1, reference.day);
    else if (period == '这个月')
      return reference;
    else if (period == '明年')
      return DateTime(reference.year + 1, reference.month, reference.day);
    else if (period == '去年')
      return DateTime(reference.year - 1, reference.month, reference.day);
    else if (period == '今年')
      return reference;
    return reference;
  }

  int _cnNumberToInt(String cnNum) {
    if (RegExp(r'^\d+$').hasMatch(cnNum)) {
      int val = int.parse(cnNum);
      return (val >= 1 && val <= 31) ? val : 0;
    }
    int result = 0;
    if (cnNum.contains('十')) {
      List<String> parts = cnNum.split('十');
      String front = parts[0];
      String back = parts.length > 1 ? parts[1] : '';
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
      case '零': return 0;
      case '一': return 1;
      case '二': return 2;
      case '三': return 3;
      case '四': return 4;
      case '五': return 5;
      case '六': return 6;
      case '七': return 7;
      case '八': return 8;
      case '九': return 9;
      case '十': return 10;
      default: return 0;
    }
  }
}

class ChineseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

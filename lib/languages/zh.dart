// lib/languages/zh.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class ChineseLanguage implements Language {
  @override
  String get code => 'zh';

  @override
  List<Parser> get parsers => [
    ChineseDateParser(),
    ChineseTimeParser(),
  ];

  @override
  List<Refiner> get refiners => [
    ChineseRefiner(),
  ];
}

// -------------------------------------------------------
// 1) ChineseDateParser
//   - "今天", "明天", "昨天", "下周 星期一", "YYYY年M月D日" etc.
// -------------------------------------------------------
class ChineseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // ---------- A. "今天", "明天", "昨天" ----------
    final RegExp relativeDayPattern = RegExp(r'(今天|明天|昨天)');
    for (final match in relativeDayPattern.allMatches(text)) {
      final matched = match.group(0)!;
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

    // ---------- B. 星期 (下周 星期一, 上周 周三, etc.) ----------
    final RegExp weekdayPattern = RegExp(
      r'(下周|上周|本周)?\s*(星期[一二三四五六日]|周[一二三四五六日]|礼拜[一二三四五六日])',
    );
    for (final match in weekdayPattern.allMatches(text)) {
      final modifier = match.group(1) ?? '';
      final weekdayStr = match.group(2)!;
      final targetWeekday = _weekdayFromString(weekdayStr);
      final date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- C. 绝对日期 (YYYY年M月D日) ----------
    final RegExp absoluteDatePattern = RegExp(r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日');
    for (final match in absoluteDatePattern.allMatches(text)) {
      final yearStr = match.group(1);
      final year =
      (yearStr != null) ? int.parse(yearStr) : referenceDate.year;
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final date = DateTime(year, month, day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- D. 相对时间段 (下周, 上个月, 明年, etc.) ----------
    final RegExp relativePeriodPattern =
    RegExp(r'(下周|上周|本周|下个月|上个月|这个月|明年|去年|今年)');
    for (final match in relativePeriodPattern.allMatches(text)) {
      final matched = match.group(0)!;
      final date = _getRelativePeriodDate(referenceDate, matched);
      results.add(ParsingResult(
        index: match.start,
        text: matched,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- E. "X天前" / "X天后" ----------
    final RegExp relativeDayNumPattern = RegExp(r'([一二三四五六七八九十\d]+)天(前|后)');
    for (final match in relativeDayNumPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final direction = match.group(2)!;
      final number = _cnNumberToInt(numStr);
      final isFuture = (direction == '后');
      final date = isFuture
          ? referenceDate.add(Duration(days: number))
          : referenceDate.subtract(Duration(days: number));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- F. 单独 "X天" => 当月 or 下月 的 X日 ----------
    final RegExp singleDayPatternForTian =
    RegExp(r'(?<!月)([一二三四五六七八九十\d]+)天(?!前|后)');
    for (final match in singleDayPatternForTian.allMatches(text)) {
      final numStr = match.group(1)!;
      final day = _cnNumberToInt(numStr);
      if (day <= 0) continue;
      final current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(current.year, current.month, day);
      if (candidate.isBefore(current)) {
        var nm = current.month + 1;
        var ny = current.year;
        if (nm > 12) {
          nm -= 12;
          ny += 1;
        }
        candidate = DateTime(ny, nm, day);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ---------- G. "X周" / "X个月" / "X年" + (前|后) ----------
    final RegExp relativeNumPattern = RegExp(r'([一二三四五六七八九十\d]+)(周|个月|月|年)(前|后)?');
    for (final match in relativeNumPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final unit = match.group(2)!;
      final direction = match.group(3);
      final number = _cnNumberToInt(numStr);
      final isFuture = (direction != '前');
      int daysToMove = 0;
      if (unit.contains('周')) {
        daysToMove = number * 7;
      } else if (unit.contains('个月') || unit == '月') {
        daysToMove = number * 30;
      } else if (unit.contains('年')) {
        daysToMove = number * 365;
      }
      final date = isFuture
          ? referenceDate.add(Duration(days: daysToMove))
          : referenceDate.subtract(Duration(days: daysToMove));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ---------- H. ISO8601 ----------
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate),
      ));
    } catch (_) {
      // ignore
    }

    // ---------- I. 单独 "◯日" or "◯号" ----------
    final RegExp singleDayPattern = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDayPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final day = _cnNumberToInt(numStr);
      if (day <= 0) continue;
      final current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(current.year, current.month, day);
      if (candidate.isBefore(current)) {
        var nm = current.month + 1;
        var ny = current.year;
        if (nm > 12) {
          nm -= 12;
          ny += 1;
        }
        candidate = DateTime(ny, nm, day);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    return results;
  }

  // ---------------------------------------
  // Utilities
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
    final current = DateTime(reference.year, reference.month, reference.day);
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
      return reference.add(const Duration(days: 7));
    } else if (period == '上周') {
      return reference.subtract(const Duration(days: 7));
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
    // 半角数字
    if (RegExp(r'^\d+$').hasMatch(cnNum)) {
      final val = int.parse(cnNum);
      return (val >= 1 && val <= 31) ? val : 0;
    }

    int result = 0;
    if (cnNum.contains('十')) {
      final parts = cnNum.split('十');
      final front = parts[0];
      final back = (parts.length > 1) ? parts[1] : '';

      int tens = 0;
      if (front.isEmpty) {
        tens = 1;
      } else {
        tens = _singleCnDigit(front);
      }

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

// -------------------------------------------------------
// 2) ChineseTimeParser
//   - "(\d{1,2}):(\d{1,2})" 例: "16:00"
//   - "(\d{1,2})[点时]((\d{1,2})分)?" 例: "16点24分", "16时"
// -------------------------------------------------------
class ChineseTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];
    final now = referenceDate;

    // (1) コロン区切り
    final RegExp timePatternColon = RegExp(r'\b(\d{1,2}):(\d{1,2})\b');
    for (final match in timePatternColon.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      if (hour > 23 || minute > 59) continue;
      DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // (2) "HH点((\d{1,2})分)?", "HH时((\d{1,2})分)?"
    final RegExp timePattern = RegExp(r'(\d{1,2})[点时]((\d{1,2})分)?');
    for (final match in timePattern.allMatches(text)) {
      final hourStr = match.group(1)!;
      final minuteStr = match.group(3);
      final hour = int.parse(hourStr);
      int minute = 0;
      if (minuteStr != null && minuteStr.isNotEmpty) {
        minute = int.parse(minuteStr);
      }
      if (hour > 23 || minute > 59) continue;
      DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    return results;
  }
}

// -------------------------------------------------------
// 3) ChineseRefiner
//   - 日付のみ + 時刻のみ -> 1つにマージ
// -------------------------------------------------------
class ChineseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    results.sort((a, b) => a.index.compareTo(b.index));

    final merged = <ParsingResult>[];
    int i = 0;
    while (i < results.length) {
      final current = results[i];
      if (i < results.length - 1) {
        final next = results[i + 1];
        if (_isDateOnly(current) && _isTimeOnly(next)) {
          final dt = DateTime(
            current.date.year,
            current.date.month,
            current.date.day,
            next.date.hour,
            next.date.minute,
            next.date.second,
          );
          final mergedText = current.text + next.text; // 例: "明天16点24分"
          merged.add(ParsingResult(
            index: current.index,
            text: mergedText,
            component: ParsedComponent(date: dt),
          ));
          i += 2;
          continue;
        }
      }
      merged.add(current);
      i++;
    }

    return merged;
  }

  bool _isDateOnly(ParsingResult r) {
    return (r.date.hour == 0 && r.date.minute == 0 && r.date.second == 0);
  }

  bool _isTimeOnly(ParsingResult r) {
    return (r.date.hour != 0 || r.date.minute != 0);
  }
}

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
  List<Refiner> get refiners => [ChineseRefiner()];
}

// -------------------------------------------------------
// 1) 日付パーサ (中国語特有: YYYY年M月D日, 今天, 明天, 昨天, etc.)
// -------------------------------------------------------
class ChineseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // "今天" "明天" "昨天"
    final relativeDayPattern = RegExp(r'(今天|明天|昨天)');
    for (final match in relativeDayPattern.allMatches(text)) {
      final matched = match.group(0)!;
      late DateTime date;
      if (matched == '今天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '明天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched == '昨天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(const Duration(days: 1));
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: matched,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // 星期 (下周 星期一, 上周 周三, 本周 礼拜五 等)
    final weekdayPattern =
    RegExp(r'(下周|上周|本周)?\s*(星期[一二三四五六日]|周[一二三四五六日]|礼拜[一二三四五六日])');
    for (final match in weekdayPattern.allMatches(text)) {
      final modifier = match.group(1) ?? '';
      final weekdayStr = match.group(2)!;
      final targetWeekday = _weekdayFromString(weekdayStr);
      final date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // 绝对日期 (YYYY年M月D日)
    final absoluteDatePattern = RegExp(r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日');
    for (final match in absoluteDatePattern.allMatches(text)) {
      final year = match.group(1) != null
          ? int.parse(match.group(1)!)
          : referenceDate.year;
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final date = DateTime(year, month, day);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // 相対時間 (下周, 上个月, 这个月, 明年, 去年, 今年)
    final relativePeriodPattern =
    RegExp(r'(下周|上周|本周|下个月|上个月|这个月|明年|去年|今年)');
    for (final match in relativePeriodPattern.allMatches(text)) {
      final matched = match.group(0)!;
      final date = _getRelativePeriodDate(referenceDate, matched);
      results.add(
        ParsingResult(
          index: match.start,
          text: matched,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // X天前 / X天后
    final relativeDayNumPattern = RegExp(r'([一二三四五六七八九十\d]+)天(前|后)');
    for (final match in relativeDayNumPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final direction = match.group(2)!;
      final number = _cnNumberToInt(numStr);
      final isFuture = (direction == '后');
      final date = isFuture
          ? referenceDate.add(Duration(days: number))
          : referenceDate.subtract(Duration(days: number));
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // 单独 "X天" => 当月 or 下月
    final singleDayPatternForTian =
    RegExp(r'(?<!月)([一二三四五六七八九十\d]+)天(?!前|后)');
    for (final match in singleDayPatternForTian.allMatches(text)) {
      final numStr = match.group(1)!;
      final day = _cnNumberToInt(numStr);
      if (day <= 0) continue;
      final current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      var candidate = DateTime(current.year, current.month, day);
      if (candidate.isBefore(current)) {
        int nextM = current.month + 1;
        int nextY = current.year;
        if (nextM > 12) {
          nextM -= 12;
          nextY += 1;
        }
        candidate = DateTime(nextY, nextM, day);
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    // (X)周 / (X)个月 / (X)年 (前|后)?
    final relativeNumPattern = RegExp(r'([一二三四五六七八九十\d]+)(周|个月|月|年)(前|后)?');
    for (final match in relativeNumPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final unit = match.group(2)!;
      final direction = match.group(3);
      final number = _cnNumberToInt(numStr);
      final isFuture = (direction != '前'); // "后" or null
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
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // ISO8601
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(
        ParsingResult(
          index: 0,
          text: text,
          component: ParsedComponent(date: parsedDate),
        ),
      );
    } catch (_) {
      // ignore
    }

    // 单独 "X日" / "X号"
    final singleDayPattern = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDayPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final day = _cnNumberToInt(numStr);
      if (day <= 0) continue;
      final current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      var candidate = DateTime(current.year, current.month, day);
      if (candidate.isBefore(current)) {
        int nextM = current.month + 1;
        int nextY = current.year;
        if (nextM > 12) {
          nextM -= 12;
          nextY += 1;
        }
        candidate = DateTime(nextY, nextM, day);
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    return results;
  }

  // ---- Utilities ----
  int _weekdayFromString(String weekday) {
    if (weekday.contains('一')) return DateTime.monday;
    if (weekday.contains('二')) return DateTime.tuesday;
    if (weekday.contains('三')) return DateTime.wednesday;
    if (weekday.contains('四')) return DateTime.thursday;
    if (weekday.contains('五')) return DateTime.friday;
    if (weekday.contains('六')) return DateTime.saturday;
    if (weekday.contains('日') || weekday.contains('天')) return DateTime.sunday;
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
    switch (period) {
      case '下周':
        return reference.add(const Duration(days: 7));
      case '上周':
        return reference.subtract(const Duration(days: 7));
      case '本周':
        return reference;
      case '下个月':
        return DateTime(reference.year, reference.month + 1, reference.day);
      case '上个月':
        return DateTime(reference.year, reference.month - 1, reference.day);
      case '这个月':
        return reference;
      case '明年':
        return DateTime(reference.year + 1, reference.month, reference.day);
      case '去年':
        return DateTime(reference.year - 1, reference.month, reference.day);
      case '今年':
        return reference;
    }
    return reference;
  }

  int _cnNumberToInt(String input) {
    if (RegExp(r'^\d+$').hasMatch(input)) {
      final val = int.parse(input);
      return (val >= 1 && val <= 31) ? val : 0;
    }
    int result = 0;
    if (input.contains('十')) {
      final parts = input.split('十');
      final front = parts[0];
      final back = parts.length > 1 ? parts[1] : '';
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
      for (int i = 0; i < input.length; i++) {
        result += _singleCnDigit(input[i]);
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
// 2) 時刻パーサ (中国語特有: "HH点MM分", "HH时MM分" 等)
//   - 数値フォーマット "HH:MM" は not_language に任せる
//   - 分省略時は00分
//   - 過去なら翌日
// -------------------------------------------------------
class ChineseTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];
    final now = referenceDate;

    // e.g. "16点24分", "16时", etc.
    final timePattern = RegExp(r'(\d{1,2})[点时](\d{1,2})?分?');
    for (final match in timePattern.allMatches(text)) {
      final hourStr = match.group(1)!;
      final minuteStr = match.group(2);
      final hour = int.parse(hourStr);
      int minute = 0;
      if (minuteStr != null && minuteStr.isNotEmpty) {
        minute = int.parse(minuteStr);
      }
      if (hour > 23 || minute > 59) continue;

      var candidate = DateTime(now.year, now.month, now.day, hour, minute);
      // 未来補正
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    return results;
  }
}

// -------------------------------------------------------
// 3) 中国語 Refiner
//    - 日付(0:00) と 時刻(当日/翌日) を同じ箇所であれば統合
// -------------------------------------------------------
class ChineseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return _mergeDateAndTimeResults(results, referenceDate);
  }

  List<ParsingResult> _mergeDateAndTimeResults(List<ParsingResult> results, DateTime referenceDate) {
    results.sort((a, b) => a.index.compareTo(b.index));

    final merged = <ParsingResult>[];
    final used = <int>{};

    for (int i = 0; i < results.length; i++) {
      if (used.contains(i)) continue;
      final rA = results[i];
      bool mergedAny = false;
      final isSameDayA = (rA.date.hour == 0 && rA.date.minute == 0 && rA.date.second == 0);

      for (int j = i + 1; j < results.length; j++) {
        if (used.contains(j)) continue;
        final rB = results[j];
        final isSameDayB = (rB.date.hour == 0 && rB.date.minute == 0 && rB.date.second == 0);

        final distance = rB.index - (rA.index + rA.text.length);
        if (distance.abs() > 3) {
          continue;
        }

        if (isSameDayA && !isSameDayB) {
          merged.add(_combineDateTime(rA, rB));
          used.add(i);
          used.add(j);
          mergedAny = true;
          break;
        } else if (!isSameDayA && isSameDayB) {
          merged.add(_combineDateTime(rB, rA));
          used.add(i);
          used.add(j);
          mergedAny = true;
          break;
        }
      }

      if (!mergedAny) {
        merged.add(rA);
        used.add(i);
      }
    }

    return merged;
  }

  ParsingResult _combineDateTime(ParsingResult dateResult, ParsingResult timeResult) {
    final d = dateResult.date;
    final t = timeResult.date;
    final combined = DateTime(d.year, d.month, d.day, t.hour, t.minute, t.second);
    final newText = dateResult.text + timeResult.text;
    return ParsingResult(
      index: dateResult.index,
      text: newText,
      component: ParsedComponent(date: combined),
    );
  }
}

// lib/languages/ja.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class JapaneseLanguage implements Language {
  @override
  String get code => 'ja';

  @override
  List<Parser> get parsers => [
    JapaneseDateParser(),
    JapaneseTimeParser(),
  ];

  @override
  List<Refiner> get refiners => [JapaneseRefiner()];
}

// -------------------------------------------------------
// 1) JapaneseDateParser
//   - "今日", "明日", "明後日", "先週 月曜", "YYYY年M月D日" etc.
// -------------------------------------------------------
class JapaneseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // (例) "明日", "明後日", "昨日"
    final RegExp relativeDayPattern = RegExp(r'(今日(?!曜日)|明日(?!曜日)|明後日(?!曜日)|明々後日(?!曜日)|昨日(?!曜日))');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == '今日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '明日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched == '明後日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 2));
      } else if (matched == '明々後日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 3));
      } else if (matched == '昨日') {
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

    // (例) "来週 月曜日", "今週 火曜"
    final RegExp weekdayPattern = RegExp(
      r'(来週|先週|今週)?\s*((?:月曜日|月曜|火曜日|火曜|水曜日|水曜|木曜日|木曜|金曜日|金曜|土曜日|土曜|日曜日|日曜))',
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

    // (例) "2024年4月1日"
    final RegExp absoluteDatePattern = RegExp(r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日');
    for (final match in absoluteDatePattern.allMatches(text)) {
      final year = (match.group(1) != null)
          ? int.parse(match.group(1)!)
          : referenceDate.year;
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final date = DateTime(year, month, day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // (例) "来週", "先週", "今年", "来年"など
    final RegExp relativePeriodPattern =
    RegExp(r'(来週|先週|今週|来月|先月|今月|来年|去年|今年)');
    for (final match in relativePeriodPattern.allMatches(text)) {
      final matched = match.group(0)!;
      final date = _getRelativePeriodDate(referenceDate, matched);
      results.add(ParsingResult(
        index: match.start,
        text: matched,
        component: ParsedComponent(date: date),
      ));
    }

    // "X日前", "X日後"
    final RegExp relativeDayNumPattern = RegExp(r'([一二三四五六七八九十\d]+)日(前|後)');
    for (final match in relativeDayNumPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final direction = match.group(2)!;
      final number = _jaNumberToInt(numStr);
      final isFuture = (direction == '後');
      final date = isFuture
          ? referenceDate.add(Duration(days: number))
          : referenceDate.subtract(Duration(days: number));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // "X週間前"/"X週間後"
    final RegExp relativeWeekPattern = RegExp(r'([一二三四五六七八九十\d]+)週間(前|後)');
    for (final match in relativeWeekPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final number = _jaNumberToInt(numStr);
      final direction = match.group(2)!;
      final isFuture = (direction == '後');
      final daysToMove = number * 7;
      final date = isFuture
          ? referenceDate.add(Duration(days: daysToMove))
          : referenceDate.subtract(Duration(days: daysToMove));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // "Xヶ月前"/"Xヶ月後"
    final RegExp relativeMonthPattern = RegExp(r'([一二三四五六七八九十\d]+)ヶ月(前|後)');
    for (final match in relativeMonthPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final number = _jaNumberToInt(numStr);
      final direction = match.group(2)!;
      final isFuture = (direction == '後');
      final date = isFuture
          ? DateTime(referenceDate.year, referenceDate.month + number, referenceDate.day)
          : DateTime(referenceDate.year, referenceDate.month - number, referenceDate.day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // (例) "10日", "15号" (月が書かれていない)
    final RegExp singleDayPattern = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDayPattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final day = _jaNumberToInt(numStr);
      if (day <= 0) continue;

      final current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
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

    return results;
  }

  // -------------- utility -------------
  int _weekdayFromString(String weekday) {
    if (weekday.contains("月")) return DateTime.monday;
    if (weekday.contains("火")) return DateTime.tuesday;
    if (weekday.contains("水")) return DateTime.wednesday;
    if (weekday.contains("木")) return DateTime.thursday;
    if (weekday.contains("金")) return DateTime.friday;
    if (weekday.contains("土")) return DateTime.saturday;
    if (weekday.contains("日")) return DateTime.sunday;
    return DateTime.monday;
  }

  DateTime _getDateForWeekday(DateTime reference, int targetWeekday, String modifier) {
    final current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier.isEmpty || modifier == '今週') {
      if (diff <= 0) diff += 7;
    } else if (modifier == '来週') {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier == '先週') {
      if (diff >= 0) diff -= 7;
    }
    return current.add(Duration(days: diff));
  }

  DateTime _getRelativePeriodDate(DateTime reference, String period) {
    if (period == '来週') {
      return reference.add(const Duration(days: 7));
    } else if (period == '先週') {
      return reference.subtract(const Duration(days: 7));
    } else if (period == '今週') {
      return reference;
    } else if (period == '来月') {
      return DateTime(reference.year, reference.month + 1, reference.day);
    } else if (period == '先月') {
      return DateTime(reference.year, reference.month - 1, reference.day);
    } else if (period == '今月') {
      return reference;
    } else if (period == '来年') {
      return DateTime(reference.year + 1, reference.month, reference.day);
    } else if (period == '去年') {
      return DateTime(reference.year - 1, reference.month, reference.day);
    } else if (period == '今年') {
      return reference;
    }
    return reference;
  }

  int _jaNumberToInt(String input) {
    // すでに数字
    if (RegExp(r'^\d+$').hasMatch(input)) {
      final val = int.parse(input);
      return (val >= 1 && val <= 31) ? val : 0;
    }

    int result = 0;
    if (input.contains('十')) {
      final parts = input.split('十');
      final front = parts[0];
      final back = (parts.length > 1) ? parts[1] : '';

      int tens = 0;
      if (front.isEmpty) {
        tens = 1; // 「十」=> 10
      } else {
        tens = _singleKanjiDigit(front);
      }
      int ones = 0;
      for (int i = 0; i < back.length; i++) {
        ones += _singleKanjiDigit(back[i]);
      }
      result = tens * 10 + ones;
    } else {
      for (int i = 0; i < input.length; i++) {
        result += _singleKanjiDigit(input[i]);
      }
    }
    return (result >= 1 && result <= 31) ? result : 0;
  }

  int _singleKanjiDigit(String ch) {
    switch (ch) {
      case '〇':
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
    }
    return 0;
  }
}

// -------------------------------------------------------
// 2) JapaneseTimeParser
//   - "(\d{1,2}):(\d{1,2})" => 24hフォーマット
//   - "(\d{1,2})時((\d{1,2})分)?" => 例: "17時32分", "17時"
//   - "もっとも近い将来" ロジックあり
// -------------------------------------------------------
class JapaneseTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // A) コロン区切り "HH:MM"
    final RegExp colonPattern = RegExp(r'\b(\d{1,2}):(\d{1,2})\b');
    for (final match in colonPattern.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      if (hour > 23 || minute > 59) continue;

      var candidate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, minute);
      if (candidate.isBefore(referenceDate)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // B) 日本語形式 "HH時MM分" or "HH時"
    final RegExp kanjiPattern = RegExp(r'(\d{1,2})時((\d{1,2})分)?');
    for (final match in kanjiPattern.allMatches(text)) {
      final hourStr = match.group(1)!;
      final minuteStr = match.group(3);
      final hour = int.parse(hourStr);
      int minute = 0;
      if (minuteStr != null && minuteStr.isNotEmpty) {
        minute = int.parse(minuteStr);
      }
      if (hour > 23 || minute > 59) continue;

      var candidate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, minute);
      if (candidate.isBefore(referenceDate)) {
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
// 3) JapaneseRefiner
//   - 日付専用 + 時刻専用 を1つにマージ
// -------------------------------------------------------
class JapaneseRefiner implements Refiner {
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
          final mergedText = current.text + next.text;
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

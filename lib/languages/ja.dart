// lib/languages/ja.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class JapaneseLanguage implements Language {
  @override
  String get code => 'ja';

  @override
  List<Parser> get parsers => [JapaneseDateParser()];

  @override
  List<Refiner> get refiners => [JapaneseRefiner()];
}

class JapaneseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // 【1】相対表現＋時刻（例："明日 17時41分"、"今日 08時"）
    final RegExp relativeDayPattern = RegExp(
        r'(今日(?!曜日)|明日(?!曜日)|明後日(?!曜日)|明々後日(?!曜日)|昨日(?!曜日))(?:\s*(\d{1,2})時(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(1)!;
      DateTime date;
      if (matched == '今日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '明日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 1));
      } else if (matched == '明後日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 2));
      } else if (matched == '明々後日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 3));
      } else if (matched == '昨日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: 1));
      } else {
        date = referenceDate;
      }
      if (match.group(2) != null) {
        int hour = int.parse(match.group(2)!);
        int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
        date = DateTime(date.year, date.month, date.day, hour, minute);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // 【2】曜日表現（例："来週 月曜日" 等）
    final RegExp weekdayPattern = RegExp(
        r'(来週|先週|今週)?\s*((?:月曜日|月曜|火曜日|火曜|水曜日|水曜|木曜日|木曜|金曜日|金曜|土曜日|土曜|日曜日|日曜))'
    );
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

    // 【3】絶対日付＋時刻（例："2024年4月1日 16時31分"、"4月1日"の場合は時刻は0:00）
    final RegExp absoluteDatePattern = RegExp(
        r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})時(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in absoluteDatePattern.allMatches(text)) {
      int year = (match.group(1) != null) ? int.parse(match.group(1)!) : referenceDate.year;
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      DateTime date = DateTime(year, month, day, hour, minute);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // 【4】相対期間（例："来週", "先月" 等）
    final RegExp relativePeriodPattern = RegExp(r'(来週|先週|今週|来月|先月|今月|来年|去年|今年)');
    for (final match in relativePeriodPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date = _getRelativePeriodDate(referenceDate, matched);
      results.add(ParsingResult(
        index: match.start,
        text: matched,
        component: ParsedComponent(date: date),
      ));
    }

    // 【5】「X日前」「X日後」
    final RegExp relativeDayNumPattern = RegExp(r'([一二三四五六七八九十\d]+)日(前|後)');
    for (final match in relativeDayNumPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      String direction = match.group(2)!;
      int number = _jaNumberToInt(numStr);
      bool isFuture = (direction == '後');
      DateTime date = isFuture
          ? referenceDate.add(Duration(days: number))
          : referenceDate.subtract(Duration(days: number));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // 【6】「X週間前」「X週間後」
    final RegExp relativeWeekPattern = RegExp(r'([一二三四五六七八九十\d]+)週間(前|後)');
    for (final match in relativeWeekPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      int number = _jaNumberToInt(numStr);
      String direction = match.group(2)!;
      bool isFuture = (direction == '後');
      int daysToMove = number * 7;
      DateTime date = isFuture
          ? referenceDate.add(Duration(days: daysToMove))
          : referenceDate.subtract(Duration(days: daysToMove));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // 【7】「Xヶ月前」「Xヶ月後」
    final RegExp relativeMonthPattern = RegExp(r'([一二三四五六七八九十\d]+)ヶ月(前|後)');
    for (final match in relativeMonthPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      int number = _jaNumberToInt(numStr);
      String direction = match.group(2)!;
      bool isFuture = (direction == '後');
      DateTime date = isFuture
          ? DateTime(referenceDate.year, referenceDate.month + number, referenceDate.day)
          : DateTime(referenceDate.year, referenceDate.month - number, referenceDate.day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // 【8】単独の「XX日」「XX号」→ 今月または来月の最も近いその日
    final RegExp singleDayPattern = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDayPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      int day = _jaNumberToInt(numStr);
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

    // 【9】時刻のみのパターン（例："16時24分"、"16時"）→ 参照日時より未来の最も近いその時刻
    final RegExp timeOnlyPattern = RegExp(r'\b(\d{1,2})時(?:\s*(\d{1,2})分)?\b');
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
        component: ParsedComponent(date: candidate),
      ));
    }

    return results;
  }

  // 以下、内部ヘルパー関数
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
    DateTime current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier.isEmpty || modifier == '今週') {
      if (diff <= 0) {
        diff += 7;
      }
    } else if (modifier == '来週') {
      if (diff <= 0) {
        diff += 7;
      }
      diff += 7;
    } else if (modifier == '先週') {
      if (diff >= 0) {
        diff -= 7;
      }
    }
    return current.add(Duration(days: diff));
  }

  DateTime _getRelativePeriodDate(DateTime reference, String period) {
    if (period == '来週') {
      return reference.add(Duration(days: 7));
    } else if (period == '先週') {
      return reference.subtract(Duration(days: 7));
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
    if (RegExp(r'^\d+$').hasMatch(input)) {
      final val = int.parse(input);
      return (val >= 1 && val <= 31) ? val : 0;
    }
    int result = 0;
    if (input.contains('十')) {
      final parts = input.split('十');
      final front = parts[0];
      final back  = parts.length > 1 ? parts[1] : '';
      int tens = front.isEmpty ? 1 : _singleKanjiDigit(front);
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
      default:
        return 0;
    }
  }
}

class JapaneseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

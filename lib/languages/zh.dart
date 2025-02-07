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
    // 星期 (下周 星期一, 上周 周三, 本周 礼拜五, 等)
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
    // 绝对日期 (2025年1月1日, 1月1日)
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
    // 数字 + 天/周/个月/年 (+ 前|后) 例: "3天后", "2周前", "5个月后", "2年后" 等
    // 漢数字 (一二三...) も簡易対応
    // ------------------------------
    final RegExp relativeNumPattern = RegExp(r'(\d+|[一二三四五六七八九十]+)(天|周|个月|月|年)(前|后)?');
    for (final match in relativeNumPattern.allMatches(text)) {
      String numStr = match.group(1)!;
      String unit = match.group(2)!;
      String? direction = match.group(3); // 前 or 后 or null
      int number = _cnNumberToInt(numStr);

      bool isFuture = true;
      if (direction == '前') {
        isFuture = false;
      }
      int daysToMove = 0;
      if (unit.contains('天')) {
        daysToMove = number;
      } else if (unit.contains('周')) {
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
    // 標準的な日付文字列 (ISO8601 等) がテキスト全体の場合にパース
    // ------------------------------
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsedDate),
      ));
    } catch (_) {
      // パース失敗なら無視
    }

    // ------------------------------
    // 追加: 「単独の '6日' or '6号'」 => 最も近い「X月6日」
    // ------------------------------
    // \b (\d{1,2})(日|号)\b のようなシンプルなパターン
    final RegExp singleDayPattern = RegExp(r'\b(\d{1,2})(日|号)\b');
    for (final match in singleDayPattern.allMatches(text)) {
      int day = int.parse(match.group(1)!);

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

    return results;
  }

  // ------------------------------
  // ユーティリティ
  // ------------------------------
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
      if (diff <= 0) {
        diff += 7;
      }
    } else if (modifier == '下周') {
      if (diff <= 0) {
        diff += 7;
      }
      diff += 7;
    } else if (modifier == '上周') {
      if (diff >= 0) {
        diff -= 7;
      }
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
    // 既にアラビア数字なら変換
    if (RegExp(r'^\d+$').hasMatch(cnNum)) {
      return int.parse(cnNum);
    }
    // 簡単な漢数字
    switch (cnNum) {
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

class ChineseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

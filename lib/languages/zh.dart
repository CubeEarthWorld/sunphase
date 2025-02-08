// lib/languages/zh.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';
import '../core/merge_datetime_refiner.dart'; // 共通マージ処理をインポート

class ChineseLanguage implements Language {
  @override
  String get code => 'zh';

  @override
  List<Parser> get parsers => [ChineseDateParser()];

  // refiners に共通の MergeDateTimeRefiner を追加
  @override
  List<Refiner> get refiners => [ChineseRefiner(), MergeDateTimeRefiner()];
}

class ChineseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ① 相对日＋时刻：例 "今天 16时24分"
    RegExp relativeDay = RegExp(
        r'(今天|明天|昨天)(?:\s*(\d{1,2})时(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in relativeDay.allMatches(text)) {
      String word = match.group(1)!;
      DateTime date;
      if (word == '今天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (word == '明天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 1));
      } else if (word == '昨天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: 1));
      } else {
        date = referenceDate;
      }
      int hour = 0, minute = 0;
      if (match.group(2) != null) {
        hour = int.parse(match.group(2)!);
      }
      if (match.group(3) != null) {
        minute = int.parse(match.group(3)!);
      }
      date = DateTime(date.year, date.month, date.day, hour, minute);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ② 星期表达：例 "下周 星期一", "周三", "礼拜五"
    RegExp weekdayExp = RegExp(
        r'(下周|上周|本周)?\s*(星期[一二三四五六日]|周[一二三四五六日]|礼拜[一二三四五六日])'
    );
    for (final match in weekdayExp.allMatches(text)) {
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

    // ③ 绝对日期＋时刻：例 "2025年1月1日 16时31分" 或 "1月1日 16时31分"
    RegExp absoluteDate = RegExp(
        r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})时(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in absoluteDate.allMatches(text)) {
      int year = match.group(1) != null ? int.parse(match.group(1)!) : referenceDate.year;
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

    // ④ 相对期间表达：例 "下周", "上个月", "这个月", "明年" 等
    RegExp relativePeriod = RegExp(r'(下周|上周|本周|下个月|上个月|这个月|明年|去年|今年)');
    for (final match in relativePeriod.allMatches(text)) {
      String word = match.group(0)!;
      DateTime date = _getRelativePeriodDate(referenceDate, word);
      results.add(ParsingResult(
        index: match.start,
        text: word,
        component: ParsedComponent(date: date),
      ));
    }

    // ⑤ “X天前”/“X天后”
    RegExp relativeDayNum = RegExp(r'([一二三四五六七八九十\d]+)天(前|后)');
    for (final match in relativeDayNum.allMatches(text)) {
      String numStr = match.group(1)!;
      String direction = match.group(2)!;
      int number = _cnNumberToInt(numStr);
      DateTime date = direction == '后'
          ? referenceDate.add(Duration(days: number))
          : referenceDate.subtract(Duration(days: number));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ⑥ 其他相对数字表达：如 "X周", "X个月", "X年"
    RegExp relativeNum = RegExp(r'([一二三四五六七八九十\d]+)(周|个月|月|年)(前|后)?');
    for (final match in relativeNum.allMatches(text)) {
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

    // ⑦ 日期单独表达：如 "◯日" 或 "◯号" → 当月或下月中最近的该日
    RegExp singleDay = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDay.allMatches(text)) {
      int day = _cnNumberToInt(match.group(1)!);
      if (day <= 0) continue;
      DateTime base = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      DateTime candidate = DateTime(base.year, base.month, day);
      if (base.day > day) {
        int nextMonth = base.month + 1;
        int nextYear = base.year;
        if (nextMonth > 12) {
          nextMonth = 1;
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

    // ※ 时刻单独表达的模式为避免与其他模式冲突，这里不单独抽取

    return results;
  }

  // 以下、内部辅助函数
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
    DateTime base = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - base.weekday;
    if (modifier.isEmpty || modifier == '本周') {
      if (diff <= 0) diff += 7;
    } else if (modifier == '下周') {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier == '上周') {
      if (diff >= 0) diff -= 7;
    }
    return base.add(Duration(days: diff));
  }

  DateTime _getRelativePeriodDate(DateTime reference, String word) {
    if (word == '下周') return reference.add(Duration(days: 7));
    if (word == '上周') return reference.subtract(Duration(days: 7));
    if (word == '本周') return reference;
    if (word == '下个月') return DateTime(reference.year, reference.month + 1, reference.day);
    if (word == '上个月') return DateTime(reference.year, reference.month - 1, reference.day);
    if (word == '这个月') return reference;
    if (word == '明年') return DateTime(reference.year + 1, reference.month, reference.day);
    if (word == '去年') return DateTime(reference.year - 1, reference.month, reference.day);
    if (word == '今年') return reference;
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
      int tens = parts[0].isEmpty ? 1 : _singleCn(parts[0]);
      int ones = parts.length > 1 && parts[1].isNotEmpty ? _singleCn(parts[1]) : 0;
      result = tens * 10 + ones;
    } else {
      result = _singleCn(cnNum);
    }
    return (result >= 1 && result <= 31) ? result : 0;
  }

  int _singleCn(String s) {
    int sum = 0;
    for (int i = 0; i < s.length; i++) {
      switch (s[i]) {
        case '零': case '〇': sum += 0; break;
        case '一': sum += 1; break;
        case '二': sum += 2; break;
        case '三': sum += 3; break;
        case '四': sum += 4; break;
        case '五': sum += 5; break;
        case '六': sum += 6; break;
        case '七': sum += 7; break;
        case '八': sum += 8; break;
        case '九': sum += 9; break;
        case '十': sum += 10; break;
        default: break;
      }
    }
    return sum;
  }
}

class ChineseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

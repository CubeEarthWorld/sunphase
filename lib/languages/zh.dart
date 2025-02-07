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

    // Pattern 1: 相对表达 "今天", "明天", "昨天"
    final RegExp relativeDayPattern = RegExp(r'(今天|明天|昨天)');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == '今天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '明天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).add(Duration(days: 1));
      } else if (matched == '昨天') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).subtract(Duration(days: 1));
      } else {
        date = referenceDate;
      }
      results.add(ParsingResult(
          index: match.start,
          text: matched,
          component: ParsedComponent(date: date)));
    }

    // Pattern 2: 星期的表达（例如："下周 星期一", "上周 周三", "礼拜五"）
    final RegExp weekdayPattern = RegExp(r'(下周|上周|本周)?\s*(星期[一二三四五六日]|周[一二三四五六日]|礼拜[一二三四五六日])');
    for (final match in weekdayPattern.allMatches(text)) {
      String modifier = match.group(1) ?? '';
      String weekdayStr = match.group(2)!;
      int targetWeekday = _weekdayFromString(weekdayStr);
      DateTime date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date)));
    }

    // Pattern 3: 绝对日期表达 (例如："2025年1月1日", "1月1日")
    final RegExp absoluteDatePattern = RegExp(r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日');
    for (final match in absoluteDatePattern.allMatches(text)) {
      int year = match.group(1) != null ? int.parse(match.group(1)!) : referenceDate.year;
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      DateTime date = DateTime(year, month, day);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date)));
    }

    // Pattern 4: 相对时间段表达 (例如："下周", "上个月", "明年", "今年", "去年")
    final RegExp relativePeriodPattern = RegExp(r'(下周|上周|本周|下个月|上个月|这个月|明年|去年|今年)');
    for (final match in relativePeriodPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date = _getRelativePeriodDate(referenceDate, matched);
      results.add(ParsingResult(
          index: match.start,
          text: matched,
          component: ParsedComponent(date: date)));
    }

    return results;
  }

  int _weekdayFromString(String weekday) {
    // Chinese weekday mapping: Monday=1, ..., Sunday=7
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
    DateTime result = current.add(Duration(days: diff));
    if (modifier == '下周') {
      result = result.add(Duration(days: 7));
    } else if (modifier == '上周') {
      result = result.subtract(Duration(days: 7));
    }
    // "本周" 或空修饰符返回当周
    return result;
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
}

class ChineseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // 可根据需要添加重叠结果排除或结果修正
    return results;
  }
}

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

    // Pattern 1: 相対表現「今日」「明日」「昨日」
    final RegExp relativeDayPattern = RegExp(r'(今日|明日|昨日)');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == '今日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '明日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).add(Duration(days: 1));
      } else if (matched == '昨日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).subtract(Duration(days: 1));
      } else {
        date = referenceDate;
      }
      results.add(ParsingResult(
          index: match.start,
          text: matched,
          component: ParsedComponent(date: date)));
    }

    // Pattern 2: 曜日の表現（例：「来週 月曜日」「先週 火曜日」「水曜日」「木」など）
    final RegExp weekdayPattern = RegExp(r'(来週|先週|今週)?\s*(月曜日|火曜日|水曜日|木曜日|金曜日|土曜日|日曜日|月|火|水|木|金|土|日)');
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

    // Pattern 3: 絶対日付の表現（例：「2025年1月1日」「1月1日」）
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

    // Pattern 4: 相対期間の表現（例：「来週」「先月」「来年」「今年」「先週」）
    final RegExp relativePeriodPattern = RegExp(r'(来週|先週|今週|来月|先月|今月|来年|去年|今年)');
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
    // 曜日の変換: 月曜日=1, …, 日曜日=7
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
    DateTime result = current.add(Duration(days: diff));
    if (modifier == '来週') {
      result = result.add(Duration(days: 7));
    } else if (modifier == '先週') {
      result = result.subtract(Duration(days: 7));
    }
    // 「今週」または修飾子がない場合は当週を返す
    return result;
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
}

class JapaneseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // 必要に応じた重複排除や補正処理を実装可能
    return results;
  }
}

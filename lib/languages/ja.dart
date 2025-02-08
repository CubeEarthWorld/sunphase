// lib/languages/ja.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';
import '../core/merge_datetime_refiner.dart'; // 共通マージ処理をインポート

class JapaneseLanguage implements Language {
  @override
  String get code => 'ja';

  @override
  List<Parser> get parsers => [JapaneseDateParser()];

  // refiners に共通の MergeDateTimeRefiner を追加
  @override
  List<Refiner> get refiners => [JapaneseRefiner(), MergeDateTimeRefiner()];
}

class JapaneseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ① 相対表現＋時刻：例 "明日12時21分"
    RegExp relativeDay = RegExp(
        r'(今日|明日|明後日|明々後日|昨日)(?:\s*(\d{1,2})時(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in relativeDay.allMatches(text)) {
      String word = match.group(1)!;
      DateTime date;
      if (word == '今日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (word == '明日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 1));
      } else if (word == '明後日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 2));
      } else if (word == '明々後日') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 3));
      } else if (word == '昨日') {
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

    // ② 曜日表現：例 "来週月曜日", "先週火曜"
    RegExp weekdayExp = RegExp(
        r'(来週|先週|今週)?\s*(月曜日|月曜|火曜日|火曜|水曜日|水曜|木曜日|木曜|金曜日|金曜|土曜日|土曜|日曜日|日曜)'
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

    // ③ 絶対日付＋時刻：例 "2024年2月14日19時31分" または "2月14日19時31分"
    RegExp absoluteDate = RegExp(
        r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})時(?:\s*(\d{1,2})分)?)?'
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

    // ④ 相対期間表現：例 "来週", "先月" など
    RegExp relativePeriod = RegExp(r'(来週|先週|今週|来月|先月|今月|来年|去年|今年)');
    for (final match in relativePeriod.allMatches(text)) {
      String word = match.group(0)!;
      DateTime date = _getRelativePeriodDate(referenceDate, word);
      results.add(ParsingResult(
        index: match.start,
        text: word,
        component: ParsedComponent(date: date),
      ));
    }

    // ⑤ 「X日前」「X日後」
    RegExp relativeDayNum = RegExp(r'([一二三四五六七八九十\d]+)日(前|後)');
    for (final match in relativeDayNum.allMatches(text)) {
      String numStr = match.group(1)!;
      String direction = match.group(2)!;
      int number = _jaNumberToInt(numStr);
      DateTime date = direction == '後'
          ? referenceDate.add(Duration(days: number))
          : referenceDate.subtract(Duration(days: number));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ⑥ 「X週間前」「X週間後」
    RegExp relativeWeek = RegExp(r'([一二三四五六七八九十\d]+)週間(前|後)');
    for (final match in relativeWeek.allMatches(text)) {
      String numStr = match.group(1)!;
      int number = _jaNumberToInt(numStr);
      String direction = match.group(2)!;
      DateTime date = direction == '後'
          ? referenceDate.add(Duration(days: number * 7))
          : referenceDate.subtract(Duration(days: number * 7));
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ⑦ 「Xヶ月前」「Xヶ月後」
    RegExp relativeMonth = RegExp(r'([一二三四五六七八九十\d]+)ヶ月(前|後)');
    for (final match in relativeMonth.allMatches(text)) {
      String numStr = match.group(1)!;
      int number = _jaNumberToInt(numStr);
      String direction = match.group(2)!;
      DateTime date = direction == '後'
          ? DateTime(referenceDate.year, referenceDate.month + number, referenceDate.day)
          : DateTime(referenceDate.year, referenceDate.month - number, referenceDate.day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ⑧ 日付のみ（単独の「◯日」または「◯号」）→ 今月または来月の最も近いその日
    RegExp singleDay = RegExp(r'(?<!月)([一二三四五六七八九十\d]+)(日|号)');
    for (final match in singleDay.allMatches(text)) {
      int day = _jaNumberToInt(match.group(1)!);
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

    // ※ 時刻のみのパターンは、他のパターンと重複しないように除外しています。

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
    DateTime base = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - base.weekday;
    if (modifier.isEmpty || modifier == '本周') {
      if (diff <= 0) diff += 7;
    } else if (modifier == '来周' || modifier == '来週') {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier == '上周' || modifier == '先週') {
      if (diff >= 0) diff -= 7;
    }
    return base.add(Duration(days: diff));
  }

  DateTime _getRelativePeriodDate(DateTime reference, String word) {
    if (word == '来週') return reference.add(Duration(days: 7));
    if (word == '先週') return reference.subtract(Duration(days: 7));
    if (word == '今週') return reference;
    if (word == '来月') return DateTime(reference.year, reference.month + 1, reference.day);
    if (word == '先月') return DateTime(reference.year, reference.month - 1, reference.day);
    if (word == '今月') return reference;
    if (word == '来年') return DateTime(reference.year + 1, reference.month, reference.day);
    if (word == '去年') return DateTime(reference.year - 1, reference.month, reference.day);
    if (word == '今年') return reference;
    return reference;
  }

  int _jaNumberToInt(String input) {
    if (RegExp(r'^\d+$').hasMatch(input)) {
      int val = int.parse(input);
      return (val >= 1 && val <= 31) ? val : 0;
    }
    int result = 0;
    if (input.contains('十')) {
      List<String> parts = input.split('十');
      int tens = parts[0].isEmpty ? 1 : _singleKanji(parts[0]);
      int ones = parts.length > 1 && parts[1].isNotEmpty ? _singleKanji(parts[1]) : 0;
      result = tens * 10 + ones;
    } else {
      result = _singleKanji(input);
    }
    return (result >= 1 && result <= 31) ? result : 0;
  }

  int _singleKanji(String s) {
    int sum = 0;
    for (int i = 0; i < s.length; i++) {
      switch (s[i]) {
        case '〇': case '零': sum += 0; break;
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

class JapaneseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

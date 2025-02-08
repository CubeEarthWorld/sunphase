// lib/languages/en.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';
import '../core/merge_datetime_refiner.dart'; // 共通マージ処理をインポート

class EnglishLanguage implements Language {
  @override
  String get code => 'en';

  @override
  List<Parser> get parsers => [EnglishDateParser()];

  // refiners に共通の MergeDateTimeRefiner を追加
  @override
  List<Refiner> get refiners => [EnglishRefiner(), MergeDateTimeRefiner()];
}

class EnglishDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ① 相対表現＋時刻：例 "today 16:31", "tomorrow 08:00"
    RegExp relativeDay = RegExp(
      r'(today|tomorrow|yesterday)(?:\s+(\d{1,2}):(\d{2}))?',
      caseSensitive: false,
    );
    for (final match in relativeDay.allMatches(text)) {
      String word = match.group(1)!.toLowerCase();
      DateTime date;
      if (word == 'today') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (word == 'tomorrow') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(Duration(days: 1));
      } else if (word == 'yesterday') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: 1));
      } else {
        date = referenceDate;
      }
      int hour = 0, minute = 0;
      if (match.group(2) != null && match.group(3) != null) {
        hour = int.parse(match.group(2)!);
        minute = int.parse(match.group(3)!);
      }
      date = DateTime(date.year, date.month, date.day, hour, minute);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ② 曜日表現：例 "next Monday", "last Tuesday"
    RegExp weekdayExp = RegExp(
      r'(?:(next|last|this)\s+)?(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)',
      caseSensitive: false,
    );
    for (final match in weekdayExp.allMatches(text)) {
      String? modifier = match.group(1)?.toLowerCase();
      String weekdayStr = match.group(2)!;
      int targetWeekday = _weekdayFromString(weekdayStr);
      DateTime date = _getDateForWeekday(referenceDate, targetWeekday, modifier);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ③ 絶対日付＋時刻（英語）: 例 "August 17, 2013 18:40"
    RegExp absoluteDate = RegExp(
        r'(?:([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4}))(?:\s+(\d{1,2}):(\d{2}))?'
    );
    for (final match in absoluteDate.allMatches(text)) {
      String monthStr = match.group(1)!;
      int day = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);
      int month = _monthFromString(monthStr);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      DateTime date = DateTime(year, month, day, hour, minute);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ④ ISO/数字形式の絶対日付＋時刻: 例 "2013-08-17 18:40"
    RegExp isoDate = RegExp(
        r'(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T]+(\d{1,2}):(\d{2}))?'
    );
    for (final match in isoDate.allMatches(text)) {
      int year = int.parse(match.group(1)!);
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

    // ⑤ 日付のみ: 例 "8/17/2013"（時刻は 00:00）
    RegExp mdy = RegExp(
        r'(\d{1,2})/(\d{1,2})/(\d{4})'
    );
    for (final match in mdy.allMatches(text)) {
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);
      DateTime date = DateTime(year, month, day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ⑥ 時刻のみ（数字形式）: 例 "16:21" → 参照日付に対して最も近い未来の時刻
    RegExp timeOnly = RegExp(r'(?<!\d)(\d{1,2}):(\d{2})(?!\d)');
    for (final match in timeOnly.allMatches(text)) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
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
    switch (weekday.toLowerCase()) {
      case 'monday': return DateTime.monday;
      case 'tuesday': return DateTime.tuesday;
      case 'wednesday': return DateTime.wednesday;
      case 'thursday': return DateTime.thursday;
      case 'friday': return DateTime.friday;
      case 'saturday': return DateTime.saturday;
      case 'sunday': return DateTime.sunday;
      default: return DateTime.monday;
    }
  }

  DateTime _getDateForWeekday(DateTime reference, int targetWeekday, String? modifier) {
    DateTime base = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - base.weekday;
    if (modifier == null || modifier.isEmpty || modifier == 'this') {
      if (diff <= 0) diff += 7;
    } else if (modifier == 'next') {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier == 'last') {
      if (diff >= 0) diff -= 7;
    }
    return base.add(Duration(days: diff));
  }

  int _monthFromString(String month) {
    switch (month.toLowerCase()) {
      case 'january': case 'jan': return 1;
      case 'february': case 'feb': return 2;
      case 'march': case 'mar': return 3;
      case 'april': case 'apr': return 4;
      case 'may': return 5;
      case 'june': case 'jun': return 6;
      case 'july': case 'jul': return 7;
      case 'august': case 'aug': return 8;
      case 'september': case 'sep': return 9;
      case 'october': case 'oct': return 10;
      case 'november': case 'nov': return 11;
      case 'december': case 'dec': return 12;
      default: return 0;
    }
  }
}

class EnglishRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

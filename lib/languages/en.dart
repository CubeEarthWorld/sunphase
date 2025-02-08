// lib/language/en.dart
import '../core/parser.dart';
import '../core/result.dart';

/// 英語表現に対応するパーサー実装例
class EnglishDateParser implements Parser {
  // 1. 月名表現："june 20", "june 20, 2024"（大文字小文字を区別しない）
  final RegExp monthNamePattern = RegExp(
      r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:,\s*(\d{4}))?\b',
      caseSensitive: false);

  // 2. relative with time: "tomorrow 7 pm", "today 12:41", "yesterday 3:15"
  final RegExp relativeWithTimePattern = RegExp(
      r'\b(tomorrow|today|yesterday)\s+(\d{1,2})(?::(\d{1,2}))?\s*(am|pm)?\b',
      caseSensitive: false);

  // 3. relative expressions: "today", "tomorrow", "yesterday", "now"
  final RegExp relativePattern = RegExp(r'\b(today|tomorrow|yesterday|now)\b', caseSensitive: false);

  // 4. ISO-like・数値表現（年あり）："2024-02-24", "2012-4-4 12:41"
  final RegExp isoPattern = RegExp(
      r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})(?::(\d{1,2}))?)?\b');

  // 5. time-only 表現："4:12", "4 pm"
  final RegExp timeOnlyPattern = RegExp(
      r'\b(\d{1,2})(?::(\d{1,2}))?\s*(am|pm)?\b',
      caseSensitive: false);

  // 6. interval 表現："next week", "two weeks ago", "3 days ago", etc.
  final RegExp intervalPattern = RegExp(
      r'\b(?:(next|last|two|three|\d+)\s+)?(week|month|day|hour|minute|second)s?\b',
      caseSensitive: false);

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // (1) 月名表現
    var match = monthNamePattern.firstMatch(text);
    if (match != null) {
      String monthStr = match.group(1)!;
      int day = int.parse(match.group(2)!);
      int year = match.group(3) != null ? int.parse(match.group(3)!) : referenceDate.year;
      int month = _monthFromName(monthStr);
      ParsedComponents comp = ParsedComponents(
          year: year, month: month, day: day, hour: 0, minute: 0, second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (2) relative with time
    match = relativeWithTimePattern.firstMatch(text);
    if (match != null) {
      String rel = match.group(1)!.toLowerCase();
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      String? meridiem = match.group(4)?.toLowerCase();
      if (meridiem != null) {
        if (meridiem == 'pm' && hour < 12) hour += 12;
        else if (meridiem == 'am' && hour == 12) hour = 0;
      }
      DateTime base;
      if (rel == 'today') base = referenceDate;
      else if (rel == 'tomorrow') base = referenceDate.add(Duration(days: 1));
      else if (rel == 'yesterday') base = referenceDate.subtract(Duration(days: 1));
      else base = referenceDate;
      ParsedComponents comp = ParsedComponents(
          year: base.year,
          month: base.month,
          day: base.day,
          hour: hour,
          minute: minute,
          second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (3) relative expressions only
    match = relativePattern.firstMatch(text);
    if (match != null) {
      String word = match.group(1)!.toLowerCase();
      DateTime dt;
      if (word == 'today' || word == 'now') dt = referenceDate;
      else if (word == 'tomorrow') dt = referenceDate.add(Duration(days: 1));
      else if (word == 'yesterday') dt = referenceDate.subtract(Duration(days: 1));
      else dt = referenceDate;
      ParsedComponents comp = ParsedComponents(
          year: dt.year, month: dt.month, day: dt.day, hour: 0, minute: 0, second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (4) ISO-like（年あり）の日付・時刻
    match = isoPattern.firstMatch(text);
    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: year, month: month, day: day, hour: hour, minute: minute, second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (5) time-only 表現
    match = timeOnlyPattern.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      String? meridiem = match.group(3)?.toLowerCase();
      if (meridiem != null) {
        if (meridiem == 'pm' && hour < 12) hour += 12;
        else if (meridiem == 'am' && hour == 12) hour = 0;
      }
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: hour,
          minute: minute,
          second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (6) interval 表現 ("next week", "two weeks ago", etc.)
    match = intervalPattern.firstMatch(text);
    if (match != null) {
      String? modifier = match.group(1)?.toLowerCase();
      String unit = match.group(2)!.toLowerCase();
      int quantity = 1;
      if (modifier != null) {
        if (modifier == 'next') quantity = 1;
        else if (modifier == 'last') quantity = -1;
        else if (modifier == 'two') quantity = 2;
        else if (modifier == 'three') quantity = 3;
        else quantity = int.tryParse(modifier) ?? 1;
      }
      DateTime dt = referenceDate;
      if (unit == 'week') dt = dt.add(Duration(days: 7 * quantity));
      else if (unit == 'day') dt = dt.add(Duration(days: quantity));
      else if (unit == 'month') dt = DateTime(dt.year, dt.month + quantity, dt.day);
      else if (unit == 'hour') dt = dt.add(Duration(hours: quantity));
      else if (unit == 'minute') dt = dt.add(Duration(minutes: quantity));
      else if (unit == 'second') dt = dt.add(Duration(seconds: quantity));
      ParsedComponents comp = ParsedComponents(
          year: dt.year, month: dt.month, day: dt.day, hour: dt.hour, minute: dt.minute, second: dt.second);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    return null;
  }

  int _monthFromName(String month) {
    switch (month.toLowerCase()) {
      case 'january': return 1;
      case 'february': return 2;
      case 'march': return 3;
      case 'april': return 4;
      case 'may': return 5;
      case 'june': return 6;
      case 'july': return 7;
      case 'august': return 8;
      case 'september': return 9;
      case 'october': return 10;
      case 'november': return 11;
      case 'december': return 12;
      default: return 0;
    }
  }
}

/// 英語用パーサーリスト
List<Parser> parsers = [
  EnglishDateParser(),
];

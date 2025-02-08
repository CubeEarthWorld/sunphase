// lib/languages/en.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// Parser for relative expressions in English.
/// (e.g., "Today", "Tomorrow", "Yesterday", "Next week", "Last Sunday", "2 weeks from now", etc.)
class EnRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    String lowerText = text.toLowerCase();
    DateTime ref = context.referenceDate;

    // "today"
    if (lowerText.contains("today")) {
      results.add(ParsingResult(
          index: lowerText.indexOf("today"),
          text: "Today",
          date: DateTime(ref.year, ref.month, ref.day, 0, 0, 0)));
    }
    // "tomorrow"
    if (lowerText.contains("tomorrow")) {
      DateTime tomorrow = DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1));
      results.add(ParsingResult(
          index: lowerText.indexOf("tomorrow"),
          text: "Tomorrow",
          date: tomorrow));
    }
    // "yesterday"
    if (lowerText.contains("yesterday")) {
      DateTime yesterday = DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1));
      results.add(ParsingResult(
          index: lowerText.indexOf("yesterday"),
          text: "Yesterday",
          date: yesterday));
    }
    // "next week"
    if (lowerText.contains("next week")) {
      DateTime nextWeek = ref.add(Duration(days: 7));
      results.add(ParsingResult(
          index: lowerText.indexOf("next week"),
          text: "Next week",
          date: nextWeek));
    }
    // "last week"
    if (lowerText.contains("last week")) {
      DateTime lastWeek = ref.subtract(Duration(days: 7));
      results.add(ParsingResult(
          index: lowerText.indexOf("last week"),
          text: "Last week",
          date: lastWeek));
    }
    // "next month"
    if (lowerText.contains("next month")) {
      DateTime nextMonth = DateTime(ref.year, ref.month + 1, ref.day);
      results.add(ParsingResult(
          index: lowerText.indexOf("next month"),
          text: "Next month",
          date: nextMonth));
    }
    // "last month"
    if (lowerText.contains("last month")) {
      DateTime lastMonth = DateTime(ref.year, ref.month - 1, ref.day);
      results.add(ParsingResult(
          index: lowerText.indexOf("last month"),
          text: "Last month",
          date: lastMonth));
    }
    // "last friday"
    if (lowerText.contains("last friday")) {
      DateTime lastFriday = ref.subtract(Duration(days: 7));
      results.add(ParsingResult(
          index: lowerText.indexOf("last friday"),
          text: "Last Friday",
          date: lastFriday));
    }
    // "last sunday"
    if (lowerText.contains("last sunday")) {
      // In ISO, Sunday is 7. To get last Sunday, subtract ref.weekday (if ref is not Sunday) or 7 if Sunday.
      int subtractDays = ref.weekday % 7 == 0 ? 7 : ref.weekday;
      DateTime lastSunday = ref.subtract(Duration(days: subtractDays));
      results.add(ParsingResult(
          index: lowerText.indexOf("last sunday"),
          text: "Last Sunday",
          date: DateTime(lastSunday.year, lastSunday.month, lastSunday.day, 0, 0, 0)));
    }
    // "this friday" with time extraction
    if (lowerText.contains("this friday")) {
      RegExp timeRegExp = RegExp(r'from\s*(\d{1,2}):(\d{2})');
      RegExpMatch? match = timeRegExp.firstMatch(lowerText);
      int targetWeekday = 5; // Friday
      int daysUntilFriday = (targetWeekday - ref.weekday + 7) % 7;
      // If today is already Friday, use today (0 days)
      if (ref.weekday == targetWeekday) {
        daysUntilFriday = 0;
      }
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        DateTime thisFriday = DateTime(ref.year, ref.month, ref.day, hour, minute)
            .add(Duration(days: daysUntilFriday));
        results.add(ParsingResult(
            index: lowerText.indexOf("this friday"),
            text: "This Friday from ${match.group(1)}:${match.group(2)}",
            date: thisFriday));
      }
    }
    // Relative expressions: e.g., "2 weeks from now", "4 days later", "5 days ago"
    RegExp regExp = RegExp(r'(\d+)\s*(days|weeks)\s*(from now|later|ago)');
    Iterable<RegExpMatch> matches = regExp.allMatches(lowerText);
    for (var match in matches) {
      int value = int.parse(match.group(1)!);
      String unit = match.group(2)!;
      String direction = match.group(3)!;
      Duration delta = unit.startsWith('day') ? Duration(days: value) : Duration(days: value * 7);
      DateTime resultDate = (direction == 'ago') ? ref.subtract(delta) : ref.add(delta);
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: resultDate));
    }
    return results;
  }
}

/// Parser for absolute date expressions in English.
/// (e.g., "August 17 2013", "17 August 2013", "june 20")
class EnAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // Regex to detect expressions with optional year.
    RegExp regExp = RegExp(
        r'(\b(?:[a-z]+)\s+\d{1,2}(?:\s*,?\s*\d{4})?\b)|(\b\d{1,2}\s+(?:[a-z]+)(?:\s*,?\s*\d{4})?\b)',
        caseSensitive: false);
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      String dateStr = match.group(0)!;
      DateTime? parsedDate = _parseEnglishDate(dateStr, context);
      if (parsedDate != null) {
        results.add(ParsingResult(index: match.start, text: dateStr, date: parsedDate));
      }
    }
    return results;
  }

  /// Parses an English date string.
  /// Supports formats like "june 20" or "june 20, 2025".
  DateTime? _parseEnglishDate(String dateStr, ParsingContext context) {
    Map<String, int> monthMap = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    dateStr = dateStr.toLowerCase().trim();
    // Pattern: month day [year]
    RegExp pattern = RegExp(r'^([a-z]+)\s+(\d{1,2})(?:\s*,?\s*(\d{4}))?$');
    RegExpMatch? m = pattern.firstMatch(dateStr);
    if (m != null) {
      String monthStr = m.group(1)!;
      int? month = monthMap[monthStr];
      int day = int.parse(m.group(2)!);
      int year;
      if (m.group(3) != null) {
        year = int.parse(m.group(3)!);
      } else {
        year = context.referenceDate.year;
        DateTime candidate = DateTime(year, month!, day);
        if (candidate.isBefore(context.referenceDate)) {
          year += 1;
        }
      }
      if (month != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}

/// Parser for time-only expressions in English.
/// (e.g., "12:41")
class EnTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    RegExp regExp = RegExp(r'\b(\d{1,2}):(\d{2})\b');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      DateTime candidate = DateTime(context.referenceDate.year, context.referenceDate.month, context.referenceDate.day, hour, minute);
      if (candidate.isBefore(context.referenceDate)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
    return results;
  }
}

/// 英語パーサー群の集合
class EnParsers {
  static final List<BaseParser> parsers = [
    EnRelativeParser(),
    EnAbsoluteParser(),
    EnTimeOnlyParser(),
  ];
}

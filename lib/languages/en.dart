// lib/languages/en.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// Parser for relative expressions in English.
class EnRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    String lowerText = text.toLowerCase().trim();
    DateTime ref = context.referenceDate;

    // "in X days" → range expression; ※ここでは今日を含むため rangeDays = X+1
    RegExp inDays = RegExp(r'in\s+(\d+)\s+days');
    RegExpMatch? mInDays = inDays.firstMatch(lowerText);
    if (mInDays != null) {
      int days = int.parse(mInDays.group(1)!);
      results.add(ParsingResult(
          index: mInDays.start,
          text: mInDays.group(0)!,
          date: ref,
          rangeDays: days + 1));
    }

    // "next week" → range expression; set rangeType = "week"
    if (lowerText == "next week") {
      // Define next week’s start as next Monday.
      int daysToNextMonday = (8 - ref.weekday) % 7;
      if (daysToNextMonday == 0) daysToNextMonday = 7;
      DateTime nextMonday = DateTime(ref.year, ref.month, ref.day)
          .add(Duration(days: daysToNextMonday));
      results.add(ParsingResult(
          index: 0,
          text: "next week",
          date: nextMonday,
          rangeType: "week"));
    }

    // Fixed expressions
    if (lowerText == "today") {
      results.add(ParsingResult(
          index: 0,
          text: "Today",
          date: DateTime(ref.year, ref.month, ref.day, 0, 0, 0)));
    }
    if (lowerText == "tomorrow") {
      DateTime tomorrow =
      DateTime(ref.year, ref.month, ref.day).add(Duration(days: 1));
      results.add(ParsingResult(index: 0, text: "Tomorrow", date: tomorrow));
    }
    if (lowerText == "yesterday") {
      DateTime yesterday =
      DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: 1));
      results.add(ParsingResult(index: 0, text: "Yesterday", date: yesterday));
    }
    if (lowerText == "next year") {
      DateTime nextYear = DateTime(ref.year + 1, ref.month, ref.day, ref.hour,
          ref.minute, ref.second);
      results.add(ParsingResult(index: 0, text: "Next year", date: nextYear));
    }
    if (lowerText == "last year") {
      DateTime lastYear = DateTime(ref.year - 1, ref.month, ref.day, ref.hour,
          ref.minute, ref.second);
      results.add(ParsingResult(index: 0, text: "Last year", date: lastYear));
    }

    // Weekday exact match (e.g. "saturday")
    Map<String, int> weekdayMap = {
      "monday": 1,
      "tuesday": 2,
      "wednesday": 3,
      "thursday": 4,
      "friday": 5,
      "saturday": 6,
      "sunday": 7,
    };
    if (weekdayMap.containsKey(lowerText)) {
      int target = weekdayMap[lowerText]!;
      int diff = (target - ref.weekday + 7) % 7;
      if (diff == 0) diff = 7;
      DateTime targetDate =
      DateTime(ref.year, ref.month, ref.day).add(Duration(days: diff));
      results.add(ParsingResult(index: 0, text: lowerText, date: targetDate));
    }

    // Phrases "next <weekday>" and "last <weekday>"
    for (var entry in weekdayMap.entries) {
      String nextPhrase = "next " + entry.key;
      String lastPhrase = "last " + entry.key;
      if (lowerText == nextPhrase) {
        int current = ref.weekday;
        int target = entry.value;
        int daysToAdd = (target - current + 7) % 7;
        if (daysToAdd == 0) daysToAdd = 7;
        DateTime targetDate =
        DateTime(ref.year, ref.month, ref.day).add(Duration(days: daysToAdd));
        results.add(ParsingResult(index: 0, text: nextPhrase, date: targetDate));
      }
      if (lowerText == lastPhrase) {
        int current = ref.weekday;
        int target = entry.value;
        int daysToSubtract = current - target;
        if (daysToSubtract <= 0) daysToSubtract += 7;
        DateTime targetDate =
        DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: daysToSubtract));
        results.add(ParsingResult(index: 0, text: lastPhrase, date: targetDate));
      }
    }

    // Relative expressions with numbers (e.g. "2 weeks from now", "4 days later", "5 days ago")
    Map<String, int> numberMap = {
      "one": 1,
      "two": 2,
      "three": 3,
      "four": 4,
      "five": 5,
      "six": 6,
      "seven": 7,
      "eight": 8,
      "nine": 9,
      "ten": 10,
    };
    RegExp relExp =
    RegExp(r'(\d+|[a-z]+)\s*(days|weeks)\s*(from now|later|ago)');
    Iterable<RegExpMatch> matches = relExp.allMatches(lowerText);
    for (var match in matches) {
      String numStr = match.group(1)!;
      int value = int.tryParse(numStr) ?? (numberMap[numStr] ?? 0);
      String unit = match.group(2)!;
      String direction = match.group(3)!;
      Duration delta = unit.startsWith('day')
          ? Duration(days: value)
          : Duration(days: value * 7);
      DateTime resultDate =
      (direction == 'ago') ? ref.subtract(delta) : ref.add(delta);
      results.add(ParsingResult(
          index: match.start, text: match.group(0)!, date: resultDate));
    }

    return results;
  }
}

/// Parser for absolute date expressions in English.
class EnAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // Regex to capture expressions like "june 20" or "august 17, 2025"
    RegExp regExp =
    RegExp(r'([a-z]+)[\s,]+(\d{1,2})(?:[\s,]+(\d{4}))?', caseSensitive: false);
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
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
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    for (var match in matches) {
      String possibleMonth = match.group(1)!;
      if (!monthMap.containsKey(possibleMonth.toLowerCase())) continue;
      String dateStr = match.group(0)!;
      DateTime? parsedDate =
      _parseEnglishDate(dateStr, context, monthMap: monthMap);
      if (parsedDate != null) {
        results.add(ParsingResult(index: match.start, text: dateStr, date: parsedDate));
      }
    }
    return results;
  }

  DateTime? _parseEnglishDate(String dateStr, ParsingContext context,
      {required Map<String, int> monthMap}) {
    dateStr = dateStr.toLowerCase().trim();
    RegExp pattern = RegExp(r'^([a-z]+)[\s,]+(\d{1,2})(?:[\s,]+(\d{4}))?$');
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
        if (!candidate.isAfter(context.referenceDate)) {
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
class EnTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    String lowerText = text.toLowerCase().trim();
    DateTime ref = context.referenceDate;

    if (lowerText == "midnight") {
      DateTime candidate = DateTime(ref.year, ref.month, ref.day, 0, 0, 0);
      if (!candidate.isAfter(ref)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(index: 0, text: "Midnight", date: candidate));
    } else if (lowerText == "noon") {
      DateTime candidate = DateTime(ref.year, ref.month, ref.day, 12, 0, 0);
      results.add(ParsingResult(index: 0, text: "Noon", date: candidate));
    } else {
      RegExp regExp = RegExp(r'^(\d{1,2}):(\d{2})$');
      RegExpMatch? m = regExp.firstMatch(lowerText);
      if (m != null) {
        int hour = int.parse(m.group(1)!);
        int minute = int.parse(m.group(2)!);
        DateTime candidate = DateTime(ref.year, ref.month, ref.day, hour, minute);
        if (!candidate.isAfter(ref)) {
          candidate = candidate.add(Duration(days: 1));
        }
        results.add(ParsingResult(index: 0, text: lowerText, date: candidate));
      }
    }
    return results;
  }
}

/// English parsers collection.
class EnParsers {
  static final List<BaseParser> parsers = [
    EnRelativeParser(),
    EnAbsoluteParser(),
    EnTimeOnlyParser(),
  ];
}

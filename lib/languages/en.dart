// lib/languages/en.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// 英語表現に対応する相対表現パーサー。
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
    // 追加の相対表現を必要に応じて実装可能

    return results;
  }
}

/// 英語表現に対応する絶対表現パーサー。
class EnAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // "August 17 2013" や "17 August 2013" 形式を検出する正規表現
    RegExp regExp = RegExp(
        r'(\b\d{1,2}\b\s*(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s*\b\d{4}\b)|((?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s*\b\d{1,2}\b\s*\b\d{4}\b)',
        caseSensitive: false);
    Iterable<RegExpMatch> matches = regExp.allMatches(text);
    for (var match in matches) {
      String dateStr = match.group(0)!;
      DateTime? parsedDate = _parseEnglishDate(dateStr);
      if (parsedDate != null) {
        results.add(ParsingResult(index: match.start, text: dateStr, date: parsedDate));
      }
    }
    return results;
  }

  /// 簡易的な英語日付文字列のパース（例："17 august 2013"）
  DateTime? _parseEnglishDate(String dateStr) {
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
    dateStr = dateStr.toLowerCase();
    RegExp pattern1 = RegExp(r'(\d{1,2})\s*(\w+)\s*(\d{4})');
    RegExp pattern2 = RegExp(r'(\w+)\s*(\d{1,2})\s*(\d{4})');
    RegExpMatch? m = pattern1.firstMatch(dateStr) ?? pattern2.firstMatch(dateStr);
    if (m != null) {
      int day = int.parse(m.group(1)!);
      String monthStr = m.group(2)!;
      int? month = monthMap[monthStr];
      int year = int.parse(m.group(3)!);
      if (month != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}

/// 英語パーサー群をまとめたクラス。
class EnParsers {
  static final List<BaseParser> parsers = [
    EnRelativeParser(),
    EnAbsoluteParser(),
  ];
}

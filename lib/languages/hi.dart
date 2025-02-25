// lib/languages/hi.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// Hindi 固有のユーティリティ
class HiDateUtils {
  static const Map<String, int> monthMap = {
    "जनवरी": 1,
    "फरवरी": 2,
    "मार्च": 3,
    "अप्रैल": 4,
    "मई": 5,
    "जून": 6,
    "जुलाई": 7,
    "अगस्त": 8,
    "सितंबर": 9,
    "अक्टूबर": 10,
    "नवंबर": 11,
    "दिसंबर": 12,
  };

  static const Map<String, int> weekdayMap = {
    "सोमवार": 1,
    "मंगलवार": 2,
    "बुधवार": 3,
    "गुरुवार": 4,
    "शुक्रवार": 5,
    "शनिवार": 6,
    "रविवार": 7,
  };

  static const Map<String, int> relativeDayOffsets = {
    "आज": 0,
    "कल": 1,
    "परसों": 2,
  };
}

/// Hindi 相対表現パーサー
class HiRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // "आज", "कल", "परसों" をチェック
    HiDateUtils.relativeDayOffsets.forEach((word, offset) {
      if (text.contains(word)) {
        int index = text.indexOf(word);
        DateTime date = DateTime(
            context.referenceDate.year,
            context.referenceDate.month,
            context.referenceDate.day)
            .add(Duration(days: offset));
        results.add(ParsingResult(index: index, text: word, date: DateTime(date.year, date.month, date.day, 0,0,0)));
      }
    });
    // 「3 दिन पहले」または「3 दिन बाद」
    RegExp relExp = RegExp(r'(\d+|[एकदोतीनचारपांचछहसातआठनौ]+)\s*दिन\s*(पहले|बाद)');
    for (final match in relExp.allMatches(text)) {
      int num = int.tryParse(match.group(1)!) ?? 0;
      // ここでは「बाद」は未来、「पहले」は過去
      int offset = match.group(2) == "बाद" ? num : -num;
      DateTime date = DateTime(
          context.referenceDate.year,
          context.referenceDate.month,
          context.referenceDate.day)
          .add(Duration(days: offset));
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }
}

/// Hindi 絶対表現パーサー
/// 例："14 मार्च 2025" または "14 मार्च"
class HiAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // パターン: 日付＋माह＋(वर्ष)　例："14 मार्च 2025" または "14 मार्च"
    RegExp reg = RegExp(r'(\d{1,2})\s*([^\s\d]+)(?:\s*(\d{4}))?');
    for (final match in reg.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      String monthStr = match.group(2)!;
      int? month = HiDateUtils.monthMap[monthStr];
      if (month == null) continue;
      int year = match.group(3) != null ? int.parse(match.group(3)!) : context.referenceDate.year;
      DateTime date = DateTime(year, month, day);
      if (match.group(3) == null && date.isBefore(context.referenceDate)) {
        date = DateTime(year + 1, month, day);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }
}

/// Hindi 時刻表現パーサー
/// 例："सुबह 10:10", "14:30"
class HiTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 時刻パターン： (सुबह|दोपहर|शाम|रात)?\s*(\d{1,2})(?::(\d{2}))?
    RegExp timeExp = RegExp(r'(सुबह|दोपहर|शाम|रात)?\s*(\d{1,2})(?::(\d{2}))?');
    for (final match in timeExp.allMatches(text)) {
      String period = match.group(1) ?? "";
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      // "दोपहर", "शाम", "रात" なら PM（12時加算）を適用
      if ((period == "दोपहर" || period == "शाम" || period == "रात") && hour < 12) {
        hour += 12;
      }
      DateTime date = DateUtils.nextOccurrenceTime(context.referenceDate, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }
}

/// Hindi 日付のみパーサー（例："15 तारीख"）
class HiDayOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    RegExp reg = RegExp(r'(\d{1,2})\s*तारीख');
    for (final match in reg.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      DateTime candidate = DateTime(context.referenceDate.year, context.referenceDate.month, day);
      if (candidate.isBefore(context.referenceDate)) {
        candidate = DateTime(context.referenceDate.year, context.referenceDate.month + 1, day);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: candidate));
    }
    return results;
  }
}

/// Hindi 曜日表現パーサー（単独の曜日）
class HiWeekdayParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    HiDateUtils.weekdayMap.forEach((weekday, value) {
      if (text.contains(weekday)) {
        int index = text.indexOf(weekday);
        DateTime candidate = DateUtils.nextWeekday(context.referenceDate, value);
        results.add(ParsingResult(index: index, text: weekday, date: DateTime(candidate.year, candidate.month, candidate.day, 0, 0, 0)));
      }
    });
    return results;
  }
}

/// Hindi 範囲表現パーサー（例："अगले महीने की योजना"）
class HiRangeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    String lower = text;
    // "अगले महीने" を検出
    if (lower.contains("अगले महीने")) {
      // 基準日が फरवरी なら अगले महीने = मार्च
      DateTime firstDay = DateUtils.firstDayOfNextMonth(context.referenceDate);
      results.add(ParsingResult(
          index: 0, text: "अगले महीने", date: firstDay, rangeType: "month"));
    }

    // "पिछले शुक्रवार"
    if (lower.contains("पिछले शुक्रवार")) {
      DateTime lastFriday = DateUtils.nextWeekday(context.referenceDate, 5).subtract(Duration(days:7));
      results.add(ParsingResult(
          index: 0, text: "पिछले शुक्रवार", date: DateTime(lastFriday.year, lastFriday.month, lastFriday.day, 0, 0, 0)));
    }
    // "2 सप्ताह बाद"
    RegExp twoWeeksLater = RegExp(r'2\s*सप्ताह\s*बाद', caseSensitive: false);
    for (final match in twoWeeksLater.allMatches(lower)) {
      DateTime twoWeeks = context.referenceDate.add(Duration(days: 14));
      results.add(ParsingResult(
          index: match.start,
          text: match.group(0)!,
          date: DateTime(twoWeeks.year, twoWeeks.month, twoWeeks.day, 0, 0, 0)));
    }

    // "अगले सोमवार"
    RegExp nextMondayRegex = RegExp(r'अगले सोमवार', caseSensitive: false);
    for(final match in nextMondayRegex.allMatches(lower)){
      DateTime nextMonday = DateUtils.nextWeekday(context.referenceDate, 1);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 0, 0, 0)));
    }

    return results;
  }
}

class HiParsers {
  static final List<BaseParser> parsers = [
    HiRelativeParser(),
    HiAbsoluteParser(),
    HiTimeOnlyParser(),
    HiDayOnlyParser(),
    HiWeekdayParser(),
    HiRangeParser(),
  ];
}
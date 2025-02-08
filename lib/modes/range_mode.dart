// lib/modes/range_mode.dart
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// If range_mode is enabled, this class generates a range of dates for expressions
/// that indicate a period (e.g. "in 5 days" returns the dates for today through 5 days later).
class RangeMode {
  /// Generate extended results based on the original parsing results.
  /// If a result’s text matches a pattern like "in X days" (English)
  /// or "X日以内" (Japanese), then generate a list of dates from the result date
  /// (typically today) through (X - 1) days later.
  static List<ParsingResult> generate(List<ParsingResult> results, ParsingContext context) {
    List<ParsingResult> rangeResults = [];
    for (var result in results) {
      // Check for English range pattern: "in X days"
      RegExp engRange = RegExp(r'in\s+(\d+)\s+days');
      RegExpMatch? mEng = engRange.firstMatch(result.text.toLowerCase());
      if (mEng != null) {
        int days = int.parse(mEng.group(1)!);
        // Generate a range including today up to (days - 1) days later.
        for (int i = 0; i < days; i++) {
          DateTime d = DateUtils.adjustIfPast(context.referenceDate.add(Duration(days: i)), context.referenceDate);
          rangeResults.add(ParsingResult(index: result.index, text: "${result.text} (Day ${i+1})", date: d));
        }
        continue;
      }
      // Check for Japanese range pattern: "X日以内"
      RegExp jaRange = RegExp(r'([0-9一二三四五六七八九十]+)日以内');
      RegExpMatch? mJa = jaRange.firstMatch(result.text);
      if (mJa != null) {
        int days = _parseJapaneseNumber(mJa.group(1)!);
        for (int i = 0; i < days; i++) {
          DateTime d = DateUtils.adjustIfPast(context.referenceDate.add(Duration(days: i)), context.referenceDate);
          rangeResults.add(ParsingResult(index: result.index, text: "${result.text} (Day ${i+1})", date: d));
        }
        continue;
      }
      // For results not matching a range pattern, add as-is.
      rangeResults.add(result);
    }
    return rangeResults;
  }

  static int _parseJapaneseNumber(String s) {
    int? value = int.tryParse(s);
    if (value != null) return value;
    Map<String, int> kanji = {
      "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
      "五": 5, "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
    };
    int result = 0;
    for (int i = 0; i < s.length; i++) {
      result = result * 10 + (kanji[s[i]] ?? 0);
    }
    return result;
  }
}

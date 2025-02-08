// lib/modes/range_mode.dart
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// rangeMode が true の場合、特定の相対表現（例："next week", "来月"）に対して
/// 日付の範囲（リスト）を生成するクラス。
class RangeMode {
  /// 与えられた [results] の中で、範囲指定が必要な結果を拡張して日付リストを生成する。
  static List<ParsingResult> generate(List<ParsingResult> results, ParsingContext context) {
    List<ParsingResult> rangeResults = [];
    for (var result in results) {
      // 「next week」または「来週」と判断
      if (_isNextWeek(result.text)) {
        // 結果の日付から7日間分を生成
        for (int i = 0; i < 7; i++) {
          DateTime d = result.date.add(Duration(days: i));
          rangeResults.add(ParsingResult(
              index: result.index,
              text: "${result.text} (Day ${i + 1})",
              date: d));
        }
      }
      // 「next month」または「来月」と判断
      else if (_isNextMonth(result.text)) {
        var range = DateUtils.getMonthRange(result.date);
        DateTime start = range['start']!;
        DateTime end = range['end']!;
        int days = end.difference(start).inDays + 1;
        for (int i = 0; i < days; i++) {
          DateTime d = start.add(Duration(days: i));
          rangeResults.add(ParsingResult(
              index: result.index,
              text: "${result.text} (Day ${i + 1})",
              date: d));
        }
      } else {
        // 範囲指定でない場合はそのまま追加
        rangeResults.add(result);
      }
    }
    return rangeResults;
  }

  static bool _isNextWeek(String text) {
    final lower = text.toLowerCase();
    return lower.contains("next week") || text.contains("来週");
  }

  static bool _isNextMonth(String text) {
    final lower = text.toLowerCase();
    return lower.contains("next month") || text.contains("来月");
  }
}

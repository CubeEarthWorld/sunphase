// lib/modes/range_mode.dart
import '../core/result.dart';
import '../core/parsing_context.dart';

/// range_mode が有効なとき、各 ParsingResult に設定された range 情報に従い
/// 複数日分の結果へ展開する（例："in 5 days" の場合、基準日時を含めて 5+1 日分を生成する）。
class RangeMode {
  static List<ParsingResult> generate(List<ParsingResult> results, ParsingContext context) {
    List<ParsingResult> expanded = [];
    for (var result in results) {
      if (result.rangeDays != null) {
        int days = result.rangeDays!;
        // 例："in 5 days" の場合、rangeDays に (5+1) を設定しているので
        // 基準日時（通常は今日）から 0～(days-1) 日後まで生成する
        for (int i = 0; i < days; i++) {
          DateTime d = result.date.add(Duration(days: i));
          expanded.add(ParsingResult(index: result.index, text: result.text, date: d));
        }
      } else if (result.rangeType != null) {
        if (result.rangeType == "week") {
          // 次週の場合は、result.date を次週の初日とし、7日間分を展開する
          for (int i = 0; i < 7; i++) {
            DateTime d = result.date.add(Duration(days: i));
            expanded.add(ParsingResult(index: result.index, text: result.text, date: d));
          }
        } else if (result.rangeType == "month") {
          DateTime first = result.date;
          // 翌月の0日目（＝当月の最終日）を求める
          DateTime last = DateTime(first.year, first.month + 1, 0);
          int totalDays = last.day;
          for (int i = 0; i < totalDays; i++) {
            DateTime d = first.add(Duration(days: i));
            expanded.add(ParsingResult(index: result.index, text: result.text, date: d));
          }
        } else {
          expanded.add(result);
        }
      } else {
        expanded.add(result);
      }
    }
    return expanded;
  }
}

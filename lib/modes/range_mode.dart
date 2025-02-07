import '../core/result.dart';

class RangeMode {
  /// 結果がレンジ指定の場合、各 ParsingResult を１週間分の日付に展開して返す。
  static List<ParsingResult> applyRangeMode(List<ParsingResult> results, DateTime referenceDate) {
    List<ParsingResult> expandedResults = [];
    for (var result in results) {
      // 簡易チェック：結果テキストに "week", "来週", "周" が含まれている場合
      if (result.text.toLowerCase().contains("week") ||
          result.text.contains("来週") ||
          result.text.contains("周")) {
        // 例として、結果の date を起点に 7 日分の結果を生成
        for (int i = 0; i < 7; i++) {
          DateTime newDate = result.component.date.add(Duration(days: i));
          expandedResults.add(ParsingResult(
              index: result.index,
              text: result.text,
              component: result.component.copyWith(date: newDate)));
        }
      } else {
        expandedResults.add(result);
      }
    }
    return expandedResults;
  }
}

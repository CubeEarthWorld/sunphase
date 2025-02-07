// lib/modes/range_mode.dart
import '../core/result.dart';

class RangeMode {
  /// 結果がレンジ指定の場合、各 ParsingResult を期間展開して返す。
  /// ここでは簡易的に:
  /// - "week" / "週" / "周" / "来週" が含まれる => 7日分に展開
  /// - "month" / "月" が含まれる => 30日分に展開
  /// - "year" / "年" が含まれる => 365日分に展開
  /// というルールに拡充している。
  static List<ParsingResult> applyRangeMode(
      List<ParsingResult> results, DateTime referenceDate) {
    List<ParsingResult> expandedResults = [];

    for (var result in results) {
      final lowerText = result.text.toLowerCase();

      // 「週」「周」を含むかどうか (日本語/中国語でも「週」や「周」)
      final bool isWeekRange = lowerText.contains('week') ||
          result.text.contains('週') ||
          result.text.contains('周') ||
          result.text.contains('来週');

      // 「month」や「月」を含むかどうか
      final bool isMonthRange =
          lowerText.contains('month') || result.text.contains('月');

      // 「year」や「年」を含むかどうか
      final bool isYearRange = lowerText.contains('year') || result.text.contains('年');

      if (isWeekRange) {
        // 1週間分 (7日分) を展開
        for (int i = 0; i < 7; i++) {
          DateTime newDate = result.component.date.add(Duration(days: i));
          expandedResults.add(
            ParsingResult(
              index: result.index,
              text: result.text,
              component: result.component.copyWith(date: newDate),
            ),
          );
        }
      } else if (isMonthRange) {
        // 30日分を展開
        for (int i = 0; i < 30; i++) {
          DateTime newDate = result.component.date.add(Duration(days: i));
          expandedResults.add(
            ParsingResult(
              index: result.index,
              text: result.text,
              component: result.component.copyWith(date: newDate),
            ),
          );
        }
      } else if (isYearRange) {
        // 365日分を展開 (あくまで簡易実装)
        for (int i = 0; i < 365; i++) {
          DateTime newDate = result.component.date.add(Duration(days: i));
          expandedResults.add(
            ParsingResult(
              index: result.index,
              text: result.text,
              component: result.component.copyWith(date: newDate),
            ),
          );
        }
      } else {
        // 上記以外はそのまま
        expandedResults.add(result);
      }
    }

    return expandedResults;
  }
}

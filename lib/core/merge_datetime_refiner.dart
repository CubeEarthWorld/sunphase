// lib/core/merge_datetime_refiner.dart
import 'result.dart';
import 'refiner.dart';

/// 共通のマージ処理：隣接する結果のうち、日付部分のみ（時刻が 00:00）の結果に対して、
/// 近くの結果で時刻情報がある場合はその時刻で上書きします。
class MergeDateTimeRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    results.sort((a, b) => a.index.compareTo(b.index));
    List<bool> used = List.filled(results.length, false);
    List<ParsingResult> mergedResults = [];
    for (int i = 0; i < results.length; i++) {
      if (used[i]) continue;
      ParsingResult base = results[i];
      DateTime baseDate = base.component.date;
      int baseEnd = base.index + base.text.length;
      for (int j = i + 1; j < results.length; j++) {
        if (used[j]) continue;
        ParsingResult candidate = results[j];
        // 近接している場合（差が 3 文字以内）に統合
        if (candidate.index - baseEnd <= 3) {
          DateTime candDate = candidate.component.date;
          if (baseDate.hour == 0 && baseDate.minute == 0 &&
              (candDate.hour != 0 || candDate.minute != 0)) {
            baseDate = DateTime(baseDate.year, baseDate.month, baseDate.day, candDate.hour, candDate.minute);
            used[j] = true;
          }
        }
      }
      mergedResults.add(ParsingResult(
        index: base.index,
        text: base.text,
        component: base.component.copyWith(date: baseDate),
      ));
    }
    return mergedResults;
  }
}

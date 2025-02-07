import 'result.dart';

class Merger {
  /// 複数の ParsingResult を統合し、重複する結果を排除する。
  static List<ParsingResult> mergeResults(List<ParsingResult> results) {
    // シンプルに index と text の組み合わせで重複を判断
    final Map<String, ParsingResult> unique = {};
    for (var result in results) {
      String key = '${result.index}-${result.text}';
      if (!unique.containsKey(key)) {
        unique[key] = result;
      }
    }
    return unique.values.toList();
  }
}

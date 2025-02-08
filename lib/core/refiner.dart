// lib/core/refiner.dart
import 'result.dart';

/// 解析結果を補正・調整するためのリファイナ
abstract class Refiner {
  /// 入力テキストと解析結果リストを受け取り、補正後の結果リストを返す。
  List<ParsingResult> refine(String text, List<ParsingResult> results);
}

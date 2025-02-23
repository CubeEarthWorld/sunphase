// lib/core/refiner.dart
import 'parsing_context.dart';
import 'result.dart';

abstract class Refiner {
  /// 複数のパーサーの解析結果を補正・統合して返す
  List<ParsingResult> refine(List<ParsingResult> results, ParsingContext context);
}

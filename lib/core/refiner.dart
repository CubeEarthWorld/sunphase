// lib/core/refiner.dart
import 'result.dart';

abstract class Refiner {
  /// [results] のリストを精査・調整し、改めて解析結果リストを返す。
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate);
}

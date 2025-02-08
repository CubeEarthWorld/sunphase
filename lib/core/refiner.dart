// lib/core/refiner.dart
import 'parsing_context.dart';
import 'result.dart';

/// 複数のパーサーの結果を統合・補正するためのリファイナーの基底クラス。
abstract class Refiner {
  /// 解析結果のリストを補正・統合し、新たなリストを返す。
  List<ParsingResult> refine(List<ParsingResult> results, ParsingContext context);
}
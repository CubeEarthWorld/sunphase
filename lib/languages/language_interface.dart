import '../core/parser.dart';
import '../core/refiner.dart';

abstract class Language {
  /// 言語コード（例："en", "ja", "zh"）
  String get code;

  /// この言語用のパーサー群
  List<Parser> get parsers;

  /// この言語用のリファイナー群
  List<Refiner> get refiners;
}

// lib/sunphase.dart
import 'core/result.dart';  // 内部で利用
export 'core/result.dart'; // 利用者が再エクスポート可能にする
import 'core/parser_manager.dart';

/// 自然言語の日付表現を解析して結果リストを返す
List<ParsingResult> parse(String text,
    {DateTime? referenceDate,
      List<String>? languages,
      bool rangeMode = false,
      String? timezone}) {
  return ParserManager.parse(text,
      referenceDate: referenceDate,
      languages: languages,
      rangeMode: rangeMode,
      timezone: timezone);
}

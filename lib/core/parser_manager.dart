// lib/core/parser_manager.dart
import 'base_parser.dart';
import 'parsing_context.dart';
import 'result.dart';
import '../languages/en.dart';
import '../languages/ja.dart';
import '../languages/zh.dart';
import '../languages/universal.dart';  // UniversalParsers を利用するための import
import '../modes/range_mode.dart';
import '../utils/timezone_utils.dart';

/// ユーザーからの入力テキストと各種オプションに応じ、
/// 適切なパーサー群を呼び出して解析結果を統合する管理クラス。
class ParserManager {
  static List<ParsingResult> parse(String text,
      {DateTime? referenceDate,
        String? language,
        bool rangeMode = false,
        String? timezone}) {
    // 基準日時、タイムゾーン、言語などの情報を ParsingContext にまとめる
    ParsingContext context = ParsingContext(
      referenceDate: referenceDate ?? DateTime.now(),
      timezoneOffset: timezone != null
          ? TimezoneUtils.offsetFromString(timezone)
          : Duration.zero,
      language: language,
    );

    // 言語指定に応じたパーサー群を取得
    List<BaseParser> parsers = _getParsersForLanguage(context.language);

    // 各パーサーを実行して解析結果を収集する
    List<ParsingResult> results = [];
    for (var parser in parsers) {
      results.addAll(parser.parse(text, context));
    }

    if (rangeMode) {
      // range_mode の場合、まず RangeMode.generate() で展開する
      List<ParsingResult> rangeResults = RangeMode.generate(results, context);
      if (rangeResults.isNotEmpty) {
        // 同一の元結果（ここでは index でグループ化）ごとにグループ化し、
        // グループ内の項目数が最大のグループを採用する
        Map<int, List<ParsingResult>> groups = {};
        for (var r in rangeResults) {
          groups.putIfAbsent(r.index, () => []).add(r);
        }
        List<ParsingResult> selected = groups.values.reduce((a, b) =>
        a.length >= b.length ? a : b);
        results = selected;
      } else {
        results = rangeResults;
      }
    } else {
      // range_mode が false の場合は、すでにマージ処理（認識テキストが最も長いものを採用）
      // （前回のコード例などと同様の処理を行う）
      if (results.isNotEmpty) {
        ParsingResult merged = results.reduce(
                (a, b) => a.text.length >= b.text.length ? a : b);
        results = [merged];
      }
    }

    // タイムゾーンの補正を適用
    results = TimezoneUtils.applyTimezone(results, context.timezoneOffset);
    return results;
  }

  /// 言語指定に応じて利用するパーサーを返す
  static List<BaseParser> _getParsersForLanguage(String? language) {
    if (language == null) {
      return [
        ...EnParsers.parsers,
        ...JaParsers.parsers,
        ...ZhParsers.parsers,
        ...UniversalParsers.parsers,
      ];
    }
    switch (language) {
      case 'en':
        return EnParsers.parsers;
      case 'ja':
        return JaParsers.parsers;
      case 'zh':
        return ZhParsers.parsers;
      default:
        return UniversalParsers.parsers;
    }
  }
}

// lib/core/parser_manager.dart
import 'base_parser.dart';
import 'parsing_context.dart';
import 'result.dart';
import '../languages/en.dart';
import '../languages/ja.dart';
import '../languages/zh.dart';
import '../languages/universal.dart';  // UniversalParsers を利用
import '../modes/range_mode.dart';
import '../utils/timezone_utils.dart';

/// ユーザーからの入力テキストと各種オプションに応じ、
/// 適切なパーサー群を呼び出して解析結果を統合する管理クラス。
class ParserManager {
  static List<ParsingResult> parse(String text,
      {DateTime? referenceDate,
        List<String>? languages, // ここを String? から List<String>? に変更
        bool rangeMode = false,
        String? timezone}) {
    // 基準日時、タイムゾーンなどの情報を ParsingContext にまとめる
    ParsingContext context = ParsingContext(
      referenceDate: referenceDate ?? DateTime.now(),
      timezoneOffset: timezone != null
          ? TimezoneUtils.offsetFromString(timezone)
          : Duration.zero,
      // language フィールドは利用しない（各パーサーは個別に処理）
    );

    // 指定された各言語のパーサーを取得し、常に UniversalParsers も追加する
    List<BaseParser> parsers = _getParsersForLanguages(languages);

    // 各パーサーを実行して解析結果を収集する
    List<ParsingResult> results = [];
    for (var parser in parsers) {
      results.addAll(parser.parse(text, context));
    }

    if (rangeMode) {
      // range_mode の場合、RangeMode.generate() で展開する
      List<ParsingResult> rangeResults = RangeMode.generate(results, context);
      if (rangeResults.isNotEmpty) {
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

  /// 複数の言語指定に応じて利用するパーサーを返す
  /// 指定がなければ全言語（en, ja, zh）のパーサーを利用し、常に UniversalParsers も追加する
  static List<BaseParser> _getParsersForLanguages(List<String>? languages) {
    List<BaseParser> parsers = [];

    if (languages == null || languages.isEmpty) {
      // 言語指定がない場合は、全言語のパーサーを利用
      parsers.addAll(EnParsers.parsers);
      parsers.addAll(JaParsers.parsers);
      parsers.addAll(ZhParsers.parsers);
    } else {
      // 指定された各言語のパーサーを追加
      for (String lang in languages) {
        switch (lang) {
          case 'en':
            parsers.addAll(EnParsers.parsers);
            break;
          case 'ja':
            parsers.addAll(JaParsers.parsers);
            break;
          case 'zh':
            parsers.addAll(ZhParsers.parsers);
            break;
          default:
          // 対応していない言語の場合は、ここで何らかの処理を行う（例: ログ出力など）
            break;
        }
      }
    }
    // universal.dart のパーサーは常に追加する
    parsers.addAll(UniversalParsers.parsers);
    return parsers;
  }
}

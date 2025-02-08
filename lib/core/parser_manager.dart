// lib/core/parser_manager.dart
import 'parsing_context.dart';
import 'result.dart';
import '../languages/en.dart';
import '../languages/ja.dart';
import '../languages/zh.dart';
import '../languages/universal.dart';
import '../modes/range_mode.dart';
import '../utils/timezone_utils.dart';
import 'base_parser.dart';

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

    // rangeMode が true の場合、範囲指定の結果を生成
    if (rangeMode) {
      results = RangeMode.generate(results, context);
    }

    // タイムゾーンの補正を適用
    results = TimezoneUtils.applyTimezone(results, context.timezoneOffset);

    return results;
  }

  static List<BaseParser> _getParsersForLanguage(String? language) {
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

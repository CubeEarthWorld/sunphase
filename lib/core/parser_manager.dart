import 'config.dart';
import 'result.dart';
import '../languages/language_interface.dart';
import 'merger.dart';
import '../modes/range_mode.dart';
import '../core/timezone_config.dart';
import 'error_handler.dart';

class ParserManager {
  /// 指定されたオプションに基づきテキスト解析を実行し、解析結果リストを返す。
  static List<ParsingResult> parse(String text,
      {DateTime? referenceDate,
        String? language,
        bool rangeMode = false,
        String? timezone}) {
    final DateTime refDate = referenceDate ?? DateTime.now();
    // タイムゾーンが指定されている場合、参照日付を調整する
    DateTime adjustedRefDate = timezone != null
        ? TimezoneConfig.applyTimezone(refDate, timezone)
        : refDate;

    // 使用する言語リストを取得。言語が指定されていなければ全言語を利用する
    List<Language> languages;
    if (language != null) {
      languages = Config.getLanguage(language);
      if (languages.isEmpty) {
        // 指定された言語が存在しない場合はデフォルト全言語を利用
        languages = Config.defaultLanguages;
      }
    } else {
      languages = Config.defaultLanguages;
    }

    List<ParsingResult> allResults = [];

    // 各言語ごとのパーサーとリファイナーを実行
    for (var lang in languages) {
      for (var parser in lang.parsers) {
        try {
          List<ParsingResult> results = parser.parse(text, adjustedRefDate);
          allResults.addAll(results);
        } catch (e) {
          ErrorHandler.handleError(e);
        }
      }
      for (var refiner in lang.refiners) {
        try {
          allResults = refiner.refine(allResults, adjustedRefDate);
        } catch (e) {
          ErrorHandler.handleError(e);
        }
      }
    }

    // 結果の統合・重複排除
    allResults = Merger.mergeResults(allResults);

    // レンジモードが有効なら、該当する結果を拡張
    if (rangeMode) {
      allResults = RangeMode.applyRangeMode(allResults, adjustedRefDate);
    }

    // 結果を index 順にソート
    allResults.sort((a, b) => a.index.compareTo(b.index));

    return allResults;
  }
}

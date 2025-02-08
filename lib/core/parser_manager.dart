// lib/core/parser_manager.dart
import 'result.dart';
import 'parser.dart';
import '../languages/en.dart' as en;
import '../languages/ja.dart' as ja;
import '../languages/zh.dart' as zh;
import '../languages/not_language.dart' as notLang;
import '../modes/range_mode.dart' as rangeModeModule;
import '../utils/date_utils.dart' as dateUtils;

class ParserManager {
  /// 指定された言語に応じたパーサーリストを返す。
  /// 言語指定がなければ、全言語のパーサーを返す。
  static List<Parser> getParsers(String? language) {
    List<Parser> parsers = [];
    if (language == null) {
      parsers.addAll(en.parsers);
      parsers.addAll(ja.parsers);
      parsers.addAll(zh.parsers);
      parsers.addAll(notLang.parsers);
    } else {
      switch (language.toLowerCase()) {
        case 'en':
          parsers.addAll(en.parsers);
          break;
        case 'ja':
          parsers.addAll(ja.parsers);
          break;
        case 'zh':
          parsers.addAll(zh.parsers);
          break;
        case 'not_language':
          parsers.addAll(notLang.parsers);
          break;
        default:
          parsers.addAll(en.parsers);
          parsers.addAll(ja.parsers);
          parsers.addAll(zh.parsers);
          parsers.addAll(notLang.parsers);
          break;
      }
    }
    return parsers;
  }

  /// パブリックAPI。入力テキストとオプションに基づき解析結果リストを返す。
  static List<ParsingResult> parse(String text,
      {DateTime? referenceDate,
        String? language,
        bool rangeMode = false,
        bool strict = false,
        String? timezone}) {
    DateTime refDate = referenceDate ?? DateTime.now();
    List<ParsingResult> results = [];

    List<Parser> parsers = getParsers(language);
    for (var parser in parsers) {
      try {
        ParsingResult? result = parser.parse(text, refDate,
            rangeMode: rangeMode, strict: strict, timezone: timezone);
        if (result != null) {
          results.add(result);
        }
      } catch (e) {
        // エラー発生時はログ出力して続行
        print('Parser error: $e');
      }
    }

    // rangeMode が有効な場合、各結果を期間として拡張する
    if (rangeMode) {
      List<ParsingResult> expanded = [];
      for (var res in results) {
        expanded.addAll(rangeModeModule.expandRange(res, refDate));
      }
      results = expanded;
    }

    // タイムゾーン指定がある場合、各結果の timezoneOffset を設定する
    if (timezone != null) {
      int offset = int.tryParse(timezone) ?? 0;
      for (var res in results) {
        res.start.timezoneOffset = offset;
        if (res.end != null) {
          res.end!.timezoneOffset = offset;
        }
      }
    }

    // 既に過ぎた日時の場合、次回の該当日時に補正する
    for (var res in results) {
      DateTime dt = res.date;
      if (dateUtils.isPast(dt, refDate)) {
        res.start = dateUtils.adjustPastDate(res.start, refDate);
        if (res.end != null) {
          res.end = dateUtils.adjustPastDate(res.end!, refDate);
        }
      }
    }

    return results;
  }
}

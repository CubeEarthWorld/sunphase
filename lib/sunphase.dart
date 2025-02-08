// lib/sunphase.dart
import 'core/parser_manager.dart';
import 'core/result.dart';

/// パッケージのエントリーポイント
///
/// [text]：解析対象の文字列
/// [referenceDate]：解析の基準日（指定がなければ現在日時）
/// [language]：使用する言語コード（例："en", "ja", "zh", "not_language"）。指定がなければ全言語で解析します。
/// [rangeMode]：true の場合、期間表現の場合に複数日付（例：来週なら1週間分、来月ならその月の日付全て）を返します。
/// [strict]：true の場合、厳密な形式のみを解析するモード（デフォルトは false）
/// [timezone]：タイムゾーン（UTCからの分単位オフセット文字列。指定がなければシステムローカルの時間を利用）
List<ParsingResult> parse(String text,
    {DateTime? referenceDate,
      String? language,
      bool rangeMode = false,
      bool strict = false,
      String? timezone}) {
  return ParserManager.parse(text,
      referenceDate: referenceDate,
      language: language,
      rangeMode: rangeMode,
      strict: strict,
      timezone: timezone);
}

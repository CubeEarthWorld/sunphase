// lib/core/parsing_context.dart
/// 解析に必要な共通情報（基準日時、タイムゾーン、言語）を保持するクラス。
class ParsingContext {
  final DateTime referenceDate;
  final Duration timezoneOffset;
  final String? language;

  ParsingContext({
    required this.referenceDate,
    required this.timezoneOffset,
    this.language,
  });
}

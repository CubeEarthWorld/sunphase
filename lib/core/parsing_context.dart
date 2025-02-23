// lib/core/parsing_context.dart
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

// lib/core/parsing_context.dart
//
// Immutable container of the contextual information every pattern needs
// when interpreting a match: the reference date to anchor relative
// expressions to, the timezone offset to apply, and (optionally) a
// language hint.

/// Context passed through the parsing pipeline.
///
/// Created once per call to the top-level `parse` function and forwarded
/// to every language parser and resolver. Treat instances as read-only.
class ParsingContext {
  /// The "now" that all relative expressions ("today", "next week",
  /// bare times, etc.) are interpreted relative to.
  final DateTime referenceDate;

  /// Offset (in whole minutes) applied to resolved dates when the caller
  /// supplied a `timezone` argument. `Duration.zero` means "no shift".
  final Duration timezoneOffset;

  /// First day of the week used for named week expressions. Supported
  /// values are [DateTime.sunday] and [DateTime.monday].
  final int weekStartsOn;

  /// Optional language hint. Currently informational — the actual set of
  /// language parsers to run is decided by `ParserManager`.
  final String? language;

  ParsingContext({
    required this.referenceDate,
    required this.timezoneOffset,
    this.weekStartsOn = DateTime.sunday,
    this.language,
  });
}

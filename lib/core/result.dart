// lib/core/result.dart
//
// Final result type returned from the public `parse` function.
//
// A `ParsingResult` represents a single date/time expression that was
// successfully extracted from the input text. A single call to `parse`
// can return multiple results — one per matched expression, or (in range
// mode) one per day in an expanded range.

/// The resolved output of a single parsed date/time expression.
class ParsingResult {
  /// Character offset of the matched substring inside the original input.
  final int index;

  /// The exact substring that was matched in the input text.
  final String text;

  /// The fully resolved calendar date and time this expression refers to.
  ///
  /// If the expression did not specify a time component, the time is set
  /// to 00:00 (midnight). If it did not specify a date component, the
  /// date is resolved to the next occurrence relative to the reference
  /// date used during parsing.
  final DateTime date;

  /// For range expressions: how many consecutive days the range covers.
  /// `null` for point-in-time results.
  final int? rangeDays;

  /// For range expressions: the kind of span the expression refers to
  /// (e.g. `"week"` or `"month"`). `null` for point-in-time results.
  final String? rangeType;

  ParsingResult({
    required this.index,
    required this.text,
    required this.date,
    this.rangeDays,
    this.rangeType,
  });

  @override
  String toString() => '[$index] "$text" -> $date';
}

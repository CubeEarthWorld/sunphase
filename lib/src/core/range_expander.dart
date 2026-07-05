// lib/src/core/range_expander.dart
//
// Range mode: expands span results into one result per day.
//
//   * rangeDays = N        → N consecutive days from the anchor date
//   * rangeType = "week"   → 7 days from the week's first day
//   * rangeType = "month"  → every day of the anchored calendar month
//
// Point-in-time results pass through unchanged.

import '../result.dart';

class RangeExpander {
  const RangeExpander();

  List<ParsingResult> expand(List<ParsingResult> results) {
    final expanded = <ParsingResult>[];

    for (final result in results) {
      final days = _spanLength(result);
      if (days == null) {
        expanded.add(result);
        continue;
      }
      for (var i = 0; i < days; i++) {
        expanded.add(
          ParsingResult(
            index: result.index,
            text: result.text,
            date: result.date.add(Duration(days: i)),
          ),
        );
      }
    }
    return expanded;
  }

  int? _spanLength(ParsingResult result) {
    if (result.rangeDays != null) return result.rangeDays;
    switch (result.rangeType) {
      case 'week':
        return 7;
      case 'month':
        final first = result.date;
        return DateTime(first.year, first.month + 1, 0).day;
      default:
        return null;
    }
  }
}

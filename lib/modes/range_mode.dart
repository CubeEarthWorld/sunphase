// lib/modes/range_mode.dart
//
// Expands span-type `ParsingResult`s into one result per day.
//
// When the caller sets `rangeMode: true`, expressions like "next week"
// or "march" do not return a single date — they return a sequence of
// dates, one per day in the span. This file contains the expansion
// logic that turns a single span result into that sequence.
//
// A result is a span if either:
//   1. `rangeDays != null` — an explicit count of days (e.g. "in 3 days"
//      stores `rangeDays = 4` so that the range includes today through
//      day N).
//   2. `rangeType != null` — a named span type: `"week"` (7 days) or
//      `"month"` (all days in the resolved calendar month).

import '../core/result.dart';
import '../core/parsing_context.dart';

/// Expands span results into per-day sequences for range mode.
class RangeMode {
  /// For each result in [results], generate the per-day expansion if the
  /// result describes a span; otherwise pass it through unchanged.
  ///
  /// [context] is accepted for future use (e.g. filtering by timezone or
  /// locale) but is not currently read.
  static List<ParsingResult> generate(
    List<ParsingResult> results,
    ParsingContext context,
  ) {
    List<ParsingResult> expanded = [];

    for (var result in results) {
      if (result.rangeDays != null) {
        // Explicit day count: emit `rangeDays` consecutive dates
        // starting from `result.date`.
        for (int i = 0; i < result.rangeDays!; i++) {
          DateTime d = result.date.add(Duration(days: i));
          expanded.add(
            ParsingResult(index: result.index, text: result.text, date: d),
          );
        }
      } else if (result.rangeType != null) {
        if (result.rangeType == "week") {
          // Weekly span: emit 7 days starting from `result.date` (which
          // the resolver anchors to Monday of the target week).
          for (int i = 0; i < 7; i++) {
            DateTime d = result.date.add(Duration(days: i));
            expanded.add(
              ParsingResult(index: result.index, text: result.text, date: d),
            );
          }
        } else if (result.rangeType == "month") {
          // Monthly span: emit every day in the calendar month that
          // `result.date` falls in.
          DateTime first = result.date;
          // `DateTime(year, month + 1, 0)` is the last day of `month`.
          DateTime last =
              DateTime(first.year, first.month + 1, 0);
          int totalDays = last.day;
          for (int i = 0; i < totalDays; i++) {
            DateTime d = first.add(Duration(days: i));
            expanded.add(
              ParsingResult(index: result.index, text: result.text, date: d),
            );
          }
        } else {
          // Unknown rangeType: pass through as-is so callers at least
          // receive the anchor date.
          expanded.add(result);
        }
      } else {
        // Point-in-time result: pass through unchanged.
        expanded.add(result);
      }
    }

    return expanded;
  }
}

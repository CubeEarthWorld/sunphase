// lib/utils/timezone_utils.dart
//
// Timezone offset helpers.
//
// Sunphase intentionally avoids a full IANA timezone database to stay
// dependency-free. Instead, callers supply a raw UTC offset in minutes
// (e.g. `"480"` for UTC+8 / Japan, `"-300"` for UTC-5 / Eastern Time).
//
// The offset is applied as a simple `DateTime.add` shift to every
// resolved result just before they are returned to the caller. This
// means the `DateTime`s in `ParsingResult.date` represent the *local*
// time in the specified zone, stored as a Dart `DateTime` without zone
// information.

import '../core/result.dart';

/// Utilities for parsing and applying UTC timezone offsets.
class TimezoneUtils {
  /// Converts an offset string (minutes from UTC) to a [Duration].
  ///
  /// Examples:
  /// - `"480"`  → `Duration(minutes: 480)`  (UTC+8)
  /// - `"-300"` → `Duration(minutes: -300)` (UTC-5)
  /// - `"0"`    → `Duration.zero`           (UTC)
  ///
  /// Returns [Duration.zero] for any string that cannot be parsed as an
  /// integer.
  static Duration offsetFromString(String offsetStr) {
    int minutes = int.tryParse(offsetStr) ?? 0;
    return Duration(minutes: minutes);
  }

  /// Shifts all `date` fields in [results] by [offset].
  ///
  /// When [offset] is `Duration.zero` the results are returned
  /// unchanged. Otherwise each `ParsingResult` is cloned with a new
  /// `date` equal to `result.date + offset`.
  static List<ParsingResult> applyTimezone(
    List<ParsingResult> results,
    Duration offset,
  ) {
    return results.map((result) {
      DateTime adjusted = result.date.add(offset);
      return ParsingResult(
        index: result.index,
        text: result.text,
        date: adjusted,
      );
    }).toList();
  }
}

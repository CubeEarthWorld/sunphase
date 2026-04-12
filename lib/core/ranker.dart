// lib/core/ranker.dart
//
// Overlap filtering and result ranking for raw matches.
//
// When multiple patterns match overlapping substrings of the input (e.g.
// "March 7 10:10" triggers both a full-date pattern and a bare-time
// pattern), we need to pick the most informative non-overlapping subset.
// `ResultRanker.filterOverlapping` does this by ranking on specificity
// first, text length second.

import 'result.dart';

/// Utility methods for choosing the best set of parse matches.
class ResultRanker {
  /// Returns the single best `ParsingResult` in point-in-time mode, or
  /// the full list unchanged in range mode.
  ///
  /// "Best" is a proxy for specificity: we prefer the match whose
  /// matched text is longest (longer match ≈ more context consumed ≈
  /// more date fields populated). The `DateResolver` already picks the
  /// best `RawMatch` before creating `ParsingResult`s, so this is
  /// mostly a safety net.
  static List<ParsingResult> rank(
    List<ParsingResult> results, {
    bool rangeMode = false,
  }) {
    if (results.isEmpty) return [];

    if (rangeMode) {
      // Keep everything so that `RangeMode` can expand them later.
      return results;
    }

    // Primary sort: longer matched text → richer expression.
    // Secondary sort: earlier start index → appears first in the input.
    results.sort((a, b) {
      int cmp = b.text.length.compareTo(a.text.length);
      if (cmp != 0) return cmp;
      return a.index.compareTo(b.index);
    });

    return [results.first];
  }

  /// Filters a list of matches, removing any that overlap with a
  /// higher-priority match.
  ///
  /// Priority is determined first by [getSpecificity] (number of date
  /// fields populated), then by [getLength] (raw character span). A
  /// match is kept only if no already-accepted match shares at least
  /// one character position with it.
  ///
  /// This is a generic method so it can operate on `RawMatch` objects
  /// (before resolution) as well as on any other type.
  static List<T> filterOverlapping<T>(
    List<T> matches,
    int Function(T) getStart,
    int Function(T) getEnd,
    int Function(T) getSpecificity,
    int Function(T) getLength,
  ) {
    if (matches.isEmpty) return [];

    // Sort best candidates first so that greedily accepting the first
    // non-overlapping match gives the right result.
    matches.sort((a, b) {
      int cmp = getSpecificity(b).compareTo(getSpecificity(a));
      if (cmp != 0) return cmp;
      return getLength(b).compareTo(getLength(a));
    });

    List<T> selected = [];
    for (var m in matches) {
      // An overlap exists when two character ranges share at least one
      // position: [s1, e1) ∩ [s2, e2) is non-empty iff s1 < e2 && s2 < e1.
      bool overlaps = selected.any((s) =>
          getStart(m) < getEnd(s) && getStart(s) < getEnd(m));
      if (!overlaps) {
        selected.add(m);
      }
    }

    return selected;
  }
}

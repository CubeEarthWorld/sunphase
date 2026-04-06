// lib/core/ranker.dart
import 'result.dart';

/// Specificity-based result ranking (replaces naive longest-match)
class ResultRanker {
  /// Select the best non-overlapping results.
  /// In non-range mode: returns the single best result.
  /// For overlapping matches: prefers higher specificity, then longer text.
  static List<ParsingResult> rank(List<ParsingResult> results, {bool rangeMode = false}) {
    if (results.isEmpty) return [];

    if (rangeMode) {
      // In range mode, keep all results for RangeMode expansion
      return results;
    }

    // Sort by: specificity-proxy (text length as primary), then index
    // We use text length as a proxy since ParsingResult doesn't carry specificity.
    // The resolver should have already selected the best raw matches.
    results.sort((a, b) {
      int cmp = b.text.length.compareTo(a.text.length);
      if (cmp != 0) return cmp;
      return a.index.compareTo(b.index);
    });

    return [results.first];
  }

  /// Select best RawMatch-level results before resolution.
  /// Removes overlapping matches, keeping higher specificity ones.
  static List<T> filterOverlapping<T>(
    List<T> matches,
    int Function(T) getStart,
    int Function(T) getEnd,
    int Function(T) getSpecificity,
    int Function(T) getLength,
  ) {
    if (matches.isEmpty) return [];

    // Sort by specificity (desc), then length (desc)
    matches.sort((a, b) {
      int cmp = getSpecificity(b).compareTo(getSpecificity(a));
      if (cmp != 0) return cmp;
      return getLength(b).compareTo(getLength(a));
    });

    List<T> selected = [];
    for (var m in matches) {
      bool overlaps = selected.any((s) =>
          getStart(m) < getEnd(s) && getStart(s) < getEnd(m));
      if (!overlaps) {
        selected.add(m);
      }
    }

    return selected;
  }
}

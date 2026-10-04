// lib/src/core/selector.dart
//
// Ranks resolved candidates from all languages and keeps a
// non-overlapping subset. In point-in-time mode only the single best
// candidate survives; in range mode every non-overlapping expression is
// kept for expansion.
//
// Ranking: longer matched text first (a longer expression subsumes more
// of the input), then higher specificity, then earlier position.

import 'resolver.dart';

class Selector {
  const Selector();

  List<Resolved> select(List<Resolved> candidates, {required bool single}) {
    if (candidates.isEmpty) return const [];

    final ranked = List.of(candidates)
      ..sort((a, b) {
        if (a.length != b.length) return b.length.compareTo(a.length);
        if (a.specificity != b.specificity) {
          return b.specificity.compareTo(a.specificity);
        }
        return a.start.compareTo(b.start);
      });

    if (single) return [ranked.first];

    final kept = <Resolved>[];
    for (final c in ranked) {
      final overlapsKept =
          kept.any((k) => c.start < k.end && k.start < c.end);
      if (!overlapsKept) kept.add(c);
    }
    return kept;
  }
}

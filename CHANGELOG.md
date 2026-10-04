## 1.0.0

* Share month-end calculation between calendar helpers and date resolution,
  avoiding temporary range maps and duplicate month-start objects.
* Avoid temporary intersection/difference sets during component compatibility
  checks while preserving parsing rules, output ordering, and the public API.
* Preserve DateTime limit behavior, leap-year handling, week-start options,
  timezone offsets, and multilingual composition.
* Add reproducible AOT benchmark tools, a pinned baseline source archive, raw
  measurements, and equivalence checks in `tool/` and `benchmark/`.
* On the recorded Windows/Dart AOT benchmark, median short-text parsing time
  decreased by 5.8%, month-anchor parsing by 9.7%, dense long-text parsing by
  11.5%, and month arithmetic by 18.9%. These are library microbenchmarks;
  process RSS and total allocation improvements were not established.
* Validation: 259 existing tests, static analysis, AOT builds, 4,484 parse
  comparisons, 3,960 month comparisons, 65,536 slot combinations, and DateTime
  boundary/invalid-week-start checks. No new dependencies.

## 0.0.1

* TODO: Describe initial release.

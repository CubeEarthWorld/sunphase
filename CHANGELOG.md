## 1.0.0

* Clean up duplicate baseline sources/ZIP, generated logs/snapshots, stale
  test results, and the inconclusive allocation diagnostic. Original evidence
  remains available at commit 0ac9cc5efd302eb3ef50350a565be6d3aa0bc5d0.
* Remove unused Flutter runtime and direct test dependencies. Development
  tests still use flutter_test; standalone Dart consumers need no Flutter SDK.
* Preserve all public parsing/calendar APIs and existing tests. Regenerate
  baseline comparison code on demand and integrate DateTime limit checks.

* Share month-end calculation between calendar helpers and date resolution,
  avoiding temporary range maps and duplicate month-start objects.
* Avoid temporary intersection/difference sets during component compatibility
  checks while preserving parsing rules, output ordering, and the public API.
* Preserve DateTime limit behavior, leap-year handling, week-start options,
  timezone offsets, and multilingual composition.
* Keep benchmark inputs, a concise measured summary, and equivalence checks.
  Obtain baseline source from Git history; keep generated results in `.dart_tool`.
* On the recorded Windows/Dart AOT benchmark, median short-text parsing time
  decreased by 5.8%, month-anchor parsing by 9.7%, dense long-text parsing by
  11.5%, and month arithmetic by 18.9%. These are library microbenchmarks;
  process RSS and total allocation improvements were not established.
* Validation: 259 existing tests, static analysis, AOT builds, 4,484 parse
  comparisons, 3,960 month comparisons, 65,536 slot combinations, and DateTime
  boundary/invalid-week-start checks. No new dependencies.

## 0.0.1

* TODO: Describe initial release.

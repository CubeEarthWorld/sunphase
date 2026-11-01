# 1.0.1 (2026-11-01)
- Remove redundant candidate storage, field validation and ISO normalization;
  keep built-in glue anchoring in the shared language constructor.
- Resolve calendar-week weekdays against `week_start` for past weeks too.
  For example, on 2025-02-08, `先週火曜14時` is 2025-01-28 at 14:00;
  unqualified `last Tuesday` still means the most recent Tuesday.
- Reject overflowing minutes instead of treating them as omitted.
- Require custom-language glue to match the entire gap between tokens.
- Keep one pending token per pattern and index selected spans to avoid
  redundant overlapping searches and quadratic range overlap checks.
- Remove the unused JSON copy of all 250 compiled Rust test cases.

# 1.0.0 (2026-10-07)

- Multilingual natural-language date and time parsing in Rust.
- Seven languages, universal dates, composition and custom language builders.
- Chrono-backed Gregorian calendar and rust-lang regex pattern matching.
- Microsecond wall clocks, arbitrary reference dates and fixed ISO offsets.
- Convenient `parse`, configurable `parse_with` and multilingual examples.
- Checked date arithmetic, invalid-date rejection and bounded ranges.
- Compact range results with checked endpoints through `Parser::parse_ranges`.
- English and Spanish ordinal weekdays share the validated weekday resolver.
- Correct month-end searches, Korean offsets and Sino-Korean numerals.
- Original UTF-8 spans survive emoji and full-width digits.
- Correct sub-microsecond rounding before the Unix epoch.
- Bounded pattern compilation with Unicode properties and scoped flags.
- Native and Wasm support; Rust 1.88 minimum, tested in CI.

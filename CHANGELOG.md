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

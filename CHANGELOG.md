# 1.0.0 — Rust replacement (2026-10-07)

- Replace the Dart/Flutter package, tests and tooling with a Cargo Rust crate.
- Preserve all seven languages and component composition; public custom language builders.
- Pure Rust standard library; zero normal, development or build dependencies.
- Shared bounded ordered NFA, byte-mask slots and conditional normalization.
- Checked Gregorian date/time types with microsecond precision.
- Convenient `parse`, configurable `parse_with`, optional Cargo, multilingual runnable examples.
- Recognize browser GMT dates through the shared calendar parser.
- Checked calendar arithmetic, invalid-date/time rejection, bounded ranges.
- Fix bare 31st resolving into the wrong month; reject numeric suffix false matches.
- Fix Korean 그제/그끄제 offsets; recognize Sino-Korean numeral strings.
- Original UTF-8 spans survive emoji and full-width digits.
- Native/Wasm tests and equivalent-workload AOT comparison.

# Sunphase — Rust

A small, extensible natural-language date/time parser. English, Japanese,
Chinese, Spanish, Hindi, Korean and Russian; ISO dates always work.
Native and `wasm32-unknown-unknown`, without a runtime, threads or system clock.

## Cargo

```toml
[dependencies]
sunphase = { git = "https://github.com/CubeEarthWorld/sunphase", tag = "v1.0.0" }
```

```rust
use sunphase::{Options, Parser};
use sunphase::NaiveDateTime;

let reference = "2025-02-08T11:05:00".parse::<NaiveDateTime>().unwrap();
let parser = Parser::default();
let mut options = Options::new(reference);
options.languages = &["ja", "en"];
let input = "明日午後３時３０分";
let matches = parser.parse(input, &options).unwrap();
assert_eq!(matches[0].date.to_string(), "2025-02-09 15:30:00");
assert_eq!(&input[matches[0].start..matches[0].end], input);
```

Supply the reference wall-clock time explicitly. Results use `NaiveDateTime`;
ISO timestamps with offsets are converted to UTC wall-clock values. Other
expressions use the supplied reference's calendar. `offset_minutes` shifts
the result, it does not select a timezone. Perform timezone conversion in the host.

`languages` defaults to `en`, `ja`, `zh`; unknown codes are ignored.
`week_start` accepts ISO weekday 1 (Monday) or 7 (Sunday), default 7.
`range = true` returns non-overlapping expressions and expands named weeks,
months and within-day spans; otherwise the longest, most specific expression wins.
Spans use UTF-8 byte offsets into the **original** input, including full-width
digits and emoji. Ranking counts UTF-16 units to preserve multilingual selection.

Invalid calendar dates and clock times are rejected rather than overflowing.
Bare times use their next occurrence; a bare day searches forward until a month
contains it. Calendar arithmetic is checked. Range expansion is capped at 36,600
days per expression and returns `Error::RangeTooLarge` beyond that limit.

## Extension

Languages contribute components; shared code composes compatible neighboring
components and resolves dates. Add vocabulary/patterns in `src/languages/`, or
supply a caller-owned `Language` and `Pattern::custom` builder. No parser fork is
needed. See [extension example](docs/EXTENDING.md).

Compile patterns once and reuse the parser. Built-ins compile lazily once;
slots use a byte mask, numeric/calendar arithmetic is checked, normalization
allocates only when needed. Regex matching has no backtracking or lookaround.

## Verification and benchmarks

```sh
cargo test --locked
cargo clippy --all-targets --locked -- -D warnings
cargo run --release --locked --example benchmark
cargo check --locked --target wasm32-unknown-unknown
```

The former 259 Dart tests were captured as 250 distinct parse cases, now checked
in Rust along with invalid inputs, calendar boundaries, Unicode offsets and a
custom language. The erroneous Korean `그끄제` expectation is corrected to three
days ago. [Measurement details](benchmark/REPORT.ja.md).

Version 1.0.0 is a breaking Rust replacement. The Dart package is removed.
BSD 3-Clause; see [LICENSE](LICENSE).

# Sunphase —（日本語）

Rust 1.88以上が必要です。

Rust標準ライブラリのみで動作する、汎用的な自然言語の日時解析パッケージです。本体・テスト・ベンチマークの外部依存はゼロです。CargoはRust標準の管理ツールで、追加ライブラリのインストールは不要です。rustc単独でもビルドできます。

`parse("tomorrow")` で現在のUTC日時を基準に解析できます。端末の現地日時・任意の過去や未来・指定時刻を使う場合は `Options::new(DateTime::parse(...))` と `parse_with` を使います。基準日時、使用言語、週の開始日、時差、範囲モード、独自言語やパターンを指定できます。以下に全機能と7言語の実行例を掲載しています。

## 任意の基準日時

```rust
use sunphase::{DateTime, Options, parse_with};

let mut options = Options::new(DateTime::parse("2021-02-04T09:30:12.123456").unwrap());
options.languages = &["en"];
let results = parse_with("next Tuesday", &options).unwrap();
assert_eq!(results[0].date.to_string(), "2021-02-09 00:00:00");
```

`DateTime` / `NaiveDateTime` are Sunphase's own checked Gregorian wall-clock
types, not another crate's types. Create them from ISO text, Unix microseconds
(`DateTime::from_timestamp_micros`), calendar fields
(`NaiveDate::from_ymd_opt(...).and_hms_opt(...)`), or a caller-supplied standard
`SystemTime` (`DateTime::from_system_time(SystemTime::now())`). Negative Unix
values, leap years, fractional seconds, and fixed ISO offsets are supported.
Dates cover years −262142 through +262142. Precision is one microsecond;
longer fractional input is truncated to microseconds.

## 7言語の使用例

With reference `2025-02-08T11:05:00`, use the corresponding language code:

| Code | Language | Input | Result |
|---|---|---|---|
| `en` | English | `tomorrow at 3pm` | 2025-02-09 15:00 |
| `ja` | 日本語 | `明日12時14分` | 2025-02-09 12:14 |
| `zh` | 中文 | `三月七号上午九点` | 2025-03-07 09:00 |
| `es` | Español | `mañana a las 15:00` | 2025-02-09 15:00 |
| `hi` | हिन्दी | `अगले सोमवार` | 2025-02-10 00:00 |
| `ko` | 한국어 | `내일 오후 3시` | 2025-02-09 15:00 |
| `ru` | Русский | `завтра в 15:00` | 2025-02-09 15:00 |

```rust
use sunphase::{DateTime, Options, Parser};
let parser = Parser::default();
let mut options = Options::new(DateTime::parse("2025-02-08T11:05:00").unwrap());
options.languages = &["ja", "en", "zh"]; // mixed-language input
let input = "明日午後３時３０分";
let matches = parser.parse(input, &options).unwrap();
assert_eq!(matches[0].date.to_string(), "2025-02-09 15:30:00");
assert_eq!(&input[matches[0].start..matches[0].end], input);
```

Default languages: `en`, `ja`, `zh`. Restrict to one code or select any combination.
Caller-owned languages can override built-ins. Unknown codes are ignored;
universal dates and `10:10` remain available regardless of language selection.

## 機能と使用例

The original public parsing features are preserved with Rust APIs:

| Feature | Example | Behavior with the same February 8 reference |
|---|---|---|
| Relative day | `today`, `tomorrow`, `明日`, `三天后` | resolve against the supplied reference |
| Bare time | `10:10` | next occurrence: February 9 at 10:10 |
| Calendar composition | `next month on the 21st at 2pm` | March 21 at 14:00 |
| Named weekday | `next Tuesday`, `来週火曜14時14分` | shared weekday/week resolver |
| Nth weekday | `el tercer lunes de marzo` | March 17 |
| Range | `next week`, `march`, `3日以内` | one result per day with `range = true` |
| ISO datetime | `2025-03-07T10:10:00+09:00` | March 7 at 01:10 UTC |
| Date / time | `2025/03/07 10:10` | adjacent compatible components combine |
| Browser date | `Fri Mar 07 2025 10:10:00 GMT+0900` | March 7 at 01:10 UTC |
| Full-width digits | `明日午後３時３０分` | same date, original source positions |

### 範囲モードと週の開始日

```rust
use sunphase::{DateTime, Options, parse_with};
let mut options = Options::new(DateTime::parse("2025-02-08T11:05:00").unwrap());
options.languages = &["en"];
options.range = true;
options.week_start = 1; // ISO: Monday=1, Sunday=7 (default)
let week = parse_with("next week", &options).unwrap();
assert_eq!(week.len(), 7);
assert_eq!(week[0].date.to_string(), "2025-02-10 00:00:00");
```

`Parser::parse_ranges` は日ごとの結果を作らず、範囲を1件で返します。
`date` は開始日、`range_days` は検証済みの日数です。
`range = false` の場合は `parse` と同じ単日結果を返します。

```rust
use sunphase::{DateTime, Options, Parser};
let mut options = Options::new(DateTime::parse("2025-02-08T11:05:00").unwrap());
options.range = true;
let week = Parser::default().parse_ranges("next week", &options).unwrap();
assert_eq!(week.len(), 1);
assert_eq!(week[0].range_days, Some(7));
```

Range mode selects non-overlapping expressions and expands named week/month/
within-day spans. `Match.range_type` and `Match.range_days` expose their metadata.
Point mode selects the longest, most specific expression.

### 分単位の時差

```rust
use sunphase::{DateTime, Options, parse_with};
let mut options = Options::new(DateTime::parse("2025-02-08T11:05:00").unwrap());
options.offset_minutes = 480; // UTC+8
assert_eq!(parse_with("明天", &options).unwrap()[0].date.to_string(),
           "2025-02-09 08:00:00");
```

`offset_minutes` shifts the resolved result; it does not load a timezone or
change the reference. Convert host-local time to reference wall-clock fields
in your application. Fixed offsets are supported; named timezone/DST rules
belong to the host.

## 独自言語・パターンを追加

```rust
use sunphase::{Component, DateTime, Language, Options, Parser, Pattern};
let pattern = Pattern::custom(r"(?i)after ([0-9]+) sleeps", |captures, _| {
    Some(vec![Component::RelativeDay(captures.get(1)?.as_str().parse().ok()?)])
}).unwrap();
let parser = Parser {
    languages: vec![Language::new("demo", r"^\s*$", vec![pattern])],
};
let mut options = Options::new(DateTime::parse("2025-02-08T11:05:00").unwrap());
options.languages = &["demo"];
assert_eq!(parser.parse("after 2 sleeps", &options).unwrap()[0].date.to_string(),
           "2025-02-10 00:00:00");
```

Vocabulary/patterns emit components; composition, validation, ranking and date
resolution stay shared. Built-ins initialize lazily once. Reuse `Parser` for
caller-owned extensions. The standard-only ordered NFA avoids exponential
backtracking; [pattern syntax and extension details](docs/EXTENDING.md).

## 正確性と移植性

Invalid calendar dates and times are rejected instead of overflowing. A bare
31st searches for the next month containing that day; February 29 without a
year selects the next leap year. Arithmetic is checked. Range expansion is
limited to 36,600 days per expression, with an explicit error above the limit.
Spans are **UTF-8 byte offsets into the original input**, including emoji and
full-width digits.
Native and `wasm32-unknown-unknown` use the same pure parser. `parse_with` works
without a host clock; convenience `parse` returns `ClockUnavailable` on Wasm.

## 全サンプルとテストを実行

```sh
cargo run --offline --locked --example usage
cargo test --offline --locked
cargo clippy --offline --all-targets --locked -- -D warnings
cargo check --offline --locked --target wasm32-unknown-unknown
cargo tree --offline --locked
```

Tests cover 250 parsing cases plus calendar,
Unicode, custom-pattern and input-boundary regressions. Fixtures are compiled
Rust data: no JSON parser, generator or Python install is needed to run them.
See [changes](CHANGELOG.md),
and [runnable multilingual examples](examples/usage.rs). BSD-3-Clause license.

# Add a language or pattern

Reuse the built-in components and calendar resolver:

```rust
use sunphase::{Component, Language, Options, Parser, Pattern, NaiveDateTime};

let token = Pattern::custom("morrow", |_, _| {
    Some(vec![Component::RelativeDay(1)])
}).unwrap();
let parser = Parser {
    languages: vec![Language::new("demo", r"^\s*$", vec![token])],
};
let mut options = Options::new("2025-02-08T11:05:00".parse::<NaiveDateTime>().unwrap());
options.languages = &["demo"];
assert_eq!(parser.parse("morrow", &options).unwrap()[0].date.to_string(),
           "2025-02-09 00:00:00");
```

`Pattern::custom` re-exports regex `Captures`; callers need only the Sunphase dependency. Return `None` to reject a match.
Each builder emits one or more `Component`s. Glue must match the entire gap.
Duplicate slots stop composition. Components validate calendar fields; the
shared resolver handles relative dates, month-end searches, weeks and AM/PM.
Zero-width tokens are ignored. Invalid regex returns an error; `Language::new`
expects a valid glue regex and panics for an invalid developer-supplied pattern.

To extend a built-in, obtain `sunphase::languages::ja::language()`, append custom
patterns to `.patterns`, and put it in `Parser.languages`. A caller-owned
language overrides the built-in with the same code. Otherwise built-ins are
shared and initialized lazily. Add tests for new vocabulary and its combinations.

## Pattern syntax and limits

Patterns use the [rust-lang regex syntax](https://docs.rs/regex/latest/regex/#syntax),
including Unicode property classes, named captures, greedy/lazy repetitions
and scoped flags. `\d`, `\s` and `\w` are Unicode-aware; use `[0-9]` for ASCII
numbers. Lookaround and backreferences are unsupported; reject unwanted
context in the builder instead.

Compilation is limited to 64 KiB source, nesting depth 64 and 8 MiB compiled
regex size. The maintained engine performs searches without exponential
backtracking. Patterns and calendars are shared by every language.

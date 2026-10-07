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

`Pattern::custom` uses Rust `regex` captures. Return `None` to reject a match.
Each builder emits one or more `Component`s. Glue must match the entire gap.
Duplicate slots stop composition. Components validate calendar fields; the
shared resolver handles relative dates, month-end searches, weeks and AM/PM.
Zero-width tokens are ignored. Invalid regex returns an error; `Language::new`
expects a valid glue regex and panics for an invalid developer-supplied pattern.

To extend a built-in, obtain `sunphase::languages::ja::language()`, append custom
patterns to `.patterns`, and put it in `Parser.languages`. A caller-owned
language overrides the built-in with the same code. Otherwise built-ins are
shared and initialized lazily. Add tests for new vocabulary and its combinations.

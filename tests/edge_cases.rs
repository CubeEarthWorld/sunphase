use sunphase::NaiveDate;
use sunphase::{Component, Error, Language, Options, Parser, Pattern};
fn options() -> Options<'static> {
    Options::new(
        NaiveDate::from_ymd_opt(2025, 2, 8)
            .unwrap()
            .and_hms_opt(11, 5, 0)
            .unwrap(),
    )
}
#[test]
fn invalid_and_calendar_boundaries() {
    let p = Parser::default();
    let mut o = options();
    o.languages = &["universal"];
    for input in ["2025-02-30", "2025-04-31", "25:00", "12:60"] {
        assert!(p.parse(input, &o).unwrap().is_empty(), "{input}");
    }
    o.languages = &["ja"];
    assert_eq!(
        p.parse("31日", &o).unwrap()[0].date.date(),
        NaiveDate::from_ymd_opt(2025, 3, 31).unwrap()
    );
    o.reference = NaiveDate::from_ymd_opt(2025, 4, 30)
        .unwrap()
        .and_hms_opt(0, 0, 0)
        .unwrap();
    assert_eq!(
        p.parse("31日", &o).unwrap()[0].date.date(),
        NaiveDate::from_ymd_opt(2025, 5, 31).unwrap()
    );
    o.range = true;
    assert_eq!(p.parse("999999日以内", &o), Err(Error::RangeTooLarge));
    assert!(p.parse("999999999999999999999日後", &o).unwrap().is_empty());
    o.week_start = 2;
    assert_eq!(p.parse("", &o), Err(Error::InvalidWeekStart));
}
#[test]
fn unicode_spans_are_original_utf8() {
    let p = Parser::default();
    let input = "😀 明日１０時３０分 と 来月";
    let mut o = options();
    o.languages = &["ja"];
    o.range = true;
    let results = p.parse(input, &o).unwrap();
    assert!(
        results
            .iter()
            .any(|r| &input[r.start..r.end] == "明日１０時３０分")
    );
    assert!(results.iter().any(|r| &input[r.start..r.end] == "来月"));
}
#[test]
fn add_language_without_changing_engine() {
    let pattern = Pattern::custom("customtomorrow", |_, _| {
        Some(vec![Component::RelativeDay(1)])
    })
    .unwrap();
    let parser = Parser {
        languages: vec![Language::new("custom", r"^\s*$", vec![pattern])],
    };
    let mut o = options();
    o.languages = &["custom"];
    assert_eq!(
        parser.parse("customtomorrow", &o).unwrap()[0].date.date(),
        NaiveDate::from_ymd_opt(2025, 2, 9).unwrap()
    );
}

#[test]
fn corrected_language_and_composition_cases() {
    let p = Parser::default();
    let mut o = options();
    o.languages = &["ko"];
    for (text, expected) in [
        ("그제", "2025-02-06 00:00:00"),
        ("그끄제", "2025-02-05 00:00:00"),
        ("십오시", "2025-02-08 15:00:00"),
        ("십사일십오시", "2025-02-14 15:00:00"),
    ] {
        assert_eq!(
            p.parse(text, &o).unwrap()[0].date.to_string(),
            expected,
            "{text}"
        );
    }
    o.languages = &["es"];
    assert_eq!(
        p.parse("el tercer lunes de marzo a las 15:00", &o).unwrap()[0]
            .date
            .to_string(),
        "2025-03-17 15:00:00"
    );
    o.languages = &["en"];
    assert_eq!(
        p.parse("February 29", &o).unwrap()[0].date.to_string(),
        "2028-02-29 00:00:00"
    );
}

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
    // Earlier normalized digits must not shift later matches into UTF-8 code points.
    let input = "９😀 ３日後；😀 １２日後；終";
    let mut spans: Vec<_> = p
        .parse(input, &o)
        .unwrap()
        .into_iter()
        .map(|r| {
            assert!(input.is_char_boundary(r.start) && input.is_char_boundary(r.end));
            &input[r.start..r.end]
        })
        .collect();
    spans.sort_unstable();
    assert_eq!(spans, ["１２日後", "３日後"]);
    let expected = p.parse(input, &o).unwrap();
    o.languages = &["ja", "ja", "universal", "universal"];
    assert_eq!(p.parse(input, &o).unwrap(), expected);
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
    for text in ["the fifth Monday of February", "fifth mon in feb"] {
        assert!(p.parse(text, &o).unwrap().is_empty(), "{text}");
    }
    assert_eq!(
        p.parse("the third Monday of March at 3pm", &o).unwrap()[0]
            .date
            .to_string(),
        "2025-03-17 15:00:00"
    );
    assert_eq!(
        p.parse("last Monday of February", &o).unwrap()[0]
            .date
            .to_string(),
        "2025-02-24 00:00:00"
    );
    assert_eq!(
        p.parse("February 29", &o).unwrap()[0].date.to_string(),
        "2028-02-29 00:00:00"
    );
}

#[test]
fn compact_ranges_check_lengths_and_the_final_day() {
    let parser = Parser::default();
    let mut o = options();
    o.range = true;
    for offset in [-90, 1440] {
        o.offset_minutes = offset;
        assert_eq!(
            parser.parse_ranges("next week", &o).unwrap()[0].date,
            parser.parse("next week", &o).unwrap()[0].date
        );
    }
    o.offset_minutes = 0;
    assert_eq!(
        parser.parse_ranges("next week", &o).unwrap()[0].range_days,
        Some(7)
    );
    assert_eq!(
        parser.parse_ranges("next month", &o).unwrap()[0].range_days,
        Some(31)
    );
    assert_eq!(
        parser.parse_ranges("36600日以内", &o),
        Err(Error::RangeTooLarge)
    );
    o.reference = NaiveDate::from_ymd_opt(262142, 12, 1)
        .unwrap()
        .and_hms_opt(0, 0, 0)
        .unwrap();
    o.languages = &["en"];
    o.offset_minutes = 1440;
    assert_eq!(
        parser.parse_ranges("December", &o),
        Err(Error::DateOutOfRange)
    );
    assert_eq!(parser.parse("December", &o), Err(Error::DateOutOfRange));
}

#[test]
fn calendar_composition_preserves_the_requested_weekday() {
    let parser = Parser::default();
    let mut o = options();
    o.languages = &["en"];
    o.range = true;
    for (text, expected) in [
        ("Monday of February", "2025-02-03 00:00:00"),
        ("next month Monday", "2025-03-03 00:00:00"),
        ("Monday February 10 at 3pm", "2025-02-10 15:00:00"),
    ] {
        let results = parser.parse(text, &o).unwrap();
        assert_eq!(results.len(), 1, "{text}");
        assert_eq!(results[0].date.to_string(), expected, "{text}");
    }
    assert!(parser.parse("Monday February 11", &o).unwrap().is_empty());
}

#[test]
fn previous_calendar_week_respects_the_week_start() {
    let parser = Parser::default();
    let mut o = options();
    o.reference = "2025-02-12T11:05:00".parse().unwrap();
    for week_start in [1, 7] {
        o.week_start = week_start;
        for (language, text) in [
            ("en", "last week Monday"),
            ("ja", "先週月曜日"),
            ("zh", "上周一"),
            ("es", "semana pasada lunes"),
            ("hi", "पिछले सप्ताह सोमवार"),
            ("ko", "지난 주 월요일"),
            ("ru", "прошлой неделе понедельник"),
        ] {
            assert_eq!(
                parser
                    .parse(
                        text,
                        &Options {
                            languages: &[language],
                            ..o.clone()
                        }
                    )
                    .unwrap()[0]
                    .date
                    .to_string(),
                "2025-02-03 00:00:00",
                "{text}, week_start={week_start}"
            );
        }
    }
    o.languages = &["en"];
    for (week_start, expected) in [(1, "2025-02-09 00:00:00"), (7, "2025-02-02 00:00:00")] {
        o.week_start = week_start;
        assert_eq!(
            parser.parse("last week Sunday", &o).unwrap()[0]
                .date
                .to_string(),
            expected
        );
    }
    assert_eq!(
        parser.parse("last Monday", &o).unwrap()[0].date.to_string(),
        "2025-02-10 00:00:00"
    );
}

#[test]
fn overflowing_minutes_are_rejected() {
    let parser = Parser::default();
    for (language, text) in [
        ("ja", "3時999999999999999999999分"),
        ("zh", "三点999999999999999999999分"),
        ("ko", "삼시999999999999999999999분"),
    ] {
        let o = Options {
            languages: &[language],
            ..options()
        };
        assert!(parser.parse(text, &o).unwrap().is_empty(), "{text}");
    }
}

#[test]
fn custom_glue_must_match_the_entire_gap() {
    let parser = Parser {
        languages: vec![Language::new(
            "demo",
            r"\s+",
            vec![
                Pattern::custom("tomorrow", |_, _| Some(vec![Component::RelativeDay(1)])).unwrap(),
                Pattern::custom("3pm", |_, _| {
                    Some(vec![Component::Time(3, None, Some(true))])
                })
                .unwrap(),
            ],
        )],
    };
    let mut o = options();
    o.languages = &["demo"];
    o.range = true;
    let text = "tomorrow unrelated 3pm";
    let results = parser.parse(text, &o).unwrap();
    assert_eq!(results.len(), 2);
    assert!(
        results
            .iter()
            .all(|m| !text[m.start..m.end].contains("unrelated"))
    );
    let combined = parser.parse("tomorrow 3pm", &o).unwrap();
    assert_eq!(combined.len(), 1);
    assert_eq!(combined[0].date.to_string(), "2025-02-09 15:00:00");
}

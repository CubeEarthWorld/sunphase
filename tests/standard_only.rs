use sunphase::{Component, DateTime, NaiveDate, Options, Parser, Pattern};
#[test]
fn calendar_roundtrips_and_offsets() {
    for year in [-400, -1, 0, 1, 1900, 2000, 2025, 2100, 2400, 262142] {
        for month in 1..=12 {
            for day in 1..=31 {
                if let Some(date) = NaiveDate::from_ymd_opt(year, month, day) {
                    let dt = date.and_hms_opt(23, 59, 59).unwrap();
                    assert_eq!((dt.year(), dt.month(), dt.day()), (year, month, day));
                    assert_eq!(DateTime::parse(&dt.to_iso8601()).unwrap(), dt);
                    assert_eq!(
                        DateTime::from_timestamp_micros(dt.timestamp_micros()),
                        Some(dt)
                    );
                }
            }
        }
    }
    for (text, expected) in [
        ("1970-01-01T00:00:00.000001Z", 1),
        ("1969-12-31T23:59:59.999999Z", -1),
        ("1970-01-01T09:00:00+0900", 0),
        ("1969-12-31T19:00:00-05:00", 0),
    ] {
        assert_eq!(DateTime::parse(text).unwrap().timestamp_micros(), expected);
    }
    for text in [
        "1900-02-29T00:00:00",
        "2025-01-01T24:00:00",
        "2025-01-01T12:00:60",
        "2025-01-01T12:00:00+24:00",
        "2025-01-01T12:00:00.",
        "2025-01-01T12:00:00junk",
    ] {
        assert!(DateTime::parse(text).is_err(), "{text}");
    }
    assert_eq!(
        DateTime::from_system_time(std::time::UNIX_EPOCH)
            .unwrap()
            .timestamp_micros(),
        0
    );
}
#[test]
fn generic_patterns_and_bounded_compilation() {
    for bad in [
        "(",
        "[z-a]",
        "a{1001}",
        "(a{1000}){1000}",
        "(?i)a(?i)b",
        "(a)\\1",
    ] {
        assert!(Pattern::custom(bad, |_, _| None).is_err(), "{bad}");
    }
    let pattern = Pattern::custom(
        r"(?i)(?:in|after)\s+(?P<days>[0-9]+)\s+d(?:ay|ays)",
        |c, _| {
            Some(vec![Component::RelativeDay(
                c.name("days")?.as_str().parse().ok()?,
            )])
        },
    )
    .unwrap();
    let parser = Parser {
        languages: vec![sunphase::Language::new("demo", r"^\s*$", vec![pattern])],
    };
    let mut options = Options::new(DateTime::parse("2025-02-08T11:05:00").unwrap());
    options.languages = &["demo"];
    assert_eq!(
        parser.parse("After 12 days", &options).unwrap()[0]
            .date
            .to_string(),
        "2025-02-20 00:00:00"
    );
    options.languages = &["universal"];
    assert_eq!(
        parser
            .parse(
                "Fri Mar 07 2025 10:10:00 GMT+0900 (Japan Standard Time)",
                &options
            )
            .unwrap()[0]
            .date
            .to_string(),
        "2025-03-07 01:10:00"
    );
}

#[test]
fn convenient_and_deterministic_entry_points() {
    let options = Options::new(DateTime::parse("2025-02-08T11:05:00").unwrap());
    assert_eq!(
        sunphase::parse_with("tomorrow", &options).unwrap(),
        Parser::default().parse("tomorrow", &options).unwrap()
    );
    assert!(
        sunphase::parse("tomorrow").unwrap()[0]
            .date
            .timestamp_micros()
            > 0
    );
}

#[test]
fn nested_repetitions_remain_linear_and_prioritized() {
    let pattern = Pattern::custom(r"(a+)+b", |_, _| Some(vec![Component::RelativeDay(1)])).unwrap();
    let parser = Parser {
        languages: vec![sunphase::Language::new("demo", r"^\s*$", vec![pattern])],
    };
    let mut options = Options::new(DateTime::parse("2025-02-08T11:05:00").unwrap());
    options.languages = &["demo"];
    assert!(
        parser
            .parse(&"a".repeat(10000), &options)
            .unwrap()
            .is_empty()
    );
    assert_eq!(parser.parse("aaaaab", &options).unwrap()[0].date.day(), 9);
}

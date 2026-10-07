use sunphase::{DateTime, Options, Parser};
fn main() {
    let parser = Parser::default();
    let reference = DateTime::parse("2025-02-08T11:05:00").unwrap();
    let mut options = Options::new(reference);
    for (language, input, expected) in [
        ("en", "tomorrow at 3pm", "2025-02-09 15:00:00"),
        ("ja", "明日12時14分", "2025-02-09 12:14:00"),
        ("zh", "三月七号上午九点", "2025-03-07 09:00:00"),
        ("es", "mañana a las 15:00", "2025-02-09 15:00:00"),
        ("hi", "अगले सोमवार", "2025-02-10 00:00:00"),
        ("ko", "내일 오후 3시", "2025-02-09 15:00:00"),
        ("ru", "завтра в 15:00", "2025-02-09 15:00:00"),
        ("en", "10:10", "2025-02-09 10:10:00"),
        ("en", "next month on the 21st at 2pm", "2025-03-21 14:00:00"),
        ("en", "2025-03-07T10:10:00+09:00", "2025-03-07 01:10:00"),
    ] {
        let codes = [language];
        let mut options = Options::new(reference);
        options.languages = &codes;
        let results = parser.parse(input, &options).unwrap();
        assert_eq!(results[0].date.to_string(), expected, "{input}");
        println!("{language}: {input} → {}", results[0].date);
    }
    options.languages = &["en"];
    options.range = true;
    for (week_start, expected) in [(7, "2025-02-09 00:00:00"), (1, "2025-02-10 00:00:00")] {
        options.week_start = week_start;
        let week = parser.parse("next week", &options).unwrap();
        assert_eq!(week.len(), 7);
        assert_eq!(week[0].date.to_string(), expected);
    }
    options.range = false;
    options.offset_minutes = 480;
    assert_eq!(
        parser.parse("tomorrow", &options).unwrap()[0]
            .date
            .to_string(),
        "2025-02-09 08:00:00"
    );
    options.offset_minutes = 0;
    options.reference = DateTime::parse("2021-02-04T00:00:00").unwrap();
    assert_eq!(
        parser.parse("next Tuesday", &options).unwrap()[0]
            .date
            .to_string(),
        "2021-02-09 00:00:00"
    );
}

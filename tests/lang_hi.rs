use sunphase::{NaiveDate, NaiveDateTime, Options, Parser};

fn ref_dt() -> NaiveDateTime {
    NaiveDate::from_ymd_opt(2025, 2, 8)
        .unwrap()
        .and_hms_opt(11, 5, 0)
        .unwrap()
}

fn dt(y: i32, m: u32, d: u32, h: u32, min: u32) -> NaiveDateTime {
    NaiveDate::from_ymd_opt(y, m, d)
        .unwrap()
        .and_hms_opt(h, min, 0)
        .unwrap()
}

fn hi_opts() -> Options<'static> {
    let mut opts = Options::new(ref_dt());
    opts.languages = &["hi"];
    opts
}

fn assert_hi(input: &str, expected_span: &str, expected_date: NaiveDateTime) {
    let matches = Parser::default().parse(input, &hi_opts()).unwrap();
    assert_eq!(
        matches.len(),
        1,
        "expected 1 match for {input:?}, got {matches:?}"
    );
    let m = &matches[0];
    assert_eq!(
        &input[m.start..m.end],
        expected_span,
        "span mismatch for {input:?}"
    );
    assert_eq!(m.date, expected_date, "date mismatch for {input:?}");
}

fn assert_none(input: &str) {
    let matches = Parser::default().parse(input, &hi_opts()).unwrap();
    assert!(
        matches.is_empty(),
        "expected no match for {input:?}, got {matches:?}"
    );
}

#[test]
fn relative_days_and_disambiguators() {
    assert_hi("आज", "आज", dt(2025, 2, 8, 0, 0));
    assert_hi("कल", "कल", dt(2025, 2, 9, 0, 0));
    assert_hi("परसों", "परसों", dt(2025, 2, 10, 0, 0));
    assert_hi("परसो", "परसो", dt(2025, 2, 10, 0, 0));
    assert_hi("नरसों", "नरसों", dt(2025, 2, 11, 0, 0));
    assert_hi("तरसों", "तरसों", dt(2025, 2, 12, 0, 0));

    assert_hi("बीता कल", "बीता कल", dt(2025, 2, 7, 0, 0));
    assert_hi("बीते हुए कल", "बीते हुए कल", dt(2025, 2, 7, 0, 0));
    assert_hi("पिछले कल", "पिछले कल", dt(2025, 2, 7, 0, 0));
    assert_hi("गुज़रा कल", "गुज़रा कल", dt(2025, 2, 7, 0, 0));
    assert_hi("आने वाला कल", "आने वाला कल", dt(2025, 2, 9, 0, 0));
    assert_hi("बीते परसों", "बीते परसों", dt(2025, 2, 6, 0, 0));
    assert_hi("आने वाला परसों", "आने वाला परसों", dt(2025, 2, 10, 0, 0));

    assert_hi("आज रात 9 बजे", "आज रात 9 बजे", dt(2025, 2, 8, 21, 0));
    assert_hi("आज बैठक है।", "आज", dt(2025, 2, 8, 0, 0));
    assert_hi("कल आना।", "कल", dt(2025, 2, 9, 0, 0));
}

#[test]
fn anchors_and_weekends() {
    assert_hi("अगले साल", "अगले साल", dt(2026, 2, 1, 0, 0));
    assert_hi("पिछले वर्ष", "पिछले वर्ष", dt(2024, 2, 1, 0, 0));
    assert_hi("इस बरस", "इस बरस", dt(2025, 2, 1, 0, 0));
    assert_hi("गत वर्ष", "गत वर्ष", dt(2024, 2, 1, 0, 0));
    assert_hi("अगला साल", "अगला साल", dt(2026, 2, 1, 0, 0));
    assert_hi("अगले माह", "अगले माह", dt(2025, 3, 1, 0, 0));
    assert_hi("बीते महीने", "बीते महीने", dt(2025, 1, 1, 0, 0));
    assert_hi("आगामी सप्ताह", "आगामी सप्ताह", dt(2025, 2, 9, 0, 0));
    assert_hi("अगले से अगले हफ्ते", "अगले से अगले हफ्ते", dt(2025, 2, 16, 0, 0));
    assert_hi("अगले साल मार्च", "अगले साल मार्च", dt(2026, 3, 1, 0, 0));

    assert_hi("सप्ताहांत", "सप्ताहांत", dt(2025, 2, 9, 0, 0));
    assert_hi("वीकेंड", "वीकेंड", dt(2025, 2, 9, 0, 0));
    assert_hi("पिछले वीकेंड", "पिछले वीकेंड", dt(2025, 2, 2, 0, 0));
    assert_hi(
        "इस सप्ताहांत शाम 5 बजे",
        "इस सप्ताहांत शाम 5 बजे",
        dt(2025, 2, 9, 17, 0),
    );
}

#[test]
fn weekdays_and_week_start() {
    assert_hi("सोमवार", "सोमवार", dt(2025, 2, 10, 0, 0));
    assert_hi("बृहस्पतिवार", "बृहस्पतिवार", dt(2025, 2, 13, 0, 0));
    assert_hi("वीरवार", "वीरवार", dt(2025, 2, 13, 0, 0));
    assert_hi("इतवार", "इतवार", dt(2025, 2, 9, 0, 0));
    assert_hi("शनीचर", "शनीचर", dt(2025, 2, 15, 0, 0));
    assert_hi("अगला सोमवार", "अगला सोमवार", dt(2025, 2, 10, 0, 0));
    assert_hi("आने वाले शुक्रवार", "आने वाले शुक्रवार", dt(2025, 2, 14, 0, 0));
    assert_hi("बीते बुधवार", "बीते बुधवार", dt(2025, 2, 5, 0, 0));
    assert_hi("इस रविवार", "इस रविवार", dt(2025, 2, 9, 0, 0));
    assert_hi(
        "अगले हफ्ते का सोमवार",
        "अगले हफ्ते का सोमवार",
        dt(2025, 2, 10, 0, 0),
    );

    let parser = Parser::default();
    let mut opts_sun = hi_opts();
    opts_sun.week_start = 7;
    let m_sun = parser.parse("अगले हफ्ते रविवार", &opts_sun).unwrap();
    assert_eq!(m_sun[0].date, dt(2025, 2, 9, 0, 0));

    let mut opts_mon = hi_opts();
    opts_mon.week_start = 1;
    let m_mon = parser.parse("अगले हफ्ते रविवार", &opts_mon).unwrap();
    assert_eq!(m_mon[0].date, dt(2025, 2, 16, 0, 0));
}

#[test]
fn months_and_dates() {
    assert_hi("14 मार्च 2025", "14 मार्च 2025", dt(2025, 3, 14, 0, 0));
    assert_hi("14 मार्च, 2025", "14 मार्च, 2025", dt(2025, 3, 14, 0, 0));
    assert_hi("15वीं अगस्त", "15वीं अगस्त", dt(2025, 8, 15, 0, 0));
    assert_hi("पंद्रह अगस्त", "पंद्रह अगस्त", dt(2025, 8, 15, 0, 0));
    assert_hi("दो अक्टूबर 2025", "दो अक्टूबर 2025", dt(2025, 10, 2, 0, 0));
    assert_hi("14 सितम्बर 2025", "14 सितम्बर 2025", dt(2025, 9, 14, 0, 0));
    assert_hi("2 अक्तूबर 2025", "2 अक्तूबर 2025", dt(2025, 10, 2, 0, 0));
    assert_hi("14 नवम्बर 2025", "14 नवम्बर 2025", dt(2025, 11, 14, 0, 0));
    assert_hi("25 दिसम्बर 2025", "25 दिसम्बर 2025", dt(2025, 12, 25, 0, 0));
    assert_hi("26 जन॰ 2026", "26 जन॰ 2026", dt(2026, 1, 26, 0, 0));
    assert_hi("14 सित. 2025", "14 सित. 2025", dt(2025, 9, 14, 0, 0));

    assert_hi("मार्च 14", "मार्च 14", dt(2025, 3, 14, 0, 0));
    assert_hi("मार्च 14, 2025", "मार्च 14, 2025", dt(2025, 3, 14, 0, 0));
    assert_hi(
        "मार्च की 14 तारीख",
        "मार्च की 14 तारीख",
        dt(2025, 3, 14, 0, 0),
    );
    assert_hi("जनवरी 2026", "जनवरी 2026", dt(2026, 1, 1, 0, 0));
    assert_hi("साल 2026 में मार्च", "साल 2026 में मार्च", dt(2026, 3, 1, 0, 0));
    assert_hi("पहली तारीख", "पहली तारीख", dt(2025, 3, 1, 0, 0));
    assert_hi("21वीं तारीख", "21वीं तारीख", dt(2025, 2, 21, 0, 0));

    assert_hi("14/03/2025", "14/03/2025", dt(2025, 3, 14, 0, 0));
    assert_hi("14-03-2025", "14-03-2025", dt(2025, 3, 14, 0, 0));
    assert_hi("14.03.2025", "14.03.2025", dt(2025, 3, 14, 0, 0));
    assert_hi("14/03/25", "14/03/25", dt(2025, 3, 14, 0, 0));
    assert_hi("2025-03-14", "2025-03-14", dt(2025, 3, 14, 0, 0));
    assert_hi("2025/03/14", "2025/03/14", dt(2025, 3, 14, 0, 0));
}

#[test]
fn nth_weekday_of_month() {
    assert_hi(
        "मार्च का पहला सोमवार",
        "मार्च का पहला सोमवार",
        dt(2025, 3, 3, 0, 0),
    );
    assert_hi(
        "मार्च के तीसरे सोमवार",
        "मार्च के तीसरे सोमवार",
        dt(2025, 3, 17, 0, 0),
    );
    assert_hi(
        "अप्रैल का आखिरी शुक्रवार",
        "अप्रैल का आखिरी शुक्रवार",
        dt(2025, 4, 25, 0, 0),
    );
    assert_hi(
        "जनवरी का पहला सोमवार",
        "जनवरी का पहला सोमवार",
        dt(2026, 1, 5, 0, 0),
    );
    assert_hi(
        "मार्च के तीसरे सोमवार को शाम 4 बजे",
        "मार्च के तीसरे सोमवार को शाम 4 बजे",
        dt(2025, 3, 17, 16, 0),
    );
}

#[test]
fn relative_offsets_and_within() {
    assert_hi("3 दिन में", "3 दिन में", dt(2025, 2, 11, 0, 0));
    assert_hi("2 दिनों बाद", "2 दिनों बाद", dt(2025, 2, 10, 0, 0));
    assert_hi("3 दिनों के बाद", "3 दिनों के बाद", dt(2025, 2, 11, 0, 0));
    assert_hi("5 दिन पहले", "5 दिन पहले", dt(2025, 2, 3, 0, 0));
    assert_hi("3 दिन पूर्व", "3 दिन पूर्व", dt(2025, 2, 5, 0, 0));
    assert_hi("दो दिन बाद", "दो दिन बाद", dt(2025, 2, 10, 0, 0));
    assert_hi("तीन हफ्ते पहले", "तीन हफ्ते पहले", dt(2025, 1, 18, 0, 0));
    assert_hi("1 महीना बाद", "1 महीना बाद", dt(2025, 3, 1, 0, 0));
    assert_hi("2 माह पहले", "2 माह पहले", dt(2024, 12, 1, 0, 0));
    assert_hi("2 वर्ष बाद", "2 वर्ष बाद", dt(2027, 2, 1, 0, 0));

    let parser = Parser::default();
    let opts = hi_opts();
    for input in ["3 दिन के अंदर", "3 दिनों के भीतर", "अगले 3 दिनों में"]
    {
        let ranges = parser.parse_ranges(input, &opts).unwrap();
        assert_eq!(ranges.len(), 1, "expected 1 range for {input:?}");
        assert_eq!(ranges[0].date, dt(2025, 2, 8, 0, 0));
        assert_eq!(ranges[0].range_days, Some(4));
        assert_eq!(&input[ranges[0].start..ranges[0].end], input);
    }

    let weeks_within = parser.parse_ranges("अगले 2 सप्ताह के अंदर", &opts).unwrap();
    assert_eq!(weeks_within.len(), 1);
    assert_eq!(weeks_within[0].range_days, Some(15));
}

#[test]
fn times_meridiems_and_idioms() {
    assert_hi("14:30:45", "14:30:45", dt(2025, 2, 8, 14, 30));
    assert_hi("10:30 बजे", "10:30 बजे", dt(2025, 2, 9, 10, 30));
    assert_hi("15 बजे", "15 बजे", dt(2025, 2, 8, 15, 0));
    assert_hi("पाँच बजे", "पाँच बजे", dt(2025, 2, 9, 5, 0));
    assert_hi("3 बजकर 20 मिनट", "3 बजकर 20 मिनट", dt(2025, 2, 9, 3, 20));
    assert_hi(
        "तीन बजकर पंद्रह मिनट",
        "तीन बजकर पंद्रह मिनट",
        dt(2025, 2, 9, 3, 15),
    );
    assert_hi("5 बजने में 10 मिनट", "5 बजने में 10 मिनट", dt(2025, 2, 9, 4, 50));

    assert_hi("3 pm", "3 pm", dt(2025, 2, 8, 15, 0));
    assert_hi("3:30 PM", "3:30 PM", dt(2025, 2, 8, 15, 30));
    assert_hi("10:15 a.m.", "10:15 a.m.", dt(2025, 2, 9, 10, 15));
    assert_hi("12:30 am", "12:30 am", dt(2025, 2, 9, 0, 30));
    assert_hi("12:30 pm", "12:30 pm", dt(2025, 2, 8, 12, 30));
    assert_hi("5 पीएम", "5 पीएम", dt(2025, 2, 8, 17, 0));
    assert_hi("10 एएम", "10 एएम", dt(2025, 2, 9, 10, 0));

    assert_hi("आधी रात", "आधी रात", dt(2025, 2, 9, 0, 0));
    assert_hi("मध्याह्न", "मध्याह्न", dt(2025, 2, 8, 12, 0));
    assert_hi("ठीक दोपहर", "ठीक दोपहर", dt(2025, 2, 8, 12, 0));

    assert_hi("डेढ़ बजे", "डेढ़ बजे", dt(2025, 2, 9, 1, 30));
    assert_hi("ढाई बजे", "ढाई बजे", dt(2025, 2, 9, 2, 30));
    assert_hi("साढ़े तीन बजे", "साढ़े तीन बजे", dt(2025, 2, 9, 3, 30));
    assert_hi("साढ़े 4 बजे", "साढ़े 4 बजे", dt(2025, 2, 9, 4, 30));
    assert_hi("सवा दो बजे", "सवा दो बजे", dt(2025, 2, 9, 2, 15));
    assert_hi("पौने पांच बजे", "पौने पांच बजे", dt(2025, 2, 9, 4, 45));
    assert_hi("दोपहर पौने 1 बजे", "दोपहर पौने 1 बजे", dt(2025, 2, 8, 12, 45));
    assert_hi("सुबह पौने 12 बजे", "सुबह पौने 12 बजे", dt(2025, 2, 8, 11, 45));

    assert_hi("प्रातः 7 बजे", "प्रातः 7 बजे", dt(2025, 2, 9, 7, 0));
    assert_hi("अपराह्न 3:30", "अपराह्न 3:30", dt(2025, 2, 8, 15, 30));
    assert_hi("सायं 6 बजे", "सायं 6 बजे", dt(2025, 2, 8, 18, 0));
    assert_hi("रात्रि 9 बजे", "रात्रि 9 बजे", dt(2025, 2, 8, 21, 0));
}

#[test]
fn devanagari_digits_utf8_spans_and_ranges() {
    let s1 = "मीटिंग १४ मार्च २०२५ को है";
    assert_hi(s1, "१४ मार्च २०२५", dt(2025, 3, 14, 0, 0));

    let s2 = "सुबह १०:३० बजे आइए";
    assert_hi(s2, "सुबह १०:३० बजे", dt(2025, 2, 9, 10, 30));

    let s3 = "२ दिन बाद";
    assert_hi(s3, "२ दिन बाद", dt(2025, 2, 10, 0, 0));

    let s4 = "१४/०३/२०२५";
    assert_hi(s4, "१४/०३/२०२५", dt(2025, 3, 14, 0, 0));

    let parser = Parser::default();
    let mut opts = hi_opts();
    opts.range = true;
    let week = parser.parse("इस हफ्ते", &opts).unwrap();
    assert_eq!(week.len(), 7);
    assert_eq!(week[0].date, dt(2025, 2, 2, 0, 0));
    assert_eq!(week[6].date, dt(2025, 2, 8, 0, 0));

    let mut multi = parser.parse("कल और परसों आना", &opts).unwrap();
    multi.sort_by_key(|m| m.start);
    assert_eq!(multi.len(), 2);
    assert_eq!(multi[0].date, dt(2025, 2, 9, 0, 0));
    assert_eq!(multi[1].date, dt(2025, 2, 10, 0, 0));
}

#[test]
fn boundary_guards_and_negative_cases() {
    assert_none("आजकल");
    assert_none("सोमवारों");
    assert_none("15 तारीखों");
    assert_none("मार्चक");
    assert_none("14/03/20250");
    assert_none("10.20.30.40");
    assert_none("3pmX");
    assert_none("10 PMZ");
    assert_none("10 एएमक");
    assert_none("अनेक दिन पहले");
    assert_none("सुबह");
    assert_none("दोपहर");
    assert_none("31/02/2025");
    assert_none("25:00");
    assert_none("15 pm");

    assert_hi("मार्च 14:30", "मार्च 14:30", dt(2025, 3, 1, 14, 30));
    assert_hi("मार्च 10 बजे", "मार्च 10 बजे", dt(2025, 3, 1, 10, 0));
    assert_hi("मार्च 3 pm", "मार्च 3 pm", dt(2025, 3, 1, 15, 0));
    assert_hi(
        "2025-02-08T15:00:00Z",
        "2025-02-08T15:00:00Z",
        dt(2025, 2, 8, 15, 0),
    );
}

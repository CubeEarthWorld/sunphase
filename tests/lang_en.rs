use sunphase::{NaiveDate, NaiveDateTime, Options, Parser, parse_with};

fn dt(y: i32, m: u32, d: u32, h: u32, min: u32) -> NaiveDateTime {
    NaiveDate::from_ymd_opt(y, m, d)
        .unwrap()
        .and_hms_opt(h, min, 0)
        .unwrap()
}

fn ref_sat() -> NaiveDateTime {
    dt(2025, 2, 8, 11, 5)
}

fn opts(reference: NaiveDateTime) -> Options<'static> {
    let mut o = Options::new(reference);
    o.languages = &["en"];
    o
}

fn assert_first(text: &str, reference: NaiveDateTime, slice: &str, expected: NaiveDateTime) {
    let ms = parse_with(text, &opts(reference)).unwrap();
    assert_eq!(ms.len(), 1, "expected 1 match for {text:?}, got {ms:?}");
    let m = &ms[0];
    assert_eq!(&text[m.start..m.end], slice, "span mismatch for {text:?}");
    assert_eq!(m.date, expected, "date mismatch for {text:?}");
}

fn assert_empty(text: &str, reference: NaiveDateTime) {
    let ms = parse_with(text, &opts(reference)).unwrap();
    assert!(ms.is_empty(), "expected no match for {text:?}, got {ms:?}");
}

#[test]
fn legacy_en_cases_preserved() {
    let r = ref_sat();
    assert_first("Today", r, "Today", dt(2025, 2, 8, 0, 0));
    assert_first("Tomorrow", r, "Tomorrow", dt(2025, 2, 9, 0, 0));
    assert_first("Yesterday", r, "Yesterday", dt(2025, 2, 7, 0, 0));
    assert_first("Midnight", r, "Midnight", dt(2025, 2, 9, 0, 0));
    assert_first(
        "Lunch with client at noon",
        r,
        "noon",
        dt(2025, 2, 8, 12, 0),
    );
    assert_first("Gym session at 06:00", r, "06:00", dt(2025, 2, 9, 6, 0));
    assert_first(
        "2 weeks from now",
        r,
        "2 weeks from now",
        dt(2025, 2, 22, 0, 0),
    );
    assert_first("4 days later", r, "4 days later", dt(2025, 2, 12, 0, 0));
    assert_first("5 days ago", r, "5 days ago", dt(2025, 2, 3, 0, 0));
    assert_first("Last Friday", r, "Last Friday", dt(2025, 2, 7, 0, 0));
    assert_first("march 7 10:10", r, "march 7 10:10", dt(2025, 3, 7, 10, 10));
    assert_first("the 16th", r, "the 16th", dt(2025, 2, 16, 0, 0));
    assert_first("February 28", r, "February 28", dt(2025, 2, 28, 0, 0));
    assert_first(
        "March 14, 2025 15:30",
        r,
        "March 14, 2025 15:30",
        dt(2025, 3, 14, 15, 30),
    );
    assert_first(
        "Dentist on the 20th at 3pm",
        r,
        "the 20th at 3pm",
        dt(2025, 2, 20, 15, 0),
    );
    assert_first(
        "next month on the 21st at 2pm",
        r,
        "next month on the 21st at 2pm",
        dt(2025, 3, 21, 14, 0),
    );
    assert_first(
        "next Tuesday at 2:30pm",
        r,
        "next Tuesday at 2:30pm",
        dt(2025, 2, 11, 14, 30),
    );
    assert_first(
        "next week Tuesday at 14:14",
        r,
        "next week Tuesday at 14:14",
        dt(2025, 2, 11, 14, 14),
    );
    assert_first(
        "tomorrow at 14:00",
        r,
        "tomorrow at 14:00",
        dt(2025, 2, 9, 14, 0),
    );
    assert_first(
        "the 21st at 14:00",
        r,
        "the 21st at 14:00",
        dt(2025, 2, 21, 14, 0),
    );
    assert_first(
        "in 3 days at 9am",
        r,
        "in 3 days at 9am",
        dt(2025, 2, 11, 9, 0),
    );
    assert_first("Meeting on １５th", r, "１５th", dt(2025, 2, 15, 0, 0));

    let mut default_opts = Options::new(r);
    default_opts.languages = &["en", "ja", "zh"];
    let cjk = parse_with("Today買い物をする", &default_opts).unwrap();
    assert_eq!(cjk.len(), 1);
    assert_eq!(&"Today買い物をする"[cjk[0].start..cjk[0].end], "Today");
    assert_eq!(cjk[0].date, dt(2025, 2, 8, 0, 0));

    let mut ws1 = opts(r);
    ws1.week_start = 1;
    let m_ws7 = parse_with("next week Sunday", &opts(r)).unwrap();
    assert_eq!(m_ws7[0].date, dt(2025, 2, 9, 0, 0));
    let m_ws1 = parse_with("next week Sunday", &ws1).unwrap();
    assert_eq!(m_ws1[0].date, dt(2025, 2, 16, 0, 0));

    let nyj = parse_with("next year January", &opts(r)).unwrap();
    assert_eq!(nyj[0].date, dt(2026, 1, 1, 0, 0));
    assert_eq!(nyj[0].range_type, Some("month"));

    let mut range_opts = opts(r);
    range_opts.range = true;
    let week_days = parse_with("next week go to university", &range_opts).unwrap();
    assert_eq!(week_days.len(), 7);
    assert_eq!(week_days[0].date, dt(2025, 2, 9, 0, 0));
    assert_eq!(week_days[6].date, dt(2025, 2, 15, 0, 0));
    let march_days = parse_with("march", &range_opts).unwrap();
    assert_eq!(march_days.len(), 31);
    assert_eq!(march_days[0].date, dt(2025, 3, 1, 0, 0));
    assert_eq!(march_days[30].date, dt(2025, 3, 31, 0, 0));
}

#[test]
fn relative_days_and_utf8_spans() {
    let r = ref_sat();
    assert_first("tmrw", r, "tmrw", dt(2025, 2, 9, 0, 0));
    assert_first("tmw", r, "tmw", dt(2025, 2, 9, 0, 0));
    assert_first("overmorrow", r, "overmorrow", dt(2025, 2, 10, 0, 0));
    assert_first(
        "day after tomorrow",
        r,
        "day after tomorrow",
        dt(2025, 2, 10, 0, 0),
    );
    assert_first(
        "See you the day after tomorrow at 3pm",
        r,
        "the day after tomorrow at 3pm",
        dt(2025, 2, 10, 15, 0),
    );
    assert_first(
        "day before yesterday",
        r,
        "day before yesterday",
        dt(2025, 2, 6, 0, 0),
    );
    assert_first(
        "the day before yesterday at 9am",
        r,
        "the day before yesterday at 9am",
        dt(2025, 2, 6, 9, 0),
    );
    assert_first("tonight", r, "tonight", dt(2025, 2, 8, 12, 0));
    assert_first("this morning", r, "this morning", dt(2025, 2, 8, 0, 0));
    assert_first("this afternoon", r, "this afternoon", dt(2025, 2, 8, 12, 0));
    assert_first("this evening", r, "this evening", dt(2025, 2, 8, 12, 0));
    assert_first("last night", r, "last night", dt(2025, 2, 7, 12, 0));
    assert_first(
        "会議 tomorrow at 3pm",
        r,
        "tomorrow at 3pm",
        dt(2025, 2, 9, 15, 0),
    );
}

#[test]
fn anchors_and_weekends() {
    let r = ref_sat();
    let ty = parse_with("this year", &opts(r)).unwrap();
    assert_eq!(ty[0].date, dt(2025, 2, 1, 0, 0));
    let ny = parse_with("next year", &opts(r)).unwrap();
    assert_eq!(ny[0].date, dt(2026, 2, 1, 0, 0));
    let ly = parse_with("last year", &opts(r)).unwrap();
    assert_eq!(ly[0].date, dt(2024, 2, 1, 0, 0));

    assert_first("weekend", r, "weekend", dt(2025, 2, 9, 0, 0));
    assert_first("this weekend", r, "this weekend", dt(2025, 2, 9, 0, 0));
    assert_first("next weekend", r, "next weekend", dt(2025, 2, 9, 0, 0));
    assert_first("last weekend", r, "last weekend", dt(2025, 2, 2, 0, 0));
    assert_first(
        "this weekend at 4pm",
        r,
        "this weekend at 4pm",
        dt(2025, 2, 9, 16, 0),
    );

    assert_first("coming week", r, "coming week", dt(2025, 2, 9, 0, 0));
    assert_first(
        "following month",
        r,
        "following month",
        dt(2025, 3, 1, 0, 0),
    );
    assert_first("past week", r, "past week", dt(2025, 1, 26, 0, 0));
    assert_first("previous year", r, "previous year", dt(2024, 2, 1, 0, 0));
    assert_first(
        "the week after next",
        r,
        "the week after next",
        dt(2025, 2, 16, 0, 0),
    );
    assert_first(
        "the week before last",
        r,
        "the week before last",
        dt(2025, 1, 19, 0, 0),
    );
    assert_first(
        "month after next",
        r,
        "month after next",
        dt(2025, 4, 1, 0, 0),
    );
    assert_first(
        "month before last",
        r,
        "month before last",
        dt(2024, 12, 1, 0, 0),
    );

    let mut range_opts = opts(r);
    range_opts.range = true;
    let compact = Parser::default()
        .parse_ranges("next month", &range_opts)
        .unwrap();
    assert_eq!(compact.len(), 1);
    assert_eq!(compact[0].range_type, Some("month"));
}

#[test]
fn weekdays_and_modifiers() {
    let r = ref_sat();
    assert_first("Tues", r, "Tues", dt(2025, 2, 11, 0, 0));
    assert_first("Weds", r, "Weds", dt(2025, 2, 12, 0, 0));
    assert_first("Thur", r, "Thur", dt(2025, 2, 13, 0, 0));
    assert_first("Thurs", r, "Thurs", dt(2025, 2, 13, 0, 0));
    assert_first("this Monday", r, "this Monday", dt(2025, 2, 10, 0, 0));
    assert_first("this Sunday", r, "this Sunday", dt(2025, 2, 9, 0, 0));
    assert_first("coming Thurs", r, "coming Thurs", dt(2025, 2, 13, 0, 0));
    assert_first("following Tues", r, "following Tues", dt(2025, 2, 11, 0, 0));
    assert_first("past Weds", r, "past Weds", dt(2025, 2, 5, 0, 0));
    assert_first("previous Mon", r, "previous Mon", dt(2025, 2, 3, 0, 0));
    assert_first(
        "this week Monday",
        r,
        "this week Monday",
        dt(2025, 2, 3, 0, 0),
    );
}

#[test]
fn dates_months_and_numeric_formats() {
    let r = ref_sat();
    assert_first("Jan. 15, 2025", r, "Jan. 15, 2025", dt(2025, 1, 15, 0, 0));
    assert_first("Sept 3rd, 2026", r, "Sept 3rd, 2026", dt(2026, 9, 3, 0, 0));
    assert_first(
        "March the 14th, 2025",
        r,
        "March the 14th, 2025",
        dt(2025, 3, 14, 0, 0),
    );
    assert_first("14 March 2025", r, "14 March 2025", dt(2025, 3, 14, 0, 0));
    assert_first("14th of March", r, "14th of March", dt(2025, 3, 14, 0, 0));
    assert_first(
        "the 14th of March, 2025",
        r,
        "the 14th of March, 2025",
        dt(2025, 3, 14, 0, 0),
    );
    assert_first("1st Jan. 2026", r, "1st Jan. 2026", dt(2026, 1, 1, 0, 0));
    assert_first("08-Feb-2025", r, "08-Feb-2025", dt(2025, 2, 8, 0, 0));
    assert_first("March 2026", r, "March 2026", dt(2026, 3, 1, 0, 0));
    assert_first(
        "February of 2027",
        r,
        "February of 2027",
        dt(2027, 2, 1, 0, 0),
    );
    assert_first("the 31st", r, "the 31st", dt(2025, 3, 31, 0, 0));
    assert_first("Feb 29", r, "Feb 29", dt(2028, 2, 29, 0, 0));
    assert_first("2025-03-14", r, "2025-03-14", dt(2025, 3, 14, 0, 0));
    assert_first("03/14/2025", r, "03/14/2025", dt(2025, 3, 14, 0, 0));
    assert_first("14/03/2025", r, "14/03/2025", dt(2025, 3, 14, 0, 0));
    assert_first("14-03-2025", r, "14-03-2025", dt(2025, 3, 14, 0, 0));
    assert_first("03/14/26", r, "03/14/26", dt(2026, 3, 14, 0, 0));
    assert_first("14/03/26", r, "14/03/26", dt(2026, 3, 14, 0, 0));
    assert_first("14.02.2025", r, "14.02.2025", dt(2025, 2, 14, 0, 0));
    assert_first("2025.02.14", r, "2025.02.14", dt(2025, 2, 14, 0, 0));
    assert_first(
        "Meeting on 14.02.2025.",
        r,
        "14.02.2025",
        dt(2025, 2, 14, 0, 0),
    );
    assert_first("On 15 Jan.", r, "15 Jan", dt(2026, 1, 15, 0, 0));
}

#[test]
fn nth_weekday_of_month() {
    let r = ref_sat();
    assert_first(
        "first Monday of March",
        r,
        "first Monday of March",
        dt(2025, 3, 3, 0, 0),
    );
    assert_first(
        "the 3rd Monday of March",
        r,
        "the 3rd Monday of March",
        dt(2025, 3, 17, 0, 0),
    );
    assert_first(
        "2nd Tuesday in April",
        r,
        "2nd Tuesday in April",
        dt(2025, 4, 8, 0, 0),
    );
    assert_first(
        "last Friday of February",
        r,
        "last Friday of February",
        dt(2025, 2, 28, 0, 0),
    );
    assert_first(
        "5th Saturday of March",
        r,
        "5th Saturday of March",
        dt(2025, 3, 29, 0, 0),
    );
    assert_first(
        "first Monday of March at 3pm",
        r,
        "first Monday of March at 3pm",
        dt(2025, 3, 3, 15, 0),
    );
    assert_empty("5th Monday of February", r);
}

#[test]
fn relative_offsets_and_within() {
    let r = ref_sat();
    assert_first("in a day", r, "in a day", dt(2025, 2, 9, 0, 0));
    assert_first("in a week", r, "in a week", dt(2025, 2, 15, 0, 0));
    assert_first("in one month", r, "in one month", dt(2025, 3, 1, 0, 0));
    assert_first("in two years", r, "in two years", dt(2027, 2, 1, 0, 0));
    assert_first(
        "in twenty-one days",
        r,
        "in twenty-one days",
        dt(2025, 3, 1, 0, 0),
    );
    assert_first("in 2 wks", r, "in 2 wks", dt(2025, 2, 22, 0, 0));
    assert_first(
        "in two weeks' time",
        r,
        "in two weeks' time",
        dt(2025, 2, 22, 0, 0),
    );
    assert_first("a week ago", r, "a week ago", dt(2025, 2, 1, 0, 0));
    assert_first("two weeks ago", r, "two weeks ago", dt(2025, 1, 25, 0, 0));
    assert_first(
        "one month later",
        r,
        "one month later",
        dt(2025, 3, 1, 0, 0),
    );
    assert_first(
        "three days earlier",
        r,
        "three days earlier",
        dt(2025, 2, 5, 0, 0),
    );

    let mut range_opts = opts(r);
    range_opts.range = true;

    let w3 = Parser::default()
        .parse_ranges("within 3 days", &range_opts)
        .unwrap();
    assert_eq!(w3.len(), 1);
    assert_eq!(w3[0].date, dt(2025, 2, 8, 0, 0));
    assert_eq!(w3[0].range_days, Some(4));

    let w3_expanded = parse_with("within 3 days", &range_opts).unwrap();
    assert_eq!(w3_expanded.len(), 4);
    assert_eq!(w3_expanded[3].date, dt(2025, 2, 11, 0, 0));

    let w1 = Parser::default()
        .parse_ranges("within a day", &range_opts)
        .unwrap();
    assert_eq!(w1[0].range_days, Some(2));

    let w5 = Parser::default()
        .parse_ranges("within the next 5 days", &range_opts)
        .unwrap();
    assert_eq!(w5[0].range_days, Some(6));

    let w2w = Parser::default()
        .parse_ranges("within 2 weeks", &range_opts)
        .unwrap();
    assert_eq!(w2w[0].range_days, Some(15));

    let w0 = Parser::default()
        .parse_ranges("within 0 days", &range_opts)
        .unwrap();
    assert_eq!(w0[0].range_days, Some(1));
}

#[test]
fn times_spoken_meridiems_and_composition() {
    let r = ref_sat();
    assert_first("14:30:45", r, "14:30:45", dt(2025, 2, 8, 14, 30));
    assert_first("3 p.m.", r, "3 p.m.", dt(2025, 2, 8, 15, 0));
    assert_first("9 a.m.", r, "9 a.m.", dt(2025, 2, 9, 9, 0));
    assert_first("3.30pm", r, "3.30pm", dt(2025, 2, 8, 15, 30));
    assert_first("midday", r, "midday", dt(2025, 2, 8, 12, 0));

    assert_first("3 o'clock", r, "3 o'clock", dt(2025, 2, 9, 3, 0));
    assert_first("five o'clock", r, "five o'clock", dt(2025, 2, 9, 5, 0));
    assert_first("12 o’clock", r, "12 o’clock", dt(2025, 2, 8, 12, 0));
    assert_first("3 o'clock pm", r, "3 o'clock pm", dt(2025, 2, 8, 15, 0));

    assert_first("half past 3", r, "half past 3", dt(2025, 2, 9, 3, 30));
    assert_first(
        "half past three",
        r,
        "half past three",
        dt(2025, 2, 9, 3, 30),
    );
    assert_first("half past 3pm", r, "half past 3pm", dt(2025, 2, 8, 15, 30));
    assert_first(
        "half past 3 in the afternoon",
        r,
        "half past 3 in the afternoon",
        dt(2025, 2, 8, 15, 30),
    );
    assert_first(
        "half past noon",
        r,
        "half past noon",
        dt(2025, 2, 8, 12, 30),
    );
    assert_first(
        "half past midnight",
        r,
        "half past midnight",
        dt(2025, 2, 9, 0, 30),
    );

    assert_first("quarter past 3", r, "quarter past 3", dt(2025, 2, 9, 3, 15));
    assert_first(
        "a quarter after 5",
        r,
        "a quarter after 5",
        dt(2025, 2, 9, 5, 15),
    );
    assert_first("quarter to 4", r, "quarter to 4", dt(2025, 2, 9, 3, 45));
    assert_first(
        "quarter to 4pm",
        r,
        "quarter to 4pm",
        dt(2025, 2, 8, 15, 45),
    );
    assert_first("quarter to 1", r, "quarter to 1", dt(2025, 2, 9, 0, 45));
    assert_first(
        "quarter to 1pm",
        r,
        "quarter to 1pm",
        dt(2025, 2, 8, 12, 45),
    );
    assert_first("quarter to 1am", r, "quarter to 1am", dt(2025, 2, 9, 0, 45));
    assert_first("quarter to 12", r, "quarter to 12", dt(2025, 2, 8, 11, 45));
    assert_first(
        "quarter to 12pm",
        r,
        "quarter to 12pm",
        dt(2025, 2, 8, 11, 45),
    );
    assert_first(
        "quarter to 12am",
        r,
        "quarter to 12am",
        dt(2025, 2, 8, 23, 45),
    );
    assert_first(
        "quarter to noon",
        r,
        "quarter to noon",
        dt(2025, 2, 8, 11, 45),
    );
    assert_first(
        "quarter to midnight",
        r,
        "quarter to midnight",
        dt(2025, 2, 8, 23, 45),
    );
    assert_first(
        "10 minutes past 3",
        r,
        "10 minutes past 3",
        dt(2025, 2, 9, 3, 10),
    );
    assert_first(
        "15 minutes to 4",
        r,
        "15 minutes to 4",
        dt(2025, 2, 9, 3, 45),
    );

    assert_first(
        "9 in the morning",
        r,
        "9 in the morning",
        dt(2025, 2, 9, 9, 0),
    );
    assert_first(
        "3 in the afternoon",
        r,
        "3 in the afternoon",
        dt(2025, 2, 8, 15, 0),
    );
    assert_first(
        "8 in the evening",
        r,
        "8 in the evening",
        dt(2025, 2, 8, 20, 0),
    );
    assert_first("10 at night", r, "10 at night", dt(2025, 2, 8, 22, 0));
    assert_first(
        "tomorrow morning at 9",
        r,
        "tomorrow morning at 9",
        dt(2025, 2, 9, 9, 0),
    );
    assert_first(
        "tomorrow morning at 9am",
        r,
        "tomorrow morning at 9am",
        dt(2025, 2, 9, 9, 0),
    );
    assert_first("tonight at 8", r, "tonight at 8", dt(2025, 2, 8, 20, 0));
    assert_first("tonight at 8pm", r, "tonight at 8pm", dt(2025, 2, 8, 20, 0));
    assert_first(
        "tonight at 21:31",
        r,
        "tonight at 21:31",
        dt(2025, 2, 8, 21, 31),
    );
    assert_first("8pm tonight", r, "8pm tonight", dt(2025, 2, 8, 20, 0));
    assert_first(
        "this evening at 7:15",
        r,
        "this evening at 7:15",
        dt(2025, 2, 8, 19, 15),
    );
    assert_first(
        "last night at 10",
        r,
        "last night at 10",
        dt(2025, 2, 7, 22, 0),
    );

    assert_first("Monday @ 3pm", r, "Monday @ 3pm", dt(2025, 2, 10, 15, 0));
    assert_first(
        "tomorrow around 4pm",
        r,
        "tomorrow around 4pm",
        dt(2025, 2, 9, 16, 0),
    );
    assert_first("Friday by 5pm", r, "Friday by 5pm", dt(2025, 2, 14, 17, 0));
}

#[test]
fn multi_match_range_and_offset_minutes() {
    let r = ref_sat();
    let mut range_opts = opts(r);
    range_opts.range = true;
    let text = "Meeting on Monday at 9am and lunch tomorrow at noon";
    let mut ms = parse_with(text, &range_opts).unwrap();
    ms.sort_by_key(|m| m.start);
    assert_eq!(ms.len(), 2);
    assert_eq!(&text[ms[0].start..ms[0].end], "Monday at 9am");
    assert_eq!(ms[0].date, dt(2025, 2, 10, 9, 0));
    assert_eq!(&text[ms[1].start..ms[1].end], "tomorrow at noon");
    assert_eq!(ms[1].date, dt(2025, 2, 9, 12, 0));

    let mut offset_opts = opts(r);
    offset_opts.offset_minutes = 60;
    let shifted = parse_with("tomorrow at 9am", &offset_opts).unwrap();
    assert_eq!(shifted[0].date, dt(2025, 2, 9, 10, 0));
}

#[test]
fn negative_boundaries_and_false_positives() {
    let r = ref_sat();
    for bad in [
        "15thFloor",
        "15thA",
        "v15th",
        "1.5th",
        "TomorrowX",
        "MondayB",
        "3pmA",
        "v3pm",
        "3.5pm",
        "win 3 days",
        "192.168.1.1",
        "v1.2.3",
        "1-2-3",
        "2025-02-08-99",
        "12:60",
        "good morning",
        "all night",
        "10 to 4",
        "half of 12",
        "2025-02-30",
        "14/14/2025",
        "25:00",
        "15am",
    ] {
        assert_empty(bad, r);
    }

    assert_first("Tonight 3 friends", r, "Tonight", dt(2025, 2, 8, 12, 0));
    assert_first(
        "This morning 2 emails",
        r,
        "This morning",
        dt(2025, 2, 8, 0, 0),
    );
    assert_first("scored 3 tonight", r, "tonight", dt(2025, 2, 8, 12, 0));
}

use sunphase::{Match, NaiveDate, NaiveDateTime, Options, Parser, parse_with};

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

fn parse_one_ws(input: &str, week_start: u8) -> Match {
    let mut opts = Options::new(ref_dt());
    opts.languages = &["ko"];
    opts.week_start = week_start;
    let matches = parse_with(input, &opts).unwrap();
    assert_eq!(
        matches.len(),
        1,
        "expected 1 match for {input:?}, got {matches:?}"
    );
    matches.into_iter().next().unwrap()
}

fn parse_one(input: &str) -> Match {
    parse_one_ws(input, 7)
}

fn assert_match(input: &str, expected_span: &str, expected_date: NaiveDateTime) {
    let m = parse_one(input);
    assert_eq!(
        &input[m.start..m.end],
        expected_span,
        "span mismatch for {input:?}"
    );
    assert_eq!(m.date, expected_date, "date mismatch for {input:?}");
}

fn assert_match_ws(input: &str, ws: u8, expected_span: &str, expected_date: NaiveDateTime) {
    let m = parse_one_ws(input, ws);
    assert_eq!(
        &input[m.start..m.end],
        expected_span,
        "span mismatch for {input:?} (ws={ws})"
    );
    assert_eq!(
        m.date, expected_date,
        "date mismatch for {input:?} (ws={ws})"
    );
}

fn parse_range(input: &str) -> Vec<Match> {
    let mut opts = Options::new(ref_dt());
    opts.languages = &["ko"];
    opts.range = true;
    parse_with(input, &opts).unwrap()
}

fn parse_compact(input: &str, ws: u8) -> Vec<Match> {
    let mut opts = Options::new(ref_dt());
    opts.languages = &["ko"];
    opts.range = true;
    opts.week_start = ws;
    Parser::default().parse_ranges(input, &opts).unwrap()
}

fn assert_none(input: &str) {
    let matches = parse_range(input);
    assert!(
        matches.is_empty(),
        "expected no match for {input:?}, got {matches:?}"
    );
}

#[test]
fn relative_days_and_tonight() {
    assert_match("오늘", "오늘", dt(2025, 2, 8, 0, 0));
    assert_match("금일", "금일", dt(2025, 2, 8, 0, 0));
    assert_match("내일", "내일", dt(2025, 2, 9, 0, 0));
    assert_match("명일", "명일", dt(2025, 2, 9, 0, 0));
    assert_match("모레", "모레", dt(2025, 2, 10, 0, 0));
    assert_match("내일모레", "내일모레", dt(2025, 2, 10, 0, 0));
    assert_match("내일 모레", "내일 모레", dt(2025, 2, 10, 0, 0));
    assert_match("글피", "글피", dt(2025, 2, 11, 0, 0));
    assert_match("그글피", "그글피", dt(2025, 2, 12, 0, 0));
    assert_match("어제", "어제", dt(2025, 2, 7, 0, 0));
    assert_match("어저께", "어저께", dt(2025, 2, 7, 0, 0));
    assert_match("작일", "작일", dt(2025, 2, 7, 0, 0));
    assert_match("그제", "그제", dt(2025, 2, 6, 0, 0));
    assert_match("그저께", "그저께", dt(2025, 2, 6, 0, 0));
    assert_match("그끄제", "그끄제", dt(2025, 2, 5, 0, 0));
    assert_match("그끄저께", "그끄저께", dt(2025, 2, 5, 0, 0));

    assert_match("오늘밤", "오늘밤", dt(2025, 2, 8, 12, 0));
    assert_match("오늘밤 9시", "오늘밤 9시", dt(2025, 2, 8, 21, 0));
    assert_match(
        "오늘 밤 9시 30분",
        "오늘 밤 9시 30분",
        dt(2025, 2, 8, 21, 30),
    );
    assert_match("오늘 저녁 7시", "오늘 저녁 7시", dt(2025, 2, 8, 19, 0));
    assert_match("내일 아침 8시", "내일 아침 8시", dt(2025, 2, 9, 8, 0));
    assert_match("모레 새벽 5시", "모레 새벽 5시", dt(2025, 2, 10, 5, 0));
    assert_match("내일 낮 1시", "내일 낮 1시", dt(2025, 2, 9, 13, 0));
}

#[test]
fn anchors_week_weekend_month_year() {
    let m = parse_one_ws("이번 주", 7);
    assert_eq!(
        (&"이번 주"[m.start..m.end], m.date, m.range_type),
        ("이번 주", dt(2025, 2, 2, 0, 0), Some("week"))
    );
    let m = parse_one_ws("이번 주", 1);
    assert_eq!((m.date, m.range_type), (dt(2025, 2, 3, 0, 0), Some("week")));

    assert_match_ws("금주", 1, "금주", dt(2025, 2, 3, 0, 0));
    assert_match_ws("다음 주", 7, "다음 주", dt(2025, 2, 9, 0, 0));
    assert_match_ws("차주", 1, "차주", dt(2025, 2, 10, 0, 0));
    assert_match_ws("다다음 주", 7, "다다음 주", dt(2025, 2, 16, 0, 0));
    assert_match_ws("차차주", 1, "차차주", dt(2025, 2, 17, 0, 0));
    assert_match_ws("지난 주", 7, "지난 주", dt(2025, 1, 26, 0, 0));
    assert_match_ws("저번 주", 1, "저번 주", dt(2025, 1, 27, 0, 0));
    assert_match_ws("지지난 주", 7, "지지난 주", dt(2025, 1, 19, 0, 0));

    let expanded = parse_range("차주");
    assert_eq!(expanded.len(), 7);
    assert_eq!(expanded[0].date, dt(2025, 2, 9, 0, 0));
    assert_eq!(expanded[6].date, dt(2025, 2, 15, 0, 0));

    assert_match("주말", "주말", dt(2025, 2, 9, 0, 0));
    assert_match("이번 주말", "이번 주말", dt(2025, 2, 9, 0, 0));
    assert_match("금 주말", "금 주말", dt(2025, 2, 9, 0, 0));
    assert_match_ws("다음 주말", 7, "다음 주말", dt(2025, 2, 9, 0, 0));
    assert_match_ws("다음 주말", 1, "다음 주말", dt(2025, 2, 16, 0, 0));
    assert_match_ws("다다음 주말", 1, "다다음 주말", dt(2025, 2, 23, 0, 0));
    assert_match("지난 주말", "지난 주말", dt(2025, 2, 2, 0, 0));
    assert_match("저번 주말", "저번 주말", dt(2025, 2, 2, 0, 0));
    assert_match("지지난 주말", "지지난 주말", dt(2025, 1, 26, 0, 0));
    assert_match(
        "이번 주말 오후 3시",
        "이번 주말 오후 3시",
        dt(2025, 2, 9, 15, 0),
    );

    let m = parse_one("이달");
    assert_eq!(
        (&"이달"[m.start..m.end], m.date, m.range_type),
        ("이달", dt(2025, 2, 1, 0, 0), Some("month"))
    );
    assert_match("이번 달", "이번 달", dt(2025, 2, 1, 0, 0));
    assert_match("금월", "금월", dt(2025, 2, 1, 0, 0));
    assert_match("다음 달", "다음 달", dt(2025, 3, 1, 0, 0));
    assert_match("익월", "익월", dt(2025, 3, 1, 0, 0));
    assert_match("차월", "차월", dt(2025, 3, 1, 0, 0));
    assert_match("다다음 달", "다다음 달", dt(2025, 4, 1, 0, 0));
    assert_match("지난 달", "지난 달", dt(2025, 1, 1, 0, 0));
    assert_match("저번 달", "저번 달", dt(2025, 1, 1, 0, 0));
    assert_match("지지난 달", "지지난 달", dt(2024, 12, 1, 0, 0));
    assert_match("다음달15일", "다음달15일", dt(2025, 3, 15, 0, 0));

    assert_match("올해", "올해", dt(2025, 2, 1, 0, 0));
    assert_match("올 해", "올 해", dt(2025, 2, 1, 0, 0));
    assert_match("금년", "금년", dt(2025, 2, 1, 0, 0));
    assert_match("내년", "내년", dt(2026, 2, 1, 0, 0));
    assert_match("명년", "명년", dt(2026, 2, 1, 0, 0));
    assert_match("다음 해", "다음 해", dt(2026, 2, 1, 0, 0));
    assert_match("내후년", "내후년", dt(2027, 2, 1, 0, 0));
    assert_match("작년", "작년", dt(2024, 2, 1, 0, 0));
    assert_match("지난 해", "지난 해", dt(2024, 2, 1, 0, 0));
    assert_match("재작년", "재작년", dt(2023, 2, 1, 0, 0));
    assert_match("내년 3월 15일", "내년 3월 15일", dt(2026, 3, 15, 0, 0));
}

#[test]
fn weekdays_and_anchored_weekdays() {
    assert_match("월요일", "월요일", dt(2025, 2, 10, 0, 0));
    assert_match("화요일", "화요일", dt(2025, 2, 11, 0, 0));
    assert_match("수요일", "수요일", dt(2025, 2, 12, 0, 0));
    assert_match("목요일", "목요일", dt(2025, 2, 13, 0, 0));
    assert_match("금요일", "금요일", dt(2025, 2, 14, 0, 0));
    assert_match("토요일", "토요일", dt(2025, 2, 15, 0, 0));
    assert_match("일요일", "일요일", dt(2025, 2, 9, 0, 0));
    assert_match("금욜", "금욜", dt(2025, 2, 14, 0, 0));

    assert_match("이번 금요일", "이번 금요일", dt(2025, 2, 14, 0, 0));
    assert_match("다음 화요일", "다음 화요일", dt(2025, 2, 11, 0, 0));
    assert_match("다다음 월요일", "다다음 월요일", dt(2025, 2, 17, 0, 0));
    assert_match("지난 수요일", "지난 수요일", dt(2025, 2, 5, 0, 0));
    assert_match("저번 일요일", "저번 일요일", dt(2025, 2, 2, 0, 0));
    assert_match("지지난 목요일", "지지난 목요일", dt(2025, 1, 30, 0, 0));

    assert_match_ws("다음 주 일요일", 7, "다음 주 일요일", dt(2025, 2, 9, 0, 0));
    assert_match_ws("다음 주 일요일", 1, "다음 주 일요일", dt(2025, 2, 16, 0, 0));
    assert_match_ws("차주 화요일", 7, "차주 화요일", dt(2025, 2, 11, 0, 0));
    assert_match_ws("금주 금요일", 1, "금주 금요일", dt(2025, 2, 7, 0, 0));
    assert_match(
        "다음 주의 화요일",
        "다음 주의 화요일",
        dt(2025, 2, 11, 0, 0),
    );
}

#[test]
fn months_dates_and_numeric_formats() {
    assert_match("유월 6일", "유월 6일", dt(2025, 6, 6, 0, 0));
    assert_match("시월 3일", "시월 3일", dt(2025, 10, 3, 0, 0));
    assert_match("십일월 11일", "십일월 11일", dt(2025, 11, 11, 0, 0));
    assert_match("십이월 25일", "십이월 25일", dt(2025, 12, 25, 0, 0));
    assert_match("삼월 1일", "삼월 1일", dt(2025, 3, 1, 0, 0));
    assert_match("3월달 15일", "3월달 15일", dt(2025, 3, 15, 0, 0));
    assert_match("2월 달 14일", "2월 달 14일", dt(2025, 2, 14, 0, 0));

    assert_match(
        "2025년 2월 14일(금)",
        "2025년 2월 14일(금)",
        dt(2025, 2, 14, 0, 0),
    );
    assert_match(
        "2월 14일 (금요일) 오후 3시",
        "2월 14일 (금요일) 오후 3시",
        dt(2025, 2, 14, 15, 0),
    );

    assert_match("2025-02-14", "2025-02-14", dt(2025, 2, 14, 0, 0));
    assert_match("2025.02.14", "2025.02.14", dt(2025, 2, 14, 0, 0));
    assert_match("2025. 2. 14.", "2025. 2. 14.", dt(2025, 2, 14, 0, 0));
    assert_match("2025/02/14", "2025/02/14", dt(2025, 2, 14, 0, 0));
    assert_match(
        "2025. 2. 14.(금) 15:30",
        "2025. 2. 14.(금) 15:30",
        dt(2025, 2, 14, 15, 30),
    );
    assert_match("2/14", "2/14", dt(2025, 2, 14, 0, 0));
    assert_match("12/25(목)", "12/25(목)", dt(2025, 12, 25, 0, 0));

    let fw = "일정은 ２０２５년 ２월 １４일 １５시 ３０분입니다";
    assert_match(
        fw,
        "２０２５년 ２월 １４일 １５시 ３０분",
        dt(2025, 2, 14, 15, 30),
    );
}

#[test]
fn nth_weekday() {
    assert_match("3월 첫째 월요일", "3월 첫째 월요일", dt(2025, 3, 3, 0, 0));
    assert_match(
        "3월 첫 번째 월요일",
        "3월 첫 번째 월요일",
        dt(2025, 3, 3, 0, 0),
    );
    assert_match("3월 첫 주 월요일", "3월 첫 주 월요일", dt(2025, 3, 3, 0, 0));
    assert_match(
        "4월 마지막 금요일",
        "4월 마지막 금요일",
        dt(2025, 4, 25, 0, 0),
    );
    assert_match(
        "4월 마지막 주 금요일",
        "4월 마지막 주 금요일",
        dt(2025, 4, 25, 0, 0),
    );
    assert_match(
        "유월 둘째 화요일",
        "유월 둘째 화요일",
        dt(2025, 6, 10, 0, 0),
    );
    assert_match(
        "시월 셋째 주 수요일",
        "시월 셋째 주 수요일",
        dt(2025, 10, 15, 0, 0),
    );
    assert_match(
        "삼월의 넷째 목요일",
        "삼월의 넷째 목요일",
        dt(2025, 3, 27, 0, 0),
    );
    assert_match(
        "3월 첫째 월요일 오후 2시",
        "3월 첫째 월요일 오후 2시",
        dt(2025, 3, 3, 14, 0),
    );
    assert_match("1월 첫째 월요일", "1월 첫째 월요일", dt(2026, 1, 5, 0, 0));
}

#[test]
fn offsets_and_within() {
    assert_match("3일 후", "3일 후", dt(2025, 2, 11, 0, 0));
    assert_match("3일 뒤", "3일 뒤", dt(2025, 2, 11, 0, 0));
    assert_match("3일 전", "3일 전", dt(2025, 2, 5, 0, 0));
    assert_match("2주일 후", "2주일 후", dt(2025, 2, 22, 0, 0));
    assert_match("일주일 전", "일주일 전", dt(2025, 2, 1, 0, 0));
    assert_match("3개월 후", "3개월 후", dt(2025, 5, 1, 0, 0));
    assert_match("2년 전", "2년 전", dt(2023, 2, 1, 0, 0));
    assert_match("백일 후", "백일 후", dt(2025, 5, 19, 0, 0));

    assert_match("하루 후", "하루 후", dt(2025, 2, 9, 0, 0));
    assert_match("이틀 전", "이틀 전", dt(2025, 2, 6, 0, 0));
    assert_match("사흘 뒤", "사흘 뒤", dt(2025, 2, 11, 0, 0));
    assert_match("나흘 후", "나흘 후", dt(2025, 2, 12, 0, 0));
    assert_match("닷새 전", "닷새 전", dt(2025, 2, 3, 0, 0));
    assert_match("열흘 뒤", "열흘 뒤", dt(2025, 2, 18, 0, 0));
    assert_match("한 달 후", "한 달 후", dt(2025, 3, 1, 0, 0));
    assert_match("두 달 전", "두 달 전", dt(2024, 12, 1, 0, 0));
    assert_match("한 주일 후", "한 주일 후", dt(2025, 2, 15, 0, 0));

    let compact = parse_compact("3일 이내", 7);
    assert_eq!(compact.len(), 1);
    assert_eq!(compact[0].date, dt(2025, 2, 8, 0, 0));
    assert_eq!(compact[0].range_days, Some(4));

    let expanded = parse_range("3일 이내");
    assert_eq!(expanded.len(), 4);
    assert_eq!(expanded[0].date, dt(2025, 2, 8, 0, 0));
    assert_eq!(expanded[3].date, dt(2025, 2, 11, 0, 0));

    assert_eq!(parse_compact("5일 안에", 7)[0].range_days, Some(6));
    assert_eq!(parse_compact("7일 내에", 7)[0].range_days, Some(8));
    assert_eq!(parse_compact("3일 내", 7)[0].range_days, Some(4));
    assert_eq!(parse_compact("하루 이내", 7)[0].range_days, Some(2));
    assert_eq!(parse_compact("이틀 안에", 7)[0].range_days, Some(3));
    assert_eq!(parse_compact("일주일 이내", 7)[0].range_days, Some(8));
    assert_eq!(parse_compact("2주 이내", 7)[0].range_days, Some(15));
}

#[test]
fn time_expressions() {
    assert_match("내일 한 시", "내일 한 시", dt(2025, 2, 9, 1, 0));
    assert_match("내일 한시", "내일 한시", dt(2025, 2, 9, 1, 0));
    assert_match("오후 두 시", "오후 두 시", dt(2025, 2, 8, 14, 0));
    assert_match("오후 세시 반", "오후 세시 반", dt(2025, 2, 8, 15, 30));
    assert_match("내일 네 시 15분", "내일 네 시 15분", dt(2025, 2, 9, 4, 15));
    assert_match("오후 다섯 시 반", "오후 다섯 시 반", dt(2025, 2, 8, 17, 30));
    assert_match("오후 여섯시", "오후 여섯시", dt(2025, 2, 8, 18, 0));
    assert_match(
        "아침 일곱시 삼십분",
        "아침 일곱시 삼십분",
        dt(2025, 2, 9, 7, 30),
    );
    assert_match(
        "내일 여덟 시 정각",
        "내일 여덟 시 정각",
        dt(2025, 2, 9, 8, 0),
    );
    assert_match("밤 아홉 시", "밤 아홉 시", dt(2025, 2, 8, 21, 0));
    assert_match("밤 열 시", "밤 열 시", dt(2025, 2, 8, 22, 0));
    assert_match("오전 열한 시 반", "오전 열한 시 반", dt(2025, 2, 8, 11, 30));
    assert_match("낮 열두 시 정각", "낮 열두 시 정각", dt(2025, 2, 8, 12, 0));

    assert_match("정오", "정오", dt(2025, 2, 8, 12, 0));
    assert_match("자정", "자정", dt(2025, 2, 9, 0, 0));
    assert_match("내일 정오", "내일 정오", dt(2025, 2, 9, 12, 0));
    assert_match("정오 15분 전", "정오 15분 전", dt(2025, 2, 8, 11, 45));
    assert_match("자정 15분 전", "자정 15분 전", dt(2025, 2, 8, 23, 45));

    assert_match("내일 3시 반", "내일 3시 반", dt(2025, 2, 9, 3, 30));
    assert_match(
        "내일 3시 15분 전",
        "내일 3시 15분 전",
        dt(2025, 2, 9, 2, 45),
    );
    assert_match(
        "오후 1시 15분 전",
        "오후 1시 15분 전",
        dt(2025, 2, 8, 12, 45),
    );
    assert_match("14시 30분 15초", "14시 30분 15초", dt(2025, 2, 8, 14, 30));
    assert_match("14:30:15", "14:30:15", dt(2025, 2, 8, 14, 30));
    assert_match("10:30 PM", "10:30 PM", dt(2025, 2, 8, 22, 30));
    assert_match("9am", "9am", dt(2025, 2, 9, 9, 0));
    assert_match("3:30 p.m.", "3:30 p.m.", dt(2025, 2, 8, 15, 30));
    assert_match("PM 3시", "PM 3시", dt(2025, 2, 8, 15, 0));
}

#[test]
fn glue_composition_and_ranges() {
    assert_match(
        "회의는 다음 주의 화요일 오후 3시 30분에 진행됩니다",
        "다음 주의 화요일 오후 3시 30분",
        dt(2025, 2, 11, 15, 30),
    );
    assert_match(
        "2025. 2. 14.(금)에 15시 30분",
        "2025. 2. 14.(금)에 15시 30분",
        dt(2025, 2, 14, 15, 30),
    );
    assert_match("내일에는 10시", "내일에는 10시", dt(2025, 2, 9, 10, 0));
    assert_match("14시 30분 전체 공개", "14시 30분", dt(2025, 2, 8, 14, 30));
    assert_match("3월 달력", "3월", dt(2025, 3, 1, 0, 0));
    assert_match(
        "2025-02-08T15:00:00Z",
        "2025-02-08T15:00:00Z",
        dt(2025, 2, 8, 15, 0),
    );

    let range_input = "오늘 오후 3시부터 내일 오전 10시까지";
    let mut ms = parse_range(range_input);
    ms.sort_by_key(|m| m.start);
    assert_eq!(ms.len(), 2, "expected 2 matches, got {ms:?}");
    assert_eq!(
        (&range_input[ms[0].start..ms[0].end], ms[0].date),
        ("오늘 오후 3시", dt(2025, 2, 8, 15, 0))
    );
    assert_eq!(
        (&range_input[ms[1].start..ms[1].end], ms[1].date),
        ("내일 오전 10시", dt(2025, 2, 9, 10, 0))
    );
}

#[test]
fn negative_and_boundary_checks() {
    let single = parse_range("내일 오시면 연락주세요");
    assert_eq!(single.len(), 1);
    assert_eq!(
        (
            &"내일 오시면 연락주세요"[single[0].start..single[0].end],
            single[0].date
        ),
        ("내일", dt(2025, 2, 9, 0, 0))
    );

    let low_temp = parse_range("오늘 낮은 기온");
    assert_eq!(low_temp.len(), 1);
    assert_eq!(
        (
            &"오늘 낮은 기온"[low_temp[0].start..low_temp[0].end],
            low_temp[0].date
        ),
        ("오늘", dt(2025, 2, 8, 0, 0))
    );

    let round_fri = parse_range("1차 금요일");
    assert_eq!(round_fri.len(), 1);
    assert_eq!(
        (
            &"1차 금요일"[round_fri[0].start..round_fri[0].end],
            round_fri[0].date
        ),
        ("금요일", dt(2025, 2, 14, 0, 0))
    );

    for s in [
        "3시간 걸려",
        "한 시간만",
        "한시적 조치",
        "일시적 오류",
        "삼일절 기념식",
        "3일간 출장",
        "3일째 휴가",
        "일일 투어",
        "3일 내내",
        "3일 내외",
        "밤색 코트",
        "아침밥 먹자",
        "아침 먹었어",
        "다음 주문 확인",
        "이번 달력",
        "금주하세요",
        "입금일 확인",
        "서명일 기준",
        "시작일 입력",
        "삼십오일",
        "이삼일 후",
        "3PMX",
        "AMEX",
        "10PMA",
        "SPAM",
        "CAMPUS",
        "2025-02-145",
        "2025.02.14.1",
        "2/145",
        "1/2/3",
        "2월 30일",
        "4월 31일",
        "2025년 2월 29일",
        "25시",
        "14시 60분",
    ] {
        assert_none(s);
    }
}

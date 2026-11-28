use sunphase::{NaiveDate, NaiveDateTime, Options, Parser, parse_with};

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

fn ja_opts(week_start: u8, range: bool) -> Options<'static> {
    Options {
        reference: ref_dt(),
        languages: &["ja"],
        range,
        week_start,
        offset_minutes: 0,
    }
}

fn assert_one(input: &str, expected_span: &str, expected_dt: NaiveDateTime) {
    assert_one_ws(input, 7, expected_span, expected_dt);
}

fn assert_one_ws(input: &str, week_start: u8, expected_span: &str, expected_dt: NaiveDateTime) {
    let matches = parse_with(input, &ja_opts(week_start, false)).unwrap();
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
    assert_eq!(m.date, expected_dt, "date mismatch for {input:?}");
}

fn assert_none(input: &str) {
    let matches = parse_with(input, &ja_opts(7, false)).unwrap();
    assert!(
        matches.is_empty(),
        "expected no matches for {input:?}, got {matches:?}"
    );
}

#[test]
fn legacy_and_core_regressions() {
    assert_one("今日", "今日", dt(2025, 2, 8, 0, 0));
    assert_one("本日", "本日", dt(2025, 2, 8, 0, 0));
    assert_one("明日", "明日", dt(2025, 2, 9, 0, 0));
    assert_one("昨日", "昨日", dt(2025, 2, 7, 0, 0));
    assert_one(
        "明日１０時３０分に会議",
        "明日１０時３０分",
        dt(2025, 2, 9, 10, 30),
    );
    assert_one(
        "来月二十一日十二時三十一分",
        "来月二十一日十二時三十一分",
        dt(2025, 3, 21, 12, 31),
    );
    assert_one(
        "会議は来月21日14時から",
        "来月21日14時",
        dt(2025, 3, 21, 14, 0),
    );
    assert_one_ws("来週日曜日", 7, "来週日曜日", dt(2025, 2, 9, 0, 0));
    assert_one_ws("来週日曜日", 1, "来週日曜日", dt(2025, 2, 16, 0, 0));
    assert_one(
        "野獣先輩",
        "野獣先輩",
        NaiveDate::from_ymd_opt(2025, 8, 10)
            .unwrap()
            .and_hms_opt(11, 45, 14)
            .unwrap(),
    );
}

#[test]
fn relative_days_and_day_parts() {
    assert_one("あした", "あした", dt(2025, 2, 9, 0, 0));
    assert_one("きのう", "きのう", dt(2025, 2, 7, 0, 0));
    assert_one("あさって", "あさって", dt(2025, 2, 10, 0, 0));
    assert_one("しあさって", "しあさって", dt(2025, 2, 11, 0, 0));
    assert_one("おととい", "おととい", dt(2025, 2, 6, 0, 0));
    assert_one("おとつい", "おとつい", dt(2025, 2, 6, 0, 0));
    assert_one("さきおととい", "さきおととい", dt(2025, 2, 5, 0, 0));
    assert_one("やのあさって", "やのあさって", dt(2025, 2, 12, 0, 0));
    assert_one("弥の明後日", "弥の明後日", dt(2025, 2, 12, 0, 0));

    assert_one("今朝", "今朝", dt(2025, 2, 8, 0, 0));
    assert_one("今晩", "今晩", dt(2025, 2, 8, 12, 0));
    assert_one("今夜", "今夜", dt(2025, 2, 8, 12, 0));
    assert_one("今宵", "今宵", dt(2025, 2, 8, 12, 0));
    assert_one("昨夜", "昨夜", dt(2025, 2, 7, 12, 0));
    assert_one("昨晩", "昨晩", dt(2025, 2, 7, 12, 0));
    assert_one("ゆうべ", "ゆうべ", dt(2025, 2, 7, 12, 0));
    assert_one("明朝", "明朝", dt(2025, 2, 9, 0, 0));
    assert_one("明晩", "明晩", dt(2025, 2, 9, 12, 0));
    assert_one("明夜", "明夜", dt(2025, 2, 9, 12, 0));

    assert_one("今夜8時", "今夜8時", dt(2025, 2, 8, 20, 0));
    assert_one("今朝7時30分", "今朝7時30分", dt(2025, 2, 8, 7, 30));
    assert_one("明朝7時半", "明朝7時半", dt(2025, 2, 9, 7, 30));
    assert_one("ゆうべ10時", "ゆうべ10時", dt(2025, 2, 7, 22, 0));
    assert_one("明日の朝9時", "明日の朝9時", dt(2025, 2, 9, 9, 0));
}

#[test]
fn anchors_and_weekdays() {
    assert_one("一昨年", "一昨年", dt(2023, 2, 1, 0, 0));
    assert_one("おととし", "おととし", dt(2023, 2, 1, 0, 0));
    assert_one("一昨々年", "一昨々年", dt(2022, 2, 1, 0, 0));
    assert_one("本年", "本年", dt(2025, 2, 1, 0, 0));
    assert_one("明年", "明年", dt(2026, 2, 1, 0, 0));
    assert_one("当月", "当月", dt(2025, 2, 1, 0, 0));
    assert_one("先々月", "先々月", dt(2024, 12, 1, 0, 0));
    assert_one("先々週", "先々週", dt(2025, 1, 19, 0, 0));
    assert_one("今週末", "今週末", dt(2025, 2, 9, 0, 0));
    assert_one("次の週末", "次の週末", dt(2025, 2, 9, 0, 0));
    assert_one_ws("来週末", 7, "来週末", dt(2025, 2, 9, 0, 0));
    assert_one_ws("来週末", 1, "来週末", dt(2025, 2, 16, 0, 0));
    assert_one_ws("先週末", 7, "先週末", dt(2025, 1, 26, 0, 0));
    assert_one_ws("先週末", 1, "先週末", dt(2025, 2, 2, 0, 0));
    assert_one("前の週末", "前の週末", dt(2025, 2, 2, 0, 0));

    assert_one("次の月曜日", "次の月曜日", dt(2025, 2, 10, 0, 0));
    assert_one("今度の土曜日", "今度の土曜日", dt(2025, 2, 15, 0, 0));
    assert_one("前の金曜日", "前の金曜日", dt(2025, 2, 7, 0, 0));
    assert_one("この前の水曜日", "この前の水曜日", dt(2025, 2, 5, 0, 0));
    assert_one("先日の日曜日", "先日の日曜日", dt(2025, 2, 2, 0, 0));

    assert_one("げつようび", "げつようび", dt(2025, 2, 10, 0, 0));
    assert_one("かようび", "かようび", dt(2025, 2, 11, 0, 0));
    assert_one("すいようび", "すいようび", dt(2025, 2, 12, 0, 0));
    assert_one("もくようび", "もくようび", dt(2025, 2, 13, 0, 0));
    assert_one("きんようび", "きんようび", dt(2025, 2, 14, 0, 0));
    assert_one("どようび", "どようび", dt(2025, 2, 15, 0, 0));
    assert_one("にちようび", "にちようび", dt(2025, 2, 9, 0, 0));
}

#[test]
fn numeric_dates_eras_and_parenthesized_weekdays() {
    assert_one("2025/2/14", "2025/2/14", dt(2025, 2, 14, 0, 0));
    assert_one("2025-02-14", "2025-02-14", dt(2025, 2, 14, 0, 0));
    assert_one("2025.02.14", "2025.02.14", dt(2025, 2, 14, 0, 0));
    assert_one("2/14", "2/14", dt(2025, 2, 14, 0, 0));
    assert_one("２／１４", "２／１４", dt(2025, 2, 14, 0, 0));
    assert_one("2/29", "2/29", dt(2028, 2, 29, 0, 0));
    assert_one("2024/02/29", "2024/02/29", dt(2024, 2, 29, 0, 0));

    assert_one("2月14日(金)", "2月14日(金)", dt(2025, 2, 14, 0, 0));
    assert_one(
        "2/14（金） 18:30",
        "2/14（金） 18:30",
        dt(2025, 2, 14, 18, 30),
    );

    assert_one("令和7年2月14日", "令和7年2月14日", dt(2025, 2, 14, 0, 0));
    assert_one("令和元年5月1日", "令和元年5月1日", dt(2019, 5, 1, 0, 0));
    assert_one("平成30年4月1日", "平成30年4月1日", dt(2018, 4, 1, 0, 0));
    assert_one("昭和64年1月7日", "昭和64年1月7日", dt(1989, 1, 7, 0, 0));
    assert_one(
        "二〇二五年五月十四日",
        "二〇二五年五月十四日",
        dt(2025, 5, 14, 0, 0),
    );
    assert_one(
        "二千二十六年五月十四日",
        "二千二十六年五月十四日",
        dt(2026, 5, 14, 0, 0),
    );
}

#[test]
fn nth_weekday_of_month() {
    assert_one("3月の第3月曜日", "3月の第3月曜日", dt(2025, 3, 17, 0, 0));
    assert_one("4月の最終金曜日", "4月の最終金曜日", dt(2025, 4, 25, 0, 0));
    assert_one("4月最後の金曜", "4月最後の金曜", dt(2025, 4, 25, 0, 0));
    assert_one(
        "2026年3月の第3月曜日",
        "2026年3月の第3月曜日",
        dt(2026, 3, 16, 0, 0),
    );
    assert_one("来月の第3月曜日", "来月の第3月曜日", dt(2025, 3, 17, 0, 0));
    assert_one("今月の第2土曜日", "今月の第2土曜日", dt(2025, 2, 8, 0, 0));
    assert_one(
        "先月の最終金曜日",
        "先月の最終金曜日",
        dt(2025, 1, 31, 0, 0),
    );
    assert_one(
        "3月の第3月曜日 14時",
        "3月の第3月曜日 14時",
        dt(2025, 3, 17, 14, 0),
    );
    assert_none("2月の第5土曜日");
}

#[test]
fn offsets_and_within() {
    assert_one("3ヵ月後", "3ヵ月後", dt(2025, 5, 1, 0, 0));
    assert_one("3カ月後", "3カ月後", dt(2025, 5, 1, 0, 0));
    assert_one("3箇月前", "3箇月前", dt(2024, 11, 1, 0, 0));
    assert_one("2週後", "2週後", dt(2025, 2, 22, 0, 0));
    assert_one("1週前", "1週前", dt(2025, 2, 1, 0, 0));
    assert_one("あと3日", "あと3日", dt(2025, 2, 11, 0, 0));
    assert_one("あと2週間", "あと2週間", dt(2025, 2, 22, 0, 0));
    assert_one("3日先", "3日先", dt(2025, 2, 11, 0, 0));
    assert_one("半月後", "半月後", dt(2025, 2, 23, 0, 0));
    assert_one("半年前", "半年前", dt(2024, 8, 1, 0, 0));

    let r1 = Parser::default()
        .parse_ranges("3日間以内に連絡", &ja_opts(7, true))
        .unwrap();
    assert_eq!(r1.len(), 1);
    assert_eq!(&"3日間以内に連絡"[r1[0].start..r1[0].end], "3日間以内");
    assert_eq!(r1[0].date, dt(2025, 2, 8, 0, 0));
    assert_eq!(r1[0].range_days, Some(4));

    let r2 = Parser::default()
        .parse_ranges("2週間以内", &ja_opts(7, true))
        .unwrap();
    assert_eq!(r2.len(), 1);
    assert_eq!(r2[0].range_days, Some(15));
}

#[test]
fn time_expressions() {
    assert_one("正午", "正午", dt(2025, 2, 8, 12, 0));
    assert_one("真夜中", "真夜中", dt(2025, 2, 9, 0, 0));
    assert_one("3時半", "3時半", dt(2025, 2, 9, 3, 30));
    assert_one("午後3時半", "午後3時半", dt(2025, 2, 8, 15, 30));
    assert_one("3時15分前", "3時15分前", dt(2025, 2, 9, 2, 45));
    assert_one("午後3時15分前", "午後3時15分前", dt(2025, 2, 8, 14, 45));
    assert_one("午後12時15分前", "午後12時15分前", dt(2025, 2, 8, 11, 45));

    assert_one("朝8時", "朝8時", dt(2025, 2, 9, 8, 0));
    assert_one("朝の8時30分", "朝の8時30分", dt(2025, 2, 9, 8, 30));
    assert_one("夕方5時", "夕方5時", dt(2025, 2, 8, 17, 0));
    assert_one("夜8時", "夜8時", dt(2025, 2, 8, 20, 0));
    assert_one("夜20時", "夜20時", dt(2025, 2, 8, 20, 0));
    assert_one("深夜2時", "深夜2時", dt(2025, 2, 9, 2, 0));
    assert_one("昼12時", "昼12時", dt(2025, 2, 8, 12, 0));
    assert_one("お昼1時", "お昼1時", dt(2025, 2, 8, 13, 0));

    assert_one("3pm", "3pm", dt(2025, 2, 8, 15, 0));
    assert_one("3:30PM", "3:30PM", dt(2025, 2, 8, 15, 30));
    assert_one("12am", "12am", dt(2025, 2, 9, 0, 0));
    assert_one("12pm", "12pm", dt(2025, 2, 8, 12, 0));
    assert_one("PM3時", "PM3時", dt(2025, 2, 8, 15, 0));
    assert_one("AM9時半", "AM9時半", dt(2025, 2, 9, 9, 30));
    assert_one("１４：３０", "１４：３０", dt(2025, 2, 8, 14, 30));
    assert_one("14:30:00", "14:30:00", dt(2025, 2, 8, 14, 30));
    assert_one("明日の午前中", "明日の午前中", dt(2025, 2, 9, 0, 0));
}

#[test]
fn glue_ranges_and_multilang() {
    assert_one(
        "明日\u{3000}14時",
        "明日\u{3000}14時",
        dt(2025, 2, 9, 14, 0),
    );
    assert_one(
        "来週の火曜日，15時",
        "来週の火曜日，15時",
        dt(2025, 2, 11, 15, 0),
    );

    let text = "明日は10時、来週火曜は14時";
    let mut matches = parse_with(text, &ja_opts(7, true)).unwrap();
    matches.sort_by_key(|m| m.start);
    assert_eq!(matches.len(), 2);
    assert_eq!(&text[matches[0].start..matches[0].end], "明日は10時");
    assert_eq!(matches[0].date, dt(2025, 2, 9, 10, 0));
    assert_eq!(&text[matches[1].start..matches[1].end], "来週火曜は14時");
    assert_eq!(matches[1].date, dt(2025, 2, 11, 14, 0));

    let iso = "2025-02-08T15:00:00Z";
    let iso_matches = parse_with(iso, &Options::new(ref_dt())).unwrap();
    assert_eq!(iso_matches.len(), 1);
    assert_eq!(&iso[iso_matches[0].start..iso_matches[0].end], iso);
    assert_eq!(iso_matches[0].date, dt(2025, 2, 8, 15, 0));
}

#[test]
fn negative_and_boundary_checks() {
    assert_none("とうきょうに行く");
    assert_none("きょうみがある");
    assert_none("学校にかよう");
    assert_one("明日は夜景を見る", "明日", dt(2025, 2, 9, 0, 0));
    assert_one("明日朝ごはん", "明日", dt(2025, 2, 9, 0, 0));
    assert_none("PM2.5");
    assert_none("PM担当");
    assert_none("会議は3時間です");
    assert_none("一時停止");
    assert_none("一時的");
    assert_none("3日間の旅行");
    assert_none("二日酔いです");
    assert_none("1日目");
    assert_none("3pmA");
    assert_none("3PMX");
    assert_none("3amazon");
    assert_none("ham3pm");
    assert_none("1/2/3");
    assert_none("2.14");
    assert_none("2-14");
    assert_none("2025/02/29");
    assert_none("2025/02/30");
    assert_none("2月14日(火)");
    assert_none("午前");
    assert_none("午後");
    assert_none("ゆうべん");
}

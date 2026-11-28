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

fn zh_opts() -> Options<'static> {
    let mut opts = Options::new(ref_dt());
    opts.languages = &["zh"];
    opts
}

fn assert_zh(input: &str, expected_span: &str, expected_dt: NaiveDateTime) {
    let ms = parse_with(input, &zh_opts()).unwrap();
    assert_eq!(ms.len(), 1, "expected 1 match for {input:?}, got {ms:?}");
    let m = &ms[0];
    assert_eq!(
        &input[m.start..m.end],
        expected_span,
        "span mismatch for {input:?}"
    );
    assert_eq!(m.date, expected_dt, "date mismatch for {input:?}");
}

fn assert_zh_none(input: &str) {
    let ms = parse_with(input, &zh_opts()).unwrap();
    assert!(ms.is_empty(), "expected no match for {input:?}, got {ms:?}");
}

#[test]
fn relative_days_and_day_times() {
    assert_zh("今天", "今天", dt(2025, 2, 8, 0, 0));
    assert_zh("今日", "今日", dt(2025, 2, 8, 0, 0));
    assert_zh("本日", "本日", dt(2025, 2, 8, 0, 0));
    assert_zh("今儿", "今儿", dt(2025, 2, 8, 0, 0));
    assert_zh("明天", "明天", dt(2025, 2, 9, 0, 0));
    assert_zh("明日", "明日", dt(2025, 2, 9, 0, 0));
    assert_zh("明儿", "明儿", dt(2025, 2, 9, 0, 0));
    assert_zh("后天", "后天", dt(2025, 2, 10, 0, 0));
    assert_zh("後天", "後天", dt(2025, 2, 10, 0, 0));
    assert_zh("大后天", "大后天", dt(2025, 2, 11, 0, 0));
    assert_zh("大後天", "大後天", dt(2025, 2, 11, 0, 0));
    assert_zh("大大后天", "大大后天", dt(2025, 2, 12, 0, 0));
    assert_zh("昨天", "昨天", dt(2025, 2, 7, 0, 0));
    assert_zh("昨日", "昨日", dt(2025, 2, 7, 0, 0));
    assert_zh("昨儿", "昨儿", dt(2025, 2, 7, 0, 0));
    assert_zh("前天", "前天", dt(2025, 2, 6, 0, 0));
    assert_zh("大前天", "大前天", dt(2025, 2, 5, 0, 0));
    assert_zh("大大前天", "大大前天", dt(2025, 2, 4, 0, 0));

    assert_zh("今晚", "今晚", dt(2025, 2, 8, 12, 0));
    assert_zh("今晚9点半", "今晚9点半", dt(2025, 2, 8, 21, 30));
    assert_zh("今晚20:15", "今晚20:15", dt(2025, 2, 8, 20, 15));
    assert_zh("今早8点", "今早8点", dt(2025, 2, 8, 8, 0));
    assert_zh("明早8点一刻", "明早8点一刻", dt(2025, 2, 9, 8, 15));
    assert_zh("明晚7点", "明晚7点", dt(2025, 2, 9, 19, 0));
    assert_zh("昨晚10点", "昨晚10点", dt(2025, 2, 7, 22, 0));
    assert_zh("昨早9点", "昨早9点", dt(2025, 2, 7, 9, 0));
    assert_zh("后晚8点", "后晚8点", dt(2025, 2, 10, 20, 0));
    assert_zh("前晚9点", "前晚9点", dt(2025, 2, 6, 21, 0));
}

#[test]
fn anchors_and_weekdays() {
    assert_zh("今年", "今年", dt(2025, 2, 1, 0, 0));
    assert_zh("本年", "本年", dt(2025, 2, 1, 0, 0));
    assert_zh("明年", "明年", dt(2026, 2, 1, 0, 0));
    assert_zh("来年", "来年", dt(2026, 2, 1, 0, 0));
    assert_zh("來年", "來年", dt(2026, 2, 1, 0, 0));
    assert_zh("后年", "后年", dt(2027, 2, 1, 0, 0));
    assert_zh("後年", "後年", dt(2027, 2, 1, 0, 0));
    assert_zh("大后年", "大后年", dt(2028, 2, 1, 0, 0));
    assert_zh("去年", "去年", dt(2024, 2, 1, 0, 0));
    assert_zh("上年", "上年", dt(2024, 2, 1, 0, 0));
    assert_zh("前年", "前年", dt(2023, 2, 1, 0, 0));
    assert_zh("大前年", "大前年", dt(2022, 2, 1, 0, 0));

    assert_zh("本月15号", "本月15号", dt(2025, 2, 15, 0, 0));
    assert_zh("这个月20日", "这个月20日", dt(2025, 2, 20, 0, 0));
    assert_zh("下月3日", "下月3日", dt(2025, 3, 3, 0, 0));
    assert_zh("上月10号", "上月10号", dt(2025, 1, 10, 0, 0));
    assert_zh("上上个月5号", "上上个月5号", dt(2024, 12, 5, 0, 0));
    assert_zh("下下個月1日", "下下個月1日", dt(2025, 4, 1, 0, 0));

    assert_zh("周末", "周末", dt(2025, 2, 9, 0, 0));
    assert_zh("週末", "週末", dt(2025, 2, 9, 0, 0));
    assert_zh("本周末", "本周末", dt(2025, 2, 9, 0, 0));
    assert_zh("这个周末", "这个周末", dt(2025, 2, 9, 0, 0));
    assert_zh("下周末", "下周末", dt(2025, 2, 9, 0, 0));

    assert_zh("周一", "周一", dt(2025, 2, 10, 0, 0));
    assert_zh("星期五", "星期五", dt(2025, 2, 14, 0, 0));
    assert_zh("礼拜天", "礼拜天", dt(2025, 2, 9, 0, 0));
    assert_zh("週三", "週三", dt(2025, 2, 12, 0, 0));
    assert_zh("禮拜一", "禮拜一", dt(2025, 2, 10, 0, 0));
    assert_zh("本周一", "本周一", dt(2025, 2, 3, 0, 0));
    assert_zh("這週三", "這週三", dt(2025, 2, 5, 0, 0));
    assert_zh("上周五", "上周五", dt(2025, 1, 31, 0, 0));
    assert_zh("上上周五", "上上周五", dt(2025, 1, 24, 0, 0));
    assert_zh("下下周二", "下下周二", dt(2025, 2, 18, 0, 0));
    assert_zh("周二两点", "周二两点", dt(2025, 2, 11, 2, 0));
    assert_zh("周三10点", "周三10点", dt(2025, 2, 12, 10, 0));

    let mut mon_opts = zh_opts();
    mon_opts.week_start = 1;
    let ms = parse_with("下周末", &mon_opts).unwrap();
    assert_eq!(ms[0].date, dt(2025, 2, 16, 0, 0));
    let ms = parse_with("上周末", &mon_opts).unwrap();
    assert_eq!(ms[0].date, dt(2025, 2, 2, 0, 0));
}

#[test]
fn dates_months_and_nth_weekday() {
    assert_zh(
        "二零二六年五月十四日",
        "二零二六年五月十四日",
        dt(2026, 5, 14, 0, 0),
    );
    assert_zh(
        "二〇二五年三月一日",
        "二〇二五年三月一日",
        dt(2025, 3, 1, 0, 0),
    );
    assert_zh("元月15日", "元月15日", dt(2026, 1, 15, 0, 0));
    assert_zh("五月廿一日", "五月廿一日", dt(2025, 5, 21, 0, 0));
    assert_zh("五月卅日", "五月卅日", dt(2025, 5, 30, 0, 0));
    assert_zh("16號", "16號", dt(2025, 2, 16, 0, 0));

    assert_zh("2025-03-14", "2025-03-14", dt(2025, 3, 14, 0, 0));
    assert_zh("2025/3/14", "2025/3/14", dt(2025, 3, 14, 0, 0));
    assert_zh("2025.03.14", "2025.03.14", dt(2025, 3, 14, 0, 0));
    assert_zh(
        "2025-03-14 下午3:30",
        "2025-03-14 下午3:30",
        dt(2025, 3, 14, 15, 30),
    );
    assert_zh(
        "2025-02-08T15:00:00Z",
        "2025-02-08T15:00:00Z",
        dt(2025, 2, 8, 15, 0),
    );

    assert_zh("3月第三个星期一", "3月第三个星期一", dt(2025, 3, 17, 0, 0));
    assert_zh(
        "四月的最后一个礼拜五",
        "四月的最后一个礼拜五",
        dt(2025, 4, 25, 0, 0),
    );
    assert_zh("4月最後一個週五", "4月最後一個週五", dt(2025, 4, 25, 0, 0));
    assert_zh(
        "3月第2个周日下午3点",
        "3月第2个周日下午3点",
        dt(2025, 3, 9, 15, 0),
    );
    assert_zh("元月第一个周一", "元月第一个周一", dt(2026, 1, 5, 0, 0));
}

#[test]
fn offsets_within_and_ranges() {
    assert_zh("两天后", "两天后", dt(2025, 2, 10, 0, 0));
    assert_zh("兩天後", "兩天後", dt(2025, 2, 10, 0, 0));
    assert_zh("3天之后", "3天之后", dt(2025, 2, 11, 0, 0));
    assert_zh("三天以前", "三天以前", dt(2025, 2, 5, 0, 0));
    assert_zh("两周后", "两周后", dt(2025, 2, 22, 0, 0));
    assert_zh("2周后周五", "2周后周五", dt(2025, 2, 21, 0, 0));
    assert_zh("两个月后", "两个月后", dt(2025, 4, 1, 0, 0));
    assert_zh("两年后", "两年后", dt(2027, 2, 1, 0, 0));
    assert_zh("再过两天", "再过两天", dt(2025, 2, 10, 0, 0));
    assert_zh("再過3天後", "再過3天後", dt(2025, 2, 11, 0, 0));

    let mut range_opts = zh_opts();
    range_opts.range = true;

    let ms = Parser::default()
        .parse_ranges("3天内", &range_opts)
        .unwrap();
    assert_eq!(ms.len(), 1);
    assert_eq!(ms[0].date, dt(2025, 2, 8, 0, 0));
    assert_eq!(ms[0].range_days, Some(4));

    let ms = parse_with("未来三天", &range_opts).unwrap();
    assert_eq!(ms.len(), 4);
    assert_eq!(ms[0].date, dt(2025, 2, 8, 0, 0));
    assert_eq!(ms[3].date, dt(2025, 2, 11, 0, 0));

    let ms = Parser::default()
        .parse_ranges("一周内", &range_opts)
        .unwrap();
    assert_eq!(ms.len(), 1);
    assert_eq!(ms[0].range_days, Some(8));

    let ms = Parser::default()
        .parse_ranges("3月份", &range_opts)
        .unwrap();
    assert_eq!(ms.len(), 1);
    assert_eq!(ms[0].date, dt(2025, 3, 1, 0, 0));
    assert_eq!(ms[0].range_type, Some("month"));

    let ms = parse_with("本周", &range_opts).unwrap();
    assert_eq!(ms.len(), 7);
    assert_eq!(ms[0].date, dt(2025, 2, 2, 0, 0));
    assert_eq!(ms[6].date, dt(2025, 2, 8, 0, 0));

    let mut mon_range = range_opts.clone();
    mon_range.week_start = 1;
    let ms = parse_with("下周", &mon_range).unwrap();
    assert_eq!(ms.len(), 7);
    assert_eq!(ms[0].date, dt(2025, 2, 10, 0, 0));
    assert_eq!(ms[6].date, dt(2025, 2, 16, 0, 0));
}

#[test]
fn time_expressions_and_composition() {
    assert_zh("两点", "两点", dt(2025, 2, 9, 2, 0));
    assert_zh("两点半", "两点半", dt(2025, 2, 9, 2, 30));
    assert_zh("3点一刻", "3点一刻", dt(2025, 2, 9, 3, 15));
    assert_zh("3点三刻", "3点三刻", dt(2025, 2, 9, 3, 45));
    assert_zh("3点整", "3点整", dt(2025, 2, 9, 3, 0));
    assert_zh("3点钟", "3点钟", dt(2025, 2, 9, 3, 0));
    assert_zh("3点过5分", "3点过5分", dt(2025, 2, 9, 3, 5));
    assert_zh("3点20", "3点20", dt(2025, 2, 9, 3, 20));
    assert_zh("3点零5", "3点零5", dt(2025, 2, 9, 3, 5));
    assert_zh("三点二十", "三点二十", dt(2025, 2, 9, 3, 20));
    assert_zh("14：30", "14：30", dt(2025, 2, 8, 14, 30));
    assert_zh("14点30分20秒", "14点30分20秒", dt(2025, 2, 8, 14, 30));

    assert_zh("差一刻3点", "差一刻3点", dt(2025, 2, 9, 2, 45));
    assert_zh("3点差一刻", "3点差一刻", dt(2025, 2, 9, 2, 45));
    assert_zh("下午3点差10分", "下午3点差10分", dt(2025, 2, 8, 14, 50));
    assert_zh("差一刻到1点", "差一刻到1点", dt(2025, 2, 9, 0, 45));

    assert_zh("中午", "中午", dt(2025, 2, 8, 12, 0));
    assert_zh("正午", "正午", dt(2025, 2, 8, 12, 0));
    assert_zh("中午12点", "中午12点", dt(2025, 2, 8, 12, 0));
    assert_zh("中午12点半", "中午12点半", dt(2025, 2, 8, 12, 30));
    assert_zh("中午12:30", "中午12:30", dt(2025, 2, 8, 12, 30));
    assert_zh("中午1点", "中午1点", dt(2025, 2, 8, 13, 0));
    assert_zh("今天中午3个同学", "今天中午", dt(2025, 2, 8, 12, 0));

    assert_zh("午夜", "午夜", dt(2025, 2, 9, 0, 0));
    assert_zh("半夜", "半夜", dt(2025, 2, 9, 0, 0));
    assert_zh("半夜12点", "半夜12点", dt(2025, 2, 9, 0, 0));
    assert_zh("半夜2点", "半夜2点", dt(2025, 2, 9, 2, 0));
    assert_zh("半夜3个强盗", "半夜", dt(2025, 2, 9, 0, 0));

    assert_zh("下周二的上午9点", "下周二的上午9点", dt(2025, 2, 11, 9, 0));
    assert_zh(
        "2025年，3月5日，下午3点",
        "2025年，3月5日，下午3点",
        dt(2025, 3, 5, 15, 0),
    );
    assert_zh(
        "会议改到下周三下午两点半开始",
        "下周三下午两点半",
        dt(2025, 2, 12, 14, 30),
    );

    let fullwidth = "２０２６年５月１４日下午３点３０分";
    let ms = parse_with(fullwidth, &zh_opts()).unwrap();
    assert_eq!(ms.len(), 1);
    assert_eq!(&fullwidth[ms[0].start..ms[0].end], fullwidth);
    assert_eq!(ms[0].date, dt(2026, 5, 14, 15, 30));
}

#[test]
fn negative_and_boundary_checks() {
    assert_zh_none("二十五月");
    assert_zh_none("十三月");
    assert_zh_none("三十二日");
    assert_zh_none("四十二号");
    assert_zh_none("有一点点累");
    assert_zh_none("有一点儿冷");
    assert_zh_none("第一点");
    assert_zh_none("第3点");
    assert_zh_none("将近三天");
    assert_zh_none("美元月线");
    assert_zh_none("2025.1.2.3");
    assert_zh_none("2025-02-14ABC");
    assert_zh_none("ABC2025-02-14");
    assert_zh_none("14:65");
    assert_zh_none("25:14");

    assert_zh("2025年3月5日前完成", "2025年3月5日", dt(2025, 3, 5, 0, 0));
    assert_zh("3点20号开会", "3点20号", dt(2025, 2, 20, 3, 0));
}

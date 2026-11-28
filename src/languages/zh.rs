use crate::{Component, Language, Pattern};

fn zh_number(s: &str) -> Option<i32> {
    if s.contains('十') && s.contains(['两', '兩']) {
        return None;
    }
    match s {
        "两" | "兩" => Some(2),
        _ if s.starts_with('廿') => match s.strip_prefix('廿') {
            Some("") => Some(20),
            Some(rest) => crate::number(rest)
                .filter(|&d| (1..=9).contains(&d))
                .map(|d| 20 + d),
            None => None,
        },
        _ if s.starts_with('卅') => match s.strip_prefix('卅') {
            Some("") => Some(30),
            Some(rest) => crate::number(rest)
                .filter(|&d| (1..=9).contains(&d))
                .map(|d| 30 + d),
            None => None,
        },
        _ if s.contains(['两', '兩', '○']) => {
            let mapped: String = s
                .chars()
                .map(|c| match c {
                    '两' | '兩' => '二',
                    '○' => '〇',
                    _ => c,
                })
                .collect();
            crate::number(&mapped)
        }
        _ => crate::number(s),
    }
}

fn zh_anchor(w: &str) -> i32 {
    match w {
        "下下" => 2,
        "下" => 1,
        "上上" => -2,
        "上" => -1,
        _ => 0,
    }
}

fn zh_weekday_num(s: &str) -> Option<i32> {
    let ch = s.chars().next()?;
    "一二三四五六日天"
        .chars()
        .position(|c| c == ch)
        .map(|i| (i as i32 + 1).min(7))
}

fn zh_unit_offset(value: i32, unit: &str) -> Component {
    match unit {
        "天" => Component::RelativeDay(value),
        "年" => Component::YearOffset(value),
        "个月" | "個月" => Component::MonthOffset(value),
        _ => Component::Week(value, false),
    }
}

fn noon_pm(raw_h: i32) -> Option<bool> {
    if (1..=5).contains(&raw_h) {
        Some(true)
    } else {
        None
    }
}

fn build_to_time(
    noon: bool,
    raw_h_str: &str,
    quarter: bool,
    min_str: Option<&str>,
) -> Option<Vec<Component>> {
    let raw_h = zh_number(raw_h_str)?;
    if !(0..=24).contains(&raw_h) {
        return None;
    }
    let sub_min = if quarter { 15 } else { zh_number(min_str?)? };
    if !(1..=59).contains(&sub_min) {
        return None;
    }
    let h = (raw_h - 1).rem_euclid(24);
    let pm = if noon { noon_pm(raw_h) } else { None };
    Some(vec![Component::Time(h, Some(60 - sub_min), pm)])
}

pub fn language() -> Language {
    Language::new(
        "zh",
        r"(?:[\s、,，]|的|于|於)+",
        vec![
            Pattern::with_builder(
                "zh_nthWeekday",
                r"(?:([0-9]{1,2})|(?P<guard0>)(元|[〇零一二三四五六七八九十]+))月(?:份)?\s*(?:的\s*)?(倒数第一|倒数第1|倒數第一|倒數第1|最后|最後|第[1-5一二三四五])(?:一个|一個|个|個)?\s*(?:星期|礼拜|禮拜|周|週)([一二三四五六日天])",
                &[(
                    "guard0",
                    true,
                    "[〇零一二两兩三四五六七八九十百千美欧歐日港台臺新加澳韩韓银銀金]",
                )],
                |c, _| {
                    let m_str = c.get(1).or_else(|| c.get(3))?.as_str();
                    let month = if m_str == "元" { 1 } else { zh_number(m_str)? };
                    if !(1..=12).contains(&month) {
                        return None;
                    }
                    let ord = match c.get(4)?.as_str() {
                        "第1" | "第一" => 1,
                        "第2" | "第二" => 2,
                        "第3" | "第三" => 3,
                        "第4" | "第四" => 4,
                        "第5" | "第五" => 5,
                        _ => -1,
                    };
                    let wd = zh_weekday_num(c.get(5)?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, month)])
                },
            ),
            Pattern::with_builder(
                "zh_ymdDate",
                r"(?P<guard0>)(?:([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})|([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})|([0-9]{4})\.([0-9]{1,2})\.([0-9]{1,2}))(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Z]"),
                    ("guard1", false, "[0-9a-zA-Z]|[-/.][0-9]"),
                ],
                |c, _| {
                    let (y, m, d) = [(2, 3, 4), (5, 6, 7), (8, 9, 10)].into_iter().find_map(
                        |(yi, mi, di)| {
                            Some((
                                c.get(yi)?.as_str().parse().ok()?,
                                c.get(mi)?.as_str().parse().ok()?,
                                c.get(di)?.as_str().parse().ok()?,
                            ))
                        },
                    )?;
                    Some(vec![
                        Component::Year(y),
                        Component::Month(m),
                        Component::Day(d),
                    ])
                },
            ),
            Pattern::new(
                "zh_relativeDayTime",
                "(大后晚|大後晚|大前晚|后晚|後晚|后夜|後夜|前晚|前夜|今晚|今夜|今早|今晨|明晚|明夜|明早|明晨|昨晚|昨夜|昨早|昨晨)",
                &[],
                &[
                    (
                        "大后晚",
                        &[Component::RelativeDay(3), Component::Meridiem(true)],
                    ),
                    (
                        "大後晚",
                        &[Component::RelativeDay(3), Component::Meridiem(true)],
                    ),
                    (
                        "大前晚",
                        &[Component::RelativeDay(-3), Component::Meridiem(true)],
                    ),
                    (
                        "后晚",
                        &[Component::RelativeDay(2), Component::Meridiem(true)],
                    ),
                    (
                        "後晚",
                        &[Component::RelativeDay(2), Component::Meridiem(true)],
                    ),
                    (
                        "后夜",
                        &[Component::RelativeDay(2), Component::Meridiem(true)],
                    ),
                    (
                        "後夜",
                        &[Component::RelativeDay(2), Component::Meridiem(true)],
                    ),
                    (
                        "前晚",
                        &[Component::RelativeDay(-2), Component::Meridiem(true)],
                    ),
                    (
                        "前夜",
                        &[Component::RelativeDay(-2), Component::Meridiem(true)],
                    ),
                    (
                        "今晚",
                        &[Component::RelativeDay(0), Component::Meridiem(true)],
                    ),
                    (
                        "今夜",
                        &[Component::RelativeDay(0), Component::Meridiem(true)],
                    ),
                    (
                        "今早",
                        &[Component::RelativeDay(0), Component::Meridiem(false)],
                    ),
                    (
                        "今晨",
                        &[Component::RelativeDay(0), Component::Meridiem(false)],
                    ),
                    (
                        "明晚",
                        &[Component::RelativeDay(1), Component::Meridiem(true)],
                    ),
                    (
                        "明夜",
                        &[Component::RelativeDay(1), Component::Meridiem(true)],
                    ),
                    (
                        "明早",
                        &[Component::RelativeDay(1), Component::Meridiem(false)],
                    ),
                    (
                        "明晨",
                        &[Component::RelativeDay(1), Component::Meridiem(false)],
                    ),
                    (
                        "昨晚",
                        &[Component::RelativeDay(-1), Component::Meridiem(true)],
                    ),
                    (
                        "昨夜",
                        &[Component::RelativeDay(-1), Component::Meridiem(true)],
                    ),
                    (
                        "昨早",
                        &[Component::RelativeDay(-1), Component::Meridiem(false)],
                    ),
                    (
                        "昨晨",
                        &[Component::RelativeDay(-1), Component::Meridiem(false)],
                    ),
                ],
            ),
            Pattern::new(
                "zh_relativeDay",
                "(大大后天|大大後天|大大前天|大后天|大後天|大后儿|大後兒|大前天|大前儿|大前兒|后天|後天|后儿|後兒|前天|前儿|前兒|明天|明日|明儿|明兒|昨天|昨日|昨儿|昨兒|今天|今日|本日|今儿|今兒)",
                &[],
                &[
                    ("大大后天", &[Component::RelativeDay(4)]),
                    ("大大後天", &[Component::RelativeDay(4)]),
                    ("大大前天", &[Component::RelativeDay(-4)]),
                    ("大后天", &[Component::RelativeDay(3)]),
                    ("大後天", &[Component::RelativeDay(3)]),
                    ("大后儿", &[Component::RelativeDay(3)]),
                    ("大後兒", &[Component::RelativeDay(3)]),
                    ("大前天", &[Component::RelativeDay(-3)]),
                    ("大前儿", &[Component::RelativeDay(-3)]),
                    ("大前兒", &[Component::RelativeDay(-3)]),
                    ("后天", &[Component::RelativeDay(2)]),
                    ("後天", &[Component::RelativeDay(2)]),
                    ("后儿", &[Component::RelativeDay(2)]),
                    ("後兒", &[Component::RelativeDay(2)]),
                    ("前天", &[Component::RelativeDay(-2)]),
                    ("前儿", &[Component::RelativeDay(-2)]),
                    ("前兒", &[Component::RelativeDay(-2)]),
                    ("明天", &[Component::RelativeDay(1)]),
                    ("明日", &[Component::RelativeDay(1)]),
                    ("明儿", &[Component::RelativeDay(1)]),
                    ("明兒", &[Component::RelativeDay(1)]),
                    ("昨天", &[Component::RelativeDay(-1)]),
                    ("昨日", &[Component::RelativeDay(-1)]),
                    ("昨儿", &[Component::RelativeDay(-1)]),
                    ("昨兒", &[Component::RelativeDay(-1)]),
                    ("今天", &[Component::RelativeDay(0)]),
                    ("今日", &[Component::RelativeDay(0)]),
                    ("本日", &[Component::RelativeDay(0)]),
                    ("今儿", &[Component::RelativeDay(0)]),
                    ("今兒", &[Component::RelativeDay(0)]),
                ],
            ),
            Pattern::new(
                "zh_yearAnchor",
                "(大后年|大後年|大前年|后年|後年|前年|下一年|明年|来年|來年|下年|上一年|去年|上年|今年|本年)",
                &[],
                &[
                    ("大后年", &[Component::YearOffset(3)]),
                    ("大後年", &[Component::YearOffset(3)]),
                    ("大前年", &[Component::YearOffset(-3)]),
                    ("后年", &[Component::YearOffset(2)]),
                    ("後年", &[Component::YearOffset(2)]),
                    ("前年", &[Component::YearOffset(-2)]),
                    ("下一年", &[Component::YearOffset(1)]),
                    ("明年", &[Component::YearOffset(1)]),
                    ("来年", &[Component::YearOffset(1)]),
                    ("來年", &[Component::YearOffset(1)]),
                    ("下年", &[Component::YearOffset(1)]),
                    ("上一年", &[Component::YearOffset(-1)]),
                    ("去年", &[Component::YearOffset(-1)]),
                    ("上年", &[Component::YearOffset(-1)]),
                    ("今年", &[Component::YearOffset(0)]),
                    ("本年", &[Component::YearOffset(0)]),
                ],
            ),
            Pattern::with_builder(
                "zh_weekendAnchor",
                "(上上|上|这|這|本|下下|下)(?:个|個)?(?:周末|週末)",
                &[],
                |c, _| {
                    let a = c.get(1)?.as_str();
                    if matches!(a, "这" | "這" | "本") {
                        Some(vec![Component::Weekend])
                    } else {
                        Some(vec![
                            Component::Week(zh_anchor(a), true),
                            Component::Weekday(7),
                        ])
                    }
                },
            ),
            Pattern::new(
                "zh_weekend",
                "(周末|週末)",
                &[],
                &[
                    ("周末", &[Component::Weekend]),
                    ("週末", &[Component::Weekend]),
                ],
            ),
            Pattern::with_builder(
                "zh_weekday",
                "(?:(上上|上|这|這|本|下下|下)(?:个|個)?)?(?:星期|礼拜|禮拜|周|週)([一二三四五六日天])",
                &[],
                |c, _| {
                    let wd = zh_weekday_num(c.get(2)?.as_str())?;
                    if let Some(a) = c.get(1) {
                        Some(vec![
                            Component::Week(zh_anchor(a.as_str()), true),
                            Component::Weekday(wd),
                        ])
                    } else {
                        Some(vec![Component::Weekday(wd)])
                    }
                },
            ),
            Pattern::with_builder(
                "zh_weekAnchor",
                "(上上|上|这|這|本|下下|下)(?:个|個)?(?:星期|礼拜|禮拜|周|週)(?P<guard0>)",
                &[("guard0", false, "[一二三四五六日天末]")],
                |c, _| Some(vec![Component::Week(zh_anchor(c.get(1)?.as_str()), true)]),
            ),
            Pattern::with_builder(
                "zh_withinPrefix",
                r"(?:未来|未來|今后|今後|接下来|接下來|最近)\s*(?:([0-9]+)|([两兩](?:[百千][〇零一二三四五六七八九十]*)?)|(?P<guard0>)([〇零一二三四五六七八九十百千]+))\s*(天|(?:个|個)?(?:星期|礼拜|禮拜|周|週))(?:\s*(?:之|以)?(?:内|內))?(?P<guard1>)",
                &[
                    ("guard0", true, "[〇零一二两兩三四五六七八九十百千]"),
                    ("guard1", false, r"\s*(?:之|以)?(?:后|後|前)"),
                ],
                |c, _| {
                    let n =
                        zh_number(c.get(1).or_else(|| c.get(2)).or_else(|| c.get(4))?.as_str())?;
                    let days = if c.get(5)?.as_str() == "天" {
                        n
                    } else {
                        n.checked_mul(7)?
                    };
                    Some(vec![Component::Within(days)])
                },
            ),
            Pattern::with_builder(
                "zh_withinSuffix",
                r"(?:([0-9]+)|([两兩](?:[百千][〇零一二三四五六七八九十]*)?)|(?P<guard0>)([〇零一二三四五六七八九十百千]+))\s*(天|(?:个|個)?(?:星期|礼拜|禮拜|周|週))\s*(?:之|以)?(?:内|內)",
                &[("guard0", true, "[〇零一二两兩三四五六七八九十百千]")],
                |c, _| {
                    let n =
                        zh_number(c.get(1).or_else(|| c.get(2)).or_else(|| c.get(4))?.as_str())?;
                    let days = if c.get(5)?.as_str() == "天" {
                        n
                    } else {
                        n.checked_mul(7)?
                    };
                    Some(vec![Component::Within(days)])
                },
            ),
            Pattern::with_builder(
                "zh_inOffset",
                r"再(?:过|過)\s*(?:([0-9]+)|([两兩](?:[百千][〇零一二三四五六七八九十]*)?)|(?P<guard0>)([〇零一二三四五六七八九十百千]+))\s*(天|(?:个|個)?(?:星期|礼拜|禮拜|周|週)|(?:个|個)月|年)(?:\s*(?:以|之)?(?:后|後))?(?P<guard1>)",
                &[
                    ("guard0", true, "[〇零一二两兩三四五六七八九十百千]"),
                    ("guard1", false, r"\s*(?:以|之)?前"),
                ],
                |c, _| {
                    let n =
                        zh_number(c.get(1).or_else(|| c.get(2)).or_else(|| c.get(4))?.as_str())?;
                    Some(vec![zh_unit_offset(n, c.get(5)?.as_str())])
                },
            ),
            Pattern::with_builder(
                "zh_offset",
                r"(?:([0-9]+)|([两兩](?:[百千][〇零一二三四五六七八九十]*)?)|(?P<guard0>)([〇零一二三四五六七八九十百千]+))\s*(天|(?:个|個)?(?:星期|礼拜|禮拜|周|週)|(?:个|個)月|年)\s*(?:以|之)?(后|後|前)",
                &[("guard0", true, "[〇零一二两兩三四五六七八九十百千]")],
                |c, _| {
                    let n =
                        zh_number(c.get(1).or_else(|| c.get(2)).or_else(|| c.get(4))?.as_str())?;
                    let v = if c.get(6)?.as_str() == "前" {
                        n.checked_neg()?
                    } else {
                        n
                    };
                    Some(vec![zh_unit_offset(v, c.get(5)?.as_str())])
                },
            ),
            Pattern::with_builder(
                "zh_monthAnchor",
                "(上上|上|这|這|本|下下|下)(?:个|個)?月",
                &[],
                |c, _| Some(vec![Component::MonthOffset(zh_anchor(c.get(1)?.as_str()))]),
            ),
            Pattern::with_builder(
                "zh_toTimePrefix",
                r"(?:(?P<noon>正午|中午)(?:\s*的\s*|\s*))?(?P<guard0>)差\s*(?:(?P<q>一刻)|(?:(?P<m1>[0-9]+)|(?P<guard1>)(?P<m2>[〇零一二两兩三四五六七八九十]+))\s*分(?:钟|鐘)?)\s*(?:到)?\s*(?:(?P<guard3>)(?P<h1>[0-9]+)|(?P<h2>[两兩])|(?P<guard2>)(?P<h3>[〇零一二三四五六七八九十]+))[点點时時](?:钟|鐘)?",
                &[
                    ("guard0", true, "[相时時误誤偏温溫]"),
                    ("guard1", true, "[〇零一二两兩三四五六七八九十百千]"),
                    ("guard2", true, "[第〇零一二两兩三四五六七八九十百千]"),
                    ("guard3", true, "第"),
                ],
                |c, _| {
                    let raw_h_str = c
                        .name("h1")
                        .or_else(|| c.name("h2"))
                        .or_else(|| c.name("h3"))?
                        .as_str();
                    let min_str = c.name("m1").or_else(|| c.name("m2")).map(|m| m.as_str());
                    build_to_time(
                        c.name("noon").is_some(),
                        raw_h_str,
                        c.name("q").is_some(),
                        min_str,
                    )
                },
            ),
            Pattern::with_builder(
                "zh_toTimeSuffix",
                r"(?:(?P<noon>正午|中午)(?:\s*的\s*|\s*))?(?:(?P<guard2>)(?P<h1>[0-9]+)|(?P<h2>[两兩])|(?P<guard0>)(?P<h3>[〇零一二三四五六七八九十]+))[点點时時]\s*差\s*(?:(?P<q>一刻)|(?:(?P<m1>[0-9]+)|(?P<guard1>)(?P<m2>[〇零一二两兩三四五六七八九十]+))\s*分(?:钟|鐘)?)",
                &[
                    ("guard0", true, "[第〇零一二两兩三四五六七八九十百千]"),
                    ("guard1", true, "[〇零一二两兩三四五六七八九十百千]"),
                    ("guard2", true, "第"),
                ],
                |c, _| {
                    let raw_h_str = c
                        .name("h1")
                        .or_else(|| c.name("h2"))
                        .or_else(|| c.name("h3"))?
                        .as_str();
                    let min_str = c.name("m1").or_else(|| c.name("m2")).map(|m| m.as_str());
                    build_to_time(
                        c.name("noon").is_some(),
                        raw_h_str,
                        c.name("q").is_some(),
                        min_str,
                    )
                },
            ),
            Pattern::with_builder(
                "zh_timeShortMin",
                r"(?:(?P<noon>正午|中午)(?:\s*的\s*|\s*))?(?:(?P<guard4>)(?P<h1>[0-9]+)|(?P<h2>[两兩])|(?P<guard0>)(?P<h3>[〇零一二三四五六七八九十]+))[点點时時](?P<m3>0[0-9]|[1-5][0-9]|零[0-9一二三四五六七八九]|十[一二三四五六七八九]?|[二三四五]十[一二三四五六七八九]?)(?P<guard2>)",
                &[
                    ("guard4", true, "第"),
                    ("guard0", true, "[第〇零一二两兩三四五六七八九十百千]"),
                    (
                        "guard2",
                        false,
                        "[0-9〇零一二三四五六七八九十号號日天周週月年个個条條元块塊人名次步点點时時分秒%万億亿]",
                    ),
                ],
                |c, _| {
                    let raw_h = zh_number(
                        c.name("h1")
                            .or_else(|| c.name("h2"))
                            .or_else(|| c.name("h3"))?
                            .as_str(),
                    )?;
                    let min = zh_number(c.name("m3")?.as_str())?;
                    let pm = c.name("noon").and_then(|_| noon_pm(raw_h));
                    Some(vec![Component::Time(raw_h, Some(min), pm)])
                },
            ),
            Pattern::with_builder(
                "zh_time",
                r"(?:(?P<noon>正午|中午)(?:\s*的\s*|\s*))?(?:(?P<guard4>)(?P<h1>[0-9]+)|(?P<h2>[两兩])|(?P<guard0>)(?P<h3>[〇零一二三四五六七八九十]+))(?:[点點时時](?:钟|鐘)?\s*(?P<word>半|一刻|三刻|整)|[点點时時]\s*(?:过|過)?\s*(?:(?P<m1>[0-9]+)|(?P<guard1>)(?P<m2>[〇零一二两兩三四五六七八九十]+))\s*分(?:钟|鐘)?(?:\s*[0-9〇零一二三四五六七八九十]+秒)?|[点點时時](?:(钟|鐘)|(?P<guard3>)))",
                &[
                    ("guard4", true, "第"),
                    ("guard0", true, "[第〇零一二两兩三四五六七八九十百千]"),
                    ("guard1", true, "[〇零一二两兩三四五六七八九十百千]"),
                    ("guard3", false, "[点點儿兒]"),
                ],
                |c, _| {
                    let raw_h = zh_number(
                        c.name("h1")
                            .or_else(|| c.name("h2"))
                            .or_else(|| c.name("h3"))?
                            .as_str(),
                    )?;
                    let min = if let Some(w) = c.name("word") {
                        match w.as_str() {
                            "半" => Some(30),
                            "一刻" => Some(15),
                            "三刻" => Some(45),
                            _ => Some(0),
                        }
                    } else if let Some(m) = c.name("m1").or_else(|| c.name("m2")) {
                        Some(zh_number(m.as_str())?)
                    } else {
                        None
                    };
                    let pm = c.name("noon").and_then(|_| noon_pm(raw_h));
                    Some(vec![Component::Time(raw_h, min, pm)])
                },
            ),
            Pattern::with_builder(
                "zh_colonTime",
                r"(?:(?P<noon>正午|中午)(?:\s*的\s*|\s*))?(?P<guard0>)(?P<h>[0-9]{1,2})[:：](?P<m>[0-9]{2})(?P<guard1>)",
                &[("guard0", true, "[0-9:：]"), ("guard1", false, "[0-9]")],
                |c, _| {
                    let raw_h: i32 = c.name("h")?.as_str().parse().ok()?;
                    let m: i32 = c.name("m")?.as_str().parse().ok()?;
                    let pm = c.name("noon").and_then(|_| noon_pm(raw_h));
                    Some(vec![Component::Time(raw_h, Some(m), pm)])
                },
            ),
            Pattern::new(
                "zh_noon",
                "(正午|中午)",
                &[],
                &[
                    ("正午", &[Component::Time(12, Some(0), None)]),
                    ("中午", &[Component::Time(12, Some(0), None)]),
                ],
            ),
            Pattern::with_builder(
                "zh_midnight",
                r"(?:午夜|半夜|子夜)(?P<guard0>)",
                &[(
                    "guard0",
                    false,
                    r"\s*(?:的\s*)?(?:[0-9]{1,2}\s*[:：]|[0-9〇零一二两兩三四五六七八九十]+\s*[点點时時]|差\s*(?:一刻|[0-9〇零一二两兩三四五六七八九十]+\s*分))",
                )],
                |_, _| Some(vec![Component::Time(0, Some(0), None)]),
            ),
            Pattern::new(
                "zh_meridiem",
                "(一大早|上午|早上|早间|早間|早晨|清晨|凌晨|半夜|午夜|子夜|黎明|拂晓|拂曉|下午|午后|午後|傍晚|晚上|晚间|晚間|夜里|夜裡|夜间|夜間|夜晚)",
                &[],
                &[
                    ("一大早", &[Component::Meridiem(false)]),
                    ("上午", &[Component::Meridiem(false)]),
                    ("早上", &[Component::Meridiem(false)]),
                    ("早间", &[Component::Meridiem(false)]),
                    ("早間", &[Component::Meridiem(false)]),
                    ("早晨", &[Component::Meridiem(false)]),
                    ("清晨", &[Component::Meridiem(false)]),
                    ("凌晨", &[Component::Meridiem(false)]),
                    ("半夜", &[Component::Meridiem(false)]),
                    ("午夜", &[Component::Meridiem(false)]),
                    ("子夜", &[Component::Meridiem(false)]),
                    ("黎明", &[Component::Meridiem(false)]),
                    ("拂晓", &[Component::Meridiem(false)]),
                    ("拂曉", &[Component::Meridiem(false)]),
                    ("下午", &[Component::Meridiem(true)]),
                    ("午后", &[Component::Meridiem(true)]),
                    ("午後", &[Component::Meridiem(true)]),
                    ("傍晚", &[Component::Meridiem(true)]),
                    ("晚上", &[Component::Meridiem(true)]),
                    ("晚间", &[Component::Meridiem(true)]),
                    ("晚間", &[Component::Meridiem(true)]),
                    ("夜里", &[Component::Meridiem(true)]),
                    ("夜裡", &[Component::Meridiem(true)]),
                    ("夜间", &[Component::Meridiem(true)]),
                    ("夜間", &[Component::Meridiem(true)]),
                    ("夜晚", &[Component::Meridiem(true)]),
                ],
            ),
            Pattern::with_builder(
                "zh_year",
                r"(?:([0-9]{4})|(?P<guard0>)([〇零○一二三四五六七八九]{4}))年",
                &[("guard0", true, "[〇零○一二三四五六七八九十百千]")],
                |c, _| {
                    Some(vec![Component::Year(zh_number(
                        c.get(1).or_else(|| c.get(3))?.as_str(),
                    )?)])
                },
            ),
            Pattern::with_builder(
                "zh_month",
                r"(?:([0-9]+)|(?P<guard0>)(元|[〇零一二三四五六七八九十百千]+))月(?:份)?",
                &[(
                    "guard0",
                    true,
                    "[〇零一二两兩三四五六七八九十百千美欧歐日港台臺新加澳韩韓银銀金]",
                )],
                |c, _| {
                    let s = c.get(1).or_else(|| c.get(3))?.as_str();
                    let m = if s == "元" { 1 } else { zh_number(s)? };
                    Some(vec![Component::Month(m)])
                },
            ),
            Pattern::with_builder(
                "zh_day",
                r"(?:([0-9]+)|(?P<guard0>)(廿[一二三四五六七八九]?|卅[一]?|[〇零一二三四五六七八九十百千]+))[号號日]",
                &[("guard0", true, "[〇零一二两兩三四五六七八九十百千廿卅]")],
                |c, _| {
                    Some(vec![Component::Day(zh_number(
                        c.get(1).or_else(|| c.get(3))?.as_str(),
                    )?)])
                },
            ),
        ],
    )
}

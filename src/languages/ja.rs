use crate::{Captures, Component, Language, NaiveDate, NaiveDateTime, Pattern, number};

fn weekday_num(s: &str) -> Option<i32> {
    match s {
        "月" | "げつようび" => Some(1),
        "火" | "かようび" => Some(2),
        "水" | "すいようび" => Some(3),
        "木" | "もくようび" => Some(4),
        "金" | "きんようび" => Some(5),
        "土" | "どようび" => Some(6),
        "日" | "にちようび" => Some(7),
        _ => None,
    }
}

fn era_base_year(era: &str) -> Option<i32> {
    match era {
        "令和" => Some(2018),
        "平成" => Some(1988),
        "昭和" => Some(1925),
        "大正" => Some(1911),
        "明治" => Some(1867),
        _ => None,
    }
}

fn parse_era_num(s: &str) -> Option<i32> {
    let n = if s == "元" { 1 } else { number(s)? };
    (1..=99).contains(&n).then_some(n)
}

fn opt_number(s: Option<&str>) -> Option<Option<i32>> {
    match s {
        Some(v) => Some(Some(number(v)?)),
        None => Some(None),
    }
}

fn compute_nth_day(y: i32, m: i32, ord: i32, target: i32) -> Option<i32> {
    let month = u32::try_from(m).ok()?;
    if ord == -1 {
        let last_d = (28..=31)
            .rev()
            .find(|&d| NaiveDate::from_ymd_opt(y, month, d as u32).is_some())?;
        let last_w = NaiveDate::from_ymd_opt(y, month, last_d as u32)?
            .and_hms_opt(0, 0, 0)?
            .weekday()
            .number_from_monday() as i32;
        Some(last_d - (last_w - target).rem_euclid(7))
    } else if (1..=5).contains(&ord) {
        let first_w = NaiveDate::from_ymd_opt(y, month, 1)?
            .and_hms_opt(0, 0, 0)?
            .weekday()
            .number_from_monday() as i32;
        let day = 1 + (target - first_w).rem_euclid(7) + (ord - 1) * 7;
        NaiveDate::from_ymd_opt(y, month, u32::try_from(day).ok()?)?;
        Some(day)
    } else {
        None
    }
}

fn meridiem_is_pm(s: &str) -> Option<bool> {
    match s {
        "午前" | "早朝" | "朝" | "深夜" | "未明" => Some(false),
        "午後" | "お昼" | "昼" | "夕方" | "夜" => Some(true),
        _ => None,
    }
}

fn time_with_optional_before(
    h: i32,
    m: Option<i32>,
    pm: Option<bool>,
    before: bool,
) -> Option<Component> {
    if !(0..24).contains(&h) {
        return None;
    }
    if before {
        let min = m.filter(|v| (1..60).contains(v))?;
        let h24 = match pm {
            Some(true) if h < 12 => h + 12,
            Some(false) if h == 12 => 0,
            _ => h,
        };
        let new_h = (h24 - 1).rem_euclid(24);
        // If meridiem was already folded into h24, omit pm so resolve does not shift again.
        Some(Component::Time(new_h, Some(60 - min), None))
    } else if m.is_none_or(|v| (0..60).contains(&v)) {
        Some(Component::Time(h, m, pm))
    } else {
        None
    }
}

fn build_within(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let n = number(c.get(1)?.as_str())?;
    if n < 0 {
        return None;
    }
    let days = match c.get(2)?.as_str() {
        "日" => n,
        "週" => n.checked_mul(7)?,
        _ => return None,
    };
    Some(vec![Component::Within(days)])
}

fn build_offset(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let (num_str, unit, neg) = if let Some(m) = c.get(1) {
        (m.as_str(), c.get(2)?.as_str(), c.get(3)?.as_str() == "前")
    } else {
        (c.get(4)?.as_str(), c.get(5)?.as_str(), false)
    };
    let raw = number(num_str)?;
    let v = if neg { raw.checked_neg()? } else { raw };
    let comp = match unit {
        "日" => Component::RelativeDay(v),
        "週" | "週間" => Component::Week(v, false),
        "年" => Component::YearOffset(v),
        _ => Component::MonthOffset(v),
    };
    Some(vec![comp])
}

fn build_nth_weekday(c: &Captures<'_>, reference: NaiveDateTime) -> Option<Vec<Component>> {
    let target = weekday_num(c.get(9)?.as_str())?;
    let ord = if c.get(8).is_some() {
        -1
    } else {
        let n = number(c.get(7)?.as_str())?;
        (1..=5).contains(&n).then_some(n)?
    };
    if let Some(anchor) = c.get(5) {
        let offset = match anchor.as_str() {
            "今" => 0i64,
            "来" => 1,
            "先" => -1,
            _ => return None,
        };
        let months =
            i64::from(reference.year()) * 12 + i64::from(reference.month() as i32) - 1 + offset;
        let y = i32::try_from(months.div_euclid(12)).ok()?;
        let m = months.rem_euclid(12) as i32 + 1;
        let day = compute_nth_day(y, m, ord, target)?;
        return Some(vec![
            Component::Year(y),
            Component::Month(m),
            Component::Day(day),
        ]);
    }
    if let Some(m_match) = c.get(4) {
        let y = if let Some(era) = c.get(1) {
            era_base_year(era.as_str())? + parse_era_num(c.get(2)?.as_str())?
        } else {
            number(c.get(3)?.as_str())?
        };
        let m = number(m_match.as_str())?;
        if !(1..=12).contains(&m) {
            return None;
        }
        let day = compute_nth_day(y, m, ord, target)?;
        return Some(vec![
            Component::Year(y),
            Component::Month(m),
            Component::Day(day),
        ]);
    }
    let m = number(c.get(6)?.as_str())?;
    if !(1..=12).contains(&m) {
        return None;
    }
    Some(vec![Component::Nth(ord, target, m)])
}

fn build_next_last_weekday(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let dir = match c.get(1)?.as_str() {
        "次の" | "今度の" => 1,
        _ => -1,
    };
    let wd = weekday_num(c.get(2).or_else(|| c.get(3))?.as_str())?;
    Some(vec![Component::Week(dir, false), Component::Weekday(wd)])
}

fn build_ymd_date(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let (ys, ms, ds) = if let Some(y) = c.get(2) {
        (y.as_str(), c.get(3)?.as_str(), c.get(4)?.as_str())
    } else if let Some(y) = c.get(5) {
        (y.as_str(), c.get(6)?.as_str(), c.get(7)?.as_str())
    } else {
        (c.get(8)?.as_str(), c.get(9)?.as_str(), c.get(10)?.as_str())
    };
    let y = number(ys)?;
    let m = number(ms)?;
    let d = number(ds)?;
    if !(1..=12).contains(&m) {
        return None;
    }
    NaiveDate::from_ymd_opt(y, u32::try_from(m).ok()?, u32::try_from(d).ok()?)?;
    Some(vec![
        Component::Year(y),
        Component::Month(m),
        Component::Day(d),
    ])
}

fn build_md_slash_date(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let m = number(c.get(2)?.as_str())?;
    let d = number(c.get(3)?.as_str())?;
    if !(1..=12).contains(&m) {
        return None;
    }
    // Validate against leap year 2024 so 2/29 resolves to the next leap year.
    NaiveDate::from_ymd_opt(2024, u32::try_from(m).ok()?, u32::try_from(d).ok()?)?;
    Some(vec![Component::Month(m), Component::Day(d)])
}

fn build_era_year(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let base = era_base_year(c.get(1)?.as_str())?;
    let n = parse_era_num(c.get(2)?.as_str())?;
    Some(vec![Component::Year(base + n)])
}

fn build_time_ampm(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let (ampm, hs, ms) = if let Some(a) = c.get(2) {
        (a.as_str(), c.get(3)?.as_str(), c.get(4).map(|m| m.as_str()))
    } else {
        (
            c.get(7)?.as_str(),
            c.get(5)?.as_str(),
            c.get(6).map(|m| m.as_str()),
        )
    };
    let h = number(hs)?;
    if !(0..=12).contains(&h) {
        return None;
    }
    let m = opt_number(ms)?;
    if m.is_some_and(|v| !(0..60).contains(&v)) {
        return None;
    }
    let pm = ampm.eq_ignore_ascii_case("pm");
    Some(vec![Component::Time(h, m, Some(pm))])
}

fn build_ampm_ja_time(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let pm = c.get(2)?.as_str().eq_ignore_ascii_case("pm");
    let h = number(c.get(3)?.as_str())?;
    if !(0..=12).contains(&h) {
        return None;
    }
    let m = if c.get(6).is_some() {
        Some(30)
    } else {
        opt_number(c.get(4).map(|v| v.as_str()))?
    };
    let before = c.get(5).is_some();
    Some(vec![time_with_optional_before(h, m, Some(pm), before)?])
}

fn build_meridiem_time(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let pm = meridiem_is_pm(c.get(2)?.as_str())?;
    let h = number(c.get(3)?.as_str())?;
    let m = if c.get(6).is_some() {
        Some(30)
    } else if let Some(min_match) = c.get(4) {
        Some(number(min_match.as_str())?)
    } else if let Some(colon_min) = c.get(9) {
        Some(number(colon_min.as_str())?)
    } else {
        None
    };
    let before = c.get(5).is_some();
    Some(vec![time_with_optional_before(h, m, Some(pm), before)?])
}

fn build_weekday(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let s = c.get(1).or_else(|| c.get(2)).or_else(|| c.get(3))?.as_str();
    Some(vec![Component::Weekday(weekday_num(s)?)])
}

fn build_year(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    Some(vec![Component::Year(number(c.get(1)?.as_str())?)])
}

fn build_time(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let h = number(c.get(1)?.as_str())?;
    let m = if c.get(4).is_some() {
        Some(30)
    } else {
        opt_number(c.get(2).map(|v| v.as_str()))?
    };
    let before = c.get(3).is_some();
    Some(vec![time_with_optional_before(h, m, None, before)?])
}

fn build_time_colon(c: &Captures<'_>, _: NaiveDateTime) -> Option<Vec<Component>> {
    let h = number(c.get(1)?.as_str())?;
    let m = number(c.get(2)?.as_str())?;
    if !(0..24).contains(&h) || !(0..60).contains(&m) {
        return None;
    }
    if let Some(sec) = c.get(3) {
        let s = number(sec.as_str())?;
        if !(0..60).contains(&s) {
            return None;
        }
    }
    Some(vec![Component::Time(h, Some(m), None)])
}

pub fn language() -> Language {
    Language::new(
        "ja",
        "(?:[\\s\\u{3000}、,，]|の|に|は)+",
        vec![
            Pattern::new("ja_special", "野獣先輩", &[], &[]),
            Pattern::with_builder(
                "ja_within",
                "([0-9〇零一二三四五六七八九十百千]+)(日|週)間?以内",
                &[],
                build_within,
            ),
            Pattern::new(
                "ja_halfOffset",
                "(半月|半年)(後|前)",
                &[],
                &[
                    ("半月後", &[Component::RelativeDay(15)]),
                    ("半月前", &[Component::RelativeDay(-15)]),
                    ("半年後", &[Component::MonthOffset(6)]),
                    ("半年前", &[Component::MonthOffset(-6)]),
                ],
            ),
            Pattern::with_builder(
                "ja_offset",
                "(?:([0-9〇零一二三四五六七八九十百千]+)(日|週間?|[ヶケヵカか箇]月|年)(後|前|先)|あと([0-9〇零一二三四五六七八九十百千]+)(日|週間?|[ヶケヵカか箇]月|年)後?(?P<guard1>))",
                &[("guard1", false, "(?:間|前|先)")],
                build_offset,
            ),
            Pattern::with_builder(
                "ja_nthWeekday",
                "(?:(?:(令和|平成|昭和|大正|明治)(元|[0-9]{1,2}|[一二三四五六七八九十]+)年|([0-9]{4})年)[\\s\\u{3000}]*の?[\\s\\u{3000}]*([0-9〇零一二三四五六七八九十]+)月の?|(今|来|先)月の?|([0-9〇零一二三四五六七八九十]+)月の?)(?:第([1-5一二三四五])|(最終|最後の))([月火水木金土日])(?:曜日|曜)?",
                &[],
                build_nth_weekday,
            ),
            Pattern::with_builder(
                "ja_nextLastWeekday",
                "(次の|今度の|前の|この前の|先日の)(?:([月火水木金土日])(?:曜日|曜)|(げつようび|かようび|すいようび|もくようび|きんようび|どようび|にちようび))",
                &[],
                build_next_last_weekday,
            ),
            // Omit bare きょう/あす/いつか/なのか/ようか due to common Japanese homophones (東京, 興味, 飛鳥, etc.).
            Pattern::new(
                "ja_relativeDay",
                "(明々後日|明明後日|弥の明後日|弥明後日|一昨々日|一昨昨日|しあさって|さきおととい|やのあさって|明後日|一昨日|あさって|おととい|おとつい|あした|きのう|ゆうべ(?P<guard1>)|今朝|今晩|今夜|今宵|昨晩|昨夜|昨朝|明朝|明晩|明夜|今日|本日|明日|昨日)",
                &[("guard1", false, "ん")],
                &[
                    ("今日", &[Component::RelativeDay(0)]),
                    ("本日", &[Component::RelativeDay(0)]),
                    ("明日", &[Component::RelativeDay(1)]),
                    ("あした", &[Component::RelativeDay(1)]),
                    ("明後日", &[Component::RelativeDay(2)]),
                    ("あさって", &[Component::RelativeDay(2)]),
                    ("明々後日", &[Component::RelativeDay(3)]),
                    ("明明後日", &[Component::RelativeDay(3)]),
                    ("しあさって", &[Component::RelativeDay(3)]),
                    ("弥の明後日", &[Component::RelativeDay(4)]),
                    ("弥明後日", &[Component::RelativeDay(4)]),
                    ("やのあさって", &[Component::RelativeDay(4)]),
                    ("昨日", &[Component::RelativeDay(-1)]),
                    ("きのう", &[Component::RelativeDay(-1)]),
                    ("一昨日", &[Component::RelativeDay(-2)]),
                    ("おととい", &[Component::RelativeDay(-2)]),
                    ("おとつい", &[Component::RelativeDay(-2)]),
                    ("一昨々日", &[Component::RelativeDay(-3)]),
                    ("一昨昨日", &[Component::RelativeDay(-3)]),
                    ("さきおととい", &[Component::RelativeDay(-3)]),
                    (
                        "今朝",
                        &[Component::RelativeDay(0), Component::Meridiem(false)],
                    ),
                    (
                        "今晩",
                        &[Component::RelativeDay(0), Component::Meridiem(true)],
                    ),
                    (
                        "今夜",
                        &[Component::RelativeDay(0), Component::Meridiem(true)],
                    ),
                    (
                        "今宵",
                        &[Component::RelativeDay(0), Component::Meridiem(true)],
                    ),
                    (
                        "昨朝",
                        &[Component::RelativeDay(-1), Component::Meridiem(false)],
                    ),
                    (
                        "昨晩",
                        &[Component::RelativeDay(-1), Component::Meridiem(true)],
                    ),
                    (
                        "昨夜",
                        &[Component::RelativeDay(-1), Component::Meridiem(true)],
                    ),
                    (
                        "ゆうべ",
                        &[Component::RelativeDay(-1), Component::Meridiem(true)],
                    ),
                    (
                        "明朝",
                        &[Component::RelativeDay(1), Component::Meridiem(false)],
                    ),
                    (
                        "明晩",
                        &[Component::RelativeDay(1), Component::Meridiem(true)],
                    ),
                    (
                        "明夜",
                        &[Component::RelativeDay(1), Component::Meridiem(true)],
                    ),
                ],
            ),
            Pattern::new(
                "ja_anchor",
                "(再来週末|来々週末|来週末|今週末|先週末|次の週末|前の週末|この前の週末|週末|再来年|来々年|来来年|さ来年|一昨々年|一昨昨年|さきおととし|一昨年|おととし|さらいねん|らいねん|きょねん|さくねん|来年|今年|本年|明年|去年|昨年|次の年|前の年|再来月|来々月|来来月|さ来月|先々月|先先月|せんせんげつ|さらいげつ|らいげつ|こんげつ|せんげつ|来月|今月|当月|先月|次の月|前の月|再来週|来々週|来来週|さ来週|先々週|先先週|来週|今週|先週|次の週|前の週)",
                &[],
                &[
                    (
                        "再来週末",
                        &[Component::Week(2, true), Component::Weekday(7)],
                    ),
                    (
                        "来々週末",
                        &[Component::Week(2, true), Component::Weekday(7)],
                    ),
                    ("来週末", &[Component::Week(1, true), Component::Weekday(7)]),
                    ("今週末", &[Component::Weekend]),
                    (
                        "先週末",
                        &[Component::Week(-1, true), Component::Weekday(7)],
                    ),
                    ("次の週末", &[Component::Weekend]),
                    (
                        "前の週末",
                        &[Component::Week(-1, false), Component::Weekday(7)],
                    ),
                    (
                        "この前の週末",
                        &[Component::Week(-1, false), Component::Weekday(7)],
                    ),
                    ("週末", &[Component::Weekend]),
                    ("再来年", &[Component::YearOffset(2)]),
                    ("来々年", &[Component::YearOffset(2)]),
                    ("来来年", &[Component::YearOffset(2)]),
                    ("さ来年", &[Component::YearOffset(2)]),
                    ("さらいねん", &[Component::YearOffset(2)]),
                    ("来年", &[Component::YearOffset(1)]),
                    ("明年", &[Component::YearOffset(1)]),
                    ("らいねん", &[Component::YearOffset(1)]),
                    ("次の年", &[Component::YearOffset(1)]),
                    ("今年", &[Component::YearOffset(0)]),
                    ("本年", &[Component::YearOffset(0)]),
                    ("去年", &[Component::YearOffset(-1)]),
                    ("昨年", &[Component::YearOffset(-1)]),
                    ("きょねん", &[Component::YearOffset(-1)]),
                    ("さくねん", &[Component::YearOffset(-1)]),
                    ("前の年", &[Component::YearOffset(-1)]),
                    ("一昨年", &[Component::YearOffset(-2)]),
                    ("おととし", &[Component::YearOffset(-2)]),
                    ("一昨々年", &[Component::YearOffset(-3)]),
                    ("一昨昨年", &[Component::YearOffset(-3)]),
                    ("さきおととし", &[Component::YearOffset(-3)]),
                    ("再来月", &[Component::MonthOffset(2)]),
                    ("来々月", &[Component::MonthOffset(2)]),
                    ("来来月", &[Component::MonthOffset(2)]),
                    ("さ来月", &[Component::MonthOffset(2)]),
                    ("さらいげつ", &[Component::MonthOffset(2)]),
                    ("来月", &[Component::MonthOffset(1)]),
                    ("らいげつ", &[Component::MonthOffset(1)]),
                    ("次の月", &[Component::MonthOffset(1)]),
                    ("今月", &[Component::MonthOffset(0)]),
                    ("当月", &[Component::MonthOffset(0)]),
                    ("こんげつ", &[Component::MonthOffset(0)]),
                    ("先月", &[Component::MonthOffset(-1)]),
                    ("せんげつ", &[Component::MonthOffset(-1)]),
                    ("前の月", &[Component::MonthOffset(-1)]),
                    ("先々月", &[Component::MonthOffset(-2)]),
                    ("先先月", &[Component::MonthOffset(-2)]),
                    ("せんせんげつ", &[Component::MonthOffset(-2)]),
                    ("再来週", &[Component::Week(2, true)]),
                    ("来々週", &[Component::Week(2, true)]),
                    ("来来週", &[Component::Week(2, true)]),
                    ("さ来週", &[Component::Week(2, true)]),
                    ("来週", &[Component::Week(1, true)]),
                    ("次の週", &[Component::Week(1, true)]),
                    ("今週", &[Component::Week(0, true)]),
                    ("先週", &[Component::Week(-1, true)]),
                    ("前の週", &[Component::Week(-1, true)]),
                    ("先々週", &[Component::Week(-2, true)]),
                    ("先先週", &[Component::Week(-2, true)]),
                ],
            ),
            Pattern::with_builder(
                "ja_ymdDate",
                "(?P<guard0>)(?:([0-9]{4})[/／]([0-9]{1,2})[/／]([0-9]{1,2})|([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})|([0-9]{4})\\.([0-9]{1,2})\\.([0-9]{1,2}))(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9./／\\-]"),
                    ("guard1", false, "(?:[0-9./／\\-]|T[0-9])"),
                ],
                build_ymd_date,
            ),
            Pattern::with_builder(
                "ja_mdSlashDate",
                "(?P<guard0>)([0-9]{1,2})[/／]([0-9]{1,2})(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9./／\\-]"),
                    ("guard1", false, "[0-9./／\\-]"),
                ],
                build_md_slash_date,
            ),
            Pattern::with_builder(
                "ja_eraYear",
                "(令和|平成|昭和|大正|明治)(元|[0-9]{1,2}|[一二三四五六七八九十]+)年(?P<guard1>)",
                &[("guard1", false, "間")],
                build_era_year,
            ),
            Pattern::with_builder(
                "ja_timeAmPm",
                "(?P<guard0>)(?:([ap]m|[AP]M)[\\s\\u{3000}]*([0-9]{1,2})(?::([0-9]{2}))?|([0-9]{1,2})(?::([0-9]{2}))?[\\s\\u{3000}]*([ap]m|[AP]M))(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-Z0-9]"),
                    ("guard1", false, r"[a-zA-Z0-9]|\.[0-9]"),
                ],
                build_time_ampm,
            ),
            Pattern::with_builder(
                "ja_ampmJaTime",
                "(?P<guard0>)([ap]m|[AP]M)[\\s\\u{3000}]*([0-9〇零一二三四五六七八九十]+)時(?:[\\s\\u{3000}]*(?:([0-9〇零一二三四五六七八九十百千]+)分(前)?|(半))(?P<guard2>)|(?P<guard1>))",
                &[
                    ("guard0", true, "[a-zA-Z0-9]"),
                    ("guard1", false, "(?:間|的)"),
                    ("guard2", false, "間"),
                ],
                build_ampm_ja_time,
            ),
            Pattern::with_builder(
                "ja_meridiemTime",
                "(?P<guard0>)(午前|午後|早朝|朝|お昼|昼|夕方|夜|深夜|未明)(?:[\\s\\u{3000}]*の?[\\s\\u{3000}]*)([0-9〇零一二三四五六七八九十百千]+)(?:時(?:[\\s\\u{3000}]*(?:([0-9〇零一二三四五六七八九十百千]+)分(前)?|(半))(?P<guard2>)|(?P<guard1>))|[:：]([0-9]{2})(?P<guard3>))",
                &[
                    ("guard0", true, "毎"),
                    ("guard1", false, "(?:間|的|停止|帰国|金|預|保|払|しのぎ)"),
                    ("guard2", false, "間"),
                    ("guard3", false, "[0-9:：]"),
                ],
                build_meridiem_time,
            ),
            Pattern::new(
                "ja_specialTime",
                "(正午|真夜中)",
                &[],
                &[
                    ("正午", &[Component::Time(12, Some(0), None)]),
                    ("真夜中", &[Component::Time(0, Some(0), None)]),
                ],
            ),
            Pattern::new(
                "ja_meridiem",
                "(午前中|午前|午後)",
                &[],
                &[
                    ("午前中", &[Component::Meridiem(false)]),
                    ("午前", &[Component::Meridiem(false)]),
                    ("午後", &[Component::Meridiem(true)]),
                ],
            ),
            Pattern::with_builder(
                "ja_weekday",
                "(?:[(（]([月火水木金土日])(?:曜|曜日)?[)）]|([月火水木金土日])曜日?|(げつようび|かようび|すいようび|もくようび|きんようび|どようび|にちようび))",
                &[],
                build_weekday,
            ),
            Pattern::with_builder(
                "ja_year",
                "([0-9]{4}|[〇零一二三四五六七八九]{4}|[一二三四五六七八九]千[〇零一二三四五六七八九十百千]+)年(?P<guard1>)",
                &[("guard1", false, "間")],
                build_year,
            ),
            Pattern::new(
                "ja_month",
                "([0-9〇零一二三四五六七八九十百千]+)月(?P<guard0>)",
                &[("guard0", false, "(?:曜|間)")],
                &[],
            ),
            Pattern::new(
                "ja_day",
                "([0-9〇零一二三四五六七八九十百千]+)[日号](?P<guard0>)",
                &[("guard0", false, "(?:間|目|酔|坊|おき|ごと|ぶり)")],
                &[],
            ),
            Pattern::with_builder(
                "ja_time",
                "([0-9〇零一二三四五六七八九十百千]+)時(?:[\\s\\u{3000}]*(?:([0-9〇零一二三四五六七八九十百千]+)分(前)?|(半))(?P<guard0>)|(?P<guard1>))",
                &[
                    ("guard0", false, "間"),
                    ("guard1", false, "(?:間|的|停止|帰国|金|預|保|払|しのぎ)"),
                ],
                build_time,
            ),
            Pattern::with_builder(
                "ja_timeColon",
                "([0-9]{1,2})[:：]([0-9]{2})(?:[:：]([0-9]{2}))?(?P<guard1>)",
                &[("guard1", false, "[0-9:：]")],
                build_time_colon,
            ),
        ],
    )
}

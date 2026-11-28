use crate::{Captures, Component, Language, Pattern};

const WORD_GUARD: &str = "[a-zA-Z0-9áéíóúüñÁÉÍÓÚÜÑ]";

const WEEKDAY_PAT: &str = "wednesday|thursday|saturday|tuesday|monday|friday|sunday|thurs|thur|tues|weds|mon|tue|wed|thu|fri|sat|sun";

const MONTH_PAT: &str = "september|february|november|december|january|october|august|march|april|june|july|sept|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec";

// Allow trailing period only on abbreviated month names so full-name sentence endings like "May. 15" do not merge.
const MONTH_DOT_PAT: &str = "(?:september|february|november|december|january|october|august|march|april|june|july|(?:sept|jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)\\.?|may)";

const WORD_HOUR_PAT: &str = "twelve|eleven|ten|nine|eight|seven|six|five|four|three|two|one|zero";

const NUM_PAT: &str = "[0-9]+|(?:twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)(?:[-\\s]+(?:one|two|three|four|five|six|seven|eight|nine))?|nineteen|eighteen|seventeen|sixteen|fifteen|fourteen|thirteen|twelve|eleven|ten|nine|eight|seven|six|five|four|three|two|one|zero|an|a";

const PERIOD_REL_PAT: &str = "tonight|this\\s+(?:morning|afternoon|evening)|last\\s+night";

fn parse_en_number(s: &str) -> Option<i32> {
    if let Some(n) = crate::number(s) {
        return Some(n);
    }
    let atom = |w: &str| -> Option<i32> {
        Some(match w {
            _ if w.eq_ignore_ascii_case("zero") => 0,
            _ if w.eq_ignore_ascii_case("a")
                || w.eq_ignore_ascii_case("an")
                || w.eq_ignore_ascii_case("one") =>
            {
                1
            }
            _ if w.eq_ignore_ascii_case("two") => 2,
            _ if w.eq_ignore_ascii_case("three") => 3,
            _ if w.eq_ignore_ascii_case("four") => 4,
            _ if w.eq_ignore_ascii_case("five") => 5,
            _ if w.eq_ignore_ascii_case("six") => 6,
            _ if w.eq_ignore_ascii_case("seven") => 7,
            _ if w.eq_ignore_ascii_case("eight") => 8,
            _ if w.eq_ignore_ascii_case("nine") => 9,
            _ if w.eq_ignore_ascii_case("ten") => 10,
            _ if w.eq_ignore_ascii_case("eleven") => 11,
            _ if w.eq_ignore_ascii_case("twelve") => 12,
            _ if w.eq_ignore_ascii_case("thirteen") => 13,
            _ if w.eq_ignore_ascii_case("fourteen") => 14,
            _ if w.eq_ignore_ascii_case("fifteen") => 15,
            _ if w.eq_ignore_ascii_case("sixteen") => 16,
            _ if w.eq_ignore_ascii_case("seventeen") => 17,
            _ if w.eq_ignore_ascii_case("eighteen") => 18,
            _ if w.eq_ignore_ascii_case("nineteen") => 19,
            _ if w.eq_ignore_ascii_case("twenty") => 20,
            _ if w.eq_ignore_ascii_case("thirty") => 30,
            _ if w.eq_ignore_ascii_case("forty") => 40,
            _ if w.eq_ignore_ascii_case("fifty") => 50,
            _ if w.eq_ignore_ascii_case("sixty") => 60,
            _ if w.eq_ignore_ascii_case("seventy") => 70,
            _ if w.eq_ignore_ascii_case("eighty") => 80,
            _ if w.eq_ignore_ascii_case("ninety") => 90,
            _ => return None,
        })
    };
    if let Some(v) = atom(s) {
        return Some(v);
    }
    let mut parts = s
        .split(|c: char| c == '-' || c.is_ascii_whitespace())
        .filter(|p| !p.is_empty());
    let tens = atom(parts.next()?)?;
    let ones = atom(parts.next()?)?;
    if parts.next().is_some() || !(20..=90).contains(&tens) || !(1..=9).contains(&ones) {
        return None;
    }
    Some(tens + ones)
}

fn parse_weekday(s: &str) -> Option<i32> {
    const TABLE: &[(&str, i32)] = &[
        ("monday", 1),
        ("mon", 1),
        ("tuesday", 2),
        ("tues", 2),
        ("tue", 2),
        ("wednesday", 3),
        ("weds", 3),
        ("wed", 3),
        ("thursday", 4),
        ("thurs", 4),
        ("thur", 4),
        ("thu", 4),
        ("friday", 5),
        ("fri", 5),
        ("saturday", 6),
        ("sat", 6),
        ("sunday", 7),
        ("sun", 7),
    ];
    TABLE
        .iter()
        .find(|(w, _)| crate::eq_word(s, w))
        .map(|&(_, v)| v)
}

fn parse_month(s: &str) -> Option<i32> {
    const TABLE: &[(&str, i32)] = &[
        ("january", 1),
        ("jan", 1),
        ("february", 2),
        ("feb", 2),
        ("march", 3),
        ("mar", 3),
        ("april", 4),
        ("apr", 4),
        ("may", 5),
        ("june", 6),
        ("jun", 6),
        ("july", 7),
        ("jul", 7),
        ("august", 8),
        ("aug", 8),
        ("september", 9),
        ("sept", 9),
        ("sep", 9),
        ("october", 10),
        ("oct", 10),
        ("november", 11),
        ("nov", 11),
        ("december", 12),
        ("dec", 12),
    ];
    let clean = s.trim_end_matches('.');
    TABLE
        .iter()
        .find(|(w, _)| crate::eq_word(clean, w))
        .map(|&(_, v)| v)
}

fn parse_ampm(s: &str) -> Option<bool> {
    match s.as_bytes().first()?.to_ascii_lowercase() {
        b'a' => Some(false),
        b'p' => Some(true),
        _ => None,
    }
}

fn offset_component(value: i32, unit: &str) -> Option<Component> {
    Some(
        if unit.eq_ignore_ascii_case("day") || unit.eq_ignore_ascii_case("days") {
            Component::RelativeDay(value)
        } else if unit.eq_ignore_ascii_case("wk")
            || unit.eq_ignore_ascii_case("wks")
            || unit.eq_ignore_ascii_case("week")
            || unit.eq_ignore_ascii_case("weeks")
        {
            Component::Week(value, false)
        } else if unit.eq_ignore_ascii_case("mo")
            || unit.eq_ignore_ascii_case("mos")
            || unit.eq_ignore_ascii_case("month")
            || unit.eq_ignore_ascii_case("months")
        {
            Component::MonthOffset(value)
        } else if unit.eq_ignore_ascii_case("yr")
            || unit.eq_ignore_ascii_case("yrs")
            || unit.eq_ignore_ascii_case("year")
            || unit.eq_ignore_ascii_case("years")
        {
            Component::YearOffset(value)
        } else {
            return None;
        },
    )
}

fn time_with_period(
    h: i32,
    min: Option<i32>,
    sec: Option<i32>,
    explicit_pm: Option<bool>,
    period_pm: bool,
) -> Option<Component> {
    if !sec.is_none_or(|s| (0..60).contains(&s)) || !min.is_none_or(|m| (0..60).contains(&m)) {
        return None;
    }
    if explicit_pm.is_some_and(|exp| exp != period_pm) {
        return None;
    }
    let valid_h = if !period_pm {
        (0..=12).contains(&h)
    } else if min.is_some() && explicit_pm.is_none() {
        (1..=23).contains(&h)
    } else {
        (1..=12).contains(&h)
    };
    valid_h.then_some(Component::Time(h, min, Some(period_pm)))
}

fn period_info(c: &Captures<'_>) -> Option<(bool, Option<i32>)> {
    if let Some(rel) = c.name("rel").map(|m| m.as_str()) {
        let lower = rel.to_ascii_lowercase();
        if lower.starts_with("last") {
            Some((true, Some(-1)))
        } else if lower.contains("morning") {
            Some((false, Some(0)))
        } else {
            Some((true, Some(0)))
        }
    } else if let Some(per) = c.name("per").map(|m| m.as_str()) {
        Some((!per.eq_ignore_ascii_case("morning"), None))
    } else if c.name("night").is_some() {
        Some((true, None))
    } else {
        None
    }
}

fn opt_num(m: Option<crate::Capture<'_>>) -> Option<Option<i32>> {
    Some(match m {
        Some(m) => Some(crate::number(m.as_str())?),
        None => None,
    })
}

fn with_optional_rel(rel_day: Option<i32>, time: Component) -> Vec<Component> {
    match rel_day {
        Some(d) => vec![Component::RelativeDay(d), time],
        None => vec![time],
    }
}

pub fn language() -> Language {
    Language::new(
        "en",
        "(?i)(?:[\\s,@]|on|at|the|of|in|around|about|by)+",
        vec![
            Pattern::with_builder(
                "en_nthWeekday",
                &format!(
                    "(?i)(?P<guard0>)(?:the\\s+)?(?P<ord>first|second|third|fourth|fifth|last|final|1st|2nd|3rd|4th|5th)\\s+(?P<wd>{WEEKDAY_PAT})\\s+(?:of|in)\\s+(?P<mo>{MONTH_PAT})(?P<guard1>)"
                ),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let ord_raw = c.name("ord")?.as_str();
                    let ord = if ord_raw.eq_ignore_ascii_case("first")
                        || ord_raw.eq_ignore_ascii_case("1st")
                    {
                        1
                    } else if ord_raw.eq_ignore_ascii_case("second")
                        || ord_raw.eq_ignore_ascii_case("2nd")
                    {
                        2
                    } else if ord_raw.eq_ignore_ascii_case("third")
                        || ord_raw.eq_ignore_ascii_case("3rd")
                    {
                        3
                    } else if ord_raw.eq_ignore_ascii_case("fourth")
                        || ord_raw.eq_ignore_ascii_case("4th")
                    {
                        4
                    } else if ord_raw.eq_ignore_ascii_case("fifth")
                        || ord_raw.eq_ignore_ascii_case("5th")
                    {
                        5
                    } else {
                        -1
                    };
                    let wd = parse_weekday(c.name("wd")?.as_str())?;
                    let mo = parse_month(c.name("mo")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, mo)])
                },
            ),
            Pattern::with_builder(
                "en_periodTime",
                &format!(
                    "(?i)(?P<guard0>)(?:(?P<rel>{PERIOD_REL_PAT})|(?:in\\s+the\\s+)?(?P<per>morning|afternoon|evening)|(?:at\\s+)?(?P<night>night))\\s+(?:(?:at|around|about)\\s+|@\\s*)?(?P<hour>[0-9]{{1,2}})(?::(?P<min>[0-9]{{2}})(?::(?P<sec>[0-9]{{2}}))?(?:\\s*(?P<oc1>o['’]?clock))?(?:\\s*(?P<ampm1>a\\.?m\\.?|p\\.?m\\.?))?|\\s*(?P<oc2>o['’]?clock)(?:\\s*(?P<ampm2>a\\.?m\\.?|p\\.?m\\.?))?|\\s*(?P<ampm3>a\\.?m\\.?|p\\.?m\\.?))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, WORD_GUARD),
                    ("guard1", false, "[a-zA-Z0-9%:]"),
                ],
                |c, _| {
                    let (period_pm, rel_day) = period_info(c)?;
                    let h = crate::number(c.name("hour")?.as_str())?;
                    let mut min = c.name("min").and_then(|m| crate::number(m.as_str()));
                    if min.is_none() && (c.name("oc1").is_some() || c.name("oc2").is_some()) {
                        min = Some(0);
                    }
                    let sec = c.name("sec").and_then(|m| crate::number(m.as_str()));
                    let exp_pm = c
                        .name("ampm1")
                        .or_else(|| c.name("ampm2"))
                        .or_else(|| c.name("ampm3"))
                        .and_then(|m| parse_ampm(m.as_str()));
                    let time = time_with_period(h, min, sec, exp_pm, period_pm)?;
                    Some(with_optional_rel(rel_day, time))
                },
            ),
            Pattern::with_builder(
                "en_periodAtHour",
                &format!(
                    "(?i)(?P<guard0>)(?:(?P<rel>{PERIOD_REL_PAT})|(?:in\\s+the\\s+)?(?P<per>morning|afternoon|evening)|(?:at\\s+)?(?P<night>night))\\s+(?:(?:at|around|about)\\s+|@\\s*)(?P<hour>[0-9]{{1,2}}|{WORD_HOUR_PAT})(?P<guard1>)"
                ),
                &[
                    ("guard0", true, WORD_GUARD),
                    ("guard1", false, "[a-zA-Z0-9%:]"),
                ],
                |c, _| {
                    let (period_pm, rel_day) = period_info(c)?;
                    let h = parse_en_number(c.name("hour")?.as_str())?;
                    if !(1..=12).contains(&h) {
                        return None;
                    }
                    let time = time_with_period(h, None, None, None, period_pm)?;
                    Some(with_optional_rel(rel_day, time))
                },
            ),
            Pattern::with_builder(
                "en_timeBeforePeriod",
                &format!(
                    "(?i)(?P<guard0>)(?:(?P<h1>[0-9]{{1,2}}|{WORD_HOUR_PAT})(?::(?P<min1>[0-9]{{2}})(?::(?P<sec1>[0-9]{{2}}))?)?(?:\\s*(?P<oc1>o['’]?clock))?(?:\\s*(?P<ampm1>a\\.?m\\.?|p\\.?m\\.?))?\\s+(?:in\\s+the\\s+(?P<per>morning|afternoon|evening)|at\\s+(?P<night>night))|(?P<h2>[0-9]{{1,2}}|{WORD_HOUR_PAT})(?::(?P<min2>[0-9]{{2}})(?::(?P<sec2>[0-9]{{2}}))?(?:\\s*(?P<ampm2>a\\.?m\\.?|p\\.?m\\.?))?|\\s*(?P<oc2>o['’]?clock)(?:\\s*(?P<ampm3>a\\.?m\\.?|p\\.?m\\.?))?|\\s*(?P<ampm4>a\\.?m\\.?|p\\.?m\\.?))\\s+(?:(?:on|at)\\s+)?(?P<rel>{PERIOD_REL_PAT}))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[a-zA-Z0-9.:]"),
                    ("guard1", false, WORD_GUARD),
                ],
                |c, _| {
                    let (period_pm, rel_day) = period_info(c)?;
                    let h_str = c.name("h1").or_else(|| c.name("h2"))?.as_str();
                    let min_m = c.name("min1").or_else(|| c.name("min2"));
                    if min_m.is_some() && !h_str.bytes().all(|b| b.is_ascii_digit()) {
                        return None;
                    }
                    let h = parse_en_number(h_str)?;
                    let mut min = min_m.and_then(|m| crate::number(m.as_str()));
                    if min.is_none() && (c.name("oc1").is_some() || c.name("oc2").is_some()) {
                        min = Some(0);
                    }
                    let sec = c
                        .name("sec1")
                        .or_else(|| c.name("sec2"))
                        .and_then(|m| crate::number(m.as_str()));
                    let exp_pm = c
                        .name("ampm1")
                        .or_else(|| c.name("ampm2"))
                        .or_else(|| c.name("ampm3"))
                        .or_else(|| c.name("ampm4"))
                        .and_then(|m| parse_ampm(m.as_str()));
                    let time = time_with_period(h, min, sec, exp_pm, period_pm)?;
                    Some(with_optional_rel(rel_day, time))
                },
            ),
            Pattern::with_builder(
                "en_relativePhrase",
                "(?i)(?P<guard0>)(?:(?:the\\s+)?day\\s+after\\s+tomorrow|(?:the\\s+)?day\\s+before\\s+yesterday|this\\s+(?:morning|afternoon|evening)|last\\s+night)(?P<guard1>)",
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let lower = c.get(0)?.as_str().to_ascii_lowercase();
                    Some(if lower.contains("tomorrow") {
                        vec![Component::RelativeDay(2)]
                    } else if lower.contains("yesterday") {
                        vec![Component::RelativeDay(-2)]
                    } else if lower.contains("morning") {
                        vec![Component::RelativeDay(0), Component::Meridiem(false)]
                    } else if lower.contains("night") {
                        vec![Component::RelativeDay(-1), Component::Meridiem(true)]
                    } else {
                        vec![Component::RelativeDay(0), Component::Meridiem(true)]
                    })
                },
            ),
            Pattern::new(
                "en_relativeDay",
                "(?i)(?P<guard0>)(yesterday|tomorrow|overmorrow|tonight|today|tmrw|tmw)(?P<guard1>)",
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                &[
                    ("today", &[Component::RelativeDay(0)]),
                    ("tomorrow", &[Component::RelativeDay(1)]),
                    ("tmrw", &[Component::RelativeDay(1)]),
                    ("tmw", &[Component::RelativeDay(1)]),
                    ("overmorrow", &[Component::RelativeDay(2)]),
                    ("yesterday", &[Component::RelativeDay(-1)]),
                    (
                        "tonight",
                        &[Component::RelativeDay(0), Component::Meridiem(true)],
                    ),
                ],
            ),
            Pattern::with_builder(
                "en_within",
                &format!(
                    "(?i)(?P<guard0>)within\\s+(?:the\\s+next\\s+)?(?P<num>{NUM_PAT})\\s+(?P<unit>days?|weeks?|wks?)(?P<guard1>)"
                ),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let n = parse_en_number(c.name("num")?.as_str())?;
                    let unit = c.name("unit")?.as_str();
                    let days = if unit.as_bytes().first()?.eq_ignore_ascii_case(&b'w') {
                        n.checked_mul(7)?
                    } else {
                        n
                    };
                    Some(vec![Component::Within(days)])
                },
            ),
            Pattern::with_builder(
                "en_in",
                &format!(
                    "(?i)(?P<guard0>)in\\s+(?P<num>{NUM_PAT})\\s+(?P<unit>days?|weeks?|wks?|months?|mos?|years?|yrs?)(?:'s?\\s+time)?(?P<guard1>)"
                ),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let n = parse_en_number(c.name("num")?.as_str())?;
                    Some(vec![offset_component(n, c.name("unit")?.as_str())?])
                },
            ),
            Pattern::with_builder(
                "en_offset",
                &format!(
                    "(?i)(?P<guard0>)(?P<num>{NUM_PAT})\\s+(?P<unit>days?|weeks?|wks?|months?|mos?|years?|yrs?)\\s+(?P<dir>from\\s+now|later|ago|earlier)(?P<guard1>)"
                ),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let n = parse_en_number(c.name("num")?.as_str())?;
                    let dir = c.name("dir")?.as_str();
                    let v =
                        if dir.eq_ignore_ascii_case("ago") || dir.eq_ignore_ascii_case("earlier") {
                            n.checked_neg()?
                        } else {
                            n
                        };
                    Some(vec![offset_component(v, c.name("unit")?.as_str())?])
                },
            ),
            Pattern::new(
                "en_anchor",
                "(?i)(?P<guard0>)(next weekend|this weekend|last weekend|next month|this month|last month|next year|this year|last year|next week|this week|last week|weekend)(?P<guard1>)",
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                &[
                    ("next year", &[Component::YearOffset(1)]),
                    ("this year", &[Component::YearOffset(0)]),
                    ("last year", &[Component::YearOffset(-1)]),
                    ("next month", &[Component::MonthOffset(1)]),
                    ("this month", &[Component::MonthOffset(0)]),
                    ("last month", &[Component::MonthOffset(-1)]),
                    ("next week", &[Component::Week(1, true)]),
                    ("this week", &[Component::Week(0, true)]),
                    ("last week", &[Component::Week(-1, true)]),
                    ("next weekend", &[Component::Weekend]),
                    ("this weekend", &[Component::Weekend]),
                    ("weekend", &[Component::Weekend]),
                    (
                        "last weekend",
                        &[Component::Week(-1, false), Component::Weekday(7)],
                    ),
                ],
            ),
            Pattern::with_builder(
                "en_anchorPhrase",
                "(?i)(?P<guard0>)(?:(?P<mod>following|previous|upcoming|current|coming|past)\\s+(?P<unit>weekend|month|year|week)|(?:the\\s+)?(?P<unit2>month|year|week)\\s+(?P<rel>after\\s+next|before\\s+last))(?P<guard1>)",
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    if let (Some(md), Some(unit)) = (c.name("mod"), c.name("unit")) {
                        let m = md.as_str();
                        let offset = if m.eq_ignore_ascii_case("current") {
                            0
                        } else if m.eq_ignore_ascii_case("past")
                            || m.eq_ignore_ascii_case("previous")
                        {
                            -1
                        } else {
                            1
                        };
                        let u = unit.as_str();
                        return Some(if u.eq_ignore_ascii_case("weekend") {
                            if offset < 0 {
                                vec![Component::Week(-1, false), Component::Weekday(7)]
                            } else {
                                vec![Component::Weekend]
                            }
                        } else if u.eq_ignore_ascii_case("week") {
                            vec![Component::Week(offset, true)]
                        } else if u.eq_ignore_ascii_case("month") {
                            vec![Component::MonthOffset(offset)]
                        } else {
                            vec![Component::YearOffset(offset)]
                        });
                    }
                    let u = c.name("unit2")?.as_str();
                    let rel = c.name("rel")?.as_str().to_ascii_lowercase();
                    let offset = if rel.starts_with("after") { 2 } else { -2 };
                    Some(if u.eq_ignore_ascii_case("week") {
                        vec![Component::Week(offset, true)]
                    } else if u.eq_ignore_ascii_case("month") {
                        vec![Component::MonthOffset(offset)]
                    } else {
                        vec![Component::YearOffset(offset)]
                    })
                },
            ),
            Pattern::with_builder(
                "en_nextLastWeekday",
                &format!(
                    "(?i)(?P<guard0>)(?P<mod>following|previous|upcoming|coming|next|last|this|past)\\s+(?P<wd>{WEEKDAY_PAT})(?P<guard1>)"
                ),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let m = c.name("mod")?.as_str();
                    let wd = parse_weekday(c.name("wd")?.as_str())?;
                    if m.eq_ignore_ascii_case("this") {
                        return Some(vec![Component::Weekday(wd)]);
                    }
                    let offset = if m.eq_ignore_ascii_case("last")
                        || m.eq_ignore_ascii_case("past")
                        || m.eq_ignore_ascii_case("previous")
                    {
                        -1
                    } else {
                        1
                    };
                    Some(vec![Component::Week(offset, false), Component::Weekday(wd)])
                },
            ),
            Pattern::with_builder(
                "en_monthDay",
                &format!(
                    "(?i)(?P<guard0>)(?P<mo>{MONTH_DOT_PAT})\\s+(?:the\\s+(?P<day_ord>[0-9]{{1,2}})(?:st|nd|rd|th)|(?P<day>[0-9]{{1,2}})(?:st|nd|rd|th)?)(?:,?\\s+(?P<yr>[0-9]{{4}}))?(?P<guard1>)"
                ),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let mo = parse_month(c.name("mo")?.as_str())?;
                    let day = crate::number(c.name("day_ord").or_else(|| c.name("day"))?.as_str())?;
                    let mut cs = vec![Component::Month(mo), Component::Day(day)];
                    if let Some(yr) = c.name("yr") {
                        cs.push(Component::Year(crate::number(yr.as_str())?));
                    }
                    Some(cs)
                },
            ),
            Pattern::with_builder(
                "en_dayMonth",
                &format!(
                    "(?i)(?P<guard0>)(?:the\\s+(?P<day_ord>[0-9]{{1,2}})(?:st|nd|rd|th)(?:\\s+of)?\\s+|(?P<day>[0-9]{{1,2}})(?:(?:st|nd|rd|th)?(?:\\s+of)?\\s+|-))(?P<mo>{MONTH_PAT})(?:(?:\\.?,?\\s+|\\s*-\\s*)(?P<yr>[0-9]{{4}}))?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[a-zA-Z0-9-]"),
                    ("guard1", false, WORD_GUARD),
                ],
                |c, _| {
                    let mo = parse_month(c.name("mo")?.as_str())?;
                    let day = crate::number(c.name("day_ord").or_else(|| c.name("day"))?.as_str())?;
                    let mut cs = vec![Component::Month(mo), Component::Day(day)];
                    if let Some(yr) = c.name("yr") {
                        cs.push(Component::Year(crate::number(yr.as_str())?));
                    }
                    Some(cs)
                },
            ),
            Pattern::with_builder(
                "en_monthYear",
                &format!(
                    "(?i)(?P<guard0>)(?P<mo>{MONTH_PAT})(?:\\.?,?\\s+|\\.?\\s+of\\s+|\\s*-\\s*)(?P<yr>[0-9]{{4}})(?P<guard1>)"
                ),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let mo = parse_month(c.name("mo")?.as_str())?;
                    let yr = crate::number(c.name("yr")?.as_str())?;
                    (yr >= 1).then_some(vec![Component::Month(mo), Component::Year(yr)])
                },
            ),
            Pattern::new(
                "en_weekday",
                &format!("(?i)(?P<guard0>)({WEEKDAY_PAT})(?P<guard1>)"),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                &[
                    ("monday", &[Component::Weekday(1)]),
                    ("mon", &[Component::Weekday(1)]),
                    ("tuesday", &[Component::Weekday(2)]),
                    ("tues", &[Component::Weekday(2)]),
                    ("tue", &[Component::Weekday(2)]),
                    ("wednesday", &[Component::Weekday(3)]),
                    ("weds", &[Component::Weekday(3)]),
                    ("wed", &[Component::Weekday(3)]),
                    ("thursday", &[Component::Weekday(4)]),
                    ("thurs", &[Component::Weekday(4)]),
                    ("thur", &[Component::Weekday(4)]),
                    ("thu", &[Component::Weekday(4)]),
                    ("friday", &[Component::Weekday(5)]),
                    ("fri", &[Component::Weekday(5)]),
                    ("saturday", &[Component::Weekday(6)]),
                    ("sat", &[Component::Weekday(6)]),
                    ("sunday", &[Component::Weekday(7)]),
                    ("sun", &[Component::Weekday(7)]),
                ],
            ),
            Pattern::new(
                "en_month",
                &format!("(?i)(?P<guard0>)({MONTH_PAT})(?P<guard1>)"),
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                &[
                    ("january", &[Component::Month(1)]),
                    ("jan", &[Component::Month(1)]),
                    ("february", &[Component::Month(2)]),
                    ("feb", &[Component::Month(2)]),
                    ("march", &[Component::Month(3)]),
                    ("mar", &[Component::Month(3)]),
                    ("april", &[Component::Month(4)]),
                    ("apr", &[Component::Month(4)]),
                    ("may", &[Component::Month(5)]),
                    ("june", &[Component::Month(6)]),
                    ("jun", &[Component::Month(6)]),
                    ("july", &[Component::Month(7)]),
                    ("jul", &[Component::Month(7)]),
                    ("august", &[Component::Month(8)]),
                    ("aug", &[Component::Month(8)]),
                    ("september", &[Component::Month(9)]),
                    ("sept", &[Component::Month(9)]),
                    ("sep", &[Component::Month(9)]),
                    ("october", &[Component::Month(10)]),
                    ("oct", &[Component::Month(10)]),
                    ("november", &[Component::Month(11)]),
                    ("nov", &[Component::Month(11)]),
                    ("december", &[Component::Month(12)]),
                    ("dec", &[Component::Month(12)]),
                ],
            ),
            Pattern::new(
                "en_ordinalDay",
                "(?i)(?P<guard0>)(?:the\\s+)?([0-9]{1,2})(?:st|nd|rd|th)(?P<guard1>)",
                &[("guard0", true, "[a-zA-Z.]"), ("guard1", false, WORD_GUARD)],
                &[],
            ),
            Pattern::with_builder(
                "en_slashDate",
                "(?P<guard0>)(?:(?P<y4>[0-9]{4})[/-](?P<m4>[0-9]{1,2})[/-](?P<d4>[0-9]{1,2})|(?P<a>[0-9]{1,2})[/-](?P<b>[0-9]{1,2})[/-](?P<y>[0-9]{2}(?:[0-9]{2})?))(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-Z0-9./-]"),
                    ("guard1", false, "[a-zA-Z0-9/-]"),
                ],
                |c, _| {
                    if let Some(y4) = c.name("y4") {
                        let y = crate::number(y4.as_str())?;
                        let m = crate::number(c.name("m4")?.as_str())?;
                        let d = crate::number(c.name("d4")?.as_str())?;
                        return Some(vec![
                            Component::Year(y),
                            Component::Month(m),
                            Component::Day(d),
                        ]);
                    }
                    let a = crate::number(c.name("a")?.as_str())?;
                    let b = crate::number(c.name("b")?.as_str())?;
                    let y_raw = c.name("y")?.as_str();
                    let y_val = crate::number(y_raw)?;
                    let y = if y_raw.len() == 2 {
                        if y_val >= 70 {
                            1900 + y_val
                        } else {
                            2000 + y_val
                        }
                    } else {
                        y_val
                    };
                    let (m, d) = if a > 12 { (b, a) } else { (a, b) };
                    Some(vec![
                        Component::Year(y),
                        Component::Month(m),
                        Component::Day(d),
                    ])
                },
            ),
            Pattern::with_builder(
                "en_dotDate",
                "(?P<guard0>)(?:(?P<y4>[0-9]{4})\\.(?P<m4>[0-9]{1,2})\\.(?P<d4>[0-9]{1,2})|(?P<d>[0-9]{1,2})\\.(?P<m>[0-9]{1,2})\\.(?P<y>[0-9]{4}))(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-Z0-9.]"),
                    ("guard1", false, "(?:[a-zA-Z0-9]|\\.[0-9])"),
                ],
                |c, _| {
                    if let Some(y4) = c.name("y4") {
                        let y = crate::number(y4.as_str())?;
                        let m = crate::number(c.name("m4")?.as_str())?;
                        let d = crate::number(c.name("d4")?.as_str())?;
                        return Some(vec![
                            Component::Year(y),
                            Component::Month(m),
                            Component::Day(d),
                        ]);
                    }
                    let mut d = crate::number(c.name("d")?.as_str())?;
                    let mut m = crate::number(c.name("m")?.as_str())?;
                    let y = crate::number(c.name("y")?.as_str())?;
                    if m > 12 && d <= 12 {
                        (m, d) = (d, m);
                    }
                    Some(vec![
                        Component::Year(y),
                        Component::Month(m),
                        Component::Day(d),
                    ])
                },
            ),
            Pattern::with_builder(
                "en_spokenTime",
                &format!(
                    "(?i)(?P<guard0>)(?:(?:(?:a\\s+)?(?P<frac>half|quarter)|(?P<mins>[0-9]{{1,2}})\\s+min(?:ute)?s?)\\s+(?P<prep>past|after|to|till|til|'til|before)\\s+(?P<target>noon|midday|midnight|[0-9]{{1,2}}|{WORD_HOUR_PAT})(?:\\s*(?P<ampm1>a\\.?m\\.?|p\\.?m\\.?))?|(?P<oh>[0-9]{{1,2}}|{WORD_HOUR_PAT})\\s*o['’]?clock(?:\\s*(?P<ampm2>a\\.?m\\.?|p\\.?m\\.?))?)(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[a-zA-Z0-9.:]"),
                    ("guard1", false, "[a-zA-Z0-9:]"),
                ],
                |c, _| {
                    if let Some(oh) = c.name("oh") {
                        let h = parse_en_number(oh.as_str())?;
                        let pm = c.name("ampm2").and_then(|m| parse_ampm(m.as_str()));
                        if pm == Some(false) && !(0..=12).contains(&h) {
                            return None;
                        }
                        if pm == Some(true) && !(1..=12).contains(&h) {
                            return None;
                        }
                        return Some(vec![Component::Time(h, Some(0), pm)]);
                    }
                    let prep = c.name("prep")?.as_str();
                    let is_past =
                        prep.eq_ignore_ascii_case("past") || prep.eq_ignore_ascii_case("after");
                    let offset_mins = if let Some(frac) = c.name("frac") {
                        if frac.as_str().eq_ignore_ascii_case("half") {
                            if !prep.eq_ignore_ascii_case("past") {
                                return None;
                            }
                            30
                        } else {
                            15
                        }
                    } else {
                        let m = crate::number(c.name("mins")?.as_str())?;
                        if !(1..=59).contains(&m) {
                            return None;
                        }
                        m
                    };
                    let explicit_pm = c.name("ampm1").and_then(|m| parse_ampm(m.as_str()));
                    let target = c.name("target")?.as_str();
                    let is_noon = target.eq_ignore_ascii_case("noon")
                        || target.eq_ignore_ascii_case("midday");
                    let is_midnight = target.eq_ignore_ascii_case("midnight");
                    if (is_noon || is_midnight) && explicit_pm.is_some() {
                        return None;
                    }
                    let base_h = if is_noon {
                        12
                    } else if is_midnight {
                        0
                    } else {
                        let h = parse_en_number(target)?;
                        if explicit_pm == Some(false) && !(0..=12).contains(&h) {
                            return None;
                        }
                        if explicit_pm == Some(true) && !(1..=12).contains(&h) {
                            return None;
                        }
                        h
                    };
                    if is_past {
                        return Some(vec![Component::Time(
                            base_h,
                            Some(offset_mins),
                            explicit_pm,
                        )]);
                    }
                    let m = 60 - offset_mins;
                    let h = (base_h - 1).rem_euclid(24);
                    // Flip AM/PM when stepping back from 12am/12pm (e.g., "quarter to 12 pm" -> 11:45 AM).
                    let pm = if is_noon {
                        Some(false)
                    } else if is_midnight {
                        None
                    } else if base_h == 12 {
                        explicit_pm.map(|p| !p)
                    } else {
                        explicit_pm
                    };
                    Some(vec![Component::Time(h, Some(m), pm)])
                },
            ),
            Pattern::new(
                "en_fixedTime",
                "(?i)(?P<guard0>)(midnight|midday|noon)(?P<guard1>)",
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                &[
                    ("noon", &[Component::Time(12, Some(0), None)]),
                    ("midday", &[Component::Time(12, Some(0), None)]),
                    ("midnight", &[Component::Time(0, Some(0), None)]),
                ],
            ),
            Pattern::with_builder(
                "en_timeAmPm",
                "(?i)(?P<guard0>)(?P<hour>[0-9]{1,2})(?:[:.](?P<min>[0-9]{2})(?::(?P<sec>[0-9]{2}))?)?\\s*(?P<ampm>a\\.m\\.?|p\\.m\\.?|am|pm)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-Z0-9.:]"),
                    ("guard1", false, WORD_GUARD),
                ],
                |c, _| {
                    let h = crate::number(c.name("hour")?.as_str())?;
                    let min = opt_num(c.name("min"))?;
                    let sec = opt_num(c.name("sec"))?;
                    if !sec.is_none_or(|s| (0..60).contains(&s)) {
                        return None;
                    }
                    let pm = parse_ampm(c.name("ampm")?.as_str())?;
                    let valid_h = if !pm {
                        (0..=12).contains(&h)
                    } else if min.is_some() {
                        (1..=23).contains(&h)
                    } else {
                        (1..=12).contains(&h)
                    };
                    valid_h.then_some(vec![Component::Time(h, min, Some(pm))])
                },
            ),
            Pattern::with_builder(
                "en_clockTime",
                "(?P<guard0>)(?P<hour>[0-9]{1,2}):(?P<min>[0-9]{2})(?::(?P<sec>[0-9]{2}))?(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-Z0-9.:]"),
                    ("guard1", false, "[a-zA-Z0-9:]"),
                ],
                |c, _| {
                    let h = crate::number(c.name("hour")?.as_str())?;
                    let m = crate::number(c.name("min")?.as_str())?;
                    let sec = opt_num(c.name("sec"))?;
                    if !sec.is_none_or(|s| (0..60).contains(&s)) {
                        return None;
                    }
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "en_meridiem",
                "(?i)(?P<guard0>)(?:(?:in\\s+the\\s+)?(?P<per>morning|afternoon|evening)|(?:at\\s+)?(?P<night>night))(?P<guard1>)",
                &[("guard0", true, WORD_GUARD), ("guard1", false, WORD_GUARD)],
                |c, _| {
                    let pm = c
                        .name("per")
                        .is_none_or(|m| !m.as_str().eq_ignore_ascii_case("morning"));
                    Some(vec![Component::Meridiem(pm)])
                },
            ),
        ],
    )
}

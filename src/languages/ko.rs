use crate::{Captures, Component, Language, Pattern};

const MONTH_CORE: &str = r"(?P<m>(?:[0-9]{1,2}|(?P<guard0>)(?:[零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+))월|(?P<guard2>)(?:유월|시월))";
const HOUR_CORE: &str = r"(?:(?P<ah>[0-9]{1,2})|(?P<guard0>)(?P<kh>열한|열두|열세|열네|열다섯|열여섯|열일곱|열여덟|열아홉|스물한|스물두|스물세|스무|다섯|여섯|일곱|여덟|아홉|한|두|세|네|열|[零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+)\s*)시";

fn ko_number(s: &str) -> Option<i32> {
    if s.is_empty() {
        return None;
    }
    match s {
        "한" | "하루" => return Some(1),
        "두" | "이틀" => return Some(2),
        "세" | "사흘" => return Some(3),
        "네" | "나흘" => return Some(4),
        "다섯" | "닷새" => return Some(5),
        "여섯" | "엿새" => return Some(6),
        "일곱" | "이레" => return Some(7),
        "여덟" | "여드레" => return Some(8),
        "아홉" | "아흐레" => return Some(9),
        "열" | "열흘" => return Some(10),
        "열한" => return Some(11),
        "열두" => return Some(12),
        "열세" => return Some(13),
        "열네" => return Some(14),
        "열다섯" => return Some(15),
        "열여섯" => return Some(16),
        "열일곱" => return Some(17),
        "열여덟" => return Some(18),
        "열아홉" => return Some(19),
        "스무" => return Some(20),
        "스물한" => return Some(21),
        "스물두" => return Some(22),
        "스물세" => return Some(23),
        _ => {}
    }
    if s.bytes().all(|b| b.is_ascii_digit()) {
        return s.parse().ok();
    }
    if s.chars().all(|c| {
        matches!(
            c,
            '영' | '일'
                | '이'
                | '삼'
                | '사'
                | '오'
                | '육'
                | '칠'
                | '팔'
                | '구'
                | '십'
                | '백'
                | '천'
        )
    }) {
        let mut total = 0i32;
        let mut current = 0i32;
        let mut has_unit = false;
        for ch in s.chars() {
            let v = match ch {
                '영' => 0,
                '일' => 1,
                '이' => 2,
                '삼' => 3,
                '사' => 4,
                '오' => 5,
                '육' => 6,
                '칠' => 7,
                '팔' => 8,
                '구' => 9,
                '십' => 10,
                '백' => 100,
                '천' => 1000,
                _ => return None,
            };
            if v >= 10 {
                if has_unit && current == 0 {
                    return None;
                }
                let mult = if has_unit { current } else { 1 };
                total = total.checked_add(mult.checked_mul(v)?)?;
                current = 0;
                has_unit = false;
            } else {
                // Reject consecutive Hangul unit digits without a power of 10 (e.g. "이삼", "일일").
                if has_unit {
                    return None;
                }
                current = v;
                has_unit = true;
            }
        }
        return total.checked_add(current);
    }
    crate::number(s)
}

fn ko_month_val(s: &str) -> Option<i32> {
    match s {
        "유월" => Some(6),
        "시월" => Some(10),
        _ => s
            .strip_suffix('월')
            .and_then(ko_number)
            .filter(|m| (1..=12).contains(m)),
    }
}

fn ko_weekday_val(s: &str) -> Option<i32> {
    let first = s.chars().next()?;
    "월화수목금토일"
        .chars()
        .position(|c| c == first)
        .map(|i| i as i32 + 1)
}

fn ko_rel_offset(s: &str) -> Option<i32> {
    match s {
        "지지난" => Some(-2),
        "지난" | "저번" | "전월" => Some(-1),
        "이번" | "금" | "금주" | "이달" | "금월" => Some(0),
        "다음" | "차주" | "차월" | "익월" => Some(1),
        "다다음" | "차차주" => Some(2),
        _ => None,
    }
}

fn parse_hour(c: &Captures<'_>) -> Option<i32> {
    c.name("ah")
        .or_else(|| c.name("kh"))
        .and_then(|m| ko_number(m.as_str()))
        .filter(|h| (0..24).contains(h))
}

fn push_opt_weekday(out: &mut Vec<Component>, c: &Captures<'_>) -> Option<()> {
    if let Some(wd) = c.name("wd") {
        out.push(Component::Weekday(ko_weekday_val(wd.as_str())?));
    }
    Some(())
}

pub fn language() -> Language {
    let time_to_re = format!(
        r"{HOUR_CORE}\s*(?P<m>[0-9]{{1,2}}|[零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+)\s*분\s*전(?P<guard1>)"
    );
    let time_half_re = format!(r"{HOUR_CORE}\s*반(?P<guard1>)");
    let time_re = format!(
        r"{HOUR_CORE}(?:\s*(?:(?P<exact>정각)|(?P<m>[0-9]{{1,2}}|[零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+)\s*분(?:\s*(?P<s>[0-5]?[0-9]|[영일이삼사오육칠팔구십]+)\s*초)?))?(?P<guard1>)"
    );
    let month_dal_re = format!(r"{MONTH_CORE}\s*달(?P<guard1>)");
    let nth_re = r"(?P<nth_m>(?:1[0-2]|0?[1-9]|(?P<guard0>)(?:[零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+))월|(?P<guard2>)(?:유월|시월))(?:\s*의)?\s*(?P<ord>첫\s*번째|두\s*번째|세\s*번째|네\s*번째|다섯\s*번째|첫째|둘째|셋째|넷째|다섯째|첫|1번째|2번째|3번째|4번째|5번째|마지막)(?:\s*주)?\s*(?P<wd>[월화수목금토일])(?:요일|욜)";

    Language::new(
        "ko",
        r"(?:[\s,]|에(?:는|도)?|의)+",
        vec![
            Pattern::with_builder(
                "ko_ymdDate",
                r"(?P<guard0>)(?:(?P<dy>[0-9]{4})\s*\.\s*(?P<dm>[0-9]{1,2})\s*\.\s*(?P<dd>[0-9]{1,2})\.?|(?P<hy>[0-9]{4})-(?P<hm>[0-9]{1,2})-(?P<hd>[0-9]{1,2})|(?P<sy>[0-9]{4})/(?P<sm>[0-9]{1,2})/(?P<sd>[0-9]{1,2}))(?:\s*\((?P<wd>[월화수목금토일])(?:요일)?\))?(?P<guard1>)",
                &[
                    ("guard0", true, r"[0-9./-]"),
                    ("guard1", false, r"[0-9/-]|\.[0-9]|T[0-9]|:[0-9]"),
                ],
                |c, _| {
                    let (y, m, d) = if let (Some(y), Some(m), Some(d)) =
                        (c.name("dy"), c.name("dm"), c.name("dd"))
                    {
                        (y, m, d)
                    } else if let (Some(y), Some(m), Some(d)) =
                        (c.name("hy"), c.name("hm"), c.name("hd"))
                    {
                        (y, m, d)
                    } else {
                        (c.name("sy")?, c.name("sm")?, c.name("sd")?)
                    };
                    let y = ko_number(y.as_str()).filter(|&v| v >= 1)?;
                    let m = ko_number(m.as_str())?;
                    let d = ko_number(d.as_str())?;
                    let mut out = vec![Component::Year(y), Component::Month(m), Component::Day(d)];
                    push_opt_weekday(&mut out, c)?;
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "ko_slashMonthDay",
                r"(?P<guard0>)(?P<m>[0-9]{1,2})/(?P<d>[0-9]{1,2})(?:\s*\((?P<wd>[월화수목금토일])(?:요일)?\))?(?P<guard1>)",
                &[
                    ("guard0", true, r"[0-9./-]"),
                    ("guard1", false, r"[0-9/-]|\.[0-9]|%"),
                ],
                |c, _| {
                    let m = ko_number(c.name("m")?.as_str())?;
                    let d = ko_number(c.name("d")?.as_str())?;
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    push_opt_weekday(&mut out, c)?;
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "ko_nthWeekday",
                nth_re,
                &[
                    (
                        "guard0",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    ("guard2", true, r"[가-힣a-zA-Z]"),
                ],
                |c, _| {
                    let m = ko_month_val(c.name("nth_m")?.as_str())?;
                    let ord_s = c.name("ord")?.as_str();
                    let ord = if ord_s == "마지막" {
                        -1
                    } else if ord_s.starts_with("첫") || ord_s == "1번째" {
                        1
                    } else if ord_s.starts_with("두") || ord_s.starts_with("둘") || ord_s == "2번째"
                    {
                        2
                    } else if ord_s.starts_with("세") || ord_s.starts_with("셋") || ord_s == "3번째"
                    {
                        3
                    } else if ord_s.starts_with("네") || ord_s.starts_with("넷") || ord_s == "4번째"
                    {
                        4
                    } else if ord_s.starts_with("다섯") || ord_s == "5번째" {
                        5
                    } else {
                        return None;
                    };
                    let wd = ko_weekday_val(c.name("wd")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, m)])
                },
            ),
            Pattern::with_builder(
                "ko_weekendAnchor",
                r"(?P<guard0>)(?P<a>지지난|다다음|다음|이번|금|저번|지난)\s*주말",
                &[("guard0", true, r"[가-힣a-zA-Z0-9]")],
                |c, _| {
                    let a = c.name("a")?.as_str();
                    Some(match a {
                        "이번" | "금" => vec![Component::Weekend],
                        "다음" => vec![Component::Week(1, true), Component::Weekday(7)],
                        "다다음" => vec![Component::Week(2, true), Component::Weekday(7)],
                        "지난" | "저번" => {
                            vec![Component::Week(-1, false), Component::Weekday(7)]
                        }
                        "지지난" => vec![Component::Week(-2, false), Component::Weekday(7)],
                        _ => return None,
                    })
                },
            ),
            Pattern::new(
                "ko_weekend",
                "(주말)",
                &[],
                &[("주말", &[Component::Weekend])],
            ),
            Pattern::with_builder(
                "ko_nextLastWeekday",
                r"(?P<guard0>)(?P<a>지지난|다다음|다음|이번|저번|지난)\s*(?P<wd>[월화수목금토일])(?:요일|욜)",
                &[("guard0", true, r"[가-힣a-zA-Z0-9]")],
                |c, _| {
                    let a = c.name("a")?.as_str();
                    let wd = ko_weekday_val(c.name("wd")?.as_str())?;
                    if a == "이번" {
                        return Some(vec![Component::Weekday(wd)]);
                    }
                    let offset = ko_rel_offset(a)?;
                    Some(vec![Component::Week(offset, false), Component::Weekday(wd)])
                },
            ),
            Pattern::with_builder(
                "ko_weekAnchor",
                r"(?P<guard0>)(?:(?P<a>지지난|다다음|다음|이번|저번|지난)\s*주|(?P<b>차차주|차주|금주))(?P<guard1>)",
                &[
                    ("guard0", true, r"[가-힣a-zA-Z0-9]"),
                    (
                        "guard1",
                        false,
                        r"[말문자식기장사인민소위제목력변관석정거권류가격파선요안체하]",
                    ),
                ],
                |c, _| {
                    let raw = c.name("a").or_else(|| c.name("b"))?.as_str();
                    Some(vec![Component::Week(ko_rel_offset(raw)?, true)])
                },
            ),
            Pattern::with_builder(
                "ko_monthAnchor",
                r"(?P<guard0>)(?:(?P<a>지지난|다다음|다음|이번|저번|지난)\s*(?:달|월)|(?P<b>이달|금월|차월|익월|전월))(?P<guard1>)",
                &[
                    ("guard0", true, r"[가-힣a-zA-Z0-9]"),
                    ("guard1", false, r"[요력리]"),
                ],
                |c, _| {
                    let raw = c.name("a").or_else(|| c.name("b"))?.as_str();
                    Some(vec![Component::MonthOffset(ko_rel_offset(raw)?)])
                },
            ),
            Pattern::with_builder(
                "ko_yearAnchor",
                r"(?P<guard0>)(?P<a>재작년|작년|금년|올해|올\s*해|내후년|내년|명년|지난\s*해|다음\s*해)(?P<guard1>)",
                &[
                    ("guard0", true, r"[가-힣a-zA-Z0-9]"),
                    ("guard1", false, r"[상명법적결외하]"),
                ],
                |c, _| {
                    let a = c.name("a")?.as_str();
                    let offset = match a {
                        "재작년" => -2,
                        "작년" => -1,
                        "금년" | "올해" => 0,
                        "내년" | "명년" => 1,
                        "내후년" => 2,
                        _ if a.starts_with("올") => 0,
                        _ if a.starts_with("지난") => -1,
                        _ if a.starts_with("다음") => 1,
                        _ => return None,
                    };
                    Some(vec![Component::YearOffset(offset)])
                },
            ),
            Pattern::with_builder(
                "ko_within",
                r"(?:(?P<guard0>)(?P<nat>하루|이틀|사흘|나흘|닷새|엿새|이레|여드레|아흐레|열흘)|(?P<guard2>)(?P<wk_one>일\s*주일?|한\s*주일?)|(?:(?P<an>[0-9]+)|(?P<guard3>)(?P<kn>[零一二三四五六七八九十]+|[영일이삼사오육칠팔구십백천]+))\s*(?P<unit>일|주일?))\s*(?:이내(?:\s*에)?|안(?:에|으로)|내\s*에|내(?P<guard1>))",
                &[
                    ("guard0", true, r"[가-힣a-zA-Z0-9]"),
                    ("guard2", true, r"[가-힣a-zA-Z0-9]"),
                    (
                        "guard3",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    ("guard1", false, r"[가-힣]"),
                ],
                |c, _| {
                    let days = if let Some(nat) = c.name("nat") {
                        ko_number(nat.as_str())?
                    } else if c.name("wk_one").is_some() {
                        7
                    } else {
                        let n = c
                            .name("an")
                            .or_else(|| c.name("kn"))
                            .and_then(|m| ko_number(m.as_str()))?;
                        let unit = c.name("unit")?.as_str();
                        if unit.starts_with('주') {
                            n.checked_mul(7)?
                        } else {
                            n
                        }
                    };
                    Some(vec![Component::Within(days)])
                },
            ),
            Pattern::with_builder(
                "ko_offset",
                r"(?:(?P<guard0>)(?P<nat_d>하루|이틀|사흘|나흘|닷새|엿새|이레|여드레|아흐레|열흘)|(?P<guard2>)(?P<nat_n>열한|열두|다섯|여섯|일곱|여덟|아홉|한|두|세|네|열)\s*(?P<nat_u>주일?|달|해)|(?:(?P<an>[0-9]+)|(?P<guard3>)(?P<kn>[零一二三四五六七八九十]+|[영일이삼사오육칠팔구십백천]+))\s*(?P<unit>일|주일?|개월|달|년))\s*(?P<dir>후|뒤|전)(?P<guard1>)",
                &[
                    ("guard0", true, r"[가-힣a-zA-Z0-9]"),
                    ("guard2", true, r"[가-힣a-zA-Z0-9]"),
                    (
                        "guard3",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    ("guard1", false, r"[화력문자배회면원보처시장]"),
                ],
                |c, _| {
                    let (n, unit) = if let Some(nat_d) = c.name("nat_d") {
                        (ko_number(nat_d.as_str())?, "일")
                    } else if let Some(nat_n) = c.name("nat_n") {
                        (ko_number(nat_n.as_str())?, c.name("nat_u")?.as_str())
                    } else {
                        let n = c
                            .name("an")
                            .or_else(|| c.name("kn"))
                            .and_then(|m| ko_number(m.as_str()))?;
                        (n, c.name("unit")?.as_str())
                    };
                    let val = if c.name("dir")?.as_str() == "전" {
                        n.checked_neg()?
                    } else {
                        n
                    };
                    let comp = match unit {
                        "일" => Component::RelativeDay(val),
                        "개월" | "달" => Component::MonthOffset(val),
                        "년" | "해" => Component::YearOffset(val),
                        _ => Component::Week(val, false),
                    };
                    Some(vec![comp])
                },
            ),
            Pattern::with_builder(
                "ko_relativeDay",
                r"(?P<guard0>)(?P<w>내일\s*모레|그끄저께|그끄제|그저께|어저께|그글피|오늘|금일|내일|명일|모레|글피|어제|작일|그제)",
                &[("guard0", true, r"[가-힣a-zA-Z0-9]")],
                |c, _| {
                    let w = c.name("w")?.as_str();
                    let d = match w {
                        "그끄제" | "그끄저께" => -3,
                        "그제" | "그저께" => -2,
                        "어제" | "어저께" | "작일" => -1,
                        "오늘" | "금일" => 0,
                        "내일" | "명일" => 1,
                        "모레" => 2,
                        "글피" => 3,
                        "그글피" => 4,
                        _ if w.starts_with("내일") => 2,
                        _ => return None,
                    };
                    Some(vec![Component::RelativeDay(d)])
                },
            ),
            Pattern::with_builder(
                "ko_noonMidnight",
                r"(?P<guard0>)(?P<kind>정오|자정)(?:\s*(?P<m>[0-9]{1,2}|[영일이삼사오육칠팔구십]+)\s*분\s*(?P<dir>전|후))?",
                &[("guard0", true, r"[가-힣a-zA-Z0-9]")],
                |c, _| {
                    let base_h = if c.name("kind")?.as_str() == "정오" {
                        12
                    } else {
                        0
                    };
                    if let (Some(m), Some(dir)) = (c.name("m"), c.name("dir")) {
                        let m = ko_number(m.as_str()).filter(|&v| (1..60).contains(&v))?;
                        if dir.as_str() == "전" {
                            Some(vec![Component::Time(
                                (base_h - 1_i32).rem_euclid(24),
                                Some(60 - m),
                                None,
                            )])
                        } else {
                            Some(vec![Component::Time(base_h, Some(m), None)])
                        }
                    } else {
                        Some(vec![Component::Time(base_h, Some(0), None)])
                    }
                },
            ),
            Pattern::with_builder(
                "ko_koMeridiem",
                r"(?P<guard0>)(?P<w>오전|오후|새벽|아침|저녁|밤)(?P<guard1>)",
                &[
                    ("guard0", true, r"[군알생]"),
                    ("guard1", false, r"[새중하길송색밥식]"),
                ],
                |c, _| {
                    let pm = matches!(c.name("w")?.as_str(), "오후" | "저녁" | "밤");
                    Some(vec![Component::Meridiem(pm)])
                },
            ),
            Pattern::with_builder(
                "ko_daytime",
                r"(?P<guard0>)낮(?P<guard1>)",
                &[
                    ("guard0", true, r"[대높]"),
                    ("guard1", false, r"[은는다지아어게며니잠술기춰추]"),
                ],
                |_, _| Some(vec![Component::Meridiem(true)]),
            ),
            Pattern::with_builder(
                "ko_asciiMeridiem",
                r"(?P<guard0>)(?P<w>[aApP]\.?[mM]\.?)(?P<guard1>)",
                &[
                    ("guard0", true, r"[a-zA-Z]"),
                    ("guard1", false, r"[a-zA-Z0-9]"),
                ],
                |c, _| {
                    let pm = c.name("w")?.as_str().starts_with(['p', 'P']);
                    Some(vec![Component::Meridiem(pm)])
                },
            ),
            Pattern::with_builder(
                "ko_timeAmPm",
                r"(?P<guard0>)(?P<h>[0-9]{1,2})(?::(?P<m>[0-9]{2}))?\s*(?P<p>[aApP]\.?[mM]\.?)(?P<guard1>)",
                &[
                    ("guard0", true, r"[a-zA-Z:]"),
                    ("guard1", false, r"[a-zA-Z0-9]"),
                ],
                |c, _| {
                    let h = ko_number(c.name("h")?.as_str()).filter(|h| (0..=12).contains(h))?;
                    let m = match c.name("m") {
                        Some(mm) => Some(ko_number(mm.as_str()).filter(|m| (0..60).contains(m))?),
                        None => None,
                    };
                    let pm = c.name("p")?.as_str().starts_with(['p', 'P']);
                    Some(vec![Component::Time(h, m, Some(pm))])
                },
            ),
            Pattern::with_builder(
                "ko_hmsTime",
                r"(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<m>[0-9]{2}):(?P<s>[0-9]{2})(?P<guard1>)",
                &[
                    ("guard0", true, r"[:0-9]"),
                    ("guard1", false, r"[:0-9a-zA-Z]"),
                ],
                |c, _| {
                    let h = ko_number(c.name("h")?.as_str()).filter(|h| (0..24).contains(h))?;
                    let m = ko_number(c.name("m")?.as_str()).filter(|m| (0..60).contains(m))?;
                    let _s = ko_number(c.name("s")?.as_str()).filter(|s| (0..60).contains(s))?;
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "ko_timeTo",
                &time_to_re,
                &[
                    (
                        "guard0",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    ("guard1", false, r"[체화력문자배회면원보처시장]"),
                ],
                |c, _| {
                    let h = parse_hour(c)?;
                    let m = ko_number(c.name("m")?.as_str()).filter(|&v| (1..60).contains(&v))?;
                    Some(vec![Component::Time(
                        (h - 1_i32).rem_euclid(24),
                        Some(60 - m),
                        None,
                    )])
                },
            ),
            Pattern::with_builder(
                "ko_timeHalf",
                &time_half_re,
                &[
                    (
                        "guard0",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    ("guard1", false, r"[달액장]"),
                ],
                |c, _| {
                    let h = parse_hour(c)?;
                    Some(vec![Component::Time(h, Some(30), None)])
                },
            ),
            Pattern::with_builder(
                "ko_time",
                &time_re,
                &[
                    (
                        "guard0",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    (
                        "guard1",
                        false,
                        r"[간적각대민장험작설면고지나죠라어세내원청보계차선기점표비국황]|\s*(?:[0-9]|[零一二三四五六七八九十]|[영일이삼사오육칠팔구십])+\s*분",
                    ),
                ],
                |c, _| {
                    let h = parse_hour(c)?;
                    if let Some(s) = c.name("s") {
                        ko_number(s.as_str()).filter(|v| (0..60).contains(v))?;
                    }
                    let m = if c.name("exact").is_some() {
                        Some(0)
                    } else if let Some(mm) = c.name("m") {
                        Some(ko_number(mm.as_str()).filter(|v| (0..60).contains(v))?)
                    } else {
                        None
                    };
                    Some(vec![Component::Time(h, m, None)])
                },
            ),
            Pattern::with_builder(
                "ko_colon",
                r"(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<m>[0-9]{2})(?P<guard1>)",
                &[
                    ("guard0", true, r"[:0-9]"),
                    ("guard1", false, r"[:0-9a-zA-Z]"),
                ],
                |c, _| {
                    let h = ko_number(c.name("h")?.as_str()).filter(|h| (0..24).contains(h))?;
                    let m = ko_number(c.name("m")?.as_str()).filter(|m| (0..60).contains(m))?;
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "ko_weekday",
                r"(?P<wd>[월화수목금토일])(?:요일|욜)",
                &[],
                |c, _| {
                    Some(vec![Component::Weekday(ko_weekday_val(
                        c.name("wd")?.as_str(),
                    )?)])
                },
            ),
            Pattern::new("ko_year", "([0-9]{4})년", &[], &[]),
            Pattern::with_builder(
                "ko_monthDal",
                &month_dal_re,
                &[
                    (
                        "guard0",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    ("guard2", true, r"[가-힣a-zA-Z]"),
                    ("guard1", false, r"[력리]"),
                ],
                |c, _| Some(vec![Component::Month(ko_month_val(c.name("m")?.as_str())?)]),
            ),
            Pattern::with_builder(
                "ko_month",
                MONTH_CORE,
                &[
                    (
                        "guard0",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    ("guard2", true, r"[가-힣a-zA-Z]"),
                ],
                |c, _| Some(vec![Component::Month(ko_month_val(c.name("m")?.as_str())?)]),
            ),
            Pattern::with_builder(
                "ko_day",
                r"(?:(?P<ad>[0-9]{1,2})|(?P<guard0>)(?P<kd>[零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+))일(?:\s*\((?P<wd>[월화수목금토일])(?:요일)?\))?(?P<guard1>)",
                &[
                    (
                        "guard0",
                        true,
                        r"[영이삼사오육칠팔구십백천零一二三四五六七八九十]",
                    ),
                    (
                        "guard1",
                        false,
                        r"요일|간|째|차|치|분|장|제|절|권|보|용|\s*내(?:내|외)",
                    ),
                ],
                |c, _| {
                    let d = if let Some(ad) = c.name("ad") {
                        ko_number(ad.as_str())?
                    } else {
                        let raw = c.name("kd")?.as_str();
                        if raw == "일" {
                            return None;
                        }
                        ko_number(raw)?
                    };
                    let mut out = vec![Component::Day(d)];
                    push_opt_weekday(&mut out, c)?;
                    Some(out)
                },
            ),
        ],
    )
}

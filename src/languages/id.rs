use crate::{Captures, Component, Language, Pattern};

const G_WORD: &str = "[0-9a-zA-Z\u{00C0}-\u{024F}]";
const DATE_GUARD0: &str = "[0-9./\\-a-zA-Z\u{00C0}-\u{024F}]";
const DATE_GUARD1: &str = "(?:[0-9:/a-zA-Z\u{00C0}-\u{024F}]|\\.[0-9]|-[0-9])";

const WORD_GUARDS: &[(&str, bool, &str)] = &[("guard0", true, G_WORD), ("guard1", false, G_WORD)];
const DATE_GUARDS: &[(&str, bool, &str)] = &[
    ("guard0", true, DATE_GUARD0),
    ("guard1", false, DATE_GUARD1),
];

const WD_FULL: &str = "jum'at|jum’at|selasa|minggu|senin|senen|kamis|jumat|sabtu|rabu|ahad";
const WD_NO_MINGGU: &str = "jum'at|jum’at|selasa|senin|senen|kamis|jumat|sabtu|rabu|ahad|sen\\.?|sel\\.?|rab\\.?|kam\\.?|jum\\.?|sab\\.?";
const WD_ALL: &str = "jum'at|jum’at|selasa|minggu|senin|senen|kamis|jumat|sabtu|ming\\.?|rabu|ahad|mgg\\.?|sen\\.?|sel\\.?|rab\\.?|kam\\.?|jum\\.?|sab\\.?|min\\.?";

const MONTH_ALL: &str = "september|november|nopember|februari|pebruari|djanuari|januari|agustus|oktober|desember|maret|april|djuni|djuli|juni|juli|agst\\.?|sept\\.?|jan\\.?|feb\\.?|peb\\.?|mar\\.?|apr\\.?|jun\\.?|jul\\.?|agt\\.?|ags\\.?|agu\\.?|sep\\.?|okt\\.?|nov\\.?|nop\\.?|des\\.?|mei";

const NUM_ANY: &str = "(?:[0-9]+|seratus|(?:(?:dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)\\s+puluh(?:\\s+(?:satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan))?|(?:dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)\\s+belas|sepuluh|sebelas|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan))";
const NUM_1_59: &str = "(?:[0-9]{1,2}|(?:dua|tiga|empat|lima)\\s+puluh(?:\\s+(?:satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan))?|(?:dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)\\s+belas|sepuluh|sebelas|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)";
const HOUR_WORD: &str = "(?:dua\\s+puluh\\s+(?:satu|dua|tiga)|dua\\s+puluh|(?:dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)\\s+belas|sepuluh|sebelas|nol|kosong|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)";
const HOUR_WORD_1_12: &str =
    "(?:dua\\s+belas|sepuluh|sebelas|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)";
const DAY_PART: &str = "[0-9]{1,2}|tiga\\s+puluh(?:\\s+satu)?|dua\\s+puluh(?:\\s+(?:satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan))?|(?:dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)\\s+belas|sepuluh|sebelas|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan";

const MERIDIEM_ALT: &str = "dini\\s+hari|pagi|siang|sore|petang|mal[ae]m|subuh";
const REL_PERIOD_ALT: &str = "mal[ae]m\\s+ini|pagi\\s+ini|siang\\s+ini|sore\\s+ini|petang\\s+ini|subuh\\s+ini|dini\\s+hari\\s+ini|tadi\\s+pagi|tadi\\s+siang|tadi\\s+sore|tadi\\s+petang|tadi\\s+mal[ae]m|kemar[ie]n\\s+mal[ae]m|semalam|nanti\\s+mal[ae]m|mal[ae]m\\s+nanti|nanti\\s+sore|sore\\s+nanti|nanti\\s+siang|siang\\s+nanti";

const WEEKDAYS: &[(&str, &[Component])] = &[
    ("senin", &[Component::Weekday(1)]),
    ("senen", &[Component::Weekday(1)]),
    ("sen.", &[Component::Weekday(1)]),
    ("sen", &[Component::Weekday(1)]),
    ("selasa", &[Component::Weekday(2)]),
    ("sel.", &[Component::Weekday(2)]),
    ("sel", &[Component::Weekday(2)]),
    ("rabu", &[Component::Weekday(3)]),
    ("rab.", &[Component::Weekday(3)]),
    ("rab", &[Component::Weekday(3)]),
    ("kamis", &[Component::Weekday(4)]),
    ("kam.", &[Component::Weekday(4)]),
    ("kam", &[Component::Weekday(4)]),
    ("jumat", &[Component::Weekday(5)]),
    ("jum'at", &[Component::Weekday(5)]),
    ("jum’at", &[Component::Weekday(5)]),
    ("jum.", &[Component::Weekday(5)]),
    ("jum", &[Component::Weekday(5)]),
    ("sabtu", &[Component::Weekday(6)]),
    ("sab.", &[Component::Weekday(6)]),
    ("sab", &[Component::Weekday(6)]),
    ("minggu", &[Component::Weekday(7)]),
    ("ahad", &[Component::Weekday(7)]),
    ("ming.", &[Component::Weekday(7)]),
    ("ming", &[Component::Weekday(7)]),
    ("mgg.", &[Component::Weekday(7)]),
    ("mgg", &[Component::Weekday(7)]),
    ("min.", &[Component::Weekday(7)]),
    ("min", &[Component::Weekday(7)]),
];

const MONTHS: &[(&str, &[Component])] = &[
    ("januari", &[Component::Month(1)]),
    ("djanuari", &[Component::Month(1)]),
    ("jan.", &[Component::Month(1)]),
    ("jan", &[Component::Month(1)]),
    ("februari", &[Component::Month(2)]),
    ("pebruari", &[Component::Month(2)]),
    ("feb.", &[Component::Month(2)]),
    ("feb", &[Component::Month(2)]),
    ("peb.", &[Component::Month(2)]),
    ("peb", &[Component::Month(2)]),
    ("maret", &[Component::Month(3)]),
    ("mar.", &[Component::Month(3)]),
    ("mar", &[Component::Month(3)]),
    ("april", &[Component::Month(4)]),
    ("apr.", &[Component::Month(4)]),
    ("apr", &[Component::Month(4)]),
    ("mei", &[Component::Month(5)]),
    ("juni", &[Component::Month(6)]),
    ("djuni", &[Component::Month(6)]),
    ("jun.", &[Component::Month(6)]),
    ("jun", &[Component::Month(6)]),
    ("juli", &[Component::Month(7)]),
    ("djuli", &[Component::Month(7)]),
    ("jul.", &[Component::Month(7)]),
    ("jul", &[Component::Month(7)]),
    ("agustus", &[Component::Month(8)]),
    ("agst.", &[Component::Month(8)]),
    ("agst", &[Component::Month(8)]),
    ("agt.", &[Component::Month(8)]),
    ("agt", &[Component::Month(8)]),
    ("ags.", &[Component::Month(8)]),
    ("ags", &[Component::Month(8)]),
    ("agu.", &[Component::Month(8)]),
    ("agu", &[Component::Month(8)]),
    ("september", &[Component::Month(9)]),
    ("sept.", &[Component::Month(9)]),
    ("sept", &[Component::Month(9)]),
    ("sep.", &[Component::Month(9)]),
    ("sep", &[Component::Month(9)]),
    ("oktober", &[Component::Month(10)]),
    ("okt.", &[Component::Month(10)]),
    ("okt", &[Component::Month(10)]),
    ("november", &[Component::Month(11)]),
    ("nopember", &[Component::Month(11)]),
    ("nov.", &[Component::Month(11)]),
    ("nov", &[Component::Month(11)]),
    ("nop.", &[Component::Month(11)]),
    ("nop", &[Component::Month(11)]),
    ("desember", &[Component::Month(12)]),
    ("des.", &[Component::Month(12)]),
    ("des", &[Component::Month(12)]),
];

fn id_atom(w: &str) -> Option<i32> {
    Some(match w {
        "nol" | "kosong" => 0,
        "satu" | "pertama" | "kesatu" => 1,
        "dua" | "kedua" => 2,
        "tiga" | "ketiga" => 3,
        "empat" | "keempat" => 4,
        "lima" | "kelima" => 5,
        "enam" | "keenam" => 6,
        "tujuh" | "ketujuh" => 7,
        "delapan" | "kedelapan" => 8,
        "sembilan" | "kesembilan" => 9,
        "sepuluh" | "kesepuluh" => 10,
        "sebelas" | "kesebelas" => 11,
        "seratus" => 100,
        _ => return None,
    })
}

fn parse_id_num(s: &str) -> Option<i32> {
    if let Some(n) = crate::number(s) {
        return Some(n);
    }
    let lower = s.to_lowercase();
    let trimmed = lower.trim();
    if let Some(rest) = trimmed.strip_prefix("ke") {
        let rest = rest.trim_start_matches(|c: char| c == '-' || c.is_ascii_whitespace());
        if let Some(n) = crate::number(rest) {
            return Some(n);
        }
    }
    let mut it = trimmed.split_whitespace();
    let w1 = it.next()?;
    let Some(w2) = it.next() else {
        return id_atom(w1);
    };
    let v1 = id_atom(w1)?;
    match w2 {
        "belas" if it.next().is_none() => (2..=9).contains(&v1).then_some(10 + v1),
        "puluh" => {
            if !(2..=9).contains(&v1) {
                return None;
            }
            match it.next() {
                None => Some(v1 * 10),
                Some(w3) if it.next().is_none() => {
                    let o = id_atom(w3)?;
                    (1..=9).contains(&o).then_some(v1 * 10 + o)
                }
                _ => None,
            }
        }
        _ => None,
    }
}

fn lookup_weekday(s: &str) -> Option<i32> {
    WEEKDAYS
        .iter()
        .find(|(w, _)| crate::eq_word(s, w))
        .and_then(|(_, cs)| match cs.first()? {
            Component::Weekday(n) => Some(*n),
            _ => None,
        })
}

fn lookup_month(s: &str) -> Option<i32> {
    MONTHS
        .iter()
        .find(|(w, _)| crate::eq_word(s, w))
        .and_then(|(_, cs)| match cs.first()? {
            Component::Month(n) => Some(*n),
            _ => None,
        })
}

fn parse_2_or_4_year(s: &str) -> Option<i32> {
    if s.len() != 2 && s.len() != 4 {
        return None;
    }
    let y = crate::number(s)?;
    if s.len() == 2 {
        Some(if y >= 70 { 1900 + y } else { 2000 + y })
    } else {
        (y >= 1).then_some(y)
    }
}

fn parse_ord(s: &str) -> Option<i32> {
    let lower = s.to_lowercase();
    if matches!(lower.as_str(), "terakhir" | "penghabisan") {
        Some(-1)
    } else {
        let v = parse_id_num(&lower)?;
        (1..=5).contains(&v).then_some(v)
    }
}

fn offset_component(value: i32, unit: &str) -> Option<Component> {
    Some(match unit.to_lowercase().as_str() {
        "hari" | "sehari" => Component::RelativeDay(value),
        "minggu" | "pekan" | "seminggu" | "sepekan" => Component::Week(value, false),
        "bulan" | "sebulan" => Component::MonthOffset(value),
        "tahun" | "setahun" => Component::YearOffset(value),
        _ => return None,
    })
}

fn parse_rel_period(s: &str) -> Option<(Option<i32>, &'static str)> {
    let lower = s.to_lowercase();
    let tod = if lower.contains("pagi") {
        "pagi"
    } else if lower.contains("subuh") {
        "subuh"
    } else if lower.contains("dini") {
        "dini hari"
    } else if lower.contains("siang") {
        "siang"
    } else if lower.contains("sore") {
        "sore"
    } else if lower.contains("petang") {
        "petang"
    } else if lower.contains("malam") || lower.contains("malem") {
        "malam"
    } else {
        return None;
    };
    let rel = if lower == "semalam" || lower.contains("tadi mal") || lower.contains("kemar") {
        Some(-1)
    } else if lower.split_whitespace().any(|w| w == "ini")
        || lower.contains("nanti")
        || lower.contains("tadi")
    {
        Some(0)
    } else {
        None
    };
    Some((rel, tod))
}

fn apply_id_meridiem(h: i32, mer: &str) -> Option<(i32, Option<bool>)> {
    let lower = mer.to_lowercase();
    if lower == "pagi" || lower == "subuh" || lower.starts_with("dini") {
        (0..=12).contains(&h).then_some((h, Some(false)))
    } else if lower == "siang" {
        match h {
            10 | 11 => Some((h, Some(false))),
            1..=5 | 12..=16 => Some((h, Some(true))),
            _ => None,
        }
    } else if lower == "sore" || lower == "petang" {
        match h {
            1..=7 | 12..=19 => Some((h, Some(true))),
            _ => None,
        }
    } else if lower == "malam" || lower == "malem" {
        match h {
            0 | 12 | 1..=4 => Some((h, Some(false))),
            5..=11 | 18..=23 => Some((h, Some(true))),
            _ => None,
        }
    } else {
        None
    }
}

fn to_24h(h: i32, pm: Option<bool>) -> i32 {
    match pm {
        Some(true) if h < 12 => h + 12,
        Some(false) if h == 12 => 0,
        _ => h,
    }
}

fn triple_group<'t>(
    c: &Captures<'t>,
    a: &str,
    b: &str,
    d: &str,
) -> Option<(&'t str, &'t str, &'t str)> {
    Some((
        c.name(a)?.as_str(),
        c.name(b)?.as_str(),
        c.name(d)?.as_str(),
    ))
}

fn opt_num(m: Option<crate::Capture<'_>>) -> Option<Option<i32>> {
    Some(match m {
        Some(v) => Some(crate::number(v.as_str())?),
        None => None,
    })
}

fn parse_ap_bool(s: &str) -> Option<bool> {
    match s.as_bytes().first()?.to_ascii_lowercase() {
        b'a' => Some(false),
        b'p' => Some(true),
        _ => None,
    }
}

fn parse_time_with_tod(
    h_str: &str,
    m_cap: Option<crate::Capture<'_>>,
    s_cap: Option<crate::Capture<'_>>,
    tepat: bool,
    tod: &str,
) -> Option<Component> {
    if m_cap.is_some() && !h_str.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    let h = parse_id_num(h_str)?;
    let min = match opt_num(m_cap)? {
        Some(m) => Some(m),
        None if tepat => Some(0),
        None => None,
    };
    let sec = opt_num(s_cap)?;
    if !sec.is_none_or(|s| (0..60).contains(&s)) {
        return None;
    }
    let (adj_h, pm) = apply_id_meridiem(h, tod)?;
    Some(Component::Time(adj_h, min, pm))
}

fn parse_setengah(h_str: &str, mer: Option<&str>) -> Option<Component> {
    let h = parse_id_num(h_str)?;
    if !(1..=12).contains(&h) {
        return None;
    }
    if let Some(mer_s) = mer {
        let (adj_h, pm) = apply_id_meridiem(h, mer_s)?;
        let base = to_24h(adj_h, pm);
        let total = (base * 60 - 30).rem_euclid(24 * 60);
        let fh = total / 60;
        Some(Component::Time(fh, Some(total % 60), Some(fh >= 12)))
    } else {
        Some(Component::Time((h - 1).rem_euclid(24), Some(30), None))
    }
}

pub fn language() -> Language {
    Language::new(
        "id",
        r"(?i)(?:[\s,@]+|\b(?:pada|di|sekitar|kira-kira|tanggal|tgl)\b\.?)+",
        vec![
            Pattern::with_builder(
                "id_numericDate",
                r"(?P<guard0>)(?:(?P<iy>[0-9]{4})[-/.](?P<im>[0-9]{1,2})[-/.](?P<id>[0-9]{1,2})|(?P<sd>[0-9]{1,2})/(?P<sm>[0-9]{1,2})/(?P<sy>[0-9]{4}|[0-9]{2})|(?P<dd>[0-9]{1,2})-(?P<dm>[0-9]{1,2})-(?P<dy>[0-9]{4}|[0-9]{2})|(?P<pd>[0-9]{1,2})\.(?P<pm>[0-9]{1,2})\.(?P<py>[0-9]{4}|[0-9]{2})|(?P<yd>[0-9]{1,2})/(?P<ym>0[1-9]|1[0-2]))(?P<guard1>)",
                DATE_GUARDS,
                |c, _| {
                    if let Some((ys, ms, ds)) = triple_group(c, "iy", "im", "id") {
                        let y = crate::number(ys)?;
                        return (y >= 1).then_some(vec![
                            Component::Year(y),
                            Component::Month(crate::number(ms)?),
                            Component::Day(crate::number(ds)?),
                        ]);
                    }
                    if let Some(yd) = c.name("yd") {
                        return Some(vec![
                            Component::Month(crate::number(c.name("ym")?.as_str())?),
                            Component::Day(crate::number(yd.as_str())?),
                        ]);
                    }
                    let (ds, ms, ys) = triple_group(c, "sd", "sm", "sy")
                        .or_else(|| triple_group(c, "dd", "dm", "dy"))
                        .or_else(|| triple_group(c, "pd", "pm", "py"))?;
                    Some(vec![
                        Component::Year(parse_2_or_4_year(ys)?),
                        Component::Month(crate::number(ms)?),
                        Component::Day(crate::number(ds)?),
                    ])
                },
            ),
            Pattern::with_builder(
                "id_nthWeekday",
                &format!(
                    r"(?i)(?P<guard0>)(?:hari\s+)?(?P<wd>{WD_FULL})\s+(?P<ord>pertama|kesatu|kedua|ketiga|keempat|kelima|ke-?[1-5]|ke\s+[1-5]|terakhir|penghabisan)\s+(?:(?:di|pada|dalam)\s+)?(?:bulan\s+)?(?P<mo>{MONTH_ALL})(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let wd = lookup_weekday(c.name("wd")?.as_str())?;
                    let ord = parse_ord(c.name("ord")?.as_str())?;
                    let mo = lookup_month(c.name("mo")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, mo)])
                },
            ),
            Pattern::with_builder(
                "id_dayMonth",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?:tanggal|tgl\.?)\s+)?(?P<d>{DAY_PART})(?:\s+(?:bulan\s+)?|\s*[-/]\s*(?:bulan\s+)?)(?P<m>{MONTH_ALL})(?P<guard1>)(?:(?:\s*,\s*|\s+(?:tahun\s+)?|[-/])(?P<y>[0-9]{{4}})(?P<guard2>))?"
                ),
                &[
                    ("guard0", true, G_WORD),
                    ("guard1", false, G_WORD),
                    ("guard2", false, "[0-9a-zA-Z\u{00C0}-\u{024F}:/-]"),
                ],
                |c, _| {
                    let d = parse_id_num(c.name("d")?.as_str())?;
                    let m = lookup_month(c.name("m")?.as_str())?;
                    if !(1..=31).contains(&d) {
                        // Consume invalid "<day> <month>" so bare month fallback does not fire.
                        return Some(vec![Component::Month(2), Component::Day(30)]);
                    }
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(ym) = c.name("y") {
                        let y = crate::number(ym.as_str())?;
                        if y < 1 {
                            return None;
                        }
                        out.push(Component::Year(y));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "id_monthDay",
                &format!(
                    r"(?i)(?P<guard0>)(?:bulan\s+)?(?P<m>{MONTH_ALL})\s+(?:(?:tanggal|tgl\.?)\s+)?(?P<d>[0-9]{{1,2}})(?P<guard1>)(?:(?:\s*,\s*|\s+(?:tahun\s+)?)(?P<y>[0-9]{{4}})(?P<guard2>))?"
                ),
                &[
                    ("guard0", true, G_WORD),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9:/a-zA-Z\u{00C0}-\u{024F}%€$]|[-/.][0-9]|\s+(?:hari|minggu|pekan|bulan|tahun|menit|detik|kali|orang|buah|ekor|persen)\b)",
                    ),
                    ("guard2", false, "[0-9a-zA-Z\u{00C0}-\u{024F}:]"),
                ],
                |c, _| {
                    let m = lookup_month(c.name("m")?.as_str())?;
                    let d = crate::number(c.name("d")?.as_str())?;
                    if !(1..=31).contains(&d) {
                        return Some(vec![Component::Month(2), Component::Day(30)]);
                    }
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(ym) = c.name("y") {
                        let y = crate::number(ym.as_str())?;
                        if y < 1 {
                            return None;
                        }
                        out.push(Component::Year(y));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "id_monthYear",
                &format!(
                    r"(?i)(?P<guard0>)(?:bulan\s+)?(?P<m>{MONTH_ALL})(?:\s*,\s*|\s+(?:tahun\s+)?|[-/])(?P<y>[0-9]{{4}})(?P<guard1>)"
                ),
                &[
                    ("guard0", true, G_WORD),
                    ("guard1", false, "[0-9a-zA-Z\u{00C0}-\u{024F}:]"),
                ],
                |c, _| {
                    let m = lookup_month(c.name("m")?.as_str())?;
                    let y = crate::number(c.name("y")?.as_str())?;
                    (y >= 1).then_some(vec![Component::Month(m), Component::Year(y)])
                },
            ),
            Pattern::with_builder(
                "id_namedYear",
                r"(?i)(?P<guard0>)(?:tahun|thn\.?)\s+(?P<y>[0-9]{4})(?P<guard1>)",
                &[
                    ("guard0", true, G_WORD),
                    ("guard1", false, "[0-9a-zA-Z\u{00C0}-\u{024F}:]"),
                ],
                |c, _| {
                    let y = crate::number(c.name("y")?.as_str())?;
                    (y >= 1).then_some(vec![Component::Year(y)])
                },
            ),
            Pattern::with_builder(
                "id_within",
                &format!(
                    r"(?i)(?P<guard0>)(?:dalam\s+(?:(?:kurun|jangka)\s+)?(?:waktu\s+)?(?:(?P<n1>{NUM_ANY})\s+(?P<u1>hari|minggu|pekan)|(?P<s1>sehari|seminggu|sepekan))(?:\s+(?:ke\s+depan|kedepan|terdekat))?|(?:selama\s+)?(?:(?P<n2>{NUM_ANY})\s+(?P<u2>hari|minggu|pekan)|(?P<s2>sehari|seminggu|sepekan))\s+(?:ke\s+depan|kedepan))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, G_WORD),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9a-zA-Z\u{00C0}-\u{024F}]|\s+(?:lagi|yang\s+(?:lalu|silam)|lalu|silam|sebelumnya|kemudian|setelahnya|berikutnya|selanjutnya|mendatang|dari\s+sekarang)\b)",
                    ),
                ],
                |c, _| {
                    let (n, u) = if let Some(s1) = c.name("s1") {
                        (1, s1.as_str())
                    } else if let Some(s2) = c.name("s2") {
                        (1, s2.as_str())
                    } else if let Some(n1) = c.name("n1") {
                        (parse_id_num(n1.as_str())?, c.name("u1")?.as_str())
                    } else {
                        (
                            parse_id_num(c.name("n2")?.as_str())?,
                            c.name("u2")?.as_str(),
                        )
                    };
                    let days = match u.to_lowercase().as_str() {
                        "hari" | "sehari" => n,
                        _ => n.checked_mul(7)?,
                    };
                    Some(vec![Component::Within(days)])
                },
            ),
            Pattern::with_builder(
                "id_offset",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?:dalam\s+)?(?:(?P<fn>{NUM_ANY})\s+(?P<fu>hari|minggu|pekan|bulan|tahun)|(?P<fs>sehari|seminggu|sepekan|sebulan|setahun))\s+(?:lagi|mendatang|berikutnya|selanjutnya|kemudian|setelahnya|dari\s+sekarang)|dalam\s+(?:(?P<dn>{NUM_ANY})\s+(?P<du>bulan|tahun)|(?P<ds>sebulan|setahun))(?:\s+(?:ke\s+depan|kedepan))?|(?:(?P<dn2>{NUM_ANY})\s+(?P<du2>bulan|tahun)|(?P<ds2>sebulan|setahun))\s+(?:ke\s+depan|kedepan)|(?:(?P<pn>{NUM_ANY})\s+(?P<pu>hari|minggu|pekan|bulan|tahun)|(?P<ps>sehari|seminggu|sepekan|sebulan|setahun))\s+(?:yang\s+)?(?:lalu|silam|sebelumnya))(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let (neg, n, unit) = if let Some(fs) = c.name("fs") {
                        (false, 1, fs.as_str())
                    } else if let Some(fnm) = c.name("fn") {
                        (false, parse_id_num(fnm.as_str())?, c.name("fu")?.as_str())
                    } else if let Some(ds) = c.name("ds").or_else(|| c.name("ds2")) {
                        (false, 1, ds.as_str())
                    } else if let Some(dn) = c.name("dn") {
                        (false, parse_id_num(dn.as_str())?, c.name("du")?.as_str())
                    } else if let Some(dn2) = c.name("dn2") {
                        (false, parse_id_num(dn2.as_str())?, c.name("du2")?.as_str())
                    } else if let Some(ps) = c.name("ps") {
                        (true, 1, ps.as_str())
                    } else {
                        (
                            true,
                            parse_id_num(c.name("pn")?.as_str())?,
                            c.name("pu")?.as_str(),
                        )
                    };
                    let val = if neg { n.checked_neg()? } else { n };
                    Some(vec![offset_component(val, unit)?])
                },
            ),
            Pattern::with_builder(
                "id_weekend",
                r"(?i)(?P<guard0>)akhir\s+(?:pekan|minggu)(?:\s+(?P<mod>yang\s+akan\s+datang|yang\s+lalu|yang\s+silam|ini|depan|mendatang|berikutnya|selanjutnya|nanti|lalu|kemar[ie]n|silam|sebelumnya))?(?P<guard1>)",
                WORD_GUARDS,
                |c, _| {
                    let past = c.name("mod").is_some_and(|m| {
                        let s = m.as_str().to_lowercase();
                        s.contains("lalu")
                            || s.contains("kemar")
                            || s.contains("silam")
                            || s == "sebelumnya"
                    });
                    if past {
                        Some(vec![Component::Week(-1, false), Component::Weekday(7)])
                    } else {
                        Some(vec![Component::Weekend])
                    }
                },
            ),
            Pattern::with_builder(
                "id_anchor",
                r"(?i)(?P<guard0>)(?P<u>minggu|pekan|bulan|tahun)\s+(?P<mod>yang\s+akan\s+datang|yang\s+lalu|yang\s+silam|ini|sekarang|depan|mendatang|berikutnya|selanjutnya|nanti|lalu|kemar[ie]n|silam|sebelumnya)(?P<guard1>)",
                WORD_GUARDS,
                |c, _| {
                    let m = c.name("mod")?.as_str().to_lowercase();
                    let off = if m == "ini" || m == "sekarang" {
                        0
                    } else if m.contains("lalu")
                        || m.contains("kemar")
                        || m.contains("silam")
                        || m == "sebelumnya"
                    {
                        -1
                    } else {
                        1
                    };
                    Some(vec![match c.name("u")?.as_str().to_lowercase().as_str() {
                        "minggu" | "pekan" => Component::Week(off, true),
                        "bulan" => Component::MonthOffset(off),
                        _ => Component::YearOffset(off),
                    }])
                },
            ),
            Pattern::with_builder(
                "id_nextLastWeekday",
                &format!(
                    r"(?i)(?P<guard0>)(?:hari\s+(?P<hwd>{WD_ALL})|(?P<wd>{WD_NO_MINGGU}))\s+(?P<mod>yang\s+akan\s+datang|yang\s+lalu|yang\s+silam|depan|mendatang|berikutnya|selanjutnya|nanti|besok|lalu|kemar[ie]n|silam|sebelumnya|ini)(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let wd = lookup_weekday(c.name("hwd").or_else(|| c.name("wd"))?.as_str())?;
                    let m = c.name("mod")?.as_str().to_lowercase();
                    if m == "ini" || m == "besok" || m == "nanti" {
                        return Some(vec![Component::Weekday(wd)]);
                    }
                    let off = if m.contains("lalu")
                        || m.contains("kemar")
                        || m.contains("silam")
                        || m == "sebelumnya"
                    {
                        -1
                    } else {
                        1
                    };
                    Some(vec![Component::Week(off, false), Component::Weekday(wd)])
                },
            ),
            Pattern::with_builder(
                "id_relativeDayPhrase",
                r"(?i)(?P<guard0>)(?P<rel>kemar[ie]n\s+(?:lusa|dulu)|kelmarin\s+lusa|besok\s+lusa|esok\s+(?:lusa|hari)|hari\s+(?:ini|esok|kemar[ie]n))(?P<guard1>)",
                WORD_GUARDS,
                |c, _| {
                    let s = c.name("rel")?.as_str().to_lowercase();
                    let off = if s.contains("lusa") || s.contains("dulu") {
                        if s.starts_with('k') { -2 } else { 2 }
                    } else if s.contains("esok") {
                        1
                    } else if s.contains("kemar") {
                        -1
                    } else {
                        0
                    };
                    Some(vec![Component::RelativeDay(off)])
                },
            ),
            Pattern::with_builder(
                "id_periodTime",
                &format!(
                    r"(?i)(?P<guard0>)(?P<per>{REL_PERIOD_ALT}|{MERIDIEM_ALT})\s+(?:(?:pada|sekitar|kira-kira)\s+)?(?:(?:(?:jam|pukul|pkl\.?|pk\.?)\s+)?(?:setengah|stgh\.?)\s+(?P<sh>[0-9]{{1,2}}|{HOUR_WORD_1_12})|(?:jam|pukul|pkl\.?|pk\.?)\s+(?P<h>[0-9]{{1,2}}|{HOUR_WORD})(?:[:.](?P<m>[0-9]{{2}})(?::(?P<s>[0-9]{{2}}))?)?)(?:\s*(?P<tepat>tepat))?(?:\s*(?:wib|wita|wit))?(?:\s+(?P<tmer>{MERIDIEM_ALT}))?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, G_WORD),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9a-zA-Z\u{00C0}-\u{024F}:%]|\.[0-9]|\s*(?:menit|mnt|detik|dtk|a\.?\s*m\.?|p\.?\s*m\.?|juta|ribu|ratus|miliar|milyar|triliun|persen|kg|gram|gr|mg|km|cm|mm|liter|ml|orang|buah|ekor|kali)\b)",
                    ),
                ],
                |c, _| {
                    let (rel, per_tod) = parse_rel_period(c.name("per")?.as_str())?;
                    let tod = match c.name("tmer") {
                        Some(tm) => {
                            let (_, t_tod) = parse_rel_period(tm.as_str())?;
                            let p_am = matches!(per_tod, "pagi" | "subuh" | "dini hari");
                            let t_am = matches!(t_tod, "pagi" | "subuh" | "dini hari");
                            if per_tod != "siang" && t_tod != "siang" && p_am != t_am {
                                return None;
                            }
                            t_tod
                        }
                        None => per_tod,
                    };
                    let time = if let Some(sh) = c.name("sh") {
                        parse_setengah(sh.as_str(), Some(tod))?
                    } else {
                        parse_time_with_tod(
                            c.name("h")?.as_str(),
                            c.name("m"),
                            c.name("s"),
                            c.name("tepat").is_some(),
                            tod,
                        )?
                    };
                    Some(match rel {
                        Some(d) => vec![Component::RelativeDay(d), time],
                        None => vec![time],
                    })
                },
            ),
            Pattern::with_builder(
                "id_timeBeforePeriod",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?:jam|pukul|pkl\.?|pk\.?)\s+)?(?P<h>[0-9]{{1,2}}|{HOUR_WORD})(?:[:.](?P<m>[0-9]{{2}})(?::(?P<s>[0-9]{{2}}))?)?(?:\s*(?:tepat|wib|wita|wit))?(?:\s*(?P<ap>a\.?\s*m\.?|p\.?\s*m\.?))?\s+(?:(?:pada|di)\s+)?(?P<rel>{REL_PERIOD_ALT})(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[0-9a-zA-Z\u{00C0}-\u{024F}.:/-]"),
                    ("guard1", false, G_WORD),
                ],
                |c, _| {
                    let h_str = c.name("h")?.as_str();
                    if c.name("m").is_some() && !h_str.bytes().all(|b| b.is_ascii_digit()) {
                        return None;
                    }
                    let (rel_opt, tod) = parse_rel_period(c.name("rel")?.as_str())?;
                    let rel = rel_opt?;
                    let h = parse_id_num(h_str)?;
                    let min = opt_num(c.name("m"))?;
                    let sec = opt_num(c.name("s"))?;
                    if !sec.is_none_or(|s| (0..60).contains(&s)) {
                        return None;
                    }
                    let time = if let Some(ap_m) = c.name("ap") {
                        let pm = parse_ap_bool(ap_m.as_str())?;
                        let valid_h = if !pm {
                            (0..=12).contains(&h)
                        } else if min.is_some() {
                            (1..=23).contains(&h)
                        } else {
                            (1..=12).contains(&h)
                        };
                        valid_h.then_some(Component::Time(h, min, Some(pm)))?
                    } else {
                        let (adj_h, pm) = apply_id_meridiem(h, tod)?;
                        Component::Time(adj_h, min, pm)
                    };
                    Some(vec![Component::RelativeDay(rel), time])
                },
            ),
            Pattern::with_builder(
                "id_partOfDay",
                &format!(r"(?i)(?P<guard0>)(?P<pod>{REL_PERIOD_ALT})(?P<guard1>)"),
                WORD_GUARDS,
                |c, _| {
                    let (rel, tod) = parse_rel_period(c.name("pod")?.as_str())?;
                    let pm = !matches!(tod, "pagi" | "subuh" | "dini hari");
                    Some(vec![Component::RelativeDay(rel?), Component::Meridiem(pm)])
                },
            ),
            Pattern::new(
                "id_relativeDay",
                "(?i)(?P<guard0>)(besok|esok|lusa|kemarin|kelmarin|kemaren)(?P<guard1>)",
                WORD_GUARDS,
                &[
                    ("besok", &[Component::RelativeDay(1)]),
                    ("esok", &[Component::RelativeDay(1)]),
                    ("lusa", &[Component::RelativeDay(2)]),
                    ("kemarin", &[Component::RelativeDay(-1)]),
                    ("kelmarin", &[Component::RelativeDay(-1)]),
                    ("kemaren", &[Component::RelativeDay(-1)]),
                ],
            ),
            Pattern::with_builder(
                "id_hariWeekday",
                &format!(r"(?i)(?P<guard0>)hari\s+(?P<wd>{WD_ALL})(?P<guard1>)"),
                WORD_GUARDS,
                |c, _| {
                    Some(vec![Component::Weekday(lookup_weekday(
                        c.name("wd")?.as_str(),
                    )?)])
                },
            ),
            Pattern::with_builder(
                "id_bulanMonth",
                &format!(r"(?i)(?P<guard0>)bulan\s+(?P<mo>{MONTH_ALL})(?P<guard1>)"),
                WORD_GUARDS,
                |c, _| {
                    Some(vec![Component::Month(lookup_month(
                        c.name("mo")?.as_str(),
                    )?)])
                },
            ),
            Pattern::with_builder(
                "id_day",
                &format!(r"(?i)(?P<guard0>)(?:tanggal|tgl\.?)\s+(?P<d>{DAY_PART})(?P<guard1>)"),
                &[
                    ("guard0", true, G_WORD),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9:/a-zA-Z\u{00C0}-\u{024F}%€$]|[-/.][0-9])",
                    ),
                ],
                |c, _| Some(vec![Component::Day(parse_id_num(c.name("d")?.as_str())?)]),
            ),
            Pattern::with_builder(
                "id_noonMidnight",
                r"(?i)(?P<guard0>)(?:(?:jam|pukul|pkl\.?|pk\.?)\s+)?12(?:[:.]00)?\s+tengah\s+(?P<tm>hari|malam)(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Z\u{00C0}-\u{024F}.:/-]"),
                    ("guard1", false, G_WORD),
                ],
                |c, _| {
                    let noon = c.name("tm")?.as_str().eq_ignore_ascii_case("hari");
                    Some(vec![Component::Time(
                        if noon { 12 } else { 0 },
                        Some(0),
                        Some(noon),
                    )])
                },
            ),
            Pattern::with_builder(
                "id_setengahTime",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?:jam|pukul|pkl\.?|pk\.?)\s+)?(?:setengah|stgh\.?)\s+(?P<h>[0-9]{{1,2}}|{HOUR_WORD_1_12})(?:\s*(?:wib|wita|wit))?(?:\s+(?P<mer>{MERIDIEM_ALT}))?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, G_WORD),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9a-zA-Z\u{00C0}-\u{024F}:%]|\.[0-9]|\s+(?:juta|ribu|ratus|miliar|milyar|triliun|persen|kg|gram|gr|mg|km|cm|mm|liter|ml|menit|detik|orang|buah|ekor|kali|lembar|batang|bungkus|botol|gelas|piring|porsi|bagian)\b)",
                    ),
                ],
                |c, _| {
                    Some(vec![parse_setengah(
                        c.name("h")?.as_str(),
                        c.name("mer").map(|m| m.as_str()),
                    )?])
                },
            ),
            Pattern::with_builder(
                "id_lewatKurangTime",
                &format!(
                    r"(?i)(?P<guard0>)(?P<pfx>jam|pukul|pkl\.?|pk\.?)?\s*(?P<h>[0-9]{{1,2}}|{HOUR_WORD})\s+(?P<op>lewat|lebih|kurang)\s+(?:(?P<q>seperempat|1/4)|(?P<half>setengah|1/2)|(?P<m>[0-9]{{1,2}}|{NUM_1_59})(?P<unit>\s+menit)?)(?P<tz>\s*(?:wib|wita|wit))?(?:\s+(?P<mer>{MERIDIEM_ALT}))?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, G_WORD),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9a-zA-Z\u{00C0}-\u{024F}:]|\.[0-9])",
                    ),
                ],
                |c, _| {
                    if c.name("pfx").is_none()
                        && c.name("q").is_none()
                        && c.name("half").is_none()
                        && c.name("unit").is_none()
                        && c.name("tz").is_none()
                        && c.name("mer").is_none()
                    {
                        return None;
                    }
                    let h = parse_id_num(c.name("h")?.as_str())?;
                    if !(0..=23).contains(&h) {
                        return None;
                    }
                    let mins = if c.name("q").is_some() {
                        15
                    } else if c.name("half").is_some() {
                        30
                    } else {
                        let m = parse_id_num(c.name("m")?.as_str())?;
                        if !(1..=59).contains(&m) {
                            return None;
                        }
                        m
                    };
                    let is_sub = c.name("op")?.as_str().eq_ignore_ascii_case("kurang");
                    if let Some(mer_m) = c.name("mer") {
                        let (adj_h, pm) = apply_id_meridiem(h, mer_m.as_str())?;
                        let base = to_24h(adj_h, pm);
                        let delta = if is_sub { -mins } else { mins };
                        let total = (base * 60 + delta).rem_euclid(24 * 60);
                        let fh = total / 60;
                        Some(vec![Component::Time(fh, Some(total % 60), Some(fh >= 12))])
                    } else if is_sub {
                        let total = (h * 60 - mins).rem_euclid(24 * 60);
                        Some(vec![Component::Time(total / 60, Some(total % 60), None)])
                    } else {
                        Some(vec![Component::Time(h, Some(mins), None)])
                    }
                },
            ),
            Pattern::with_builder(
                "id_amPmTime",
                r"(?i)(?P<guard0>)(?:(?:jam|pukul|pkl\.?|pk\.?)\s+)?(?P<h>[0-9]{1,2})(?:[:.](?P<m>[0-9]{2})(?::(?P<s>[0-9]{2}))?)?\s*(?P<ap>a\.?\s*m\.?|p\.?\s*m\.?)(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Z\u{00C0}-\u{024F}.:/-]"),
                    ("guard1", false, G_WORD),
                ],
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let min = opt_num(c.name("m"))?;
                    let sec = opt_num(c.name("s"))?;
                    if !sec.is_none_or(|s| (0..60).contains(&s)) {
                        return None;
                    }
                    let pm = parse_ap_bool(c.name("ap")?.as_str())?;
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
                "id_clockTime",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?:jam|pukul|pkl\.?|pk\.?)\s+(?:(?P<h1>[0-9]{{1,2}})(?:[:.](?P<m1>[0-9]{{2}})(?::(?P<s1>[0-9]{{2}}))?)?|(?P<hw1>{HOUR_WORD}))(?:\s*(?P<tepat1>tepat))?(?:\s*(?:wib|wita|wit))?(?:\s+(?P<mer1>{MERIDIEM_ALT}))?|(?P<h2>[0-9]{{1,2}})[:.](?P<m2>[0-9]{{2}})(?::(?P<s2>[0-9]{{2}}))?(?:\s*(?P<tepat2>tepat))?\s*(?:(?:wib|wita|wit)(?:\s+(?P<mer2a>{MERIDIEM_ALT}))?|(?P<mer2b>{MERIDIEM_ALT}))|(?P<h3>[0-9]{{1,2}}):(?P<m3>[0-9]{{2}}):(?P<s3>[0-9]{{2}})|(?P<h4>[0-9]{{1,2}}|{HOUR_WORD_1_12})(?:\s+(?P<tepat4>tepat))?\s+(?P<mer4>{MERIDIEM_ALT}))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[0-9a-zA-Z\u{00C0}-\u{024F}.:/-]"),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9a-zA-Z\u{00C0}-\u{024F}:]|\.[0-9]|\s*(?:menit|mnt|detik|dtk|a\.?\s*m\.?|p\.?\s*m\.?)\b)",
                    ),
                ],
                |c, _| {
                    if let Some(h_m) = c.name("h1").or_else(|| c.name("hw1")) {
                        let min = match opt_num(c.name("m1"))? {
                            Some(m) => Some(m),
                            None if c.name("tepat1").is_some() => Some(0),
                            None => None,
                        };
                        let sec = opt_num(c.name("s1"))?;
                        if !sec.is_none_or(|s| (0..60).contains(&s)) {
                            return None;
                        }
                        let h = parse_id_num(h_m.as_str())?;
                        return if let Some(mer) = c.name("mer1") {
                            let (adj_h, pm) = apply_id_meridiem(h, mer.as_str())?;
                            Some(vec![Component::Time(adj_h, min, pm)])
                        } else {
                            Some(vec![Component::Time(h, min, None)])
                        };
                    }
                    if let Some(h2) = c.name("h2") {
                        let h = crate::number(h2.as_str())?;
                        let min = crate::number(c.name("m2")?.as_str())?;
                        let sec = opt_num(c.name("s2"))?;
                        if !sec.is_none_or(|s| (0..60).contains(&s)) {
                            return None;
                        }
                        return if let Some(mer) = c.name("mer2a").or_else(|| c.name("mer2b")) {
                            let (adj_h, pm) = apply_id_meridiem(h, mer.as_str())?;
                            Some(vec![Component::Time(adj_h, Some(min), pm)])
                        } else {
                            Some(vec![Component::Time(h, Some(min), None)])
                        };
                    }
                    if let Some(h3) = c.name("h3") {
                        let h = crate::number(h3.as_str())?;
                        let min = crate::number(c.name("m3")?.as_str())?;
                        let sec = crate::number(c.name("s3")?.as_str())?;
                        return (0..60).contains(&sec).then_some(vec![Component::Time(
                            h,
                            Some(min),
                            None,
                        )]);
                    }
                    let h = parse_id_num(c.name("h4")?.as_str())?;
                    let min = c.name("tepat4").map(|_| 0);
                    let (adj_h, pm) = apply_id_meridiem(h, c.name("mer4")?.as_str())?;
                    Some(vec![Component::Time(adj_h, min, pm)])
                },
            ),
            Pattern::with_builder(
                "id_fixedPhrase",
                r"(?i)(?P<guard0>)(?P<k>tengah\s+hari|tengah\s+malam|siang\s+hari)(?P<guard1>)",
                WORD_GUARDS,
                |c, _| {
                    let s = c.name("k")?.as_str().to_lowercase();
                    let h = if s.contains("malam") { 0 } else { 12 };
                    Some(vec![Component::Time(h, Some(0), None)])
                },
            ),
            Pattern::new(
                "id_fixedTime",
                "(?i)(?P<guard0>)(siang)(?P<guard1>)",
                WORD_GUARDS,
                &[("siang", &[Component::Time(12, Some(0), None)])],
            ),
            Pattern::with_builder(
                "id_diniHari",
                r"(?i)(?P<guard0>)dini\s+hari(?P<guard1>)",
                WORD_GUARDS,
                |_, _| Some(vec![Component::Meridiem(false)]),
            ),
            Pattern::new(
                "id_meridiem",
                "(?i)(?P<guard0>)(pagi|subuh|sore|petang|malam|malem)(?P<guard1>)",
                WORD_GUARDS,
                &[
                    ("pagi", &[Component::Meridiem(false)]),
                    ("subuh", &[Component::Meridiem(false)]),
                    ("sore", &[Component::Meridiem(true)]),
                    ("petang", &[Component::Meridiem(true)]),
                    ("malam", &[Component::Meridiem(true)]),
                    ("malem", &[Component::Meridiem(true)]),
                ],
            ),
            Pattern::new(
                "id_weekday",
                &format!("(?i)(?P<guard0>)({WD_ALL})(?P<guard1>)"),
                WORD_GUARDS,
                WEEKDAYS,
            ),
            Pattern::new(
                "id_month",
                &format!("(?i)(?P<guard0>)({MONTH_ALL})(?P<guard1>)"),
                WORD_GUARDS,
                MONTHS,
            ),
            Pattern::new("id_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

#![doc = include_str!("../README.md")]
//! Multilingual component recognition, composition and calendar resolution.
//! Compile a [`Parser`] once and reuse it. Dates are timezone-free wall clocks;
//! ISO offsets are converted to UTC. Result offsets are UTF-8 byte offsets.
mod calendar;
mod pattern;
use calendar::Duration;
pub use calendar::{DateError, DateTime, NaiveDate, NaiveDateTime};
use pattern::Regex;
pub use pattern::{Capture, Captures, PatternError};
use std::{borrow::Cow, sync::LazyLock};
pub mod languages;
mod resolve;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Component {
    Year(i32),
    YearOffset(i32),
    Month(i32),
    MonthOffset(i32),
    Day(i32),
    Weekday(i32),
    RelativeDay(i32),
    Week(i32, bool),
    Weekend,
    Time(i32, Option<i32>, Option<bool>),
    Meridiem(bool),
    Within(i32),
    Instant(NaiveDateTime),
    Nth(i32, i32, i32),
}
impl Component {
    fn slots(self) -> u8 {
        match self {
            Self::Year(_) | Self::YearOffset(_) => 1,
            Self::Month(_) | Self::MonthOffset(_) => 2,
            Self::Day(_) => 4,
            Self::Weekday(_) => 8,
            Self::Time(_, _, pm) => 16 | if pm.is_some() { 32 } else { 0 },
            Self::Meridiem(_) => 32,
            Self::RelativeDay(_) => 64,
            Self::Week(_, _) => 128,
            Self::Weekend => 136,
            Self::Nth(..) => 207,
            Self::Within(_) | Self::Instant(_) => 255,
        }
    }
    fn score(self) -> i32 {
        match self {
            Self::Year(_) => 4,
            Self::Instant(_) => 12,
            Self::Nth(..) => 10,
            Self::Meridiem(_) => 0,
            Self::Time(_, minute, _) => 2 + i32::from(minute.is_some()),
            _ => 3,
        }
    }
    fn valid(self) -> bool {
        match self {
            Self::Month(v) => (1..=12).contains(&v),
            Self::Day(v) => (1..=31).contains(&v),
            Self::Weekday(v) => (1..=7).contains(&v),
            Self::Within(v) => v >= 0,
            Self::Nth(n, w, m) => {
                (n == -1 || (1..=5).contains(&n)) && (1..=7).contains(&w) && (1..=12).contains(&m)
            }
            Self::Time(h, m, _) => (0..24).contains(&h) && m.is_none_or(|m| (0..60).contains(&m)),
            _ => true,
        }
    }
}

pub type Builder = fn(&Captures<'_>, NaiveDateTime) -> Option<Vec<Component>>;
pub struct Pattern {
    name: &'static str,
    regex: Regex,
    guards: Vec<(&'static str, bool, Regex)>,
    words: &'static [(&'static str, &'static [Component])],
    builder: Option<Builder>,
}
impl Pattern {
    fn new(
        name: &'static str,
        source: &str,
        guards: &[(&'static str, bool, &str)],
        words: &'static [(&'static str, &'static [Component])],
    ) -> Self {
        Self {
            name,
            regex: compile(source),
            guards: guards
                .iter()
                .map(|&(n, b, s)| (n, b, compile(&format!("^(?:{s})"))))
                .collect(),
            words,
            builder: None,
        }
    }
    /// Add a component recognizer. Rust regex syntax deliberately excludes
    /// backtracking/lookaround. Use the builder to reject unwanted captures.
    pub fn custom(source: &str, builder: Builder) -> Result<Self, PatternError> {
        Ok(Self {
            name: "custom",
            regex: Regex::new(source)?,
            guards: vec![],
            words: &[],
            builder: Some(builder),
        })
    }
    fn accepts(&self, c: &Captures<'_>, text: &str) -> bool {
        self.guards.iter().all(|(name, behind, regex)| {
            let at = c.name(name).unwrap().start();
            if *behind {
                text[..at]
                    .chars()
                    .next_back()
                    .is_none_or(|ch| !regex.is_match(ch.encode_utf8(&mut [0; 4])))
            } else {
                !regex.is_match(&text[at..])
            }
        })
    }
}
fn compile(s: &str) -> Regex {
    Regex::new(s).expect("built-in pattern")
}
pub struct Language {
    pub code: &'static str,
    glue: Regex,
    pub patterns: Vec<Pattern>,
}
impl Language {
    pub fn new(code: &'static str, glue: &str, patterns: Vec<Pattern>) -> Self {
        Self {
            code,
            glue: compile(glue),
            patterns,
        }
    }
    fn word(&self, suffix: &str, word: &str) -> Option<i32> {
        self.patterns
            .iter()
            .find(|p| p.name.ends_with(suffix))?
            .words
            .iter()
            .find(|(w, _)| *w == word)
            .and_then(|(_, cs)| match cs.first()? {
                Component::Month(n) | Component::Weekday(n) => Some(*n),
                _ => None,
            })
    }
}
static BUILTINS: [LazyLock<Language>; 8] = [
    LazyLock::new(languages::en::language),
    LazyLock::new(languages::ja::language),
    LazyLock::new(languages::zh::language),
    LazyLock::new(languages::es::language),
    LazyLock::new(languages::hi::language),
    LazyLock::new(languages::ko::language),
    LazyLock::new(languages::ru::language),
    LazyLock::new(languages::universal::language),
];
/// Parser with caller-owned languages; built-ins compile lazily once.
#[derive(Default)]
pub struct Parser {
    pub languages: Vec<Language>,
}
#[derive(Clone, Debug)]
pub struct Options<'a> {
    pub reference: NaiveDateTime,
    pub languages: &'a [&'a str],
    pub range: bool,
    pub week_start: u8,
    pub offset_minutes: i32,
}
impl Options<'_> {
    pub fn new(reference: NaiveDateTime) -> Self {
        Self {
            reference,
            languages: &["en", "ja", "zh"],
            range: false,
            week_start: 7,
            offset_minutes: 0,
        }
    }
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Match {
    pub start: usize,
    pub end: usize,
    pub date: NaiveDateTime,
    pub range_type: Option<&'static str>,
    pub range_days: Option<i32>,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Error {
    ClockUnavailable,
    InvalidWeekStart,
    DateOutOfRange,
    RangeTooLarge,
}
impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}
impl std::error::Error for Error {}

/// Parse with today's UTC clock and the default languages (en, ja, zh).
/// For local time, a historical clock, or Wasm, use [`parse_with`].
pub fn parse(text: &str) -> Result<Vec<Match>, Error> {
    parse_with(
        text,
        &Options::new(DateTime::now_utc().ok_or(Error::ClockUnavailable)?),
    )
}
/// Parse with explicit options. Built-ins are initialized once and reused.
pub fn parse_with(text: &str, options: &Options<'_>) -> Result<Vec<Match>, Error> {
    Parser::default().parse(text, options)
}
#[derive(Debug)]
struct Expression {
    start: usize,
    end: usize,
    slots: u8,
    score: i32,
    components: Vec<Component>,
}
impl Expression {
    fn new(start: usize, end: usize, components: Vec<Component>) -> Self {
        Self {
            start,
            end,
            slots: components.iter().fold(0, |s, c| s | c.slots()),
            score: components.iter().map(|c| c.score()).sum(),
            components,
        }
    }
    fn accepts(&self, other: &Self) -> bool {
        if self.slots & other.slots != 0 {
            return false;
        }
        if self
            .components
            .iter()
            .chain(&other.components)
            .any(|c| matches!(c, Component::Nth(..)))
        {
            return true;
        }
        let s = self.slots | other.slots;
        if s & 64 != 0 {
            s & !(64 | 16 | 32) == 0
        } else if s & 128 != 0 {
            s & !(128 | 8 | 16 | 32) == 0
        } else {
            true
        }
    }
}
impl Parser {
    /// Return one match per day for date ranges.
    pub fn parse(&self, text: &str, options: &Options<'_>) -> Result<Vec<Match>, Error> {
        self.parse_impl(text, options, true)
    }
    /// Keep ranges compact: `range_days` is the number of consecutive days
    /// beginning at `date`. With `Options::range = false`, behaves like `parse`.
    /// The entire range is checked, including its final date after the offset.
    pub fn parse_ranges(&self, text: &str, options: &Options<'_>) -> Result<Vec<Match>, Error> {
        self.parse_impl(text, options, false)
    }
    fn parse_impl(
        &self,
        text: &str,
        options: &Options<'_>,
        expand: bool,
    ) -> Result<Vec<Match>, Error> {
        if ![1, 7].contains(&options.week_start) {
            return Err(Error::InvalidWeekStart);
        }
        if text.is_empty() {
            return Ok(vec![]);
        }
        let (normalized, wide_digits) = normalize(text);
        let codes = if options.languages.is_empty() {
            &["en", "ja", "zh"][..]
        } else {
            options.languages
        };
        let mut candidates = Vec::new();
        for (index, code) in codes
            .iter()
            .copied()
            .chain(std::iter::once("universal"))
            .enumerate()
        {
            if codes
                .iter()
                .position(|&c| c == code)
                .is_some_and(|first| first < index)
            {
                continue;
            }
            let language = self.languages.iter().find(|l| l.code == code).or_else(|| {
                let index = ["en", "ja", "zh", "es", "hi", "ko", "ru", "universal"]
                    .iter()
                    .position(|&c| c == code)?;
                Some(&*BUILTINS[index])
            });
            let Some(lang) = language else { continue };
            let mut tokens = Vec::new();
            for (order, p) in lang.patterns.iter().enumerate() {
                let mut at = 0;
                while at < normalized.len() {
                    let Some(c) = p.regex.captures_at(&normalized, at) else {
                        break;
                    };
                    let m = c.get(0).unwrap();
                    let Some(ch) = normalized[m.start()..].chars().next() else {
                        break;
                    };
                    at = m.start() + ch.len_utf8();
                    if m.is_empty() {
                        continue;
                    }
                    if normalized.as_bytes()[m.start()].is_ascii_digit()
                        && normalized[..m.start()]
                            .chars()
                            .next_back()
                            .is_some_and(|ch| ch.is_ascii_digit())
                    {
                        continue;
                    }
                    if !p.accepts(&c, &normalized) {
                        continue;
                    }
                    let cs = if let Some(b) = p.builder {
                        b(&c, options.reference)
                    } else {
                        build(lang, p, &c, options.reference)
                    };
                    if let Some(cs) = cs.filter(|cs| !cs.is_empty() && cs.iter().all(|c| c.valid()))
                    {
                        tokens.push((Expression::new(m.start(), m.end(), cs), order));
                    }
                }
            }
            tokens.sort_by_key(|(t, o)| (t.start, std::cmp::Reverse(t.end), *o));
            let mut last_end = 0;
            let mut current: Option<Expression> = None;
            for (t, _) in tokens {
                if t.start < last_end {
                    continue;
                }
                last_end = t.end;
                if let Some(e) = current.as_mut() {
                    let gap = &normalized[e.end..t.start];
                    if e.accepts(&t) && (gap.is_empty() || lang.glue.is_match(gap)) {
                        e.end = t.end;
                        e.slots |= t.slots;
                        e.score += t.score;
                        e.components.extend(t.components);
                        continue;
                    }
                }
                if let Some(e) = current.replace(t)
                    && let Some(m) = resolve::resolve(&e, options)?
                {
                    candidates.push((m, e.score));
                }
            }
            if let Some(e) = current
                && let Some(m) = resolve::resolve(&e, options)?
            {
                candidates.push((m, e.score));
            }
        }
        candidates.sort_by_cached_key(|(m, s)| {
            (
                std::cmp::Reverse(normalized[m.start..m.end].encode_utf16().count()),
                std::cmp::Reverse(*s),
                m.start,
            )
        });
        let mut selected: Vec<Match> = Vec::new();
        for (m, _) in candidates {
            if selected.iter().any(|k| m.start < k.end && k.start < m.end) {
                continue;
            }
            selected.push(m);
            if !options.range {
                break;
            }
        }
        let mut results = Vec::new();
        for mut m in selected {
            // Normalization changes UTF-8 widths. Return spans into the original.
            m.start += 2 * wide_digits.partition_point(|&at| at < m.start);
            m.end += 2 * wide_digits.partition_point(|&at| at < m.end);
            let days = if options.range {
                m.range_days.or(match m.range_type {
                    Some("week") => Some(7),
                    Some("month") => {
                        Some(calendar::month_days(m.date.year(), m.date.month()) as i32)
                    }
                    _ => None,
                })
            } else {
                None
            };
            let offset = Duration::minutes(i64::from(options.offset_minutes));
            m.date = m
                .date
                .checked_add_signed(offset)
                .ok_or(Error::DateOutOfRange)?;
            if let Some(days) = days {
                if !(0..=36600).contains(&days) {
                    return Err(Error::RangeTooLarge);
                }
                if days == 0 {
                    continue;
                }
                if !expand {
                    m.date
                        .checked_add_signed(Duration::days(i64::from(days - 1)))
                        .ok_or(Error::DateOutOfRange)?;
                    m.range_days = Some(days);
                    results.push(m);
                    continue;
                }
                for i in 0..days {
                    results.push(Match {
                        date: m
                            .date
                            .checked_add_signed(Duration::days(i64::from(i)))
                            .ok_or(Error::DateOutOfRange)?,
                        range_type: None,
                        range_days: None,
                        ..m.clone()
                    });
                }
            } else {
                results.push(m);
            }
        }
        Ok(results)
    }
}
fn normalize(text: &str) -> (Cow<'_, str>, Vec<usize>) {
    let Some(first) = text.find(|c| ('０'..='９').contains(&c)) else {
        return (Cow::Borrowed(text), Vec::new());
    };
    let mut normalized = String::with_capacity(text.len());
    normalized.push_str(&text[..first]);
    let mut wide_digits = Vec::new();
    for c in text[first..].chars() {
        if ('０'..='９').contains(&c) {
            wide_digits.push(normalized.len());
            normalized.push(char::from_u32(c as u32 - 0xfee0).unwrap());
        } else {
            normalized.push(c);
        }
    }
    (Cow::Owned(normalized), wide_digits)
}
fn number(s: &str) -> Option<i32> {
    if s.is_empty() {
        return None;
    }
    if let Ok(n) = s.parse() {
        return Some(n);
    }
    let mut total = 0i32;
    let mut current = 0i32;
    for ch in s.chars() {
        let v = match ch {
            '〇' | '零' | '영' => 0,
            '一' | '일' => 1,
            '二' | '이' => 2,
            '三' | '삼' => 3,
            '四' | '사' => 4,
            '五' | '오' => 5,
            '六' | '육' => 6,
            '七' | '칠' => 7,
            '八' | '팔' => 8,
            '九' | '구' => 9,
            '十' | '십' => 10,
            '百' => 100,
            '千' => 1000,
            _ => i32::try_from(ch.to_digit(10)?).ok()?,
        };
        if v >= 10 {
            total = total.checked_add(current.max(1).checked_mul(v)?)?;
            current = 0;
        } else {
            current = current.checked_mul(10)?.checked_add(v)?;
        }
    }
    total.checked_add(current)
}
fn build(
    lang: &Language,
    p: &Pattern,
    c: &Captures<'_>,
    reference: NaiveDateTime,
) -> Option<Vec<Component>> {
    use Component::*;
    let get = |i| {
        let actual = p
            .regex
            .capture_names()
            .enumerate()
            .filter(|(_, name)| name.is_none_or(|n| !n.starts_with("guard")))
            .nth(i)?
            .0;
        c.get(actual).map(|m| m.as_str())
    };
    let n = |i| number(get(i)?);
    let word = |i| get(i).unwrap_or("").to_lowercase();
    let full = word(0);
    if let Some((_, cs)) = p.words.iter().find(|(w, _)| *w == full) {
        return Some(cs.to_vec());
    }
    let kind = p.name.split_once('_')?.1;
    let valid = |v: Option<i32>, max| v.filter(|n| *n >= 1 && *n <= max);
    let offset = |value: i32, unit: &str| match unit {
        "day" | "days" | "日" | "天" | "दिन" | "일" => RelativeDay(value),
        "year" | "years" | "年" | "साल" | "년" => YearOffset(value),
        "month" | "months" | "ヶ月" | "ケ月" | "か月" | "个月" | "महीने" | "개월" | "달" => {
            MonthOffset(value)
        }
        _ if unit.starts_with("d") || unit.starts_with('д') => RelativeDay(value),
        _ if unit.starts_with("mes") || unit.starts_with("месяц") => MonthOffset(value),
        _ if unit.starts_with("año") || unit.starts_with("год") || unit == "лет" => {
            YearOffset(value)
        }
        _ => Week(value, false),
    };
    let anchor = |w: &str| match w {
        "下下" | "다다음" => 2,
        "下" | "अगले" | "다음" | "следующей" | "следующем" => 1,
        "上" | "पिछले" | "지난" | "저번" | "прошлой" | "прошлом" => -1,
        _ => 0,
    };
    Some(match kind {
        "colonTime" => vec![Time(n(1)?, Some(n(2)?), None)],
        "year" => vec![Year(n(1)?)],
        "month" => vec![Month(valid(n(1), 12)?)],
        "day" | "ordinalDay" | "elDia" | "dayOnly" => vec![Day(valid(n(1), 31)?)],
        "time" | "baje" => vec![Time(n(1)?, get(2).and_then(number), None)],
        "timeAmPm" => vec![Time(n(1)?, get(2).and_then(number), Some(word(3) == "pm"))],
        "withinDays" => vec![Within(n(1)?)],
        "in" | "en" | "desdeAhora" | "offsetAhead" => vec![offset(n(1)?, &word(2))],
        "ago" | "atras" | "offsetAgo" => vec![offset(-n(1)?, &word(2))],
        "offset" => {
            let negative = matches!(word(3).as_str(), "ago" | "前" | "पहले" | "전");
            vec![offset(if negative { -n(1)? } else { n(1)? }, &word(2))]
        }
        "nextLastWeekday" => {
            let a = word(1);
            let next = a == "next"
                || a.starts_with("pr")
                || a == "अगले"
                || a == "다음"
                || a.starts_with("следующ");
            let weekday = if lang.code == "ko" {
                "월화수목금토일"
                    .chars()
                    .position(|ch| word(2).starts_with(ch))
                    .map(|i| i as i32 + 1)
            } else {
                lang.word("_weekday", &word(2))
            };
            vec![Week(if next { 1 } else { -1 }, false), Weekday(weekday?)]
        }
        "weekday" => {
            let (chars, i) = if lang.code == "ja" {
                ("月火水木金土日", 1)
            } else if lang.code == "ko" {
                ("월화수목금토일", 1)
            } else {
                ("一二三四五六日天", 2)
            };
            let day = chars.chars().position(|ch| word(i).starts_with(ch))? as i32 + 1;
            let mut cs = vec![];
            if lang.code == "zh" && get(1).is_some() {
                cs.push(Week(anchor(&word(1)), true));
            }
            cs.push(Weekday(day.min(7)));
            cs
        }
        "weekAnchor" | "monthAnchor" | "yearAnchor" => {
            let value = if lang.code == "es" {
                if full.contains("pasad") {
                    -1
                } else if full.starts_with("est") {
                    0
                } else {
                    1
                }
            } else {
                anchor(&word(1))
            };
            vec![match kind {
                "weekAnchor" => Week(value, true),
                "monthAnchor" => MonthOffset(value),
                _ => YearOffset(value),
            }]
        }
        "monthDay" | "dayMonth" => {
            let (month, day) = if kind == "monthDay" {
                (lang.word("_month", &word(1))?, valid(n(2), 31)?)
            } else {
                (lang.word("_month", &word(2))?, valid(n(1), 31)?)
            };
            let mut cs = vec![Month(month), Day(day)];
            if let Some(y) = n(3) {
                cs.push(Year(y));
            }
            cs
        }
        "slashDate" | "dotDate" | "date" => {
            let (y, m, d) = if kind == "dotDate" {
                (n(3)?, n(2)?, n(1)?)
            } else if get(1)?.len() == 4 {
                (n(1)?, n(2)?, n(3)?)
            } else {
                (
                    if get(3)?.len() == 4 {
                        n(3)?
                    } else {
                        reference.year()
                    },
                    n(1)?,
                    n(2)?,
                )
            };
            vec![
                Year(y),
                Month(valid(Some(m), 12)?),
                Day(valid(Some(d), 31)?),
            ]
        }
        "estaNoche" => vec![RelativeDay(0), Meridiem(true)],
        "meridiem" if lang.code == "es" => vec![Meridiem(!word(1).starts_with("ma"))],
        "nthWeekday" => {
            let ord = match word(1).as_str() {
                "first" | "primer" | "primero" => 1,
                "second" | "segundo" => 2,
                "third" | "tercer" | "tercero" => 3,
                "fourth" | "cuarto" => 4,
                "fifth" | "quinto" => 5,
                _ => -1,
            };
            vec![Nth(
                ord,
                lang.word("_weekday", &word(2))?,
                lang.word("_month", &word(3))?,
            )]
        }
        "special" => {
            let mut d =
                NaiveDate::from_ymd_opt(reference.year(), 8, 10)?.and_hms_opt(11, 45, 14)?;
            if d < reference {
                d = NaiveDate::from_ymd_opt(reference.year() + 1, 8, 10)?
                    .and_hms_opt(11, 45, 14)?;
            }
            vec![Instant(d)]
        }
        "iso" => {
            let s = get(0)?.replace(' ', "T");
            let dt = DateTime::parse(&s).ok()?;
            vec![Instant(dt)]
        }
        "rfc" => {
            let mut parts = get(0)?.split_whitespace();
            parts.next()?;
            let m = [
                "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
            ]
            .iter()
            .position(|m| Some(*m) == parts.clone().next())?
                + 1;
            parts.next()?;
            let day: u32 = parts.next()?.parse().ok()?;
            let year: i32 = parts.next()?.parse().ok()?;
            let clock = parts.next()?;
            let zone = parts.next()?.strip_prefix("GMT")?;
            let s = format!("{year:04}-{m:02}-{day:02}T{clock}{zone}");
            vec![Instant(DateTime::parse(&s).ok()?)]
        }
        _ => return None,
    })
}

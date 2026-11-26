#![doc = include_str!("../README.md")]
//! Multilingual component recognition, composition and calendar resolution.
//! Compile a [`Parser`] once and reuse it. Dates are timezone-free wall clocks;
//! ISO offsets are converted to UTC. Result offsets are UTF-8 byte offsets.
mod calendar;
use calendar::Duration;
pub use calendar::{DateError, DateTime, NaiveDate, NaiveDateTime};
pub use regex::{Captures, Error as PatternError, Match as Capture};
use regex::{Regex, RegexBuilder};
use std::{
    borrow::Cow,
    collections::HashMap,
    sync::{LazyLock, Mutex},
};
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

static GUARD_CACHE: LazyLock<Mutex<HashMap<&'static str, Regex>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));
static COLON_TIME_RE: LazyLock<Regex> =
    LazyLock::new(|| compile("([0-9]{1,2}):([0-9]{2})"));

fn compile_guard(s: &'static str) -> Regex {
    let mut cache = GUARD_CACHE.lock().unwrap_or_else(|e| e.into_inner());
    if let Some(re) = cache.get(s) {
        return re.clone();
    }
    let re = compile(&format!("^(?:{s})"));
    cache.insert(s, re.clone());
    re
}

pub struct Pattern {
    name: &'static str,
    regex: Regex,
    guards: Vec<(usize, bool, Regex)>,
    captures: Vec<usize>,
    words: &'static [(&'static str, &'static [Component])],
    builder: Option<Builder>,
}
impl Pattern {
    fn new(
        name: &'static str,
        source: &str,
        guards: &[(&'static str, bool, &'static str)],
        words: &'static [(&'static str, &'static [Component])],
    ) -> Self {
        let regex = if name.ends_with("_colonTime") {
            COLON_TIME_RE.clone()
        } else {
            compile(source)
        };
        let mut captures = Vec::new();
        for (idx, cname) in regex.capture_names().enumerate() {
            if cname.is_none_or(|n| !n.starts_with("guard")) {
                captures.push(idx);
            }
        }
        let guards = guards
            .iter()
            .filter_map(|&(gname, behind, s)| {
                let idx = regex.capture_names().position(|n| n == Some(gname))?;
                Some((idx, behind, compile_guard(s)))
            })
            .collect();
        Self {
            name,
            regex,
            guards,
            captures,
            words,
            builder: None,
        }
    }
    /// Add a component recognizer. Rust regex syntax deliberately excludes
    /// backtracking/lookaround. Use the builder to reject unwanted captures.
    pub fn custom(source: &str, builder: Builder) -> Result<Self, PatternError> {
        Ok(Self {
            name: "custom",
            regex: compile_checked(source)?,
            guards: vec![],
            captures: vec![],
            words: &[],
            builder: Some(builder),
        })
    }
    fn accepts(&self, c: &Captures<'_>, text: &str) -> bool {
        self.guards.iter().all(|(idx, behind, regex)| {
            let at = c.get(*idx).unwrap().start();
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
    compile_checked(s).expect("valid language pattern")
}
fn compile_checked(s: &str) -> Result<Regex, PatternError> {
    if s.len() > 64 * 1024 {
        return Err(PatternError::Syntax("pattern exceeds 64 KiB".into()));
    }
    RegexBuilder::new(s)
        .nest_limit(64)
        .size_limit(8 * 1024 * 1024)
        .build()
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
            glue: compile(&format!(r"\A(?:{glue})\z")),
            patterns,
        }
    }
    fn word(&self, suffix: &str, word: &str) -> Option<i32> {
        self.patterns
            .iter()
            .find(|p| p.name.ends_with(suffix))?
            .words
            .iter()
            .find(|(w, _)| eq_word(word, w))
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
enum CompVec {
    Inline([Component; 2], u8),
    Heap(Vec<Component>),
}
impl CompVec {
    fn from_slice(s: &[Component]) -> Self {
        if s.len() <= 2 {
            let mut buf = [Component::Weekend; 2];
            buf[..s.len()].copy_from_slice(s);
            Self::Inline(buf, s.len() as u8)
        } else {
            Self::Heap(s.to_vec())
        }
    }
    fn from_vec(v: Vec<Component>) -> Self {
        if v.len() <= 2 {
            Self::from_slice(&v)
        } else {
            Self::Heap(v)
        }
    }
    fn extend(&mut self, other: Self) {
        let slice = &*other;
        match self {
            Self::Inline(buf, len) if (*len as usize) + slice.len() <= 2 => {
                let start = *len as usize;
                buf[start..start + slice.len()].copy_from_slice(slice);
                *len += slice.len() as u8;
            }
            Self::Heap(v) => v.extend_from_slice(slice),
            Self::Inline(buf, len) => {
                let mut v = Vec::with_capacity((*len as usize) + slice.len());
                v.extend_from_slice(&buf[..*len as usize]);
                v.extend_from_slice(slice);
                *self = Self::Heap(v);
            }
        }
    }
}
impl std::ops::Deref for CompVec {
    type Target = [Component];
    fn deref(&self) -> &[Component] {
        match self {
            Self::Inline(buf, len) => &buf[..*len as usize],
            Self::Heap(v) => v,
        }
    }
}
impl<'a> IntoIterator for &'a CompVec {
    type Item = &'a Component;
    type IntoIter = std::slice::Iter<'a, Component>;
    fn into_iter(self) -> Self::IntoIter {
        self.iter()
    }
}
#[derive(Debug)]
struct Expression {
    start: usize,
    end: usize,
    slots: u8,
    score: i32,
    components: CompVec,
}
impl Expression {
    fn new(start: usize, end: usize, components: CompVec) -> Self {
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
        let s = self.slots | other.slots;
        // Proved equivalent to scanning for Component::Nth via Why3 (accepts_bitmask_equiv).
        if (s & 207) == 207 {
            return true;
        }
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
        let mut tokens: Vec<(Option<Expression>, usize)> = Vec::new();
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
            tokens.clear();
            tokens.resize_with(lang.patterns.len(), || (None, 0));
            let mut last_end = 0;
            let mut current: Option<Expression> = None;
            loop {
                // Keep one candidate per pattern; skip spans already covered by a chosen token.
                for ((token, at), p) in tokens.iter_mut().zip(&lang.patterns) {
                    if token.as_ref().is_some_and(|t| t.start >= last_end) {
                        continue;
                    }
                    *token = None;
                    *at = (*at).max(last_end);
                    while *at < normalized.len() {
                        let Some(c) = p.regex.captures_at(&normalized, *at) else {
                            *at = normalized.len();
                            break;
                        };
                        let m = c.get(0).unwrap();
                        let Some(ch) = normalized[m.start()..].chars().next() else {
                            *at = normalized.len();
                            break;
                        };
                        *at = m.start()
                            + if ch.is_ascii_digit() {
                                normalized[m.start()..]
                                    .bytes()
                                    .take_while(|b| b.is_ascii_digit())
                                    .count()
                            } else {
                                ch.len_utf8()
                            };
                        if m.is_empty() {
                            continue;
                        }
                        if normalized.as_bytes()[m.start()].is_ascii_digit()
                            && m.start() > 0
                            && normalized.as_bytes()[m.start() - 1].is_ascii_digit()
                        {
                            continue;
                        }
                        if !p.accepts(&c, &normalized) {
                            continue;
                        }
                        let cs = if let Some(b) = p.builder {
                            b(&c, options.reference).map(CompVec::from_vec)
                        } else {
                            build(lang, p, &c, options.reference)
                        };
                        if let Some(cs) =
                            cs.filter(|cs| !cs.is_empty() && cs.iter().all(|c| c.valid()))
                        {
                            *token = Some(Expression::new(m.start(), m.end(), cs));
                            break;
                        }
                    }
                }
                let Some(index) = tokens
                    .iter()
                    .enumerate()
                    .filter_map(|(i, (t, _))| Some((i, t.as_ref()?)))
                    .min_by_key(|(i, t)| (t.start, std::cmp::Reverse(t.end), *i))
                    .map(|(i, _)| i)
                else {
                    break;
                };
                let t = tokens[index].0.take().unwrap();
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
        if !options.range {
            if let Some((mut m, _)) = candidates.into_iter().max_by_key(|(m, s)| {
                (
                    normalized[m.start..m.end].encode_utf16().count(),
                    *s,
                    std::cmp::Reverse(m.start),
                )
            }) {
                m.start += 2 * wide_digits.partition_point(|&at| at < m.start);
                m.end += 2 * wide_digits.partition_point(|&at| at < m.end);
                let offset = Duration::minutes(i64::from(options.offset_minutes));
                m.date = m
                    .date
                    .checked_add_signed(offset)
                    .ok_or(Error::DateOutOfRange)?;
                return Ok(vec![m]);
            }
            return Ok(vec![]);
        }
        if candidates.len() > 1 {
            candidates.sort_by_cached_key(|(m, s)| {
                (
                    std::cmp::Reverse(normalized[m.start..m.end].encode_utf16().count()),
                    std::cmp::Reverse(*s),
                    m.start,
                )
            });
        }
        let mut results = Vec::new();
        let mut accepted = [(0usize, 0usize); 8];
        let mut accepted_len = 0usize;
        let mut accepted_extra = Vec::new();
        let check_overlap = candidates.len() > 1;
        for (mut m, _) in candidates {
            if check_overlap {
                if accepted[..accepted_len]
                    .iter()
                    .chain(&accepted_extra)
                    .any(|&(s, e)| m.start < e && s < m.end)
                {
                    continue;
                }
                if accepted_len < accepted.len() {
                    accepted[accepted_len] = (m.start, m.end);
                    accepted_len += 1;
                } else {
                    accepted_extra.push((m.start, m.end));
                }
            }
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
                if !(1..=36600).contains(&days) {
                    return Err(Error::RangeTooLarge);
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
            if !options.range {
                break;
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
fn eq_word(raw: &str, target: &str) -> bool {
    if raw.is_ascii() {
        raw.eq_ignore_ascii_case(target)
    } else if raw.chars().all(|c| !c.is_uppercase()) {
        raw == target
    } else {
        raw.to_lowercase() == target
    }
}
fn build(
    lang: &Language,
    p: &Pattern,
    c: &Captures<'_>,
    reference: NaiveDateTime,
) -> Option<CompVec> {
    use Component::*;
    let get = |i| {
        let actual = *p.captures.get(i)?;
        c.get(actual).map(|m| m.as_str())
    };
    let n = |i| number(get(i)?);
    let word = |i| get(i).unwrap_or("").to_lowercase();
    if !p.words.is_empty() {
        let raw0 = get(0).unwrap_or("");
        if let Some((_, cs)) = p.words.iter().find(|(w, _)| eq_word(raw0, w)) {
            return Some(CompVec::from_slice(cs));
        }
    }
    let kind = p.name.split_once('_')?.1;
    let minute = || match get(2) {
        Some(value) => number(value).map(Some),
        None => Some(None),
    };
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
    let one = |c| CompVec::from_slice(&[c]);
    Some(match kind {
        "colonTime" => one(Time(n(1)?, Some(n(2)?), None)),
        "year" => one(Year(n(1)?)),
        "month" => one(Month(n(1)?)),
        "day" | "ordinalDay" | "elDia" | "dayOnly" => one(Day(n(1)?)),
        "time" | "baje" => one(Time(n(1)?, minute()?, None)),
        "timeAmPm" => one(Time(n(1)?, minute()?, Some(eq_word(get(3).unwrap_or(""), "pm")))),
        "withinDays" => one(Within(n(1)?)),
        "in" | "en" | "desdeAhora" | "offsetAhead" => one(offset(n(1)?, &word(2))),
        "ago" | "atras" | "offsetAgo" => one(offset(-n(1)?, &word(2))),
        "offset" => {
            let negative = matches!(word(3).as_str(), "ago" | "前" | "पहले" | "전");
            one(offset(if negative { -n(1)? } else { n(1)? }, &word(2)))
        }
        "nextLastWeekday" => {
            let a = word(1);
            let next = a == "next"
                || a.starts_with("pr")
                || a == "अगले"
                || a == "다음"
                || a.starts_with("следующ");
            let weekday = if lang.code == "ko" {
                let first = get(2)?.chars().next()?;
                "월화수목금토일"
                    .chars()
                    .position(|ch| ch == first)
                    .map(|i| i as i32 + 1)
            } else {
                lang.word("_weekday", get(2)?)
            };
            CompVec::from_slice(&[Week(if next { 1 } else { -1 }, false), Weekday(weekday?)])
        }
        "weekday" => {
            let (chars, i) = if lang.code == "ja" {
                ("月火水木金土日", 1)
            } else if lang.code == "ko" {
                ("월화수목금토일", 1)
            } else {
                ("一二三四五六日天", 2)
            };
            let first = get(i)?.chars().next()?;
            let day = chars.chars().position(|ch| ch == first)? as i32 + 1;
            if lang.code == "zh" && let Some(a) = get(1) {
                CompVec::from_slice(&[Week(anchor(a), true), Weekday(day.min(7))])
            } else {
                one(Weekday(day.min(7)))
            }
        }
        "weekAnchor" | "monthAnchor" | "yearAnchor" => {
            let value = if lang.code == "es" {
                let full = word(0);
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
            one(match kind {
                "weekAnchor" => Week(value, true),
                "monthAnchor" => MonthOffset(value),
                _ => YearOffset(value),
            })
        }
        "monthDay" | "dayMonth" => {
            let (month, day) = if kind == "monthDay" {
                (lang.word("_month", get(1)?)?, n(2)?)
            } else {
                (lang.word("_month", get(2)?)?, n(1)?)
            };
            if let Some(y) = n(3) {
                CompVec::from_slice(&[Month(month), Day(day), Year(y)])
            } else {
                CompVec::from_slice(&[Month(month), Day(day)])
            }
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
            CompVec::from_slice(&[Year(y), Month(m), Day(d)])
        }
        "estaNoche" => CompVec::from_slice(&[RelativeDay(0), Meridiem(true)]),
        "meridiem" if lang.code == "es" => {
            let w1 = get(1).unwrap_or("");
            one(Meridiem(!w1.get(..2).is_some_and(|p| p.eq_ignore_ascii_case("ma"))))
        }
        "nthWeekday" => {
            let ord = match word(1).as_str() {
                "first" | "primer" | "primero" => 1,
                "second" | "segundo" => 2,
                "third" | "tercer" | "tercero" => 3,
                "fourth" | "cuarto" => 4,
                "fifth" | "quinto" => 5,
                _ => -1,
            };
            one(Nth(
                ord,
                lang.word("_weekday", get(2)?)?,
                lang.word("_month", get(3)?)?,
            ))
        }
        "special" => {
            let mut d =
                NaiveDate::from_ymd_opt(reference.year(), 8, 10)?.and_hms_opt(11, 45, 14)?;
            if d < reference {
                d = NaiveDate::from_ymd_opt(reference.year() + 1, 8, 10)?
                    .and_hms_opt(11, 45, 14)?;
            }
            one(Instant(d))
        }
        "iso" => one(Instant(DateTime::parse(get(0)?).ok()?)),
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
            one(Instant(DateTime::parse(&s).ok()?))
        }
        _ => return None,
    })
}

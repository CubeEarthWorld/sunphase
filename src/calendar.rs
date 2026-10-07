//! Checked proleptic Gregorian wall-clock dates. No clock or timezone database.
use std::{fmt, str::FromStr};

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct NaiveDate(i64);
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct NaiveDateTime(i64);
pub type DateTime = NaiveDateTime;
#[derive(Clone, Copy)]
pub(crate) struct Duration(i64);
impl Duration {
    pub fn days(n: i64) -> Self {
        Self(n.saturating_mul(86400))
    }
    pub fn minutes(n: i64) -> Self {
        Self(n.saturating_mul(60))
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct DateError;
impl fmt::Display for DateError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("invalid Gregorian date or time")
    }
}
impl std::error::Error for DateError {}
pub struct Weekday(u32);
impl Weekday {
    pub fn number_from_monday(&self) -> u32 {
        self.0
    }
}

// March-based 400-year eras make negative years obey the same leap rule.
fn days(y: i32, m: u32, d: u32) -> i64 {
    let y = i64::from(y) - i64::from(m <= 2);
    let era = y.div_euclid(400);
    let yo = y - era * 400;
    let mo = i64::from(m) + if m > 2 { -3 } else { 9 };
    era * 146097 + yo * 365 + yo / 4 - yo / 100 + (153 * mo + 2) / 5 + i64::from(d) - 1 - 719468
}
fn civil(day: i64) -> (i32, u32, u32) {
    let z = day + 719468;
    let era = z.div_euclid(146097);
    let do_ = z - era * 146097;
    let yo = (do_ - do_ / 1460 + do_ / 36524 - do_ / 146096) / 365;
    let doy = do_ - (365 * yo + yo / 4 - yo / 100);
    let mo = (5 * doy + 2) / 153;
    let d = doy - (153 * mo + 2) / 5 + 1;
    let m = mo + if mo < 10 { 3 } else { -9 };
    (
        (yo + era * 400 + i64::from(m <= 2)) as i32,
        m as u32,
        d as u32,
    )
}
impl NaiveDate {
    pub fn from_ymd_opt(y: i32, m: u32, d: u32) -> Option<Self> {
        if !(-262142..=262142).contains(&y)
            || !(1..=12).contains(&m)
            || d == 0
            || d > super::resolve::month_days(y, m)
        {
            return None;
        }
        Some(Self(days(y, m, d)))
    }
    pub fn year(self) -> i32 {
        civil(self.0).0
    }
    pub fn month(self) -> u32 {
        civil(self.0).1
    }
    pub fn day(self) -> u32 {
        civil(self.0).2
    }
    pub fn and_hms_opt(self, h: u32, m: u32, s: u32) -> Option<NaiveDateTime> {
        if h >= 24 || m >= 60 || s >= 60 {
            return None;
        }
        NaiveDateTime::from_timestamp_micros(
            self.0
                .checked_mul(86_400_000_000)?
                .checked_add(i64::from(h * 3600 + m * 60 + s) * 1_000_000)?,
        )
    }
}
impl NaiveDateTime {
    /// Current UTC wall clock on native targets. Hosts without a clock inject
    /// their reference explicitly through Options::new.
    pub fn now_utc() -> Option<Self> {
        #[cfg(not(target_arch = "wasm32"))]
        {
            Self::from_system_time(std::time::SystemTime::now())
        }
        #[cfg(target_arch = "wasm32")]
        {
            None
        }
    }
    /// Convert a caller-supplied system clock to UTC; no local-zone assumptions.
    pub fn from_system_time(time: std::time::SystemTime) -> Option<Self> {
        let micros = match time.duration_since(std::time::UNIX_EPOCH) {
            Ok(d) => i64::try_from(d.as_micros()).ok()?,
            Err(e) => -i64::try_from(e.duration().as_micros()).ok()?,
        };
        Self::from_timestamp_micros(micros)
    }
    pub fn from_timestamp_micros(n: i64) -> Option<Self> {
        let year = civil(n.div_euclid(86_400_000_000)).0;
        (-262142..=262142).contains(&year).then_some(Self(n))
    }
    pub fn timestamp_micros(self) -> i64 {
        self.0
    }
    pub fn and_utc(self) -> Self {
        self
    }
    pub fn naive_utc(self) -> Self {
        self
    }
    pub fn date(self) -> NaiveDate {
        NaiveDate(self.0.div_euclid(86_400_000_000))
    }
    pub fn year(self) -> i32 {
        self.date().year()
    }
    pub fn month(self) -> u32 {
        self.date().month()
    }
    pub fn day(self) -> u32 {
        self.date().day()
    }
    pub fn weekday(self) -> Weekday {
        Weekday((self.date().0 + 3).rem_euclid(7) as u32 + 1)
    }
    pub(crate) fn checked_add_signed(self, d: Duration) -> Option<Self> {
        Self::from_timestamp_micros(self.0.checked_add(d.0.checked_mul(1_000_000)?)?)
    }
    pub fn parse(s: &str) -> Result<Self, DateError> {
        let b = s.as_bytes();
        let number = |a, z| -> Option<u32> {
            let t = b.get(a..z)?;
            if !t.iter().all(u8::is_ascii_digit) {
                return None;
            }
            t.iter().try_fold(0u32, |n, c| {
                n.checked_mul(10)?.checked_add(u32::from(c - b'0'))
            })
        };
        let sign = match b.first() {
            Some(b'-') => -1,
            _ => 1,
        };
        let signed = usize::from(matches!(b.first(), Some(b'-' | b'+')));
        let year_end = b
            .iter()
            .enumerate()
            .skip(signed)
            .find(|(_, c)| **c == b'-')
            .map(|(i, _)| i)
            .ok_or(DateError)?;
        if !(4..=6).contains(&(year_end - signed)) {
            return Err(DateError);
        }
        let base = year_end - 4;
        if b.len() < base + 19
            || b[base + 7] != b'-'
            || !matches!(b[base + 10], b'T' | b' ')
            || b[base + 13] != b':'
            || b[base + 16] != b':'
        {
            return Err(DateError);
        }
        let year = (number(signed, year_end).ok_or(DateError)? as i32) * sign;
        let mut d = NaiveDate::from_ymd_opt(
            year,
            number(base + 5, base + 7).ok_or(DateError)?,
            number(base + 8, base + 10).ok_or(DateError)?,
        )
        .and_then(|v| {
            v.and_hms_opt(
                number(base + 11, base + 13)?,
                number(base + 14, base + 16)?,
                number(base + 17, base + 19)?,
            )
        })
        .ok_or(DateError)?;
        let mut at = base + 19;
        if b.get(at) == Some(&b'.') {
            at += 1;
            let start = at;
            let mut us = 0;
            while b.get(at).is_some_and(u8::is_ascii_digit) {
                if at - start < 6 {
                    us = us * 10 + i64::from(b[at] - b'0');
                }
                at += 1;
            }
            if at == start {
                return Err(DateError);
            }
            for _ in at - start..6 {
                us *= 10;
            }
            d.0 += us;
        }
        if at == b.len() {
            return Ok(d);
        }
        if b.get(at) == Some(&b'Z') && at + 1 == b.len() {
            return Ok(d);
        }
        let sign = match b.get(at) {
            Some(b'+') => 1,
            Some(b'-') => -1,
            _ => return Err(DateError),
        };
        let h = number(at + 1, at + 3).ok_or(DateError)?;
        let colon = usize::from(b.get(at + 3) == Some(&b':'));
        let m = number(at + 3 + colon, at + 5 + colon).ok_or(DateError)?;
        if at + 5 + colon != b.len() || h > 23 || m > 59 {
            return Err(DateError);
        }
        d.checked_add_signed(Duration::minutes(-sign * i64::from(h * 60 + m)))
            .ok_or(DateError)
    }
    pub fn to_iso8601(self) -> String {
        self.to_string().replacen(' ', "T", 1)
    }
    pub fn to_rfc3339(self) -> String {
        format!("{}+00:00", self.to_iso8601())
    }
}
impl FromStr for NaiveDateTime {
    type Err = DateError;
    fn from_str(s: &str) -> Result<Self, DateError> {
        Self::parse(s)
    }
}
impl fmt::Display for NaiveDateTime {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let (y, m, d) = civil(self.date().0);
        let us = self.0.rem_euclid(86_400_000_000);
        let sec = us / 1_000_000;
        if y < 0 {
            write!(f, "-{:04}", -y)?;
        } else if y > 9999 {
            write!(f, "+{y}")?;
        } else {
            write!(f, "{y:04}")?;
        }
        write!(
            f,
            "-{m:02}-{d:02} {:02}:{:02}:{:02}",
            sec / 3600,
            sec / 60 % 60,
            sec % 60
        )?;
        if us % 1_000_000 != 0 {
            write!(f, ".{:06}", us % 1_000_000)?;
        }
        Ok(())
    }
}

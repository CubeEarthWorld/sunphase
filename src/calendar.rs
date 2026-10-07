//! Checked microsecond wall clocks backed by Chrono's Gregorian calendar.
pub(crate) use chrono::Duration;
use chrono::{Datelike, Timelike};
use std::{fmt, str::FromStr, sync::LazyLock};

static ISO: LazyLock<regex::Regex> = LazyLock::new(|| {
    regex::Regex::new(r"\A[+-]?[0-9]{4,6}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?(?:Z|[+-](?:[01][0-9]|2[0-3]):?[0-5][0-9])?\z")
        .expect("ISO input shape")
});

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct NaiveDate(chrono::NaiveDate);
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct NaiveDateTime(chrono::NaiveDateTime);
pub type DateTime = NaiveDateTime;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct DateError;
impl fmt::Display for DateError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("invalid Gregorian date or time")
    }
}
impl std::error::Error for DateError {}

pub(crate) fn month_days(y: i32, m: u32) -> u32 {
    chrono::NaiveDate::from_ymd_opt(y, m, 1).map_or(0, |d| u32::from(d.num_days_in_month()))
}
impl NaiveDate {
    pub fn from_ymd_opt(y: i32, m: u32, d: u32) -> Option<Self> {
        if !(-262142..=262142).contains(&y) {
            return None;
        }
        chrono::NaiveDate::from_ymd_opt(y, m, d).map(Self)
    }
    pub fn year(self) -> i32 {
        self.0.year()
    }
    pub fn month(self) -> u32 {
        self.0.month()
    }
    pub fn day(self) -> u32 {
        self.0.day()
    }
    pub fn and_hms_opt(self, h: u32, m: u32, s: u32) -> Option<NaiveDateTime> {
        self.0.and_hms_opt(h, m, s).map(NaiveDateTime)
    }
}
impl NaiveDateTime {
    /// Native UTC clock. Wasm hosts supply an explicit reference through Options.
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
    pub fn from_system_time(time: std::time::SystemTime) -> Option<Self> {
        let nanos = match time.duration_since(std::time::UNIX_EPOCH) {
            Ok(d) => i128::try_from(d.as_nanos()).ok()?,
            Err(e) => -i128::try_from(e.duration().as_nanos()).ok()?,
        };
        Self::from_timestamp_micros(nanos.div_euclid(1000).try_into().ok()?)
    }
    fn checked(value: chrono::NaiveDateTime) -> Option<Self> {
        if !(-262142..=262142).contains(&value.year()) || value.nanosecond() >= 1_000_000_000 {
            return None;
        }
        value
            .with_nanosecond(value.nanosecond() / 1000 * 1000)
            .map(Self)
    }
    pub fn from_timestamp_micros(n: i64) -> Option<Self> {
        Self::checked(chrono::DateTime::from_timestamp_micros(n)?.naive_utc())
    }
    pub fn timestamp_micros(self) -> i64 {
        self.0.and_utc().timestamp_micros()
    }
    pub fn and_utc(self) -> Self {
        self
    }
    pub fn naive_utc(self) -> Self {
        self
    }
    pub fn date(self) -> NaiveDate {
        NaiveDate(self.0.date())
    }
    pub fn year(self) -> i32 {
        self.0.year()
    }
    pub fn month(self) -> u32 {
        self.0.month()
    }
    pub fn day(self) -> u32 {
        self.0.day()
    }
    pub fn weekday(self) -> chrono::Weekday {
        self.0.weekday()
    }
    pub(crate) fn checked_add_signed(self, d: Duration) -> Option<Self> {
        Self::checked(self.0.checked_add_signed(d)?)
    }
    pub fn parse(s: &str) -> Result<Self, DateError> {
        if !ISO.is_match(s) {
            return Err(DateError);
        }
        for (format, zoned) in [
            ("%Y-%m-%dT%H:%M:%S%.f", "%Y-%m-%dT%H:%M:%S%.f%#z"),
            ("%Y-%m-%d %H:%M:%S%.f", "%Y-%m-%d %H:%M:%S%.f%#z"),
        ] {
            if let Ok(value) = chrono::NaiveDateTime::parse_from_str(s, format) {
                return Self::checked(value).ok_or(DateError);
            }
            if let Ok(value) = chrono::DateTime::parse_from_str(s, zoned) {
                // Reject leap seconds before an offset could normalize them away.
                if value.nanosecond() >= 1_000_000_000 {
                    return Err(DateError);
                }
                return Self::checked(value.naive_utc()).ok_or(DateError);
            }
        }
        Err(DateError)
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
        write!(f, "{}", self.0.format("%Y-%m-%d %H:%M:%S"))?;
        let micros = self.0.nanosecond() / 1000;
        if micros != 0 {
            write!(f, ".{micros:06}")?;
        }
        Ok(())
    }
}

use super::*;
use calendar::month_days;
fn date(y: i32, m: i32, d: i32, h: i32, min: i32) -> Option<NaiveDateTime> {
    NaiveDate::from_ymd_opt(y, m.try_into().ok()?, d.try_into().ok()?)?.and_hms_opt(
        h.try_into().ok()?,
        min.try_into().ok()?,
        0,
    )
}
fn shift(d: NaiveDateTime, days: i64) -> Result<NaiveDateTime, Error> {
    d.checked_add_signed(Duration::days(days))
        .ok_or(Error::DateOutOfRange)
}
pub(super) fn resolve(e: &Expression, o: &Options<'_>) -> Result<Option<Match>, Error> {
    use Component::*;
    let (
        mut year,
        mut ya,
        mut month,
        mut ma,
        mut day,
        mut weekday,
        mut relative,
        mut week,
        mut hour,
        mut minute,
        mut pm,
        mut within,
        mut instant,
        mut nth,
    ) = (
        None, None, None, None, None, None, None, None, None, None, None, None, None, None,
    );
    let mut weekend = false;
    for &c in &e.components {
        match c {
            Year(v) => year = Some(v),
            YearOffset(v) => ya = Some(v),
            Month(v) => month = Some(v),
            MonthOffset(v) => ma = Some(v),
            Day(v) => day = Some(v),
            Weekday(v) => weekday = Some(v),
            RelativeDay(v) => relative = Some(v),
            Week(v, b) => week = Some((v, b)),
            Weekend => weekend = true,
            Time(h, m, p) => {
                hour = Some(h);
                minute = m;
                if p.is_some() {
                    pm = p;
                }
            }
            Meridiem(v) => pm = Some(v),
            Within(v) => within = Some(v),
            Instant(v) => instant = Some(v),
            Nth(a, b, c) => nth = Some((a, b, c)),
        }
    }
    let reference = o.reference;
    let midnight = reference.date().and_hms_opt(0, 0, 0).unwrap();
    let mut h = hour.unwrap_or(0);
    let min = minute.unwrap_or(0);
    if let Some(p) = pm {
        if p && h < 12 {
            h += 12;
        } else if !p && h == 12 {
            h = 0;
        }
    }
    if !(0..24).contains(&h) || !(0..60).contains(&min) {
        return Ok(None);
    }
    let clock = |d: NaiveDateTime| d.date().and_hms_opt(h as u32, min as u32, 0);
    let wd = reference.weekday().number_from_monday() as i32;
    let next = |target: i32| {
        let diff = (target - wd).rem_euclid(7);
        shift(midnight, i64::from(if diff == 0 { 7 } else { diff }))
    };
    let week_start = |offset: i32| {
        shift(
            midnight,
            i64::from(offset) * 7 - i64::from((wd - i32::from(o.week_start)).rem_euclid(7)),
        )
    };
    let mut range_type = None;
    let mut range_days = None;
    let result = if let Some(d) = instant {
        Some(d)
    } else if let Some(n) = within {
        range_days = n.checked_add(1);
        if range_days.is_none() {
            return Err(Error::RangeTooLarge);
        }
        Some(midnight)
    } else if let Some((ord, target, m)) = nth {
        let compute = |y| -> Option<NaiveDateTime> {
            let first = date(
                y,
                m,
                if ord < 0 {
                    month_days(y, m as u32) as i32
                } else {
                    1
                },
                0,
                0,
            )?;
            let w = first.weekday().number_from_monday() as i32;
            let diff = if ord < 0 {
                -(w - target).rem_euclid(7)
            } else {
                (target - w).rem_euclid(7) + (ord - 1) * 7
            };
            let candidate = first.checked_add_signed(Duration::days(i64::from(diff)))?;
            if candidate.month() != m as u32 {
                return None;
            }
            clock(candidate)
        };
        let first = compute(reference.year());
        if first.is_some_and(|d| d < reference) {
            compute(reference.year() + 1)
        } else {
            first
        }
    } else if weekend {
        clock(next(7)?)
    } else if let Some(n) = relative {
        clock(shift(midnight, i64::from(n))?)
    } else if let Some((offset, calendar)) = week {
        if let Some(target) = weekday {
            let base = if calendar && offset >= 0 {
                shift(
                    week_start(offset)?,
                    i64::from((target - i32::from(o.week_start)).rem_euclid(7)),
                )?
            } else if offset < 0 {
                let diff = (wd - target).rem_euclid(7);
                shift(
                    midnight,
                    -i64::from(if diff == 0 { 7 } else { diff }) + (i64::from(offset) + 1) * 7,
                )?
            } else {
                shift(
                    next(target)?,
                    i64::from(offset.saturating_sub(1).max(0)) * 7,
                )?
            };
            clock(base)
        } else if calendar {
            if hour.is_none() {
                range_type = Some("week");
            }
            clock(week_start(offset)?)
        } else {
            clock(shift(midnight, i64::from(offset) * 7)?)
        }
    } else if year.is_none() && ya.is_none() && month.is_none() && ma.is_none() && day.is_none() {
        if let Some(target) = weekday {
            clock(next(target)?)
        } else if hour.is_some() {
            let today = clock(midnight).unwrap();
            Some(if today > reference {
                today
            } else {
                shift(today, 1)?
            })
        } else {
            None
        }
    } else {
        let mut y = reference
            .year()
            .checked_add(ya.unwrap_or(0))
            .ok_or(Error::DateOutOfRange)?;
        let mut m = reference.month() as i32;
        let d = day.unwrap_or(1);
        if let Some(offset) = ma {
            let months = i64::from(y) * 12 + i64::from(m) - 1 + i64::from(offset);
            y = i32::try_from(months.div_euclid(12)).map_err(|_| Error::DateOutOfRange)?;
            m = months.rem_euclid(12) as i32 + 1;
        }
        if let Some(v) = month {
            m = v;
        }
        if let Some(v) = year {
            y = v;
        } else if month.is_some() && day.is_some() && ya.is_none() && ma.is_none() {
            if (m, d) < (reference.month() as i32, reference.day() as i32) {
                y += 1;
            }
            if m == 2 && d == 29 {
                while date(y, m, d, h, min).is_none() {
                    y += 1;
                    if y > 262142 {
                        return Err(Error::DateOutOfRange);
                    }
                }
            }
        } else if day.is_some() && month.is_none() && ma.is_none() && ya.is_none() {
            // Keep advancing until the requested day exists (31st after Feb).
            while date(y, m, d, h, min).is_none_or(|v| v.date() <= reference.date()) {
                m += 1;
                if m > 12 {
                    m = 1;
                    y += 1;
                }
                if y > 262142 {
                    return Err(Error::DateOutOfRange);
                }
            }
        } else if month.is_some()
            && day.is_none()
            && ma.is_none()
            && ya.is_none()
            && m < reference.month() as i32
        {
            y += 1;
        }
        if day.is_none()
            && weekday.is_none()
            && hour.is_none()
            && (month.is_some() || ma.is_some())
            && year.is_none()
        {
            range_type = Some("month");
        }
        let result = date(y, m, d, h, min);
        if let Some(target) = weekday {
            result.and_then(|candidate| {
                let diff = (target - candidate.weekday().number_from_monday() as i32).rem_euclid(7);
                if day.is_some() {
                    (diff == 0).then_some(candidate)
                } else {
                    candidate.checked_add_signed(Duration::days(i64::from(diff)))
                }
            })
        } else {
            result
        }
    };
    Ok(result.map(|date| Match {
        start: e.start,
        end: e.end,
        date,
        range_type,
        range_days,
    }))
}

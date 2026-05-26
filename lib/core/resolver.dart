// lib/core/resolver.dart
//
// Translates a `RawMatch` (the intermediate, partially-resolved output
// of a language pattern) into a final `ParsingResult` with a concrete
// `DateTime`.
//
// The resolver is the single place where the "inference rules" for
// incomplete expressions live:
//   * bare times roll forward to their next occurrence
//   * a weekday name without a qualifier resolves to the *next* one
//   * a month+day without a year resolves with a future bias
//   * etc.
//
// Keeping these rules centralized means every language pattern can stay
// focused on extraction and let the resolver decide what the extracted
// fields actually mean in calendar terms.

import '../languages/lang_def.dart';
import '../utils/date_utils.dart';
import 'result.dart';

/// Centralized date resolution: converts `RawMatch` -> `ParsingResult`.
class DateResolver {
  /// Resolves a single [m] into a [ParsingResult] using [ref] as the
  /// anchor for every relative field.
  static ParsingResult resolve(
    RawMatch m,
    DateTime ref, {
    int weekStartsOn = DateTime.sunday,
  }) {
    // Extract time first so each date branch below only has to worry
    // about the year/month/day components.
    int hour = m.hour ?? 0;
    int minute = m.minute ?? 0;
    if (m.pmFlag && hour < 12) hour += 12;

    bool hasTime = m.hour != null;
    DateTime date;

    if (!m.hasDateInfo && hasTime) {
      // Time-only expression (e.g. "10:10"): roll forward to the next
      // time this clock reading occurs.
      date = DateUtils.nextOccurrenceTime(ref, hour, minute);
    } else if (m.dayOffset != null) {
      // Relative day ("today", "tomorrow", "yesterday", "in 3 days").
      DateTime base = DateTime(
        ref.year,
        ref.month,
        ref.day,
      ).add(Duration(days: m.dayOffset!));
      date = DateTime(base.year, base.month, base.day, hour, minute);
    } else if (m.weekOffset != null &&
        m.weekday != null &&
        m.month == null &&
        m.day == null &&
        m.monthOffset == null) {
      // "next Monday", "last Friday" — weekday combined with a
      // week-level offset.
      date = _resolveWeekday(m, ref, hour, minute, weekStartsOn);
    } else if (m.weekOffset != null &&
        m.weekday == null &&
        m.month == null &&
        m.day == null &&
        m.dayOffset == null) {
      if (m.rangeType == 'week') {
        DateTime base = _resolveWeekStart(ref, m.weekOffset!, weekStartsOn);
        date = DateTime(base.year, base.month, base.day, hour, minute);
      } else {
        // Week offset without a named week span ("2 weeks from now"):
        // treat it as a day offset of `weekOffset * 7`.
        int dayOffset = m.weekOffset! * 7;
        DateTime base = DateTime(
          ref.year,
          ref.month,
          ref.day,
        ).add(Duration(days: dayOffset));
        date = DateTime(base.year, base.month, base.day, hour, minute);
      }
    } else if (m.weekday != null &&
        m.month == null &&
        m.day == null &&
        m.monthOffset == null) {
      // Bare weekday ("Monday") — resolves to the next occurrence.
      date = _resolveWeekday(m, ref, hour, minute, weekStartsOn);
    } else {
      // Everything else is a calendar-date expression with at least
      // one of year/month/day set.
      date = _resolveCalendarDate(m, ref, hour, minute, hasTime, weekStartsOn);
    }

    return ParsingResult(
      index: m.startIndex,
      text: m.text,
      date: date,
      rangeType: m.rangeType,
      rangeDays: m.rangeDays,
    );
  }

  /// Returns the start date of the named week offset from [ref].
  static DateTime _resolveWeekStart(
    DateTime ref,
    int weekOffset,
    int weekStartsOn,
  ) {
    DateTime weekStart = DateUtils.firstDayOfWeek(
      ref,
      startWeekday: weekStartsOn,
    );
    DateTime base = weekStart.add(Duration(days: weekOffset * 7));
    return DateTime(base.year, base.month, base.day);
  }

  /// Resolves a weekday expression, honoring an optional week offset.
  static DateTime _resolveWeekday(
    RawMatch m,
    DateTime ref,
    int hour,
    int minute,
    int weekStartsOn,
  ) {
    int weekOffset = m.weekOffset ?? 0;
    DateTime base;

    if (m.calendarWeek) {
      DateTime weekStart = _resolveWeekStart(ref, weekOffset, weekStartsOn);
      int weekdayOffset = (m.weekday! - weekStartsOn + 7) % 7;
      base = weekStart.add(Duration(days: weekdayOffset));
      return DateTime(base.year, base.month, base.day, hour, minute);
    }

    if (weekOffset == 0) {
      // No offset — pick the next occurrence of the weekday.
      base = DateUtils.nextWeekday(ref, m.weekday!);
    } else if (weekOffset < 0) {
      // Past reference ("last Friday"): find the most recent matching
      // weekday strictly before `ref`.
      int diff = (ref.weekday - m.weekday! + 7) % 7;
      diff = diff == 0 ? 7 : diff;
      base = ref.subtract(Duration(days: diff));
    } else {
      // Future reference. weekOffset == 1 is the same as "next".
      // For larger values ("in 3 weeks on Monday") we first jump to
      // the next matching weekday and then add full weeks.
      base = DateUtils.nextWeekday(ref, m.weekday!);
      if (weekOffset > 1) {
        base = base.add(Duration(days: (weekOffset - 1) * 7));
      }
    }
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  /// Resolves a calendar-date expression (has at least one of
  /// year/month/day and/or month/year offsets).
  static DateTime _resolveCalendarDate(
    RawMatch m,
    DateTime ref,
    int hour,
    int minute,
    bool hasTime,
    int weekStartsOn,
  ) {
    int year = ref.year;
    int month = ref.month;
    int day = m.day ?? 1;

    // Year offset ("next year", "来年"): shift from the reference.
    if (m.yearOffset != null) {
      year = ref.year + m.yearOffset!;
    }

    // Month offset ("next month", "来月"): move the month pointer
    // before we apply any explicit month/day below.
    if (m.monthOffset != null) {
      DateTime base = DateUtils.addMonths(
        DateTime(ref.year, ref.month, 1),
        m.monthOffset!,
      );
      year = base.year;
      month = base.month;
      if (m.day == null) day = 1;
    }

    // Explicit month takes precedence over the offset-derived one.
    if (m.month != null) {
      month = m.month!;
    }

    // Explicit year trumps every inference rule below.
    if (m.year != null) {
      year = m.year!;
      return DateTime(year, month, day, hour, minute);
    }

    // Month + day with no year: apply a "future bias" so that a date
    // that has already passed this year is interpreted as next year.
    if (m.month != null &&
        m.day != null &&
        m.yearOffset == null &&
        m.monthOffset == null) {
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(DateTime(ref.year, ref.month, ref.day))) {
        if (month < ref.month || (month == ref.month && day < ref.day)) {
          year++;
        }
      }
      return DateTime(year, month, day, hour, minute);
    }

    // Day-only expression ("the 20th"): infer the nearest future month
    // that actually contains that day.
    if (m.day != null &&
        m.month == null &&
        m.monthOffset == null &&
        m.yearOffset == null) {
      // If the requested day doesn't even exist this month (e.g. "the
      // 31st" in April), jump straight to the next month.
      int lastDayOfCurrentMonth = DateUtils.getMonthRange(
        DateTime(year, month, 1),
      )['end']!.day;
      if (day > lastDayOfCurrentMonth) {
        DateTime next = DateUtils.addMonths(DateTime(year, month, 1), 1);
        year = next.year;
        month = next.month;
      } else {
        // Otherwise keep the current month only if the resulting date
        // is strictly in the future; else roll into next month.
        DateTime candidate = DateTime(year, month, day);
        if (!candidate.isAfter(DateTime(ref.year, ref.month, ref.day))) {
          DateTime next = DateUtils.addMonths(DateTime(year, month, 1), 1);
          year = next.year;
          month = next.month;
        }
      }
      return DateTime(year, month, day, hour, minute);
    }

    // Range-type expressions that didn't carry a concrete day. These
    // are handled by anchoring to the first day of the relevant week
    // or month; `RangeMode` later expands them into per-day results.
    if (m.rangeType != null && m.day == null && m.dayOffset == null) {
      if (m.rangeType == "week") {
        if (m.weekOffset != null) {
          if (m.weekOffset == 0) {
            // "this week" — configured first day of the current week.
            DateTime base = _resolveWeekStart(ref, 0, weekStartsOn);
            return DateTime(base.year, base.month, base.day);
          } else if (m.weekOffset == 1) {
            // "next week" — first day one week after the current week.
            DateTime base = _resolveWeekStart(ref, 1, weekStartsOn);
            return DateTime(base.year, base.month, base.day);
          } else if (m.weekOffset == -1) {
            // "last week" — first day of the previous week.
            DateTime base = _resolveWeekStart(ref, -1, weekStartsOn);
            return DateTime(base.year, base.month, base.day);
          } else if (m.weekOffset == -7) {
            // Special sentinel used by Japanese "週末" (weekend):
            // resolves to the next upcoming Sunday.
            int diff = (7 - ref.weekday) % 7;
            diff = diff == 0 ? 7 : diff;
            DateTime base = ref.add(Duration(days: diff));
            return DateTime(base.year, base.month, base.day);
          }
        }
      }
      return DateTime(year, month, day);
    }

    return DateTime(year, month, day, hour, minute);
  }
}

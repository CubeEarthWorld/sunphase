// lib/core/resolver.dart
import '../languages/lang_def.dart';
import '../utils/date_utils.dart';
import 'result.dart';

/// Centralized date resolution: converts RawMatch → ParsingResult
class DateResolver {
  static ParsingResult resolve(RawMatch m, DateTime ref) {
    int hour = m.hour ?? 0;
    int minute = m.minute ?? 0;
    if (m.pmFlag && hour < 12) hour += 12;

    bool hasTime = m.hour != null;
    DateTime date;

    if (!m.hasDateInfo && hasTime) {
      // Time only → next occurrence
      date = DateUtils.nextOccurrenceTime(ref, hour, minute);
    } else if (m.dayOffset != null) {
      // Relative day (today, tomorrow, yesterday, etc.)
      DateTime base =
          DateTime(ref.year, ref.month, ref.day).add(Duration(days: m.dayOffset!));
      date = DateTime(base.year, base.month, base.day, hour, minute);
    } else if (m.weekOffset != null && m.weekday != null && m.month == null && m.day == null && m.monthOffset == null) {
      // Weekday with week offset
      date = _resolveWeekday(m, ref, hour, minute);
    } else if (m.weekOffset != null && m.weekday == null && m.month == null && m.day == null && m.dayOffset == null) {
      // Week offset without weekday → convert to day offset
      int dayOffset = m.weekOffset! * 7;
      DateTime base = DateTime(ref.year, ref.month, ref.day).add(Duration(days: dayOffset));
      date = DateTime(base.year, base.month, base.day, hour, minute);
    } else if (m.weekday != null && m.month == null && m.day == null && m.monthOffset == null) {
      // Weekday resolution
      date = _resolveWeekday(m, ref, hour, minute);
    } else {
      date = _resolveCalendarDate(m, ref, hour, minute, hasTime);
    }

    return ParsingResult(
      index: m.startIndex,
      text: m.text,
      date: date,
      rangeType: m.rangeType,
      rangeDays: m.rangeDays,
    );
  }

  static DateTime _resolveWeekday(RawMatch m, DateTime ref, int hour, int minute) {
    int weekOffset = m.weekOffset ?? 0;
    DateTime base;

    if (weekOffset == 0) {
      base = DateUtils.nextWeekday(ref, m.weekday!);
    } else if (weekOffset < 0) {
      // Negative week offset (past)
      // For "last Friday" with weekOffset=-7, find the previous Friday
      int diff = (ref.weekday - m.weekday! + 7) % 7;
      diff = diff == 0 ? 7 : diff;
      base = ref.subtract(Duration(days: diff));
    } else {
      base = DateUtils.nextWeekday(ref, m.weekday!);
      if (weekOffset > 1) {
        base = base.add(Duration(days: (weekOffset - 1) * 7));
      }
    }
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  static DateTime _resolveCalendarDate(
      RawMatch m, DateTime ref, int hour, int minute, bool hasTime) {
    int year = ref.year;
    int month = ref.month;
    int day = m.day ?? 1;

    // Year offset (来年, next year, etc.)
    if (m.yearOffset != null) {
      year = ref.year + m.yearOffset!;
    }

    // Month offset (来月, next month, etc.)
    if (m.monthOffset != null) {
      DateTime base = DateUtils.addMonths(DateTime(ref.year, ref.month, 1), m.monthOffset!);
      year = base.year;
      month = base.month;
      if (m.day == null) day = 1;
    }

    // Explicit month
    if (m.month != null) {
      month = m.month!;
    }

    // Explicit year (overrides offset)
    if (m.year != null) {
      year = m.year!;
      return DateTime(year, month, day, hour, minute);
    }

    // Infer year for month+day (future bias)
    if (m.month != null && m.day != null && m.yearOffset == null && m.monthOffset == null) {
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(DateTime(ref.year, ref.month, ref.day))) {
        if (month < ref.month || (month == ref.month && day < ref.day)) {
          year++;
        }
      }
      return DateTime(year, month, day, hour, minute);
    }

    // Day-only: infer month (future bias)
    if (m.day != null && m.month == null && m.monthOffset == null && m.yearOffset == null) {
      // First check if day is valid for current month
      int lastDayOfCurrentMonth = DateUtils.getMonthRange(DateTime(year, month, 1))['end']!.day;
      if (day > lastDayOfCurrentMonth) {
        // Day exceeds current month, go to next month
        DateTime next = DateUtils.addMonths(DateTime(year, month, 1), 1);
        year = next.year;
        month = next.month;
      } else {
        DateTime candidate = DateTime(year, month, day);
        if (!candidate.isAfter(DateTime(ref.year, ref.month, ref.day))) {
          DateTime next = DateUtils.addMonths(DateTime(year, month, 1), 1);
          year = next.year;
          month = next.month;
        }
      }
      return DateTime(year, month, day, hour, minute);
    }

    // Range expressions (month/week modifiers without day)
    if (m.rangeType != null && m.day == null && m.dayOffset == null) {
      if (m.rangeType == "week") {
        // Week ranges resolved via weekOffset
        if (m.weekOffset != null) {
          if (m.weekOffset == 0) {
            DateTime base = DateUtils.firstDayOfWeek(ref);
            return DateTime(base.year, base.month, base.day);
          } else if (m.weekOffset == 1) {
            // Next week: Monday of the week after the current week
            DateTime thisWeekMonday = DateUtils.firstDayOfWeek(ref);
            DateTime nextWeekMonday = thisWeekMonday.add(Duration(days: 7));
            return DateTime(nextWeekMonday.year, nextWeekMonday.month, nextWeekMonday.day);
          } else if (m.weekOffset == -1) {
            DateTime base = DateUtils.firstDayOfWeek(ref).subtract(Duration(days: 7));
            return DateTime(base.year, base.month, base.day);
          } else if (m.weekOffset == -7) {
            // 週末: next Sunday
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

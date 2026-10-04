// lib/src/core/resolver.dart
//
// Turns a composed DateExpression into a concrete DateTime. This is the
// single home of every inference rule for incomplete expressions:
//
//   * a bare time rolls forward to its next occurrence
//   * a bare weekday resolves to the next occurrence
//   * month + day without a year gets a future bias
//   * a bare day-of-month picks the nearest future month containing it
//   * named weeks (来週) resolve against the configured week start;
//     duration weeks (2週間後) resolve as offset × 7 days
//
// Languages never encode these rules — they only emit components.

import '../../utils/date_utils.dart';
import 'component.dart';
import 'expression.dart';

/// A resolved expression, ready for ranking and result construction.
class Resolved {
  final int start;
  final int end;
  final DateTime date;
  final String? rangeType;
  final int? rangeDays;
  final int specificity;

  Resolved({
    required this.start,
    required this.end,
    required this.date,
    required this.specificity,
    this.rangeType,
    this.rangeDays,
  });

  int get length => end - start;
}

class Resolver {
  final DateTime ref;
  final int weekStartsOn;

  const Resolver(this.ref, {required this.weekStartsOn});

  DateTime get _refDay => DateTime(ref.year, ref.month, ref.day);

  /// Resolves [expr], or returns null when it carries no usable
  /// date/time information (e.g. a stray meridiem marker).
  Resolved? resolve(DateExpression expr) {
    final f = _Fields()..collect(expr.components);

    Resolved make(DateTime date, {String? rangeType, int? rangeDays}) =>
        Resolved(
          start: expr.start,
          end: expr.end,
          date: date,
          specificity: expr.specificity,
          rangeType: rangeType,
          rangeDays: rangeDays,
        );

    if (f.instant != null) return make(f.instant!);

    final hasTime = f.hour != null;
    final hour = _adjustedHour(f.hour ?? 0, f.meridiem);
    final minute = f.minute ?? 0;

    if (f.withinDays != null) {
      return make(_refDay, rangeDays: f.withinDays! + 1);
    }

    if (f.nth != null) {
      return make(_resolveNthWeekday(f.nth!, hour, minute));
    }

    if (f.weekend) {
      final base = DateUtils.nextWeekday(_refDay, DateTime.sunday);
      return make(DateTime(base.year, base.month, base.day, hour, minute));
    }

    if (f.dayRel != null) {
      final base = _refDay.add(Duration(days: f.dayRel!));
      return make(DateTime(base.year, base.month, base.day, hour, minute));
    }

    if (f.weekRel && f.weekday != null) {
      return make(
        _resolveWeekday(f.weekday!, f.weekRelOffset!, f.weekRelCalendar, hour,
            minute),
      );
    }

    if (f.weekRel) {
      if (f.weekRelCalendar) {
        // Named week span: anchor at the week's first day.
        final base = _weekStart(f.weekRelOffset!);
        return make(
          DateTime(base.year, base.month, base.day, hour, minute),
          rangeType: hasTime ? null : 'week',
        );
      }
      // Duration weeks: N × 7 days from the reference.
      final base = _refDay.add(Duration(days: f.weekRelOffset! * 7));
      return make(DateTime(base.year, base.month, base.day, hour, minute));
    }

    final hasCalendarDate = f.year != null ||
        f.yearAnchor != null ||
        f.month != null ||
        f.monthAnchor != null ||
        f.day != null;

    if (f.weekday != null && !hasCalendarDate) {
      return make(_resolveWeekday(f.weekday!, 0, false, hour, minute));
    }

    if (!hasCalendarDate) {
      if (!hasTime) return null; // nothing to resolve
      return make(DateUtils.nextOccurrenceTime(ref, hour, minute));
    }

    return _resolveCalendarDate(f, hour, minute, hasTime, make);
  }

  // -- calendar-date path ---------------------------------------------------

  Resolved _resolveCalendarDate(
    _Fields f,
    int hour,
    int minute,
    bool hasTime,
    Resolved Function(DateTime, {String? rangeType, int? rangeDays}) make,
  ) {
    int year = ref.year;
    int month = ref.month;
    int day = f.day ?? 1;

    if (f.yearAnchor != null) year = ref.year + f.yearAnchor!;

    if (f.monthAnchor != null) {
      final base =
          DateUtils.addMonths(DateTime(year, ref.month, 1), f.monthAnchor!);
      year = base.year;
      month = base.month;
    }

    if (f.month != null) month = f.month!;

    // An explicit year trumps every inference rule.
    if (f.year != null) {
      return make(DateTime(f.year!, month, day, hour, minute));
    }

    // Month + day with no year: future bias.
    if (f.month != null &&
        f.day != null &&
        f.yearAnchor == null &&
        f.monthAnchor == null) {
      final candidate = DateTime(year, month, day);
      if (candidate.isBefore(_refDay) &&
          (month < ref.month || (month == ref.month && day < ref.day))) {
        year++;
      }
      return make(DateTime(year, month, day, hour, minute));
    }

    // Day only: nearest future month that contains that day.
    if (f.day != null &&
        f.month == null &&
        f.monthAnchor == null &&
        f.yearAnchor == null) {
      final lastDay = DateUtils.getMonthRange(DateTime(year, month, 1))['end']!
          .day;
      if (day > lastDay || !DateTime(year, month, day).isAfter(_refDay)) {
        final next = DateUtils.addMonths(DateTime(year, month, 1), 1);
        year = next.year;
        month = next.month;
      }
      return make(DateTime(year, month, day, hour, minute));
    }

    // Bare month name: future bias to the next occurrence of that month.
    // Only applies when the year is otherwise unconstrained — an explicit
    // year anchor (来年, 再来年, …) already fixed the year above, so the
    // bias must not run again on top of it (that double-advances the year).
    if (f.month != null &&
        f.day == null &&
        f.monthAnchor == null &&
        f.yearAnchor == null) {
      if (f.month! < ref.month) year++;
    }

    // Month-level expressions without a day are month spans (来月, march).
    final isMonthSpan =
        f.day == null && !hasTime && (f.month != null || f.monthAnchor != null);
    return make(
      DateTime(year, month, day, hour, minute),
      rangeType: isMonthSpan ? 'month' : null,
    );
  }

  // -- weekday helpers ------------------------------------------------------

  DateTime _weekStart(int weekOffset) {
    final start = DateUtils.firstDayOfWeek(ref, startWeekday: weekStartsOn);
    final base = start.add(Duration(days: weekOffset * 7));
    return DateTime(base.year, base.month, base.day);
  }

  /// Weekday resolution, honoring an optional week anchor.
  ///
  /// - Named future weeks (来週火曜, next week Tuesday) resolve inside
  ///   that calendar week.
  /// - Past anchors (先週金曜, last Friday) resolve to the most recent
  ///   occurrence strictly before the reference.
  /// - Duration anchors (3週間後金曜) resolve as next occurrence plus
  ///   whole weeks.
  DateTime _resolveWeekday(
    int weekday,
    int offset,
    bool calendar,
    int hour,
    int minute,
  ) {
    DateTime base;
    if (calendar && offset >= 0) {
      final start = _weekStart(offset);
      base = start.add(Duration(days: (weekday - weekStartsOn + 7) % 7));
    } else if (offset < 0) {
      var diff = (ref.weekday - weekday + 7) % 7;
      if (diff == 0) diff = 7;
      base = _refDay.subtract(Duration(days: diff + (-offset - 1) * 7));
    } else if (offset == 0) {
      base = DateUtils.nextWeekday(_refDay, weekday);
    } else {
      base = DateUtils.nextWeekday(_refDay, weekday)
          .add(Duration(days: (offset - 1) * 7));
    }
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  DateTime _resolveNthWeekday(NthWeekdayOfMonth nth, int hour, int minute) {
    DateTime compute(int year) {
      if (nth.ordinal < 0) {
        final last = DateTime(year, nth.month + 1, 0);
        final diff = (last.weekday - nth.weekday + 7) % 7;
        return last.subtract(Duration(days: diff));
      }
      final first = DateTime(year, nth.month, 1);
      final toFirst = (nth.weekday - first.weekday + 7) % 7;
      return first.add(Duration(days: toFirst + (nth.ordinal - 1) * 7));
    }

    var date = compute(ref.year);
    if (date.isBefore(ref)) date = compute(ref.year + 1);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static int _adjustedHour(int hour, Meridiem? meridiem) {
    if (meridiem == Meridiem.pm && hour < 12) return hour + 12;
    if (meridiem == Meridiem.am && hour == 12) return 0;
    return hour;
  }
}

/// Flattens an expression's component list into named fields.
class _Fields {
  int? year;
  int? yearAnchor;
  int? month;
  int? monthAnchor;
  int? day;
  int? weekday;
  bool weekend = false;
  int? dayRel;
  int? weekRelOffset;
  bool weekRelCalendar = false;
  bool weekRel = false;
  int? hour;
  int? minute;
  Meridiem? meridiem;
  int? withinDays;
  DateTime? instant;
  NthWeekdayOfMonth? nth;

  void collect(List<DateComponent> components) {
    for (final c in components) {
      switch (c) {
        case YearValue(:final year):
          this.year = year;
        case YearAnchor(:final offset):
          yearAnchor = offset;
        case MonthValue(:final month):
          this.month = month;
        case MonthAnchor(:final offset):
          monthAnchor = offset;
        case DayOfMonth(:final day):
          this.day = day;
        case WeekdayRef(:final weekday):
          this.weekday = weekday;
        case RelativeDay(:final offset):
          dayRel = offset;
        case WeekAnchor(:final offset, :final calendar):
          weekRel = true;
          weekRelOffset = offset;
          weekRelCalendar = calendar;
        case Weekend():
          weekend = true;
        case ClockTime(:final hour, :final minute, :final meridiem):
          this.hour = hour;
          this.minute = minute;
          if (meridiem != null) this.meridiem = meridiem;
        case MeridiemMarker(:final value):
          meridiem = value;
        case WithinDays(:final days):
          withinDays = days;
        case AbsoluteInstant(:final value):
          instant = value;
        case NthWeekdayOfMonth():
          nth = c;
      }
    }
  }
}

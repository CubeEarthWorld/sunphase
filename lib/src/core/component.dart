// lib/src/core/component.dart
//
// The universal semantic vocabulary of date/time expressions.
//
// Every language reduces its surface forms to these components. A
// component answers "what was said" in calendar-neutral terms (e.g.
// `MonthAnchor(+2)` for 再来月 / "in two months"); the resolver later
// decides "what date that means" relative to a reference date.
//
// Each component occupies one or more *slots*. The composer merges
// adjacent components into a single expression only while no slot is
// filled twice, which is what makes composition safe: 来月 + 21日 + 14時
// merge (month + day + time), while 明日 + 昨日 do not (both dayRel).

/// Semantic slots a component can occupy. Used for conflict detection
/// when merging adjacent components.
enum Slot { year, month, day, weekday, time, meridiem, dayRel, weekRel }

/// AM/PM marker semantics (午前/午後, 上午/下午, am/pm, …).
enum Meridiem { am, pm }

/// Base class for all date/time components.
sealed class DateComponent {
  const DateComponent();

  /// The semantic slots this component fills.
  Set<Slot> get slots;

  /// Contribution to an expression's specificity score. Higher-scoring
  /// expressions win overlap resolution.
  int get specificity;
}

/// All slots — used by components that must never merge with anything.
final Set<Slot> _allSlots = Slot.values.toSet();

/// An explicit calendar year: 2025年, "March 14, 2025".
final class YearValue extends DateComponent {
  final int year;
  const YearValue(this.year);
  @override
  Set<Slot> get slots => const {Slot.year};
  @override
  int get specificity => 4;
}

/// A year relative to the reference: 来年 = +1, 再来年 = +2, last year = -1.
final class YearAnchor extends DateComponent {
  final int offset;
  const YearAnchor(this.offset);
  @override
  Set<Slot> get slots => const {Slot.year};
  @override
  int get specificity => 3;
}

/// An explicit month 1–12: 3月, "march", февраля.
final class MonthValue extends DateComponent {
  final int month;
  const MonthValue(this.month);
  @override
  Set<Slot> get slots => const {Slot.month};
  @override
  int get specificity => 3;
}

/// A month relative to the reference: 来月 = +1, 再来月 = +2, 先月 = -1.
final class MonthAnchor extends DateComponent {
  final int offset;
  const MonthAnchor(this.offset);
  @override
  Set<Slot> get slots => const {Slot.month};
  @override
  int get specificity => 3;
}

/// A day of month 1–31: 21日, "the 21st", 15 तारीख.
final class DayOfMonth extends DateComponent {
  final int day;
  const DayOfMonth(this.day);
  @override
  Set<Slot> get slots => const {Slot.day};
  @override
  int get specificity => 3;
}

/// A named weekday, ISO numbering 1 (Monday) – 7 (Sunday).
final class WeekdayRef extends DateComponent {
  final int weekday;
  const WeekdayRef(this.weekday);
  @override
  Set<Slot> get slots => const {Slot.weekday};
  @override
  int get specificity => 3;
}

/// A day relative to the reference: 明日 = +1, "in 3 days" = +3, ayer = -1.
final class RelativeDay extends DateComponent {
  final int offset;
  const RelativeDay(this.offset);
  @override
  Set<Slot> get slots => const {Slot.dayRel};
  @override
  int get specificity => 3;
}

/// A week relative to the reference.
///
/// [calendar] distinguishes *named* weeks (来週, next week — resolved
/// against the configured week start) from *duration* weeks (2週間後,
/// "2 weeks from now" — resolved as `offset × 7` days).
final class WeekAnchor extends DateComponent {
  final int offset;
  final bool calendar;
  const WeekAnchor(this.offset, {required this.calendar});
  @override
  Set<Slot> get slots => const {Slot.weekRel};
  @override
  int get specificity => 3;
}

/// The weekend (週末, 주말): resolves to the next upcoming Sunday.
/// Fills both weekday and weekRel slots so it cannot combine with either.
final class Weekend extends DateComponent {
  const Weekend();
  @override
  Set<Slot> get slots => const {Slot.weekday, Slot.weekRel};
  @override
  int get specificity => 3;
}

/// A clock time. [minute] is null when the expression named only an hour
/// (14時). [meridiem] is set when the marker is fused into the same
/// token ("3pm"); a standalone marker (午後) is a [MeridiemMarker].
final class ClockTime extends DateComponent {
  final int hour;
  final int? minute;
  final Meridiem? meridiem;
  const ClockTime(this.hour, [this.minute, this.meridiem]);
  @override
  Set<Slot> get slots =>
      meridiem == null ? const {Slot.time} : const {Slot.time, Slot.meridiem};
  @override
  int get specificity => 2 + (minute != null ? 1 : 0);
}

/// A standalone AM/PM word (午前, 下午, दोपहर, вечера) that qualifies an
/// adjacent [ClockTime].
final class MeridiemMarker extends DateComponent {
  final Meridiem value;
  const MeridiemMarker(this.value);
  @override
  Set<Slot> get slots => const {Slot.meridiem};
  @override
  int get specificity => 0;
}

/// "Within N days" span (3日以内): expands to N+1 daily results in
/// range mode. Atomic — merges with nothing.
final class WithinDays extends DateComponent {
  final int days;
  const WithinDays(this.days);
  @override
  Set<Slot> get slots => _allSlots;
  @override
  int get specificity => 3;
}

/// A fully specified instant (ISO 8601 and similar machine formats, or
/// fixed easter eggs). Atomic — merges with nothing, resolves to itself.
final class AbsoluteInstant extends DateComponent {
  final DateTime value;
  const AbsoluteInstant(this.value);
  @override
  Set<Slot> get slots => _allSlots;
  @override
  int get specificity => 12;
}

/// "The Nth weekday of a month" (el tercer lunes de marzo).
/// [ordinal] is 1-based; -1 means the last occurrence.
/// Fills the date slots but leaves time open so a time can compose.
final class NthWeekdayOfMonth extends DateComponent {
  final int ordinal;
  final int weekday;
  final int month;
  const NthWeekdayOfMonth({
    required this.ordinal,
    required this.weekday,
    required this.month,
  });
  @override
  Set<Slot> get slots =>
      const {Slot.year, Slot.month, Slot.day, Slot.weekday, Slot.dayRel, Slot.weekRel};
  @override
  int get specificity => 10;
}

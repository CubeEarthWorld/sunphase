// lib/utils/date_utils.dart
//
// Low-level calendar helpers used by the resolver and language patterns.
//
// All methods are pure functions (no mutation, no side effects) and
// operate on `DateTime` objects. They avoid Dart's built-in
// `DateTime.add(Duration(...))` for month/year arithmetic because
// `Duration` works in days and therefore can't correctly represent a
// "one calendar month" shift.

class DateUtils {
  /// Returns [date] unchanged if it is after [reference]; otherwise
  /// returns [date] shifted forward by one day.
  ///
  /// Useful when a bare time expression resolves to a time earlier than
  /// now, so that "10:00" always means the next 10:00.
  static DateTime adjustIfPast(DateTime date, DateTime reference) {
    return date.isBefore(reference) ? date.add(Duration(days: 1)) : date;
  }

  /// Returns a map with the first (`start`) and last (`end`) days of the
  /// month that [date] belongs to.
  static Map<String, DateTime> getMonthRange(DateTime date) {
    DateTime firstDay = firstDayOfMonth(date);
    // `DateTime(year, month + 1, 0)` is the last day of `month` because
    // "day 0 of next month" == "day −1" == last day of current month.
    DateTime lastDay = DateTime(date.year, date.month + 1, 0);
    return {'start': firstDay, 'end': lastDay};
  }

  /// Returns `true` if [s] can be parsed as a `double`.
  static bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  /// Adds [months] calendar months to [date].
  ///
  /// Correctly handles year rollovers. When the resulting month has
  /// fewer days than [date.day], the day is clamped to the last day of
  /// that month (e.g. Jan 31 + 1 month → Feb 28/29).
  static DateTime addMonths(DateTime date, int months) {
    int year = date.year;
    int month = date.month + months;
    while (month > 12) {
      month -= 12;
      year++;
    }
    while (month < 1) {
      month += 12;
      year--;
    }
    int day = date.day;
    int lastDay = getMonthRange(DateTime(year, month, 1))['end']!.day;
    if (day > lastDay) day = lastDay;
    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }

  /// Returns midnight on the first day of the month containing [date].
  static DateTime firstDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Returns midnight on the first day of the month after [date].
  static DateTime firstDayOfNextMonth(DateTime date) =>
      firstDayOfMonth(addMonths(date, 1));

  /// Returns midnight on the first day of the month before [date].
  static DateTime firstDayOfPreviousMonth(DateTime date) =>
      firstDayOfMonth(addMonths(date, -1));

  /// Returns the date of the *next* occurrence of [targetWeekday] after
  /// [date], where 1 = Monday … 7 = Sunday (matching `DateTime.weekday`).
  ///
  /// Never returns [date] itself — if [date] is already the target
  /// weekday the returned value is 7 days later.
  static DateTime nextWeekday(DateTime date, int targetWeekday) {
    int diff = (targetWeekday - date.weekday + 7) % 7;
    if (diff == 0) diff = 7;
    return date.add(Duration(days: diff));
  }

  /// Returns midnight on the Monday that begins the ISO week containing
  /// [date].
  ///
  /// [startWeekday] allows overriding the first day of the week (default
  /// is 1 = Monday).
  static DateTime firstDayOfWeek(DateTime date, {int startWeekday = 1}) {
    return date.subtract(Duration(days: date.weekday - startWeekday));
  }

  /// Returns the next `DateTime` at [hour]:[minute] after [reference].
  ///
  /// If the specified time is still in the future *today* it is returned
  /// for today; otherwise it is returned for tomorrow.
  static DateTime nextOccurrenceTime(
    DateTime reference,
    int hour,
    int minute,
  ) {
    DateTime candidate = DateTime(
      reference.year,
      reference.month,
      reference.day,
      hour,
      minute,
    );
    return candidate.isAfter(reference)
        ? candidate
        : candidate.add(Duration(days: 1));
  }

  /// Builds a `DateTime` by reading the hour and minute from specific
  /// capture groups of [match] and delegates to [nextOccurrenceTime].
  ///
  /// - [hourGroup] : 1-based capture group index for the hour value.
  /// - [minuteGroup]: 1-based capture group index for the minute value,
  ///   or `null` if the pattern doesn't capture minutes.
  /// - [minuteDefault]: fallback minute when [minuteGroup] is `null`.
  static DateTime parseTimeFromMatch(
    RegExpMatch match,
    DateTime reference,
    int hourGroup,
    int? minuteGroup, {
    int minuteDefault = 0,
  }) {
    int hour = int.parse(match.group(hourGroup)!);
    int minute = minuteGroup != null && match.group(minuteGroup) != null
        ? int.parse(match.group(minuteGroup)!)
        : minuteDefault;
    return nextOccurrenceTime(reference, hour, minute);
  }

  /// Tries to parse [dateStr] into a `DateTime` using a small set of
  /// common date formats. Returns `null` on failure.
  ///
  /// Recognised formats:
  /// - `YYYY-MM-DD` / `YYYY/MM/DD`
  /// - `YYYY年MM月DD日`  (Japanese)
  /// - `YYYY年MM月DD号`  (Chinese)
  static DateTime? parseDate(String dateStr, {DateTime? reference}) {
    // ISO-style: 2025-03-07 or 2025/03/07
    final universalPattern = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
    final universalMatch = universalPattern.firstMatch(dateStr);
    if (universalMatch != null) {
      return DateTime(
        int.parse(universalMatch.group(1)!),
        int.parse(universalMatch.group(2)!),
        int.parse(universalMatch.group(3)!),
      );
    }

    // Japanese: 2025年3月7日
    final jaPattern = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日');
    final jaMatch = jaPattern.firstMatch(dateStr);
    if (jaMatch != null) {
      return DateTime(
        int.parse(jaMatch.group(1)!),
        int.parse(jaMatch.group(2)!),
        int.parse(jaMatch.group(3)!),
      );
    }

    // Chinese: 2025年3月7号
    final zhPattern = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})号');
    final zhMatch = zhPattern.firstMatch(dateStr);
    if (zhMatch != null) {
      return DateTime(
        int.parse(zhMatch.group(1)!),
        int.parse(zhMatch.group(2)!),
        int.parse(zhMatch.group(3)!),
      );
    }

    return null;
  }
}

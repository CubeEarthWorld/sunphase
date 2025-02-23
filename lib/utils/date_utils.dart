// lib/utils/date_utils.dart
class DateUtils {
  static DateTime adjustIfPast(DateTime date, DateTime reference) {
    return date.isBefore(reference) ? date.add(Duration(days: 1)) : date;
  }

  static Map<String, DateTime> getMonthRange(DateTime date) {
    DateTime firstDay = firstDayOfMonth(date);
    DateTime lastDay = DateTime(date.year, date.month + 1, 0);
    return {'start': firstDay, 'end': lastDay};
  }

  static bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

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
    if (day > lastDay) {
      day = lastDay;
    }
    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }

  static DateTime firstDayOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  static DateTime firstDayOfNextMonth(DateTime date) => firstDayOfMonth(addMonths(date, 1));

  static DateTime firstDayOfPreviousMonth(DateTime date) => firstDayOfMonth(addMonths(date, -1));

  static DateTime nextWeekday(DateTime date, int targetWeekday) {
    int diff = (targetWeekday - date.weekday + 7) % 7;
    if (diff == 0) diff = 7;
    return date.add(Duration(days: diff));
  }

  static DateTime firstDayOfWeek(DateTime date, {int startWeekday = 1}) {
    return date.subtract(Duration(days: date.weekday - startWeekday));
  }

  static DateTime nextOccurrenceTime(DateTime reference, int hour, int minute) {
    DateTime candidate = DateTime(reference.year, reference.month, reference.day, hour, minute);
    return candidate.isAfter(reference) ? candidate : candidate.add(Duration(days: 1));
  }

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

  static DateTime? parseDate(String dateStr, {DateTime? reference}) {
    DateTime ref = reference ?? DateTime.now();
    final universalPattern =
    RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
    final universalMatch = universalPattern.firstMatch(dateStr);
    if (universalMatch != null) {
      final year = int.parse(universalMatch.group(1)!);
      final month = int.parse(universalMatch.group(2)!);
      final day = int.parse(universalMatch.group(3)!);
      return DateTime(year, month, day);
    }
    final jaPattern = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日');
    final jaMatch = jaPattern.firstMatch(dateStr);
    if (jaMatch != null) {
      final year = int.parse(jaMatch.group(1)!);
      final month = int.parse(jaMatch.group(2)!);
      final day = int.parse(jaMatch.group(3)!);
      return DateTime(year, month, day);
    }
    final zhPattern = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})号');
    final zhMatch = zhPattern.firstMatch(dateStr);
    if (zhMatch != null) {
      final year = int.parse(zhMatch.group(1)!);
      final month = int.parse(zhMatch.group(2)!);
      final day = int.parse(zhMatch.group(3)!);
      return DateTime(year, month, day);
    }
    return null;
  }
}

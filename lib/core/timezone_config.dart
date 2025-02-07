// lib/core/timezone_config.dart

/// TimezoneConfig provides functionality to adjust a DateTime based on a given UTC offset in minutes.
/// TimezoneConfig は、UTCからの分単位オフセットに基づいて DateTime を調整する機能を提供します.
class TimezoneConfig {
  /// Adjusts the given [date] by the specified timezone offset.
  /// If [timezoneOffset] is provided as a string representing the offset in minutes from UTC,
  /// e.g. "540" for UTC+9, the function converts [date] to UTC and adds the offset.
  /// If parsing fails, no adjustment is made.
  ///
  /// 指定された [date] を、[timezoneOffset]（UTCからの分単位オフセット、例："540" は UTC+9）
  /// に従って調整します。内部では [date] を UTC に変換した後、オフセット分を加算します。
  /// パースに失敗した場合は調整せず [date] をそのまま返します.
  static DateTime applyTimezone(DateTime date, String timezoneOffset) {
    // オフセットのパース: 例 "540" -> 540 分
    int offsetMinutes = int.tryParse(timezoneOffset) ?? 0;
    // Convert the date to UTC, then add the offset.
    // date を UTC に変換し、指定された分だけ加算して調整する.
    return date.toUtc().add(Duration(minutes: offsetMinutes));
  }
}

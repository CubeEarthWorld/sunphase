class DateUtils {
  /// [startDate] から 7 日分の DateTime のリストを返す
  static List<DateTime> getWeekDates(DateTime startDate) {
    return List.generate(7, (i) => startDate.add(Duration(days: i)));
  }

/// 必要に応じたその他の日付変換処理を追加可能
}

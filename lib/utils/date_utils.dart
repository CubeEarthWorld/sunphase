/// 日付計算や補正などの共通処理を提供するユーティリティクラス。
class DateUtils {
  /// 指定された [date] が [reference] より過去の場合、翌日などに補正して返す。
  /// ※シンプルな実装として、[date] が過去なら1日加算する。
  static DateTime adjustIfPast(DateTime date, DateTime reference) {
    if (date.isBefore(reference)) {
      return date.add(Duration(days: 1));
    }
    return date;
  }

  /// [date] の属する月の初日と最終日を返す。
  /// 戻り値は {'start': 初日, 'end': 最終日} の形式。
  static Map<String, DateTime> getMonthRange(DateTime date) {
    DateTime firstDay = DateTime(date.year, date.month, 1);
    // 次月の初日から1日引くことで最終日を算出
    DateTime lastDay = DateTime(date.year, date.month + 1, 0);
    return {'start': firstDay, 'end': lastDay};
  }

  /// 文字列中の "hh:mm" 形式の時刻部分を抽出し、与えられた [date] に反映する。
  static DateTime adjustDateTimeWithTime(DateTime date, String text) {
    final timeRegExp = RegExp(r'(\d{1,2}):(\d{2})');
    final timeMatch = timeRegExp.firstMatch(text);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    return date;
  }

  /// [candidate] が [reference] より過去の場合、翌日の日付を返す（そうでなければそのまま）。
  static DateTime getNextOccurrence(DateTime reference, DateTime candidate) {
    return candidate.isBefore(reference)
        ? candidate.add(Duration(days: 1))
        : candidate;
  }

  /// 文字列が数値として有効かどうかを判定する
  static bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }
}

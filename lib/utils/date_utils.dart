// lib/utils/date_utils.dart
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

  /// 文字列が数値として有効かどうかを判定する
  static bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }
}

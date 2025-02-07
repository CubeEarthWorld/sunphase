class TimezoneConfig {
  /// [date] を指定された [timezone] に合わせて調整する。
  /// 例として "JST" → +9 時間、その他の場合は変更なし（必要に応じて拡張）。
  static DateTime applyTimezone(DateTime date, String timezone) {
    if (timezone.toUpperCase() == "JST") {
      return date.toUtc().add(Duration(hours: 9));
    }
    // 他のタイムゾーン処理をここに追加可能
    return date;
  }
}

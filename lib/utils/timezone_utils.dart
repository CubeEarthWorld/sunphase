// lib/utils/timezone_utils.dart
import '../core/result.dart';

/// タイムゾーンのオフセット処理など、タイムゾーン関連の補助関数を提供するクラス。
class TimezoneUtils {
  /// タイムゾーンのオフセット文字列（分単位）を Duration に変換する。
  /// 例："540" → Duration(minutes: 540)
  static Duration offsetFromString(String offsetStr) {
    int minutes = int.tryParse(offsetStr) ?? 0;
    return Duration(minutes: minutes);
  }

  /// 各 [ParsingResult] の日付にタイムゾーンの [offset] を適用する。
  /// ここでは単純に [date] に [offset] を加算する。
  static List<ParsingResult> applyTimezone(List<ParsingResult> results, Duration offset) {
    return results.map((result) {
      DateTime adjusted = result.date.add(offset);
      return ParsingResult(index: result.index, text: result.text, date: adjusted);
    }).toList();
  }
}

// lib/utils/date_utils.dart
import 'dart:core';
import '../core/result.dart';

/// dt が refDate より過去かどうかを判定する
bool isPast(DateTime dt, DateTime refDate) {
  return dt.isBefore(refDate);
}

/// 過ぎた日時の場合、単純に翌日の日付に補正する（例）
ParsedComponents adjustPastDate(ParsedComponents comp, DateTime refDate) {
  DateTime dt = comp.toDateTime(refDate);
  if (dt.isBefore(refDate)) {
    dt = dt.add(Duration(days: 1));
  }
  return ParsedComponents(
    year: dt.year,
    month: dt.month,
    day: dt.day,
    hour: dt.hour,
    minute: dt.minute,
    second: dt.second,
    timezoneOffset: comp.timezoneOffset,
  );
}

/// タイムゾーンオフセット（分）を利用して日時を調整する
DateTime adjustTimezone(DateTime dt, int offsetMinutes) {
  return dt.toUtc().add(Duration(minutes: offsetMinutes));
}

/// refDate から翌週の開始日（同じ曜日の日付）を返す（簡易実装）
DateTime nextWeekStart(DateTime refDate) {
  return refDate.add(Duration(days: 7));
}

/// 指定年・月の日数を返す
int daysInMonth(int year, int month) {
  if (month == 12) {
    return DateTime(year + 1, 1, 0).day;
  }
  return DateTime(year, month + 1, 0).day;
}

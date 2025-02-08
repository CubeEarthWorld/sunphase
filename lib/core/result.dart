// lib/core/result.dart
/// 日付・時刻の各コンポーネントを保持するクラス
class ParsedComponents {
  int? year;
  int? month;
  int? day;
  int? hour;
  int? minute;
  int? second;
  int? timezoneOffset; // 分単位のUTCからのオフセット

  ParsedComponents({
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
    this.timezoneOffset,
  });

  /// コンポーネントから DateTime オブジェクトを生成する。
  /// timezoneOffset が指定されている場合はオフセット分調整する。
  DateTime toDateTime(DateTime reference) {
    int y = year ?? reference.year;
    int m = month ?? reference.month;
    int d = day ?? reference.day;
    int h = hour ?? 0;
    int min = minute ?? 0;
    int sec = second ?? 0;
    DateTime dt = DateTime(y, m, d, h, min, sec);
    if (timezoneOffset != null) {
      // 指定されたオフセット（分単位）をUTC基準に調整する
      dt = dt.toUtc().add(Duration(minutes: timezoneOffset!));
    }
    return dt;
  }

  @override
  String toString() {
    return 'ParsedComponents(year: $year, month: $month, day: $day, hour: $hour, minute: $minute, second: $second, timezoneOffset: $timezoneOffset)';
  }
}

/// 解析結果を保持するクラス
class ParsingResult {
  final int index;
  final String text;
  ParsedComponents start;
  ParsedComponents? end;
  final DateTime refDate;

  ParsingResult({
    required this.index,
    required this.text,
    required this.start,
    this.end,
    required this.refDate,
  });

  /// start のコンポーネントから DateTime を生成
  DateTime get date => start.toDateTime(refDate);

  @override
  String toString() {
    if (end != null) {
      return 'ParsingResult(index: $index, text: "$text", start: $start, end: $end)';
    } else {
      return 'ParsingResult(index: $index, text: "$text", start: $start)';
    }
  }
}

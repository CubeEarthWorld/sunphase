// lib/modes/range_mode.dart
import '../utils/date_utils.dart' as dateUtils;
import '../core/result.dart';

/// rangeMode が true の場合、入力結果を期間として拡張する関数
List<ParsingResult> expandRange(ParsingResult result, DateTime refDate) {
  List<ParsingResult> expandedResults = [];
  if (result.text.toLowerCase().contains('week') ||
      result.text.contains('来週') ||
      result.text.toLowerCase().contains('next week')) {
    DateTime startDate = dateUtils.nextWeekStart(refDate);
    for (int i = 0; i < 7; i++) {
      DateTime day = startDate.add(Duration(days: i));
      ParsedComponents comp = ParsedComponents(
        year: day.year,
        month: day.month,
        day: day.day,
        hour: result.start.hour,
        minute: result.start.minute,
        second: result.start.second,
        timezoneOffset: result.start.timezoneOffset,
      );
      ParsingResult pr = ParsingResult(
          index: result.index,
          text: result.text + " (Day ${i + 1})",
          start: comp,
          refDate: refDate);
      expandedResults.add(pr);
    }
  } else if (result.text.toLowerCase().contains('month') ||
      result.text.contains('来月') ||
      result.text.toLowerCase().contains('next month')) {
    DateTime firstDay = DateTime(refDate.year, refDate.month + 1, 1);
    int days = dateUtils.daysInMonth(firstDay.year, firstDay.month);
    for (int i = 0; i < days; i++) {
      DateTime day = firstDay.add(Duration(days: i));
      ParsedComponents comp = ParsedComponents(
        year: day.year,
        month: day.month,
        day: day.day,
        hour: result.start.hour,
        minute: result.start.minute,
        second: result.start.second,
        timezoneOffset: result.start.timezoneOffset,
      );
      ParsingResult pr = ParsingResult(
          index: result.index,
          text: result.text + " (Day ${i + 1})",
          start: comp,
          refDate: refDate);
      expandedResults.add(pr);
    }
  } else {
    expandedResults.add(result);
  }
  return expandedResults;
}

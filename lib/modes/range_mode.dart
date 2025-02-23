// lib/modes/range_mode.dart
import '../core/result.dart';
import '../core/parsing_context.dart';

class RangeMode {
  static List<ParsingResult> generate(List<ParsingResult> results, ParsingContext context) {
    List<ParsingResult> expanded = [];
    for (var result in results) {
      if (result.rangeDays != null) {
        for (int i = 0; i < result.rangeDays!; i++) {
          DateTime d = result.date.add(Duration(days: i));
          expanded.add(ParsingResult(index: result.index, text: result.text, date: d));
        }
      } else if (result.rangeType != null) {
        if (result.rangeType == "week") {
          for (int i = 0; i < 7; i++) {
            DateTime d = result.date.add(Duration(days: i));
            expanded.add(ParsingResult(index: result.index, text: result.text, date: d));
          }
        } else if (result.rangeType == "month") {
          DateTime first = result.date;
          DateTime last = DateTime(first.year, first.month + 1, 0);
          int totalDays = last.day;
          for (int i = 0; i < totalDays; i++) {
            DateTime d = first.add(Duration(days: i));
            expanded.add(ParsingResult(index: result.index, text: result.text, date: d));
          }
        } else {
          expanded.add(result);
        }
      } else {
        expanded.add(result);
      }
    }
    return expanded;
  }
}

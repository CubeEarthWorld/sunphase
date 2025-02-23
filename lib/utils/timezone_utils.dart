// lib/utils/timezone_utils.dart
import '../core/result.dart';

class TimezoneUtils {
  static Duration offsetFromString(String offsetStr) {
    int minutes = int.tryParse(offsetStr) ?? 0;
    return Duration(minutes: minutes);
  }

  static List<ParsingResult> applyTimezone(List<ParsingResult> results, Duration offset) {
    return results.map((result) {
      DateTime adjusted = result.date.add(offset);
      return ParsingResult(index: result.index, text: result.text, date: adjusted);
    }).toList();
  }
}

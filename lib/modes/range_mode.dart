// lib/modes/range_mode.dart
import '../core/result.dart';

class RangeMode {
  /// 入力テキストが「範囲指定」専用の場合のみレンジ展開を行います。
  /// たとえば "来週" や "2月"、"去年" といった入力の場合は、
  /// それぞれ1週間分、対象月の全日、対象年の全日分に展開します。
  /// ※ 時刻情報が含まれている場合は、その時刻も各展開結果にセットされます。
  static List<ParsingResult> applyRangeMode(
      List<ParsingResult> results, DateTime referenceDate) {
    List<ParsingResult> expandedResults = [];

    for (var result in results) {
      // ここでは、入力テキストが「純粋な範囲指定」であるかをチェックします。
      if (_isRangeExpression(result.text)) {
        // 週レンジの場合
        if (_isWeekRange(result.text)) {
          for (int i = 0; i < 7; i++) {
            DateTime newDate =
            result.component.date.add(Duration(days: i));
            expandedResults.add(
              ParsingResult(
                index: result.index,
                text: result.text,
                component: result.component.copyWith(date: newDate),
              ),
            );
          }
        }
        // 月レンジの場合（対象月の日数で展開）
        else if (_isMonthRange(result.text)) {
          int year = result.component.date.year;
          int month = result.component.date.month;
          int daysInMonth = DateTime(year, month + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            DateTime newDate = DateTime(year, month, day,
                result.component.date.hour,
                result.component.date.minute);
            expandedResults.add(
              ParsingResult(
                index: result.index,
                text: result.text,
                component: result.component.copyWith(date: newDate),
              ),
            );
          }
        }
        // 年レンジの場合（対象年の全日分）
        else if (_isYearRange(result.text)) {
          int year = result.component.date.year;
          for (int month = 1; month <= 12; month++) {
            int daysInMonth = DateTime(year, month + 1, 0).day;
            for (int day = 1; day <= daysInMonth; day++) {
              DateTime newDate = DateTime(year, month, day,
                  result.component.date.hour,
                  result.component.date.minute);
              expandedResults.add(
                ParsingResult(
                  index: result.index,
                  text: result.text,
                  component: result.component.copyWith(date: newDate),
                ),
              );
            }
          }
        } else {
          // それ以外の範囲指定（念のためそのまま追加）
          expandedResults.add(result);
        }
      } else {
        // 範囲指定でない場合はそのまま返す
        expandedResults.add(result);
      }
    }

    return expandedResults;
  }

  /// 入力テキストが「純粋な範囲指定」かを判定します。
  /// 例: "2月", "来週", "去年" など。
  static bool _isRangeExpression(String text) {
    return RegExp(r'^\s*(\d{1,2}月|来週|上週|今週|下个月|上个月|这个月|明年|去年|今年)\s*$')
        .hasMatch(text);
  }

  static bool _isWeekRange(String text) {
    return RegExp(r'^\s*(来週|上週|今週)\s*$').hasMatch(text);
  }

  static bool _isMonthRange(String text) {
    return RegExp(r'^\s*(\d{1,2}月|下个月|上个月|这个月)\s*$').hasMatch(text);
  }

  static bool _isYearRange(String text) {
    return RegExp(r'^\s*(明年|去年|今年)\s*$').hasMatch(text);
  }
}

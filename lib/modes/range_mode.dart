// lib/modes/range_mode.dart
import '../core/result.dart';

class RangeMode {
  /// 入力テキストが「純粋な範囲指定」専用の場合のみレンジ展開を行います。
  /// 例えば、"2月" と入力された場合は、最も近い将来の該当月の1日から最終日まで、
  /// "来年" と入力された場合は、来年の1月1日から12月31日までを展開します。
  static List<ParsingResult> applyRangeMode(
      List<ParsingResult> results, DateTime referenceDate) {
    List<ParsingResult> expandedResults = [];

    for (var result in results) {
      if (_isRangeExpression(result.text)) {
        // 週レンジの場合は、その基準日から連続7日を展開
        if (_isWeekRange(result.text)) {
          for (int i = 0; i < 7; i++) {
            DateTime newDate = result.component.date.add(Duration(days: i));
            expandedResults.add(
              ParsingResult(
                index: result.index,
                text: result.text,
                component: result.component.copyWith(date: newDate),
              ),
            );
          }
        }
        // 月レンジの場合
        else if (_isMonthRange(result.text)) {
          // 入力が純粋な月指定（例："2月"）の場合、最も近い将来の該当月を選択
          RegExp monthExpr = RegExp(r'^\s*(\d{1,2})月\s*$');
          if (monthExpr.hasMatch(result.text)) {
            var match = monthExpr.firstMatch(result.text)!;
            int month = int.parse(match.group(1)!);
            int year;
            // もし現在の月が指定月より前なら今年、そうでなければ来年を採用
            if (referenceDate.month < month) {
              year = referenceDate.year;
            } else {
              year = referenceDate.year + 1;
            }
            int daysInMonth = DateTime(year, month + 1, 0).day;
            for (int day = 1; day <= daysInMonth; day++) {
              DateTime newDate = DateTime(
                year,
                month,
                day,
                result.component.date.hour,
                result.component.date.minute,
              );
              expandedResults.add(
                ParsingResult(
                  index: result.index,
                  text: result.text,
                  component: result.component.copyWith(date: newDate),
                ),
              );
            }
          } else {
            // それ以外の場合は、解析結果に含まれる月情報をそのまま利用
            int year = result.component.date.year;
            int month = result.component.date.month;
            int daysInMonth = DateTime(year, month + 1, 0).day;
            for (int day = 1; day <= daysInMonth; day++) {
              DateTime newDate = DateTime(
                year,
                month,
                day,
                result.component.date.hour,
                result.component.date.minute,
              );
              expandedResults.add(
                ParsingResult(
                  index: result.index,
                  text: result.text,
                  component: result.component.copyWith(date: newDate),
                ),
              );
            }
          }
        }
        // 年レンジの場合
        else if (_isYearRange(result.text)) {
          RegExp yearExpr = RegExp(r'^\s*(明年|去年|今年)\s*$');
          if (yearExpr.hasMatch(result.text)) {
            String period = result.text.trim();
            int baseYear;
            if (period == "明年") {
              baseYear = referenceDate.year + 1;
            } else if (period == "去年") {
              baseYear = referenceDate.year - 1;
            } else { // "今年"
              baseYear = referenceDate.year;
            }
            // 展開はその年の全日分（1月1日～12月31日）
            for (int month = 1; month <= 12; month++) {
              int daysInMonth = DateTime(baseYear, month + 1, 0).day;
              for (int day = 1; day <= daysInMonth; day++) {
                DateTime newDate = DateTime(
                  baseYear,
                  month,
                  day,
                  result.component.date.hour,
                  result.component.date.minute,
                );
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
            // それ以外の場合は、解析結果にある年情報をそのまま利用
            int year = result.component.date.year;
            for (int month = 1; month <= 12; month++) {
              int daysInMonth = DateTime(year, month + 1, 0).day;
              for (int day = 1; day <= daysInMonth; day++) {
                DateTime newDate = DateTime(
                  year,
                  month,
                  day,
                  result.component.date.hour,
                  result.component.date.minute,
                );
                expandedResults.add(
                  ParsingResult(
                    index: result.index,
                    text: result.text,
                    component: result.component.copyWith(date: newDate),
                  ),
                );
              }
            }
          }
        } else {
          expandedResults.add(result);
        }
      } else {
        expandedResults.add(result);
      }
    }

    return expandedResults;
  }

  /// 入力テキストが「純粋な範囲指定」かどうかを判定します。
  static bool _isRangeExpression(String text) {
    return RegExp(
        r'^\s*(\d{1,2}月|来週|上週|今週|下个月|上个月|这个月|明年|去年|今年)\s*$'
    ).hasMatch(text);
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

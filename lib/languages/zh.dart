// lib/language/zh.dart
import '../core/parser.dart';
import '../core/result.dart';

/// 中国語表現に対応するパーサー実装例
class ChineseDateParser implements Parser {
  // 「今天」「明天」「昨天」「现在」
  final RegExp relativePattern = RegExp(r'\b(今天|明天|昨天|现在|目前)\b');
  // 時刻のみ (例："4:12" また是 "4点12分")
  final RegExp timeOnlyPattern = RegExp(r'\b(\d{1,2})(?::|点)(\d{1,2})(?:分)?\b');
  // ISO形式（例："2024-02-24", "2042/4/1", "2012-4-4 12:31"）
  final RegExp isoPattern = RegExp(
      r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})(?::|点)(\d{1,2})(?::(\d{1,2})秒?)?)?');
  // 月日だけ (例："6/27", "3/14")
  final RegExp monthDayPattern = RegExp(r'\b(\d{1,2})[/-](\d{1,2})\b');
  // 相对表达式（例如："下周", "上周", "周末", "两周前", "3周后", "四天后"）
  final RegExp relativeDurationPattern = RegExp(
      r'\b(下周|上周|本周|周末|两周前|[零一二三四五六七八九十\d]+周后|[零一二三四五六七八九十\d]+天后|[零一二三四五六七八九十\d]+天前)\b');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // ① 基本相对表达式
    var match = relativePattern.firstMatch(text);
    if (match != null) {
      String word = match.group(1)!;
      ParsedComponents comp;
      if (word == '现在' || word == '目前') {
        comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: referenceDate.hour,
          minute: referenceDate.minute,
          second: referenceDate.second,
        );
      } else if (word == '今天') {
        comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else if (word == '明天') {
        DateTime dt = referenceDate.add(Duration(days: 1));
        comp = ParsedComponents(
          year: dt.year,
          month: dt.month,
          day: dt.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else if (word == '昨天') {
        DateTime dt = referenceDate.subtract(Duration(days: 1));
        comp = ParsedComponents(
          year: dt.year,
          month: dt.month,
          day: dt.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else {
        return null;
      }
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // ② 時刻のみ的表达式 (例如："4:12" 或 "4点12分")
    match = timeOnlyPattern.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: hour,
          minute: minute,
          second: 0);
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // ③ ISO形式的表达
    match = isoPattern.firstMatch(text);
    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      int second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: year, month: month, day: day, hour: hour, minute: minute, second: second);
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // ④ 月日只表达 (例如："6/27", "3/14")，缺少年份时补当前年
    match = monthDayPattern.firstMatch(text);
    if (match != null) {
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: month,
          day: day,
          hour: 0,
          minute: 0,
          second: 0);
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // ⑤ 相对表达式 (例如："下周", "上周", "周末", "两周前", "3周后", "四天后")
    match = relativeDurationPattern.firstMatch(text);
    if (match != null) {
      String expr = match.group(0)!;
      ParsedComponents comp;
      if (expr.contains('下周')) {
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day + 7,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('上周')) {
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day - 7,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('本周') || expr.contains('周末')) {
        // "周末"の場合は週末（例: 土曜日）を返す（簡易実装：ここでは週末として referenceDate の週の土曜日を補完）
        int diff = (6 - referenceDate.weekday) % 7;
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day + diff,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('两周前')) {
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day - 14,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('周后')) {
        // 例如："3周后"
        RegExp numExp = RegExp(r'(\d+)');
        var m = numExp.firstMatch(expr);
        int n = m != null ? int.parse(m.group(1)!) : 0;
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day + n * 7,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('天后')) {
        RegExp numExp = RegExp(r'(\d+)');
        var m = numExp.firstMatch(expr);
        int n = m != null ? int.parse(m.group(1)!) : 0;
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day + n,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('天前')) {
        RegExp numExp = RegExp(r'(\d+)');
        var m = numExp.firstMatch(expr);
        int n = m != null ? int.parse(m.group(1)!) : 0;
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day - n,
            hour: 0,
            minute: 0,
            second: 0);
      } else {
        return null;
      }
      return ParsingResult(
          index: match.start, text: expr, start: comp, refDate: referenceDate);
    }
    return null;
  }
}

/// 中国語用パーサー列表
List<Parser> parsers = [
  ChineseDateParser(),
];

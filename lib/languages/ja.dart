// lib/language/ja.dart
import '../core/parser.dart';
import '../core/result.dart';

/// 日本語表現に対応するパーサー実装例
class JapaneseDateParser implements Parser {
  // 「今日」「明日」「昨日」「今」
  final RegExp relativePattern = RegExp(r'\b(今日|明日|昨日|今(すぐ)?|現在)\b');
  // 時刻のみ (例："4:12" または "4時12分")
  final RegExp timeOnlyPattern = RegExp(r'\b(\d{1,2})(?::|時)(\d{1,2})(?:分)?\b');
  // ISO形式（例："2012-4-4 12:31", "2024/02/24"）
  final RegExp isoPattern = RegExp(
      r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})[:時](\d{1,2})(?:[:分](\d{1,2})秒?)?)?');
  // 月日だけ（例："4/27"、"04/27"）
  final RegExp monthDayPattern = RegExp(r'\b(\d{1,2})[/-](\d{1,2})\b');
  // 相対表現（例："来週", "来月", "3週間後", "四日後"）
  final RegExp relativeDurationPattern = RegExp(
      r'\b(来週|先週|今週|来月|先月|(\d+|一|二|三|四|五|六|七|八|九|十)[日天]後|(\d+|一|二|三|四|五|六|七|八|九|十)[日天]前|(\d+|一|二|三|四|五|六|七|八|九|十)週間後)\b');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // ① 基本相対表現
    var match = relativePattern.firstMatch(text);
    if (match != null) {
      String word = match.group(1)!;
      ParsedComponents comp;
      if (word == '今' || word.startsWith('現在') || word == '今すぐ') {
        comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: referenceDate.hour,
          minute: referenceDate.minute,
          second: referenceDate.second,
        );
      } else if (word == '今日') {
        comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else if (word == '明日') {
        DateTime dt = referenceDate.add(Duration(days: 1));
        comp = ParsedComponents(
          year: dt.year,
          month: dt.month,
          day: dt.day,
          hour: 0,
          minute: 0,
          second: 0,
        );
      } else if (word == '昨日') {
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

    // ② 時刻のみの表現 (例："4:12" または "4時12分")
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

    // ③ ISO形式の表現
    match = isoPattern.firstMatch(text);
    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      int second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
      ParsedComponents comp = ParsedComponents(
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
          second: second);
      return ParsingResult(
          index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // ④ 月日だけの表現 (例："4/27")
    match = monthDayPattern.firstMatch(text);
    if (match != null) {
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      // 補完：年は現在年
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

    // ⑤ 相対表現 (例："来週", "来月", "3週間後", "四日後")
    match = relativeDurationPattern.firstMatch(text);
    if (match != null) {
      String expr = match.group(0)!;
      ParsedComponents comp;
      // 簡易実装: 「来週」→+7日、「先週」→-7日、「来月」→+30日、「先月」→-30日
      if (expr.contains('来週')) {
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day + 7,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('先週')) {
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day - 7,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('今週')) {
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('来月')) {
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month + 1,
            day: 1,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('先月')) {
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month - 1,
            day: 1,
            hour: 0,
            minute: 0,
            second: 0);
      } else if (expr.contains('week')) {
        // 英語の場合: "next week", "two weeks ago"など
        int offset = 0;
        if (expr.toLowerCase().contains('next')) {
          offset = 7;
        } else if (expr.toLowerCase().contains('last') || expr.toLowerCase().contains('ago')) {
          offset = -7;
        }
        comp = ParsedComponents(
            year: referenceDate.year,
            month: referenceDate.month,
            day: referenceDate.day + offset,
            hour: 0,
            minute: 0,
            second: 0);
      } else {
        // 数字＋「日後」や「日後」
        RegExp relNum = RegExp(r'(\d+|一|二|三|四|五|六|七|八|九|十)');
        var numMatch = relNum.firstMatch(expr);
        int num = numMatch != null ? int.tryParse(numMatch.group(0)!) ?? 0 : 0;
        if (expr.contains('日後') || expr.contains('天後')) {
          comp = ParsedComponents(
              year: referenceDate.year,
              month: referenceDate.month,
              day: referenceDate.day + num,
              hour: 0,
              minute: 0,
              second: 0);
        } else {
          // ここでは他の表現は未対応とする
          return null;
        }
      }
      return ParsingResult(
          index: match.start, text: expr, start: comp, refDate: referenceDate);
    }
    return null;
  }
}

/// 日本語用パーサーリスト
List<Parser> parsers = [
  JapaneseDateParser(),
];

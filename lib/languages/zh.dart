// lib/language/zh.dart
import '../core/parser.dart';
import '../core/result.dart';

class ChineseDateParser implements Parser {
  // 1. 相对表达: "今天", "明天", "昨天", "现在"
  final RegExp relativePattern = RegExp(r'\b(今天|明天|昨天|现在)\b');
  // 2. 相对表达＋时刻: "明天12时30分" 等
  final RegExp relativeWithTimePattern = RegExp(r'\b(今天|明天|昨天|现在)\s*(\d{1,2})[时:]\s*(\d{1,2})?[分]?\b');
  // 3. 数字形式日期（年有）："2024-02-24", "2042/4/1", "2012-4-4 12:31"
  final RegExp isoPattern = RegExp(
      r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})[时:](\d{1,2})(?::(\d{1,2})秒?)?)?\b');
  // 4. 时刻仅："4:12", "4时12分"
  final RegExp timeOnlyPattern = RegExp(
      r'\b(\d{1,2})(?::(\d{1,2}))?\s*(?:[时]\s*(\d{1,2})[分]?)\b');
  // 5. 间隔表达："下周", "下个月", "周末", "两周前", "三周后", "4天后"
  final RegExp intervalPattern = RegExp(
      r'\b(下周|下个月|周末|(\d+|一|二|三|四|五|六|七|八|九|十)周[前后]|(\d+|一|二|三|四|五|六|七|八|九|十)天后)\b');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // (1) 相对表达＋时刻："明天12时30分"
    var match = relativeWithTimePattern.firstMatch(text);
    if (match != null) {
      String rel = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      DateTime base;
      if (rel == '今天' || rel == '现在') base = referenceDate;
      else if (rel == '明天') base = referenceDate.add(Duration(days: 1));
      else if (rel == '昨天') base = referenceDate.subtract(Duration(days: 1));
      else base = referenceDate;
      ParsedComponents comp = ParsedComponents(
          year: base.year, month: base.month, day: base.day, hour: hour, minute: minute, second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (2) 相对表达："今天", "明天", "昨天", "现在"
    match = relativePattern.firstMatch(text);
    if (match != null) {
      String word = match.group(1)!;
      DateTime dt;
      if (word == '今天' || word == '现在') dt = referenceDate;
      else if (word == '明天') dt = referenceDate.add(Duration(days: 1));
      else if (word == '昨天') dt = referenceDate.subtract(Duration(days: 1));
      else dt = referenceDate;
      ParsedComponents comp = ParsedComponents(
          year: dt.year, month: dt.month, day: dt.day, hour: 0, minute: 0, second: 0);
      return ParsingResult(index: match.start, text: word, start: comp, refDate: referenceDate);
    }

    // (3) ISO pattern
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
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (4) 时刻仅："4:12", "4时12分"
    match = timeOnlyPattern.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      if (match.group(3) != null) {
        minute = int.parse(match.group(3)!);
      }
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: hour,
          minute: minute,
          second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (5) 间隔表达："下周", "下个月", "周末", "两周前", "三周后", "4天后"
    match = intervalPattern.firstMatch(text);
    if (match != null) {
      String expr = match.group(0)!;
      DateTime dt = referenceDate;
      if (expr.contains('下周')) {
        dt = referenceDate.add(Duration(days: 7));
      } else if (expr.contains('下个月')) {
        dt = DateTime(referenceDate.year, referenceDate.month + 1, referenceDate.day);
      } else if (expr.contains('周末')) {
        int diff = (6 - referenceDate.weekday) % 7;
        dt = referenceDate.add(Duration(days: diff));
      } else if (expr.contains('周')) {
        RegExp numPattern = RegExp(r'(\d+|一|二|三|四|五|六|七|八|九|十)');
        var numMatch = numPattern.firstMatch(expr);
        int weeks = numMatch != null ? (int.tryParse(numMatch.group(0)!) ?? _kanjiToInt(numMatch.group(0)!)) : 1;
        dt = referenceDate.add(Duration(days: 7 * weeks));
      } else if (expr.contains('天后')) {
        RegExp numPattern = RegExp(r'(\d+|一|二|三|四|五|六|七|八|九|十)');
        var numMatch = numPattern.firstMatch(expr);
        int days = numMatch != null ? (int.tryParse(numMatch.group(0)!) ?? _kanjiToInt(numMatch.group(0)!)) : 1;
        dt = referenceDate.add(Duration(days: days));
      }
      ParsedComponents comp = ParsedComponents(
          year: dt.year,
          month: dt.month,
          day: dt.day,
          hour: dt.hour,
          minute: dt.minute,
          second: dt.second);
      return ParsingResult(index: match.start, text: expr, start: comp, refDate: referenceDate);
    }

    return null;
  }

  int _kanjiToInt(String kanji) {
    switch (kanji) {
      case '一': return 1;
      case '二': return 2;
      case '三': return 3;
      case '四': return 4;
      case '五': return 5;
      case '六': return 6;
      case '七': return 7;
      case '八': return 8;
      case '九': return 9;
      case '十': return 10;
      default: return 1;
    }
  }
}

/// 中国語用パーサーリスト
List<Parser> parsers = [
  ChineseDateParser(),
];

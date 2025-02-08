// lib/language/ja.dart
import '../core/parser.dart';
import '../core/result.dart';

class JapaneseDateParser implements Parser {
  // 1. 相対表現単体："今日", "明日", "昨日", "今"
  final RegExp relativePattern = RegExp(r'\b(今日|明日|昨日|今)\b');
  // 2. 相対表現＋時刻："明日12時41", "今日 3時", "昨日 9時30分"
  final RegExp relativeWithTimePattern = RegExp(r'\b(今日|明日|昨日|今)\s*(\d{1,2})時(?:\s*(\d{1,2})分)?\b');
  // 3. ISO形式・数字形式（年あり）："2012-4-4 12:31", "2024/02/24"
  final RegExp isoPattern = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2})(?::|時)(\d{1,2})(?::(\d{1,2})秒?)?)?\b');
  // 4. 時刻のみ："4:12", "4時12分"
  final RegExp timeOnlyPattern = RegExp(r'\b(\d{1,2})(?::(\d{1,2}))?\s*(?:時(?:\s*(\d{1,2})分)?)\b');
  // 5. 間隔表現："来週", "来月", "週末", "3週間後", "四日後"
  final RegExp intervalPattern = RegExp(
      r'\b(来週|来月|週末|(\d+|一|二|三|四|五|六|七|八|九|十)週間後|(\d+|一|二|三|四|五|六|七|八|九|十)日後)\b');

  @override
  ParsingResult? parse(String text, DateTime referenceDate,
      {bool rangeMode = false, bool strict = false, String? timezone}) {
    // (1) 相対表現＋時刻："明日12時41"
    var match = relativeWithTimePattern.firstMatch(text);
    if (match != null) {
      String rel = match.group(1)!;
      int hour = int.parse(match.group(2)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      DateTime base;
      if (rel == '今日' || rel == '今') base = referenceDate;
      else if (rel == '明日') base = referenceDate.add(Duration(days: 1));
      else if (rel == '昨日') base = referenceDate.subtract(Duration(days: 1));
      else base = referenceDate;
      ParsedComponents comp = ParsedComponents(
          year: base.year,
          month: base.month,
          day: base.day,
          hour: hour,
          minute: minute,
          second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (2) 相対表現単体："今日", "明日", "昨日", "今"
    match = relativePattern.firstMatch(text);
    if (match != null) {
      String word = match.group(1)!;
      DateTime dt;
      if (word == '今日' || word == '今') dt = referenceDate;
      else if (word == '明日') dt = referenceDate.add(Duration(days: 1));
      else if (word == '昨日') dt = referenceDate.subtract(Duration(days: 1));
      else dt = referenceDate;
      ParsedComponents comp = ParsedComponents(
          year: dt.year, month: dt.month, day: dt.day, hour: 0, minute: 0, second: 0);
      return ParsingResult(index: match.start, text: word, start: comp, refDate: referenceDate);
    }

    // (3) ISO/数字形式（年あり）："2012-4-4 12:31", "2024/02/24"
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

    // (4) 時刻のみ："4:12", "4時12分"
    match = timeOnlyPattern.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      // group(3)があればそれが分とみなす（通常は存在するので上記で補完済み）
      ParsedComponents comp = ParsedComponents(
          year: referenceDate.year,
          month: referenceDate.month,
          day: referenceDate.day,
          hour: hour,
          minute: minute,
          second: 0);
      return ParsingResult(index: match.start, text: match.group(0)!, start: comp, refDate: referenceDate);
    }

    // (5) 間隔表現："来週", "来月", "週末", "3週間後", "四日後"
    match = intervalPattern.firstMatch(text);
    if (match != null) {
      String expr = match.group(0)!;
      DateTime dt = referenceDate;
      if (expr.contains('来週')) {
        dt = referenceDate.add(Duration(days: 7));
      } else if (expr.contains('来月')) {
        dt = DateTime(referenceDate.year, referenceDate.month + 1, referenceDate.day);
      } else if (expr.contains('週末')) {
        int diff = (6 - referenceDate.weekday) % 7;
        dt = referenceDate.add(Duration(days: diff));
      } else if (expr.contains('週間後')) {
        RegExp numPattern = RegExp(r'(\d+|一|二|三|四|五|六|七|八|九|十)');
        var numMatch = numPattern.firstMatch(expr);
        int weeks = numMatch != null
            ? (int.tryParse(numMatch.group(0)!) ?? _kanjiToInt(numMatch.group(0)!))
            : 1;
        dt = referenceDate.add(Duration(days: 7 * weeks));
      } else if (expr.contains('日後')) {
        RegExp numPattern = RegExp(r'(\d+|一|二|三|四|五|六|七|八|九|十)');
        var numMatch = numPattern.firstMatch(expr);
        int days = numMatch != null
            ? (int.tryParse(numMatch.group(0)!) ?? _kanjiToInt(numMatch.group(0)!))
            : 1;
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

/// 日本語用パーサーリスト
List<Parser> parsers = [
  JapaneseDateParser(),
];

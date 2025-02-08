// lib/languages/universal.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';

/// 言語に依存しない、ISO形式や一般的な日付表現に対応するパーサー。
class UniversalParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // ISO 8601 形式 (例: "2014-11-30T08:15:30-05:30") の検出
    RegExp isoExp = RegExp(
        r'\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+\-]\d{2}:?\d{2})?');
    Iterable<RegExpMatch> isoMatches = isoExp.allMatches(text);
    for (var match in isoMatches) {
      String dateStr = match.group(0)!;
      try {
        DateTime dt = DateTime.parse(dateStr);
        results.add(ParsingResult(index: match.start, text: dateStr, date: dt));
      } catch (e) {
        // パースエラーの場合は無視
      }
    }
    // 別形式 (例: "Sat Aug 17 2013 18:40:39 GMT+0900 (JST)") の検出
    RegExp altExp = RegExp(r'\w{3}\s+\w{3}\s+\d{1,2}\s+\d{4}\s+\d{2}:\d{2}:\d{2}\s+GMT[+\-]\d{4}');
    Iterable<RegExpMatch> altMatches = altExp.allMatches(text);
    for (var match in altMatches) {
      String dateStr = match.group(0)!;
      try {
        DateTime dt = DateTime.parse(dateStr);
        results.add(ParsingResult(index: match.start, text: dateStr, date: dt));
      } catch (e) {
        // エラー無視
      }
    }
    return results;
  }
}

/// 言語に依存しないパーサー群をまとめたクラス。
class UniversalParsers {
  static final List<BaseParser> parsers = [
    UniversalParser(),
  ];
}

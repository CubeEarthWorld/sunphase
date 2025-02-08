// lib/languages/not_language.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// 非言語（数値や記号のみ）の日付／時刻表現を解析するパーサー
class NonLanguage implements Language {
  @override
  String get code => 'not_language';

  @override
  List<Parser> get parsers => [NonLanguageDateTimeParser()];

  @override
  List<Refiner> get refiners => [];
}

/// 数値や記号のみのパターンから日付・時刻情報を抽出する実装例。
class NonLanguageDateTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ① フル数字形式：YYYY/MM/DD または YYYY-MM-DD　（オプションで "HH:MM"）
    RegExp fullNumericDateTime = RegExp(
        r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})(?:[ T]+(\d{1,2}):(\d{2}))?\b'
    );
    for (final match in fullNumericDateTime.allMatches(text)) {
      int year   = int.parse(match.group(1)!);
      int month  = int.parse(match.group(2)!);
      int day    = int.parse(match.group(3)!);
      int hour   = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      DateTime dt = DateTime(year, month, day, hour, minute);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: dt),
      ));
    }

    // ② 日本語／中国語スタイルの絶対日付：例 "2024年4月1日"（オプションで "16時31分"）
    RegExp fullJPDateTime = RegExp(
        r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})時(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in fullJPDateTime.allMatches(text)) {
      if (match.group(2) == null) continue;
      int year   = match.group(1) != null ? int.parse(match.group(1)!) : referenceDate.year;
      int month  = int.parse(match.group(2)!);
      int day    = int.parse(match.group(3)!);
      int hour   = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      DateTime dt = DateTime(year, month, day, hour, minute);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: dt),
      ));
    }

    // ③ 日付のみ（年なし）：例 "5/6" → 現在の年を用い、もし過ぎていれば翌年を採用
    RegExp mdPattern = RegExp(r'\b(\d{1,2})/(\d{1,2})(?!/)\b');
    for (final match in mdPattern.allMatches(text)) {
      int month = int.parse(match.group(1)!);
      int day   = int.parse(match.group(2)!);
      DateTime candidate = DateTime(referenceDate.year, month, day, 0, 0);
      if (!candidate.isAfter(referenceDate)) {
        candidate = DateTime(referenceDate.year + 1, month, day, 0, 0);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ④ 時刻のみ（数字コロン形式）：例 "16:31" → 参照日の時刻として、もし過ぎていれば翌日
    RegExp timeOnlyNumeric = RegExp(r'\b(\d{1,2}):(\d{2})\b');
    for (final match in timeOnlyNumeric.allMatches(text)) {
      int hour   = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      DateTime candidate = DateTime(
          referenceDate.year, referenceDate.month, referenceDate.day, hour, minute
      );
      if (!candidate.isAfter(referenceDate)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ⑤ 時刻のみ（日本語／中国語スタイル）：例 "16時24分" または "16時" → 同様に最も近い将来の時刻を返す
    RegExp timeOnlyJP = RegExp(r'\b(\d{1,2})時(?:\s*(\d{1,2})分)?\b');
    for (final match in timeOnlyJP.allMatches(text)) {
      int hour   = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      DateTime candidate = DateTime(
          referenceDate.year, referenceDate.month, referenceDate.day, hour, minute
      );
      if (!candidate.isAfter(referenceDate)) {
        candidate = candidate.add(Duration(days: 1));
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    return results;
  }
}

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
  List<Refiner> get refiners => []; // 個別の統合処理は不要
}

class NonLanguageDateTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ① フル数字形式: YYYY/MM/DD または YYYY-MM-DD （オプションで "HH:MM"）
    RegExp fullNumeric = RegExp(
        r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})(?:[ T]+(\d{1,2}):(\d{2}))?'
    );
    for (final match in fullNumeric.allMatches(text)) {
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

    // ② 日本語／中国語スタイルの絶対日付: "YYYY年M月D日"（オプションで "H時M分"）
    RegExp jpDate = RegExp(
        r'(?:(\d{1,4})年)?(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})時(?:\s*(\d{1,2})分)?)?'
    );
    for (final match in jpDate.allMatches(text)) {
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

    // ③ 日付のみ（年なし）："M/D" 形式（将来の日付を採用）
    RegExp mdPattern = RegExp(r'(\d{1,2})/(\d{1,2})(?![0-9])');
    for (final match in mdPattern.allMatches(text)) {
      int month = int.parse(match.group(1)!);
      int day   = int.parse(match.group(2)!);
      DateTime candidate = DateTime(referenceDate.year, month, day);
      if (!candidate.isAfter(referenceDate)) {
        candidate = DateTime(referenceDate.year + 1, month, day);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ④ 時刻のみ（数字コロン形式）："16:21" → 参照日付の時刻（過ぎていれば翌日）
    RegExp timeNumeric = RegExp(r'(?<!\d)(\d{1,2}):(\d{2})(?!\d)');
    for (final match in timeNumeric.allMatches(text)) {
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

    // ⑤ 時刻のみ（日本語／中国語スタイル）："16時41分" または "16時"
    RegExp timeJP = RegExp(r'(\d{1,2})時(?:\s*(\d{1,2})分)?');
    for (final match in timeJP.allMatches(text)) {
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

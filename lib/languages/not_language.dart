// lib/languages/not_language.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// 非言語形式（数値や区切り文字による日付・時刻表現）を処理するクラス
class NonLanguage implements Language {
  @override
  String get code => 'not';

  @override
  List<Parser> get parsers => [NonLanguageParser()];

  @override
  List<Refiner> get refiners => [NonLanguageRefiner()];
}

/// 数値形式など、言語に依存しない日付・時刻表現を抽出するパーサー
class NonLanguageParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------
    // 絶対日付＋時刻の表現 (例: "2024/4/1 16:31" や "2024-04-04 16時40分")
    // ------------------------------
    final RegExp fullDateTimePattern = RegExp(
        r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})(?:\s+(\d{1,2})(?::|時)(\d{2}))?(?:分)?\b'
    );
    for (final match in fullDateTimePattern.allMatches(text)) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      int minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      DateTime date = DateTime(year, month, day, hour, minute);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 絶対日付（年指定なし：例 "5/6"）＋オプションの時刻 (例: "5/6 16:40")
    // ------------------------------
    final RegExp monthDayTimePattern = RegExp(
        r'\b(\d{1,2})[/-](\d{1,2})(?:\s+(\d{1,2})(?::|時)(\d{2}))?(?:分)?\b'
    );
    for (final match in monthDayTimePattern.allMatches(text)) {
      // 4桁の数字で始まる場合は fullDateTimePattern のはずなので除外
      if (match.group(1)!.length == 4) continue;
      int month = int.parse(match.group(1)!);
      int day = int.parse(match.group(2)!);
      int hour = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      int minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      // 年が指定されていない場合は、参照日付より未来となる最も近い日付を設定
      DateTime candidate = DateTime(referenceDate.year, month, day, hour, minute);
      if (!candidate.isAfter(referenceDate)) {
        candidate = DateTime(referenceDate.year + 1, month, day, hour, minute);
      }
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ------------------------------
    // 時刻のみの表現 (例: "16:31", "16時40分", "16時")
    // ------------------------------
    final RegExp timeOnlyPattern = RegExp(
        r'\b(\d{1,2})(?::|時)(\d{2})?(?:分)?\b'
    );
    for (final match in timeOnlyPattern.allMatches(text)) {
      // 時刻のみと判断するため、前後に日付の区切りがないことを想定
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      // 日付指定がない場合、参照日時より未来になる最も近い日時を設定
      DateTime candidate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, minute);
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

/// 非言語パーサーでは特に精錬処理は行わずそのまま返す
class NonLanguageRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return results;
  }
}

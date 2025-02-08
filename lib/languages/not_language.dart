// lib/languages/not_language.dart
import 'language_interface.dart';
import '../core/parser.dart';
import '../core/result.dart';
import '../core/refiner.dart';

class NotLanguage implements Language {
  @override
  String get code => 'not';

  @override
  List<Parser> get parsers => [NotLanguageParser()];

  @override
  List<Refiner> get refiners => [NotLanguageRefiner()];
}

class NotLanguageParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // -- 1) YYYY/MM/DD や YYYY-MM-DD (+ optional time)
    //    例: 2024/4/1, 2024-04-04, 2025/12/31 16:40 など
    final RegExp ymdPattern = RegExp(
      r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?\b',
    );
    for (final match in ymdPattern.allMatches(text)) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);

      final hourStr = match.group(4);
      final minuteStr = match.group(5);
      final secondStr = match.group(6);

      int hour = 0;
      int minute = 0;
      int second = 0;
      if (hourStr != null) {
        hour = int.parse(hourStr);
      }
      if (minuteStr != null) {
        minute = int.parse(minuteStr);
      }
      if (secondStr != null) {
        second = int.parse(secondStr);
      }

      final date = DateTime(year, month, day, hour, minute, second);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // -- 2) M/D (+ optional time), 年がない形式
    //    例: 5/6, 12/1 16:31 など
    //    過去になる場合は翌年とみなす
    final RegExp mdPattern = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?\b',
    );
    for (final match in mdPattern.allMatches(text)) {
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);

      final hourStr = match.group(3);
      final minuteStr = match.group(4);
      final secondStr = match.group(5);

      int hour = 0;
      int minute = 0;
      int second = 0;
      if (hourStr != null) {
        hour = int.parse(hourStr);
      }
      if (minuteStr != null) {
        minute = int.parse(minuteStr);
      }
      if (secondStr != null) {
        second = int.parse(secondStr);
      }

      // 基準日の年を使うが、もし基準日より過去になる場合は翌年にする
      final tentative = DateTime(referenceDate.year, month, day, hour, minute, second);
      DateTime date =
      (tentative.isBefore(referenceDate)) ? DateTime(referenceDate.year + 1, month, day, hour, minute, second) : tentative;

      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // -- 3) 時刻だけ (HH:MM(:SS)?) 24時間表記と仮定
    //    例: 16:31, 9:05:12 など
    //    これだけの場合は「最も近い将来」にする
    final RegExp timeOnlyPattern = RegExp(
      r'\b(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?\b',
    );
    for (final match in timeOnlyPattern.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final secondStr = match.group(3);
      int second = (secondStr != null) ? int.parse(secondStr) : 0;

      // 日付が無いなら、"最も近い将来" のその時刻
      // すなわち referenceDate の日付を基準に、
      // もし referenceDate より前なら翌日
      final base = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
        hour,
        minute,
        second,
      );
      DateTime date = base.isBefore(referenceDate)
          ? base.add(const Duration(days: 1))
          : base;

      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    return results;
  }
}

class NotLanguageRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // この「not_language」では特別なリファインは行わず、そのまま返す
    // （必要に応じて重複や競合の解消などを行うことも可能）
    return results;
  }
}

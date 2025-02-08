// lib/languages/not_language.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class NotLanguage implements Language {
  @override
  String get code => 'not';

  @override
  List<Parser> get parsers => [
    NotLanguageDateParser(),
    NotLanguageTimeParser(),
  ];

  @override
  List<Refiner> get refiners => [
    NotLanguageRefiner(),
  ];
}

// ----------------------
// 1) 数値フォーマット日付 (YYYY-MM-DD, YYYY/MM/DD, M/D など)
// ----------------------
class NotLanguageDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // (A) YYYY-MM-DD or YYYY/MM/DD
    final RegExp ymdPattern = RegExp(r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b');
    for (final match in ymdPattern.allMatches(text)) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final date = DateTime(year, month, day);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // (B) M/D (年がない) => もっとも近い(今年or来年)
    final RegExp mdPattern = RegExp(r'\b(\d{1,2})[-/](\d{1,2})\b');
    for (final match in mdPattern.allMatches(text)) {
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);
      final nowDate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      var candidate = DateTime(referenceDate.year, month, day);
      if (candidate.isBefore(nowDate)) {
        candidate = DateTime(referenceDate.year + 1, month, day);
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    // (C) ISO8601 parse
    try {
      final parsed = DateTime.parse(text.trim());
      results.add(
        ParsingResult(
          index: 0,
          text: text,
          component: ParsedComponent(date: parsed),
        ),
      );
    } catch (_) {
      // ignore
    }

    return results;
  }
}

// ----------------------
// 2) 数値フォーマット時刻 (HH:MM) → もっとも近い将来
// ----------------------
class NotLanguageTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];
    final now = referenceDate;

    final RegExp timePattern = RegExp(r'\b(\d{1,2}):(\d{1,2})\b');
    for (final match in timePattern.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      if (hour > 23 || minute > 59) {
        continue;
      }
      var candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: candidate),
        ),
      );
    }

    return results;
  }
}

// ----------------------
// 3) Refiner: 日付(0:00) と 時刻(当日or翌日) を合体
// ----------------------
class NotLanguageRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    return _mergeDateAndTimeResults(results, referenceDate);
  }

  List<ParsingResult> _mergeDateAndTimeResults(List<ParsingResult> results, DateTime referenceDate) {
    results.sort((a, b) => a.index.compareTo(b.index));
    final merged = <ParsingResult>[];
    final used = <int>{};

    for (int i = 0; i < results.length; i++) {
      if (used.contains(i)) continue;
      final rA = results[i];
      bool mergedAny = false;

      // date-only => hour:minute = 0:00
      final isDateOnlyA = (rA.date.hour == 0 && rA.date.minute == 0 && rA.date.second == 0);

      for (int j = i + 1; j < results.length; j++) {
        if (used.contains(j)) continue;
        final rB = results[j];
        final isDateOnlyB = (rB.date.hour == 0 && rB.date.minute == 0 && rB.date.second == 0);

        final distance = rB.index - (rA.index + rA.text.length);
        if (distance.abs() > 3) {
          continue;
        }

        // 片方日付のみ(0:00) & 片方時刻(実質future補正済み) => 合体
        if (isDateOnlyA && !isDateOnlyB) {
          merged.add(_combineDateTime(rA, rB));
          used.add(i);
          used.add(j);
          mergedAny = true;
          break;
        } else if (!isDateOnlyA && isDateOnlyB) {
          merged.add(_combineDateTime(rB, rA));
          used.add(i);
          used.add(j);
          mergedAny = true;
          break;
        }
      }

      if (!mergedAny) {
        merged.add(rA);
        used.add(i);
      }
    }

    return merged;
  }

  ParsingResult _combineDateTime(ParsingResult dateResult, ParsingResult timeResult) {
    final d = dateResult.date;
    final t = timeResult.date;
    // dateの年月日に timeのhour/minuteを合わせる
    final combined = DateTime(d.year, d.month, d.day, t.hour, t.minute, t.second);
    final newText = '${dateResult.text} ${timeResult.text}';
    return ParsingResult(
      index: dateResult.index,
      text: newText,
      component: ParsedComponent(date: combined),
    );
  }
}

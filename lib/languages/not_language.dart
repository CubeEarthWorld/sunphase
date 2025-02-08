// lib/languages/not_language.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// 非言語 (数値フォーマット) 用の Language 実装
/// code: 'not'
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

// -------------------------------------------------------
// 1) NotLanguageDateParser
//    - "YYYY-MM-DD" / "YYYY/MM/DD" / "M/D" など数値フォーマットの日付をパース
//    - 年が省略された場合は「もっとも近い未来」となるよう翌年補正など
// -------------------------------------------------------
class NotLanguageDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // --------------------------------
    // A) YYYY-MM-DD or YYYY/MM/DD
    //    例: "2024-01-05", "2024/1/5"
    // --------------------------------
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

    // --------------------------------
    // B) M/D  (年省略)
    //    例: "1/5", "12/31"
    //    → 今年か、過ぎていれば翌年
    // --------------------------------
    final RegExp mdPattern = RegExp(r'\b(\d{1,2})[-/](\d{1,2})\b');
    for (final match in mdPattern.allMatches(text)) {
      // すでに YYYY-MM-DD にマッチしている可能性もあるが
      // 重複は後で Merger or Refiner で排除される想定
      final now = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);

      // 今年で作って、もし過ぎていれば翌年
      var candidate = DateTime(referenceDate.year, month, day);
      if (candidate.isBefore(now)) {
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

    // --------------------------------
    // C) ISO8601 全文 parse できるなら試す
    //    (ex: "2025-01-05T16:40:00Z") など
    //    ただし複合要素をまとめて解析してしまうと
    //    分割検知が難しいので要件次第
    // --------------------------------
    try {
      final parsed = DateTime.parse(text.trim());
      // これが成功すると、"2024-01-05 16:00" など空白込みも解析して
      // 一発で dateTime = 2024-01-05 16:00:00.000 になる可能性がありますが、
      // 文中に余分な文字がある場合などは失敗することも
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

// -------------------------------------------------------
// 2) NotLanguageTimeParser
//    - 数値フォーマットの時刻 (HH:MM) をパース
//    - 24時間制とし、"00:00"～"23:59" まで
// -------------------------------------------------------
class NotLanguageTimeParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];
    final now = referenceDate;

    // e.g. "16:00", "09:30"
    final RegExp timePattern = RegExp(r'\b(\d{1,2}):(\d{1,2})\b');
    for (final match in timePattern.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      if (hour > 23 || minute > 59) {
        continue;
      }

      // 当日 hour:minute
      var candidate = DateTime(now.year, now.month, now.day, hour, minute);
      // "もっとも近い未来" にするなら (candidate.isBefore(now)) で +1日
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

// -------------------------------------------------------
// 3) NotLanguageRefiner
//    - 日付パーサと時刻パーサの結果が連続していれば、1つのDateTimeにマージ
//    - 例: "2024-01-05 16:00" →
//        "2024-01-05" (index=0) と "16:00" (index=11) などを1件にまとめる
// -------------------------------------------------------
class NotLanguageRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    if (results.isEmpty) return results;

    // index順にソート
    results.sort((a, b) => a.index.compareTo(b.index));

    final merged = <ParsingResult>[];
    int i = 0;

    while (i < results.length) {
      final current = results[i];

      if (i < results.length - 1) {
        final next = results[i + 1];
        // 2つの結果が近接していればマージ
        final distance = next.index - (current.index + current.text.length);

        if (_isDateOnly(current, referenceDate) && _isTimeOnly(next, referenceDate)) {
          // マージ
          // current.date (年・月・日) + next.date (hour/minute)
          final combined = DateTime(
            current.date.year,
            current.date.month,
            current.date.day,
            next.date.hour,
            next.date.minute,
            next.date.second,
          );
          final mergedText = '${current.text} ${next.text}';
          merged.add(
            ParsingResult(
              index: current.index,
              text: mergedText,
              component: ParsedComponent(date: combined),
            ),
          );
          i += 2;
          continue;
        }
      }

      merged.add(current);
      i++;
    }

    return merged;
  }

  /// 「日付のみ」かどうかの簡易判定
  ///   - hour/minute/second == 0
  ///   - あるいは text 内に ":" が含まれていない など
  bool _isDateOnly(ParsingResult r, DateTime reference) {
    final dt = r.date;
    // ざっくり hour/minute/second が 0 なら「日付のみ」と判定
    if (dt.hour == 0 && dt.minute == 0 && dt.second == 0) {
      return true;
    }
    return false;
  }

  /// 「時刻のみ」かどうかの簡易判定
  ///   - text 内に ":" が含まれる など
  bool _isTimeOnly(ParsingResult r, DateTime reference) {
    // ここでは text に ":" が含まれていれば "time only" とする (ざっくり)
    // または dt と reference を比較して "日が同じ + 時間が違う" などでもOK
    return r.text.contains(":");
  }
}

// lib/languages/not_language.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

class NotLanguage implements Language {
  @override
  String get code => 'not';  // 非言語用のコード

  @override
  List<Parser> get parsers => [NotLanguageDateParser()];

  @override
  List<Refiner> get refiners => [NotLanguageRefiner()];
}

class NotLanguageDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    final results = <ParsingResult>[];

    // ------------------------------
    // 1) YYYY/MM/DD (区切りに - もあり) を検出: e.g. "2024/4/1", "2024-04-04"
    //    先に西暦+月+日だけ抜き出す
    // ------------------------------
    final RegExp ymdPattern = RegExp(r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b');
    for (final match in ymdPattern.allMatches(text)) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final date = DateTime(year, month, day);
      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: date),
      ));
    }

    // ------------------------------
    // 2) M/D (年がない場合) : "5/6" など -> 今年かつ「もっとも近い M/D」(もう過ぎていれば翌年)
    // ------------------------------
    final RegExp mdPattern = RegExp(r'\b(\d{1,2})[-/](\d{1,2})\b');
    for (final match in mdPattern.allMatches(text)) {
      // すでに上の YYYY/MM/DD にマッチしていればそちらが優先される場合もあるため、
      // 重複チェックなどは後段の Refiner や Merger で行われる想定
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);

      // とりあえず今年で作って、もし既に今日より過去なら翌年にする
      DateTime candidate = DateTime(referenceDate.year, month, day);
      final nowDateOnly = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      if (candidate.isBefore(nowDateOnly)) {
        candidate = DateTime(referenceDate.year + 1, month, day);
      }

      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ------------------------------
    // 3) 時刻 (HH:MM) パターン -> 24時間制と仮定
    //    - 時間のみなら "16" や "9" といった数字だけのケースを拾いすぎるので
    //      コロン付きの場合に限定
    // ------------------------------
    final RegExp timePattern = RegExp(r'\b(\d{1,2}):(\d{1,2})\b');
    for (final match in timePattern.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);

      if (hour > 23 || minute > 59) {
        // 不正な時刻はスキップ
        continue;
      }
      // 日付指定がない場合 -> "もっとも近い未来" として
      // まずは referenceDate の日付部分を流用し、時刻だけ上書き
      final now = referenceDate;
      DateTime candidate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // もし既に今の時刻を過ぎているなら翌日にする
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }

      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ------------------------------
    // 4) 時刻 (HH) のみ (例: "16" 時)
    //    コロンがない単独数字は日付や他の数値と衝突しやすいので、ここではあえて
    //    "[H]時" という形に限定するなど、工夫が必要。
    //    ※「not_language」では実装例として簡易に ( \b\d{1,2}\b ) を拾うと衝突が多すぎるため注意
    // ------------------------------
    // 今回は例示のため、 "(\d{1,2})時" をチェックし、分がなければ 00分 とする:
    final RegExp hourOnlyPattern = RegExp(r'\b(\d{1,2})時\b');
    for (final match in hourOnlyPattern.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      if (hour > 23) {
        continue;
      }
      final now = referenceDate;
      DateTime candidate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );
      // 過ぎていれば翌日
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }

      results.add(ParsingResult(
        index: match.start,
        text: match.group(0)!,
        component: ParsedComponent(date: candidate),
      ));
    }

    // ------------------------------
    // 5) ISO8601 などに対応できるならトライ
    // ------------------------------
    try {
      final parsed = DateTime.parse(text.trim());
      results.add(ParsingResult(
        index: 0,
        text: text,
        component: ParsedComponent(date: parsed),
      ));
    } catch (_) {
      // 無視
    }

    return results;
  }
}

class NotLanguageRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // 特に何もしない。重複除去やマージは共通の Merger などで処理される想定
    return results;
  }
}

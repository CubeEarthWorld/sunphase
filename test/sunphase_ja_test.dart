import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';
import 'package:sunphase/utils/date_utils.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  group('Sunphase Parser Tests for Japanese', () {
    test('Japanese: "今日"', () {
      String input = "今日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('Japanese: "明日"', () {
      String input = "明日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Japanese: "昨日"', () {
      String input = "昨日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 7, 0, 0, 0));
    });

    test('Japanese: "21時31分"', () {
      String input = "21時31分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 21, 31, 0));
    });

    test('Japanese: "3日12時15分"', () {
      String input = "3日12時15分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 3, 3, 12, 15, 0));
    });

    test('Japanese: "明日14時25分"', () {
      String input = "明日14時25分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 14, 25, 0));
    });

    test('Japanese: "24日14時25分"', () {
      String input = "24日14時25分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 24, 14, 25, 0));
    });

    test('Japanese: "木曜14時36分"', () {
      String input = "木曜14時36分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 13, 14, 36, 0));
    });

    test('Japanese: "明日十時三十一分"', () {
      String input = "明日十時三十一分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 10, 31, 0));
    });

    test('Japanese: "再来週土曜"', () {
      String input = "再来週土曜";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 22, 0, 0, 0));
    });

    test('Japanese: "明日5時"', () {
      String input = "明日5時";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 5, 0, 0));
    });

    test('Japanese: "来年五月十二日"', () {
      String input = "来年五月十二日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2026, 5, 12, 0, 0, 0));
    });

    test('Japanese: "16日"', () {
      String input = "16日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Japanese: "3日" (past day → next month)', () {
      String input = "3日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 3, 3, 0, 0, 0));
    });

    test('Japanese: "十六日"', () {
      String input = "十六日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Japanese: "8日" (same day → next month)', () {
      String input = "8日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 3, 8, 0, 0, 0));
    });

    test('Japanese: "16日 14時"', () {
      String input = "16日 14時";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 16, 14, 0, 0));
    });

    test('Japanese: "2月28日"', () {
      String input = "2月28日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 28, 0, 0, 0));
    });

    test('Japanese: "31日" (Feb → March 31)', () {
      String input = "31日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 3, 31, 0, 0, 0));
    });

    test('Japanese: "1日" (past → next month)', () {
      String input = "1日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
    });

    test('Japanese: "20日に歯医者"', () {
      String input = "20日に歯医者";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 20, 0, 0, 0));
    });

    test('Japanese (Range): "来月の予定"', () {
      String input = "来月の予定";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
        rangeMode: true,
      );
      int daysInMarch = DateUtils.getMonthRange(
        DateTime(2025, 3, 1),
      )['end']!.day;
      expect(results.length, daysInMarch);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });

    // --- Weekday yobi suffix tests ---

    test('Japanese: kin-yobi standalone', () {
      String input = "金曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 0, 0, 0));
    });

    test('Japanese: kin-yobi 12:43', () {
      String input = "金曜日12時43分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 12, 43, 0));
    });

    test('Japanese: do-yobi gogo 3ji', () {
      String input = "土曜日午後3時";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 15, 15, 0, 0));
    });

    test('Japanese: raishu kayobi', () {
      String input = "来週火曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 11, 0, 0, 0));
    });

    test('Japanese: Saraishu getsuyobi', () {
      String input = "再来週月曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 17, 0, 0, 0));
    });

    test('Japanese: 3-shuukan-go kin-yobi', () {
      String input = "3週間後金曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 28, 0, 0, 0));
    });

    test('Japanese: 1-shuukan-go nichiyo', () {
      String input = "1週間後日曜";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    // --- Year expression tests ---

    test('Japanese: saranen', () {
      String input = "再来年";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2027, 2, 1, 0, 0, 0));
    });

    test('Japanese: 2-nen-go', () {
      String input = "2年後";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2027, 2, 1, 0, 0, 0));
    });

    test('Japanese: 5-nen-go', () {
      String input = "5年後";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2030, 2, 1, 0, 0, 0));
    });

    // --- Full-width digit (全角数字) tests ---

    test('Japanese fullwidth: "明日１０時３０分"', () {
      String input = "明日１０時３０分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 10, 30, 0));
    });

    test('Japanese fullwidth: "２１時３１分"', () {
      String input = "２１時３１分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 21, 31, 0));
    });

    test('Japanese fullwidth: "３日１２時１５分"', () {
      String input = "３日１２時１５分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 3, 3, 12, 15, 0));
    });

    test('Japanese fullwidth: "１６日"', () {
      String input = "１６日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Japanese fullwidth: "２０２６年５月１４日"', () {
      String input = "２０２６年５月１４日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2026, 5, 14, 0, 0, 0));
    });

    test('Japanese fullwidth: "８日" (same day → next month)', () {
      String input = "８日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 3, 8, 0, 0, 0));
    });

    test('Japanese fullwidth: "来年五月十二日" (mixed kanji)', () {
      String input = "来年五月十二日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2026, 5, 12, 0, 0, 0));
    });

    // --- Next/last week + weekday tests ---

    test('Japanese: "来週水曜日"', () {
      String input = "来週水曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 12, 0, 0, 0));
    });

    test('Japanese: "来週日曜日"', () {
      String input = "来週日曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Japanese: "来週日曜日" with Monday week start', () {
      String input = "来週日曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
        weekStartsOn: DateTime.monday,
      );
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Japanese: "先週月曜日"', () {
      String input = "先週月曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 3, 0, 0, 0));
    });

    test('Japanese: "先週金曜日"', () {
      String input = "先週金曜日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(2025, 2, 7, 0, 0, 0));
    });
  });
}

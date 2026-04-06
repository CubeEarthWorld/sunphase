import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';
import 'package:sunphase/utils/date_utils.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  group('Sunphase Parser Tests for Japanese', () {
    test('Japanese: "今日"', () {
      String input = "今日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('Japanese: "明日"', () {
      String input = "明日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Japanese: "昨日"', () {
      String input = "昨日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 7, 0, 0, 0));
    });

    test('Japanese: "21時31分"', () {
      String input = "21時31分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 8, 21, 31, 0));
    });

    test('Japanese: "3日12時15分"', () {
      String input = "3日12時15分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 3, 3, 12, 15, 0));
    });

    test('Japanese: "明日14時25分"', () {
      String input = "明日14時25分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 9, 14, 25, 0));
    });

    test('Japanese: "24日14時25分"', () {
      String input = "24日14時25分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 24, 14, 25, 0));
    });

    test('Japanese: "木曜14時36分"', () {
      String input = "木曜14時36分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 13, 14, 36, 0));
    });

    test('Japanese: "明日十時三十一分"', () {
      String input = "明日十時三十一分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 9, 10, 31, 0));
    });

    test('Japanese: "再来週土曜"', () {
      String input = "再来週土曜";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 22, 0, 0, 0));
    });

    test('Japanese: "明日5時"', () {
      String input = "明日5時";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 9, 5, 0, 0));
    });

    test('Japanese: "来年五月十二日"', () {
      String input = "来年五月十二日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2026, 5, 12, 0, 0, 0));
    });

    test('Japanese: "16日"', () {
      String input = "16日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Japanese: "3日" (past day → next month)', () {
      String input = "3日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 3, 3, 0, 0, 0));
    });

    test('Japanese: "十六日"', () {
      String input = "十六日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Japanese: "8日" (same day → next month)', () {
      String input = "8日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 3, 8, 0, 0, 0));
    });

    test('Japanese: "16日 14時"', () {
      String input = "16日 14時";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 16, 14, 0, 0));
    });

    test('Japanese: "2月28日"', () {
      String input = "2月28日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 28, 0, 0, 0));
    });

    test('Japanese: "31日" (Feb → March 31)', () {
      String input = "31日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 3, 31, 0, 0, 0));
    });

    test('Japanese: "1日" (past → next month)', () {
      String input = "1日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
    });

    test('Japanese: "20日に歯医者"', () {
      String input = "20日に歯医者";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      expect(results.first.date, DateTime(2025, 2, 20, 0, 0, 0));
    });

    test('Japanese (Range): "来月の予定"', () {
      String input = "来月の予定";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja'], rangeMode: true);
      int daysInMarch = DateUtils.getMonthRange(DateTime(2025, 3, 1))['end']!.day;
      expect(results.length, daysInMarch);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });
  });
}

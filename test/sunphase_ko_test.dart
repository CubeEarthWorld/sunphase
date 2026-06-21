import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  group('Sunphase Parser Tests for Korean', () {
    test('Korean: "오늘"', () {
      String input = "오늘";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('Korean: "내일"', () {
      String input = "내일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Korean: "어제"', () {
      String input = "어제";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 7, 0, 0, 0));
    });

    test('Korean: "2월14일"', () {
      String input = "2월14일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 0, 0, 0));
    });

    test('Korean: "14일"', () {
      String input = "14일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 0, 0, 0));
    });

    test('Korean: "3일" (past → next month)', () {
      String input = "3일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 3, 3, 0, 0, 0));
    });

    test('Korean: "2025년2월8일"', () {
      String input = "2025년2월8일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('Korean: "월요일"', () {
      String input = "월요일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 10, 0, 0, 0));
    });

    test('Korean: "금요일"', () {
      String input = "금요일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 0, 0, 0));
    });

    test('Korean: "다음 주"', () {
      String input = "다음 주";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Korean: "다음 주" with Monday week start', () {
      String input = "다음 주";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
        weekStartsOn: DateTime.monday,
      );
      expect(results.first.date, DateTime(2025, 2, 10, 0, 0, 0));
    });

    test('Korean: "다음 주 일요일"', () {
      String input = "다음 주 일요일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Korean: "다음 주 일요일" with Monday week start', () {
      String input = "다음 주 일요일";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
        weekStartsOn: DateTime.monday,
      );
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Korean: "3시30분"', () {
      String input = "3시30분";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 3, 30, 0));
    });

    test('Korean: "내일 14시"', () {
      String input = "내일 14시";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 14, 0, 0));
    });

    test('Korean: "14일 3시"', () {
      String input = "14일 3시";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 3, 0, 0));
    });

    test('Korean: "3일 후"', () {
      String input = "3일 후";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 11, 0, 0, 0));
    });

    test('Korean: "2주 후"', () {
      String input = "2주 후";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 22, 0, 0, 0));
    });

    test('Korean: "다음 달"', () {
      String input = "다음 달";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
    });

    test('Korean: "10:30"', () {
      String input = "10:30";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 10, 30, 0));
    });

    // Regression: relative-day words beyond 오늘/내일/어제 must also combine
    // with a 시 time.
    test('Korean: "모레 3시"', () {
      List<ParsingResult> results = parse(
        "모레 3시",
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 10, 3, 0, 0));
    });

    test('Korean: "그끄제 10시"', () {
      List<ParsingResult> results = parse(
        "그끄제 10시",
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 6, 10, 0, 0));
    });
  });
}

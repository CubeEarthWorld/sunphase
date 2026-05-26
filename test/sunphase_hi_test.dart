import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';
import 'package:sunphase/utils/date_utils.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);
  print("Reference Date: $reference\n");

  group('Sunphase Parser Tests for Hindi', () {
    test('Hindi: "आज"', () {
      String input = "आज";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "कल"', () {
      String input = "कल";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "परसों"', () {
      String input = "परसों";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "14 मार्च 2025"', () {
      String input = "14 मार्च 2025";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 3, 14, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "सुबह 10:10"', () {
      String input = "सुबह 10:10";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 9, 10, 10, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "आज 14:30"', () {
      String input = "आज 14:30";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 8, 14, 30, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "अगले सोमवार"', () {
      String input = "अगले सोमवार";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "पिछले शुक्रवार"', () {
      String input = "पिछले शुक्रवार";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "2 सप्ताह बाद"', () {
      String input = "2 सप्ताह बाद";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 22, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "3 दिन पहले"', () {
      String input = "3 दिन पहले";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "15 तारीख"', () {
      String input = "15 तारीख";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "सोमवार"', () {
      String input = "सोमवार";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi (Range): "अगले महीने की योजना"', () {
      String input = "अगले महीने की योजना";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
        rangeMode: true,
      );
      int daysInMarch = DateUtils.getMonthRange(
        DateTime(2025, 3, 1),
      )['end']!.day;
      expect(results.length, daysInMarch);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });

    test('HI Day-Only: "15 तारीख को मीटिंग"', () {
      String input = "15 तारीख को मीटिंग";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 15);
      expect(results.first.date, expected);
    });

    // --- Next/last week + weekday tests ---

    test('Hindi: "अगले मंगलवार"', () {
      String input = "अगले मंगलवार";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 11, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "अगले हफ्ते रविवार"', () {
      String input = "अगले हफ्ते रविवार";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "अगले हफ्ते रविवार" with Monday week start', () {
      String input = "अगले हफ्ते रविवार";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
        weekStartsOn: DateTime.monday,
      );
      DateTime expected = DateTime(2025, 2, 16, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "पिछले रविवार"', () {
      String input = "पिछले रविवार";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 2, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "पिछले बुधवार"', () {
      String input = "पिछले बुधवार";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      expect(results.first.date, expected);
    });
  });
}

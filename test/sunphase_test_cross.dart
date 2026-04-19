import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  group('Cross-Language Tests', () {
    test('Mixed: "Today買い物をする"', () {
      String input = "Today買い物をする";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['en', 'ja', 'zh'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('Mixed: "2026年5月14日"', () {
      String input = "2026年5月14日";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['en', 'ja', 'zh'],
      );
      expect(results.first.date, DateTime(2026, 5, 14, 0, 0, 0));
    });

    test('Universal: ISO 8601', () {
      String input = "2025-02-08T15:00:00Z";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['en', 'ja', 'zh'],
      );
      DateTime expected = DateTime.utc(2025, 2, 8, 15, 0, 0);
      expect(results.first.date, expected);
    });
  });

  group('Day-Only in Sentences (Cross-Language)', () {
    test('ES: "28 de febrero"', () {
      String input = "28 de febrero";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      expect(results.first.date, DateTime(2025, 2, 28));
    });

    test('HI: "15 तारीख को मीटिंग"', () {
      String input = "15 तारीख को मीटिंग";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      expect(results.first.date, DateTime(2025, 2, 15));
    });

    test('ES: "Cita el día 20 a las 15:00"', () {
      String input = "Cita el día 20 a las 15:00";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      expect(results.first.date, DateTime(2025, 2, 20, 15, 0));
    });

    test('ES: "el día 20"', () {
      String input = "el día 20";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      expect(results.first.date, DateTime(2025, 2, 20));
    });
  });

  group('Full DateTime Tests', () {
    test('JA: "5241年11月11日21時41分"', () {
      String input = "5241年11月11日21時41分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ja'],
      );
      expect(results.first.date, DateTime(5241, 11, 11, 21, 41));
    });

    test('ZH: "2026年5月14日14时30分"', () {
      String input = "2026年5月14日14时30分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['zh'],
      );
      expect(results.first.date, DateTime(2026, 5, 14, 14, 30));
    });

    test('ZH: "2026年5月14日下午3点30分"', () {
      String input = "2026年5月14日下午3点30分";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['zh'],
      );
      expect(results.first.date, DateTime(2026, 5, 14, 15, 30));
    });

    test('KO: "2025년2월14일15시30분"', () {
      String input = "2025년2월14일15시30분";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ko'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 15, 30));
    });

    test('RU: "14.02.2025 в 15:30"', () {
      String input = "14.02.2025 в 15:30";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 15, 30));
    });

    test('ES: "14 de marzo de 2025 a las 15:30"', () {
      String input = "14 de marzo de 2025 a las 15:30";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      expect(results.first.date, DateTime(2025, 3, 14, 15, 30));
    });

    test('HI: "14 मार्च 2025 दोपहर 3:30"', () {
      String input = "14 मार्च 2025 दोपहर 3:30";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['hi'],
      );
      expect(results.first.date, DateTime(2025, 3, 14, 15, 30));
    });

    test('EN: "March 14, 2025 15:30"', () {
      String input = "March 14, 2025 15:30";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['en'],
      );
      expect(results.first.date, DateTime(2025, 3, 14, 15, 30));
    });
  });
}

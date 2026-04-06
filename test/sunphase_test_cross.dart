import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  group('Cross-Language Tests', () {
    test('Mixed: "Today買い物をする"', () {
      String input = "Today買い物をする";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en', 'ja', 'zh']);
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('Mixed: "2026年5月14日"', () {
      String input = "2026年5月14日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en', 'ja', 'zh']);
      expect(results.first.date, DateTime(2026, 5, 14, 0, 0, 0));
    });

    test('Universal: ISO 8601', () {
      String input = "2025-02-08T15:00:00Z";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en', 'ja', 'zh']);
      DateTime expected = DateTime.utc(2025, 2, 8, 15, 0, 0);
      expect(results.first.date, expected);
    });
  });

  group('Day-Only in Sentences (Cross-Language)', () {
    test('ES: "28 de febrero"', () {
      String input = "28 de febrero";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      expect(results.first.date, DateTime(2025, 2, 28));
    });

    test('HI: "15 तारीख को मीटिंग"', () {
      String input = "15 तारीख को मीटिंग";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      expect(results.first.date, DateTime(2025, 2, 15));
    });

    test('ES: "Cita el día 20 a las 15:00"', () {
      String input = "Cita el día 20 a las 15:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      expect(results.first.date, DateTime(2025, 2, 20, 15, 0));
    });

    test('ES: "el día 20"', () {
      String input = "el día 20";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      expect(results.first.date, DateTime(2025, 2, 20));
    });
  });
}

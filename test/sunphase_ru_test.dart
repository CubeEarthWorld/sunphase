import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  group('Sunphase Parser Tests for Russian', () {
    test('Russian: "сегодня"', () {
      String input = "сегодня";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('Russian: "завтра"', () {
      String input = "завтра";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Russian: "вчера"', () {
      String input = "вчера";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 7, 0, 0, 0));
    });

    test('Russian: "14 февраля"', () {
      String input = "14 февраля";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 0, 0, 0));
    });

    test('Russian: "14.02.2025"', () {
      String input = "14.02.2025";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 0, 0, 0));
    });

    test('Russian: "14-го"', () {
      String input = "14-го";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 0, 0, 0));
    });

    test('Russian: "3-го" (past → next month)', () {
      String input = "3-го";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 3, 3, 0, 0, 0));
    });

    test('Russian: "понедельник"', () {
      String input = "понедельник";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 10, 0, 0, 0));
    });

    test('Russian: "пятницу"', () {
      String input = "пятницу";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 14, 0, 0, 0));
    });

    test('Russian: "на следующей неделе"', () {
      String input = "на следующей неделе";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Russian: "на следующей неделе" with Monday week start', () {
      String input = "на следующей неделе";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
        weekStartsOn: DateTime.monday,
      );
      expect(results.first.date, DateTime(2025, 2, 10, 0, 0, 0));
    });

    test('Russian: "в воскресенье на следующей неделе"', () {
      String input = "в воскресенье на следующей неделе";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test(
      'Russian: "в воскресенье на следующей неделе" with Monday week start',
      () {
        String input = "в воскресенье на следующей неделе";
        List<ParsingResult> results = parse(
          input,
          referenceDate: reference,
          languages: ['ru'],
          weekStartsOn: DateTime.monday,
        );
        expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
      },
    );

    test('Russian: "в 15:30"', () {
      String input = "в 15:30";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 15, 30, 0));
    });

    test('Russian: "вечера 18:00"', () {
      String input = "вечера 18:00";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 8, 18, 0, 0));
    });

    test('Russian: "через 3 дня"', () {
      String input = "через 3 дня";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 11, 0, 0, 0));
    });

    test('Russian: "3 дня назад"', () {
      String input = "3 дня назад";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 5, 0, 0, 0));
    });

    test('Russian: "через 2 недели"', () {
      String input = "через 2 недели";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 22, 0, 0, 0));
    });

    test('Russian: "в следующем месяце"', () {
      String input = "в следующем месяце";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
    });

    test('Russian: "10:30"', () {
      String input = "10:30";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 9, 10, 30, 0));
    });

    // Multi-step relative-day words.
    test('Russian: "послезавтра"', () {
      List<ParsingResult> results = parse(
        "послезавтра",
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 10, 0, 0, 0));
    });

    test('Russian: "позавчера"', () {
      List<ParsingResult> results = parse(
        "позавчера",
        referenceDate: reference,
        languages: ['ru'],
      );
      expect(results.first.date, DateTime(2025, 2, 6, 0, 0, 0));
    });
  });
}

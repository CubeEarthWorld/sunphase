import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  group('Sunphase Parser Tests for English', () {
    test('English: "Today"', () {
      String input = "Today";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('English: "Tomorrow"', () {
      String input = "Tomorrow";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('English: "Yesterday"', () {
      String input = "Yesterday";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 7, 0, 0, 0));
    });

    test('English: "Midnight"', () {
      String input = "Midnight";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('English: "2 weeks from now"', () {
      String input = "2 weeks from now";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 22, 0, 0, 0));
    });

    test('English: "4 days later"', () {
      String input = "4 days later";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 12, 0, 0, 0));
    });

    test('English: "5 days ago"', () {
      String input = "5 days ago";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 3, 0, 0, 0));
    });

    test('English: "Last Friday"', () {
      String input = "Last Friday";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 7, 0, 0, 0));
    });

    test('English: "march 7 10:10"', () {
      String input = "march 7 10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 3, 7, 10, 10, 0));
    });

    test('English: "the 16th"', () {
      String input = "the 16th";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('English: "February 28"', () {
      String input = "February 28";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 28, 0, 0, 0));
    });

    test('English: "Dentist on the 20th at 3pm"', () {
      String input = "Dentist on the 20th at 3pm";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 20, 15, 0, 0));
    });

    test('English (Range): "next week go to university"', () {
      String input = "next week go to university";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en'], rangeMode: true);
      expect(results.length, 7);
      expect(results.first.date, DateTime(2025, 2, 15, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 21, 0, 0, 0));
    });

    test('English (Range): "march"', () {
      String input = "march";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en'], rangeMode: true);
      expect(results.length, 31);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, 31, 0, 0, 0));
    });

    test('EN: "Gym session at 06:00"', () {
      String input = "Gym session at 06:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 9, 6, 0, 0));
    });

    test('EN: "Lunch with client at noon"', () {
      String input = "Lunch with client at noon";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      expect(results.first.date, DateTime(2025, 2, 8, 12, 0, 0));
    });
  });
}

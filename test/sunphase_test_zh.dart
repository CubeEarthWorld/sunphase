import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  group('Sunphase Parser Tests for Chinese', () {
    test('Chinese: "今天"', () {
      String input = "今天";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 8, 0, 0, 0));
    });

    test('Chinese: "明天"', () {
      String input = "明天";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('Chinese: "昨天"', () {
      String input = "昨天";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 7, 0, 0, 0));
    });

    test('Chinese: "四号一点"', () {
      String input = "四号一点";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 3, 4, 1, 0, 0));
    });

    test('Chinese: "3月1号 14:24"', () {
      String input = "3月1号 14:24";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 3, 1, 14, 24, 0));
    });

    test('Chinese: "三月七号上午九点"', () {
      String input = "三月七号上午九点";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 3, 7, 9, 0, 0));
    });

    test('Chinese: "三天后"', () {
      String input = "三天后";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 11, 0, 0, 0));
    });

    test('Chinese: "16号"', () {
      String input = "16号";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Chinese: "十六号"', () {
      String input = "十六号";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 16, 0, 0, 0));
    });

    test('Chinese: "20号下午3点"', () {
      String input = "20号下午3点";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 20, 15, 0, 0));
    });

    test('Chinese: "2月28日"', () {
      String input = "2月28日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 28, 0, 0, 0));
    });

    test('Chinese: "29日" (Feb 2025 → March 29)', () {
      String input = "29日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 3, 29, 0, 0, 0));
    });

    test('Chinese: "20号去看牙医"', () {
      String input = "20号去看牙医";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      expect(results.first.date, DateTime(2025, 2, 20, 0, 0, 0));
    });
  });
}

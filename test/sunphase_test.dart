// test/demo.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  // 固定基準日時: 2025-02-08 11:05:00
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);
  print("Reference Date: $reference\n");

  group('Additional Sunphase Parser Tests', () {
    test('English: Today', () {
      String input = "Today";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Today'");
      expect(results.first.date, expected);
    });

    test('English: Tomorrow', () {
      String input = "Tomorrow";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Tomorrow'");
      expect(results.first.date, expected);
    });

    test('Japanese: 明日', () {
      String input = "明日";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明日'");
      expect(results.first.date, expected);
    });

    test('Japanese: 明日12時41分', () {
      String input = "明日12時41分";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明日'");
      expect(results.first.date, expected);
    });

    test('Japanese: 明日', () {
      String input = "明日";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明日'");
      expect(results.first.date, expected);
    });

    test('Japanese: 4月26日4時8分', () {
      String input = "4月26日4時8分";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = DateTime(2025, 4, 26, 4, 8, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '4月26日4時8分'");
      expect(results.first.date, expected);
    });

    test('Japanese: 時刻のみ "21時31分"', () {
      String input = "21時31分";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 21, 31, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '21時31分'");
      expect(results.first.date, expected);
    });

    test('Japanese: 時刻のみ "10時5分"', () {
      String input = "10時5分";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 10, 5, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '10時5分'");
      expect(results.first.date, expected);
    });

    test('English: 2 weeks from now', () {
      String input = "2 weeks from now";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 14));
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2 weeks from now'");
      expect(results.first.date, expected);
    });

    test('English: 4 days later', () {
      String input = "4 days later";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 4));
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '4 days later'");
      expect(results.first.date, expected);
    });

    test('English: 5 days ago', () {
      String input = "5 days ago";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = reference.subtract(Duration(days: 5));
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '5 days ago'");
      expect(results.first.date, expected);
    });

    test('English: 2 weeks later', () {
      String input = "2 weeks later";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 14));
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2 weeks later'");
      expect(results.first.date, expected);
    });

    test('English: Last Friday', () {
      String input = "Last Friday";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      // 例として、"Last Friday" を基準日から 7 日前とする
      DateTime expected = reference.subtract(Duration(days: 7));
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Last Friday'");
      expect(results.first.date, expected);
    });

    test('English: Date range "17 August 2013 - 19 August 2013" (rangeMode:true)', () {
      String input = "17 August 2013 - 19 August 2013";
      List<ParsingResult> results = parse(input,
          referenceDate: reference,rangeMode: true);
      // 期待: 2013-08-17, 2013-08-18, 2013-08-19（各0:00）
      DateTime expected1 = DateTime(2013, 8, 17, 0, 0, 0);
      DateTime expected2 = DateTime(2013, 8, 18, 0, 0, 0);
      DateTime expected3 = DateTime(2013, 8, 19, 0, 0, 0);
      print("Input: $input (range mode)");
      expect(results.length, greaterThanOrEqualTo(3), reason: "Range mode did not produce at least 3 results.");
      if (results.length >= 3) {
        print("Output: ${results[0].date}, ${results[1].date}, ${results[2].date}");
        print("Expected: $expected1, $expected2, $expected3");
        expect(results[0].date, expected1);
        expect(results[1].date, expected2);
        expect(results[2].date, expected3);
      }
    });

    test('English: "This Friday from 13:00 - 16:00"', () {
      String input = "This Friday from 13:00 - 16:00";
      List<ParsingResult> results = parse(input,
          referenceDate: reference);
      // シンプルな実装例として、"This Friday" は基準日に変化がないと仮定し、開始時刻のみ指定
      DateTime expected = DateTime(reference.year, reference.month, reference.day, 13, 0, 0);
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'This Friday from 13:00 - 16:00'");
      expect(results.first.date, expected);
    });

    test('Universal: "Sat Aug 17 2013 18:40:39 GMT+0900 (JST)"', () {
      String input = "Sat Aug 17 2013 18:40:39 GMT+0900 (JST)";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime.parse("2013-08-17T18:40:39+09:00");
      print("Input: $input, Output: ${results.isNotEmpty ? results.first.date : 'No result'}, Expected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for universal ISO format input");
      expect(results.first.date, expected);
    });
  });
}

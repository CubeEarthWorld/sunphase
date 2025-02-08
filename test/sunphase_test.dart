// test/sunphase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  // 固定基準日時: 2025年2月8日(土) 11:05:00
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);
  print("Reference Date: $reference\n");

  group('Additional Sunphase Parser Tests', () {

    test('English: Today', () {
      String input = "Today";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Today'");
      expect(results.first.date == expected, true);
    });

    test('English: Tomorrow', () {
      String input = "Tomorrow";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Tomorrow'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 明日', () {
      String input = "明日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明日'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 4月26日4時8分', () {
      String input = "4月26日4時8分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 4, 26, 4, 8, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '4月26日4時8分'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 時刻のみ "21時31分"', () {
      String input = "21時31分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 21, 31, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '21時31分'");
      expect(results.first.date == expected, true);
    });

    test('English: 2 weeks from now', () {
      String input = "2 weeks from now";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 14));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2 weeks from now'");
      expect(results.first.date == expected, true);
    });

    test('English: 4 days later', () {
      String input = "4 days later";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 4));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '4 days later'");
      expect(results.first.date == expected, true);
    });

    test('English: 5 days ago', () {
      String input = "5 days ago";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.subtract(Duration(days: 5));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '5 days ago'");
      expect(results.first.date == expected, true);
    });

    test('English: 2 weeks later', () {
      String input = "2 weeks later";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 14));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2 weeks later'");
      expect(results.first.date == expected, true);
    });

    test('English: Last Friday', () {
      String input = "Last Friday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Last Friday'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 土曜', () {
      String input = "土曜";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '土曜'");
      expect(results.first.date == expected, true);
    });

    test('English: sunday', () {
      String input = "sunday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'last sunday'");
      expect(results.first.date == expected, true);
    });

    test('English: saturday', () {
      String input = "saturday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'saturday'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 明後日', () {
      String input = "明後日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明後日'");
      expect(results.first.date == expected, true);
    });

    test('English: two weeks ago', () {
      String input = "two weeks ago";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.subtract(Duration(days: 14));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'two weeks ago'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 今天', () {
      String input = "今天";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '今天'");
      expect(results.first.date == expected, true);
    });

    test('English: june 20', () {
      String input = "june 20";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 6, 20, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'june 20'");
      expect(results.first.date == expected, true);
    });

    test('English: 12:41 (time only)', () {
      String input = "12:41";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 12, 41, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '12:41'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 8月21日', () {
      String input = "8月21日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 8, 21, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '8月21日'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 21時12分', () {
      String input = "21時12分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 21, 12, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '21時12分'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 2週間後', () {
      String input = "2週間後";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 14));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2週間後'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 1ヶ月後', () {
      String input = "1ヶ月後";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '1ヶ月後'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 2週間後火曜', () {
      String input = "2週間後火曜";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 18, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2週間後火曜'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 来週火曜', () {
      String input = "来週火曜";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 11, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '来週火曜'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 明後日12時', () {
      String input = "明後日12時";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 10, 12, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明後日12時'");
      expect(results.first.date == expected, true);
    });

    // test('Japanese: 5日以内', () {
    //  String input = "5日以内";
    //// List<ParsingResult> results = parse(input, referenceDate: reference);
    //   DateTime expected = reference.add(Duration(days: 5));
    //    print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
    //    expect(results.isNotEmpty, true, reason: "Result should not be empty for '5日以内'");
    //    expect(results.first.date == expected, true);
    //   });

    //  test('Japanese: 三日以内', () {
    //    String input = "三日以内";
    //    List<ParsingResult> results = parse(input, referenceDate: reference);
    //   DateTime expected = reference.add(Duration(days: 3));
    //   print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
    //   expect(results.isNotEmpty, true, reason: "Result should not be empty for '三日以内'");
    //    expect(results.first.date == expected, true);
    // });

    test('Japanese: 来週日曜11時', () {
      String input = "来週日曜11時";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 11, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '来週日曜11時'");
      expect(results.first.date == expected, true);
    });

    // 以下の2テストは、以前は "No result" となっていましたが、
    // 基準日時と入力文から最も近い将来の日付を返す仕様に合わせ、正しい期待値に更新します。

    test('Chinese: 六号', () {
      String input = "六号";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 6, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "'六号'");
      expect(results.first.date == expected, true);
    });

    test('English: 3th', () {
      String input = "3th";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 3, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "'3th'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 14日', () {
      String input = "14日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 14, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "'14日'");
      expect(results.first.date == expected, true);
    });

    test('English: Next Tuesday', () {
      String input = "Next Tuesday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 11, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Next Tuesday'");
      expect(results.first.date == expected, true);
    });

    test('English: Last Monday', () {
      String input = "Last Monday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 3, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Last Monday'");
      expect(results.first.date == expected, true);
    });

    test('English: August 15, 2025', () {
      String input = "August 15, 2025";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 8, 15, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'August 15, 2025'");
      expect(results.first.date == expected, true);
    });

    test('English: Sep 30', () {
      String input = "Sep 30";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 9, 30, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Sep 30'");
      expect(results.first.date == expected, true);
    });

    test('English: Midnight', () {
      String input = "Midnight";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Midnight'");
      expect(results.first.date == expected, true);
    });

    test('English: Noon', () {
      String input = "Noon";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 12, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Noon'");
      expect(results.first.date == expected, true);
    });

    test('English: 3 days ago', () {
      String input = "3 days ago";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.subtract(Duration(days: 3));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '3 days ago'");
      expect(results.first.date == expected, true);
    });

    test('English: next year', () {
      String input = "next year";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2026, 2, 8, 11, 5, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'next year'");
      expect(results.first.date == expected, true);
    });

    test('English: last year', () {
      String input = "last year";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2024, 2, 8, 11, 5, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'last year'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 明天上午9点', () {
      String input = "明天上午9点";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 9, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明天上午9点'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 后天晚上8点', () {
      String input = "后天晚上8点";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 10, 20, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '后天晚上8点'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 昨天12点', () {
      String input = "昨天12点";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 7, 12, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '昨天12点'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 下个月15号', () {
      String input = "下个月15号";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 15, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '下个月15号'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 上个月20号', () {
      String input = "上个月20号";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 1, 20, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '上个月20号'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 12月31日', () {
      String input = "12月31日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 12, 31, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '12月31日'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 明年1月1日', () {
      String input = "明年1月1日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2026, 1, 1, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明年1月1日'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 2天后', () {
      String input = "2天后";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 2));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2天后'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 3天前', () {
      String input = "3天前";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.subtract(Duration(days: 3));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '3天前'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 下周四', () {
      String input = "下周四";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 13, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '下周四'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 周三', () {
      String input = "周三";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 12, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '周三'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 明後日12時', () {
      String input = "明後日12時";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 10, 12, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明後日12時'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 来週日曜11時', () {
      String input = "来週日曜11時";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 11, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '来週日曜11時'");
      expect(results.first.date == expected, true);
    });

    test('Chinese: 三月四号', () {
      String input = "三月四号";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 4, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "最も近い3月4日が結果となる");
      expect(results.first.date == expected, true);
    });

    test('English: Next Wednesday', () {
      String input = "Next Wednesday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 12, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Next Wednesday'");
      expect(results.first.date == expected, true);
    });

    // test('English: in 5 days', () {
    //   String input = "in 5 days";
    //    List<ParsingResult> results = parse(input, referenceDate: reference);
    //    DateTime expected = reference.add(Duration(days: 5));
    //   print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
    //    expect(results.isNotEmpty, true, reason: "Result should not be empty for 'in 5 days'");
    //    expect(results.first.date == expected, true);
    //  });

    test('English: 4:30 (time only)', () {
      String input = "4:30";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 4, 30, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '4:30'");
      expect(results.first.date == expected, true);
    });

    test('English: Sunday', () {
      String input = "Sunday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Sunday'");
      expect(results.first.date == expected, true);
    });

    // Universal pattern: ISO 8601 string
    test('Universal: ISO 8601', () {
      String input = "2025-02-08T15:00:00Z";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime.parse("2025-02-08T15:00:00Z");
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for ISO 8601 input");
      expect(results.first.date == expected, true);
    });
  });
}

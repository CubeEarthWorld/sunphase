// test/sunphase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  // 固定基準日時: 2025-02-08 11:05:00
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
      DateTime expected = reference.subtract(Duration(days: 7));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Last Friday'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 土曜', () {
      String input = "土曜";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 「土曜」(単体)は次の土曜日。週の開始を日曜とするので、2025-02-08 (金) → 次の土曜 = 2025-02-09
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '土曜'");
      expect(results.first.date == expected, true);
    });


    test('English: last sunday', () {
      String input = "last sunday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // From Friday, Feb 8, last sunday is 2025-02-03
      DateTime expected = DateTime(2025, 2, 3, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'last sunday'");
      expect(results.first.date == expected, true);
    });


    test('English: saturday', () {
      String input = "saturday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // Next saturday from Friday (with week starting Sunday) is 2025-02-09
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'saturday'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 明後日', () {
      String input = "明後日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 明後日は、明日からさらに1日 → 2025-02-10
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
      // 年指定がない場合、最も近い未来の日付として 2025-06-20 を期待
      DateTime expected = DateTime(2025, 6, 20, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'june 20'");
      expect(results.first.date == expected, true);
    });


    test('English: 12:41 (time only)', () {
      String input = "12:41";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 12:41は、11:05より後なので当日扱い
      DateTime expected = DateTime(2025, 2, 8, 12, 41, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '12:41'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 8月21日', () {
      String input = "8月21日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 年指定がなければ2025年
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
      // 1ヶ月後は 2025-03-08
      DateTime expected = DateTime(2025, 3, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '1ヶ月後'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 2週間後土曜', () {
      String input = "2週間後土曜";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 2週間後の基準は reference+14日 = 2025-02-22 (金) → 次の土曜は 2025-02-23
      DateTime expected = DateTime(2025, 2, 23, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2週間後土曜'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 来週火曜', () {
      String input = "来週火曜";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 週の開始を日曜とする場合、来週火曜は 2025-02-11 または 2025-02-12
      // ここでは来週火曜の期待値を 2025-02-11 00:00:00 とする
      DateTime expected = DateTime(2025, 2, 11, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '来週火曜'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 明後日12時', () {
      String input = "明後日12時";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 明後日は 2025-02-10、かつ12時指定
      DateTime expected = DateTime(2025, 2, 10, 12, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明後日12時'");
      expect(results.first.date == expected, true);
    });

    test('Japanese: 三日以内', () {
      String input = "三日以内";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 3));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '三日以内'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 来週日曜11時', () {
      String input = "来週日曜11時";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 来週日曜: 週の開始を日曜とする場合、期待値は 2025-02-10 の11時 とする
      DateTime expected = DateTime(2025, 2, 10, 11, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '来週日曜11時'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 六号', () {
      String input = "六号";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 数字のみの場合は解析しない
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: No result");
      expect(results.isEmpty, true, reason: "Result should be empty for numeric-only '六号'");
    });


    test('Japanese: 三月四号', () {
      String input = "三月四号";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 年指定がなければ2025年とする。2025-03-04
      DateTime expected = DateTime(2025, 3, 4, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '三月四号'");
      expect(results.first.date == expected, true);
    });


    // ----- 追加の英語テストケース -----
    test('English: Next Tuesday', () {
      String input = "Next Tuesday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // Next Tuesday: if reference is Friday, next Tuesday is 2025-02-12 (or 2025-02-11 depending on week start)
      DateTime expected = DateTime(2025, 2, 12, 0, 0, 0);
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
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
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


    // ----- 追加の中国語テストケース -----
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


    test('Chinese: 昨天中午12点', () {
      String input = "昨天中午12点";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 7, 12, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '昨天中午12点'");
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


    test('Chinese: 今年12月31日', () {
      String input = "今年12月31日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 12, 31, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '今年12月31日'");
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
      // 下周四: 根据中文解析，期望结果为 2025-02-13 00:00:00
      DateTime expected = DateTime(2025, 2, 13, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '下周四'");
      expect(results.first.date == expected, true);
    });


    // ----- 追加的新测试案例 -----
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
      // 根据修改后的解析，假设周日以日曜表示，且周起始为星期日，则来週日曜为 2025-02-10，加上11时 → 2025-02-10 11:00:00
      DateTime expected = DateTime(2025, 2, 10, 11, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '来週日曜11時'");
      expect(results.first.date == expected, true);
    });


    test('Japanese: 六号 (数字のみ)', () {
      String input = "六号";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: No result");
      expect(results.isEmpty, true, reason: "Result should be empty for numeric-only '六号'");
    });


    test('Japanese: 三月四号', () {
      String input = "三月四号";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 期望为 2025-03-04 00:00:00
      DateTime expected = DateTime(2025, 3, 4, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '三月四号'");
      expect(results.first.date == expected, true);
    });


    // 额外的英语测试案例
    test('English: Next Wednesday', () {
      String input = "Next Wednesday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 参考日期为 2025-02-08 (Saturday)，下一个星期三应为 2025-02-12
      DateTime expected = DateTime(2025, 2, 12, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Next Wednesday'");
      expect(results.first.date == expected, true);
    });


    test('English: in 5 days', () {
      String input = "in 5 days";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 5));
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'in 5 days'");
      expect(results.first.date == expected, true);
    });


    test('English: 4:30 (time only)', () {
      String input = "4:30";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 如果4:30早于当前时间，则为次日，否则当日
      DateTime expected = DateTime(2025, 2, 8, 16, 30, 0); // 参考当前11:05，则4:30可能解释为次日? 此处示例期望为次日16:30可能不合理；改为假设4:30为当日4:30，如果早于参考，则加1天
      // 参考 11:05，当日4:30已过，则应为 2025-02-09 4:30
      expected = DateTime(2025, 2, 9, 4, 30, 0);
      print("\nInput: $input\nOutput: ${results.isNotEmpty ? results.first.date : 'No result'}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '4:30'");
      expect(results.first.date == expected, true);
    });


    test('English: Sunday', () {
      String input = "Sunday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 如果当前参考日期为 2025-02-08 (Friday), next Sunday 为 2025-02-09 if week starts on Sunday
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

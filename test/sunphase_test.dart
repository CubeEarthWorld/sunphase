// test/sunphase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  // 固定基準日時: 2025年2月8日(土) 11:05:00
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);
  print("Reference Date: $reference\n");

  group('Additional Sunphase Parser Tests', () {
    // ──────────────────────────────
    // 既存のサンプルテストケース
    test('English: Today', () {
      String input = "Today買い物をする";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Today'");
      expect(results.first.date, expected);
    });

    test('English: Tomorrow', () {
      String input = "Tomorrow学校に行く";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Tomorrow'");
      expect(results.first.date, expected);
    });

    test('Japanese: 明日の', () {
      String input = "明日の";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明日の'");
      expect(results.first.date, expected);
    });

    test('Japanese: 4月26日4時8分', () {
      String input = "4月26日4時8分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 4, 26, 4, 8, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '4月26日4時8分'");
      expect(results.first.date, expected);
    });

    test('Japanese: 時刻のみ "21時31分"', () {
      String input = "21時31分カフェでお茶をする";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 21, 31, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '21時31分'");
      expect(results.first.date, expected);
    });

    test('English: 2 weeks from now', () {
      String input = "2 weeks from now";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 14));
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2 weeks from now'");
      expect(results.first.date, expected);
    });

    test('English: 4 days later', () {
      String input = "4 days later";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 4));
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '4 days later'");
      expect(results.first.date, expected);
    });

    test('English: 5 days ago', () {
      String input = "5 days ago";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.subtract(Duration(days: 5));
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '5 days ago'");
      expect(results.first.date, expected);
    });

    test('English: Last Friday', () {
      String input = "Last Friday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Last Friday'");
      expect(results.first.date, expected);
    });

    test('Chinese: 今天', () {
      String input = "今天看私服";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '今天'");
      expect(results.first.date, expected);
    });

    test('English: Midnight', () {
      String input = "Midnight";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Midnight'");
      expect(results.first.date, expected);
    });

    test('Universal: ISO 8601', () {
      String input = "2025-02-08T15:00:00Z";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime.parse("2025-02-08T15:00:00Z");
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for ISO 8601 input");
      expect(results.first.date, expected);
    });

    test('Test: "3日12時15分"', () {
      String input = "3日12時15分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 3, 12, 15, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '3日12時15分'");
      expect(results.first.date, expected);
    });

    test('Test: "四号一点"', () {
      String input = "四号一点";
      List<ParsingResult> results = parse(input, referenceDate: reference,language:"zh");
      DateTime expected = DateTime(2025, 3, 4, 1, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '四号一点'");
      expect(results.first.date, expected);
    });

    test('Test: "3月1号 14:24"', () {
      String input = "3月1号 14:24";
      List<ParsingResult> results = parse(input, referenceDate: reference,language: "zh");
      DateTime expected = DateTime(2025, 3, 1, 14, 24, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected",);
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '3月1号 14:24'");
      expect(results.first.date, expected);
    });

    test('Test: "3月23日 14:24"', () {
      String input = "3月23日 14:24";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 23, 14, 24, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '3月23日 14:24'");
      expect(results.first.date, expected);
    });

    test('Test: "明日14時25分 "', () {
      String input = "明日14時25分 ";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 14, 25, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明日14時25分 '");
      expect(results.first.date, expected);
    });

    test('Test: "24日14時25分"', () {
      String input = "24日14時25分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 「24日」は同月内の24日と解釈
      DateTime expected = DateTime(2025, 2, 24, 14, 25, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '24日14時25分'");
      expect(results.first.date, expected);
    });

    test('Test: "木曜14時36分"', () {
      String input = "木曜14時36分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 2025/2/8（土）を基準とすると、次の木曜は2025/2/13
      DateTime expected = DateTime(2025, 2, 13, 14, 36, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '木曜14時36分'");
      expect(results.first.date, expected);
    });

    test('Test: "10:10" (時間のみ)', () {
      String input = "10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 10:10 は基準時刻より前のため翌日と解釈
      DateTime expected = DateTime(2025, 2, 9, 10, 10, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '10:10'");
      expect(results.first.date, expected);
    });

    test('Test: "march 7 10:10"', () {
      String input = "march 7 10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 7, 10, 10, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'march 7 10:10'");
      expect(results.first.date, expected);
    });

    test('Test: "明日12時14分" (日本語)', () {
      String input = "明日12時14分";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      DateTime expected = DateTime(2025, 2, 9, 12, 14, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '明日12時14分'");
      expect(results.first.date, expected);
    });

    test('Test: "三月七号上午九点" (中国語)', () {
      String input = "三月七号上午九点";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 3, 7, 9, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '三月七号上午九点'");
      expect(results.first.date, expected);
    });

    test('Test: "Tomorrow" (英語)', () {
      String input = "Tomorrow";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Tomorrow'");
      expect(results.first.date, expected);
    });

    test('Test: "三天后" (中国語)', () {
      String input = "三天后";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = reference.add(Duration(days: 3));
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '三天后'");
      expect(results.first.date, expected);
    });

    test('Test: "Next Tuesday" with custom reference', () {
      String input = "Next Tuesday";
      DateTime customRef = DateTime(2021, 2, 4);
      List<ParsingResult> results = parse(input, referenceDate: customRef, language: 'en');
      // 2021-02-04(木) の次の火曜は2021-02-09
      DateTime expected = DateTime(2021, 2, 9, 0, 0, 0);
      print("\nInput: $input\nReference: $customRef\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Next Tuesday' with custom reference");
      expect(results.first.date, expected);
    });

    test('Test: "Next week" in range mode', () {
      String input = "Next week";
      List<ParsingResult> results = parse(input, referenceDate: reference, rangeMode: true);
      // 例として、次週の開始を月曜、終了を日曜と仮定
      List<DateTime> expectedRange = [
        DateTime(2025, 2, 10, 0, 0, 0), // 月曜
        DateTime(2025, 2, 11, 0, 0, 0), // 火曜
        DateTime(2025, 2, 12, 0, 0, 0), // 水曜
        DateTime(2025, 2, 13, 0, 0, 0), // 木曜
        DateTime(2025, 2, 14, 0, 0, 0), // 金曜
        DateTime(2025, 2, 15, 0, 0, 0), // 土曜
        DateTime(2025, 2, 16, 0, 0, 0)  // 日曜
      ];
      print("\nInput: $input\nOutput: ${results.map((r) => r.date).toList()}\nExpected: $expectedRange");
      expect(results.length, expectedRange.length, reason: "Range mode should return two dates for 'Next week'");
      for (int i = 0; i < expectedRange.length; i++) {
        expect(results[i].date, expectedRange[i]);
      }
    });

    // ──────────────────────────────
    // タスク管理アプリを想定した仮想タスク入力テスト（30件以上）
    // 【英語タスク】
    test('Virtual Task EN: "Meeting with Bob at 3pm"', () {
      String input = "Meeting with Bob at 3pm";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 8, 15, 0, 0); // 3pm = 15:00（本日）
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Doctor appointment tomorrow at 09:00"', () {
      String input = "Doctor appointment tomorrow at 09:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 9, 9, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Dinner with family at 7:30pm"', () {
      String input = "Dinner with family at 7:30pm";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 8, 19, 30, 0); // 7:30pm = 19:30
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Submit report on March 15"', () {
      String input = "Submit report on March 15";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 3, 15, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Project deadline: Feb 28 23:59"', () {
      String input = "Project deadline: Feb 28 23:59";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 28, 23, 59, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Gym session at 06:00"', () {
      String input = "Gym session at 06:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      // 06:00 は既に過ぎているため翌日06:00と解釈
      DateTime expected = DateTime(2025, 2, 9, 6, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Lunch with client at noon"', () {
      String input = "Lunch with client at noon";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 8, 12, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Conference call on 4/20 at 10:00"', () {
      String input = "Conference call on 4/20 at 10:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 4, 20, 10, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Submit assignment next Monday"', () {
      String input = "Submit assignment next Monday";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      // 基準日 2025/2/8（土）の次の月曜は 2025/2/10
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Flight to Tokyo on 5th May 2025 at 8:00"', () {
      String input = "Flight to Tokyo on 5th May 2025 at 8:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 5, 5, 8, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task EN: "Call mom at 18:00"', () {
      String input = "Call mom at 18:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 8, 18, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    // 【日本語タスク】
    test('Virtual Task JA: "明日14時に会議"', () {
      String input = "明日14時に会議";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      DateTime expected = DateTime(2025, 2, 9, 14, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "水曜日午後3時に歯医者"', () {
      String input = "水曜日午後3時に歯医者";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      // 2025/2/8（土）の次の水曜は2025/2/12
      DateTime expected = DateTime(2025, 2, 12, 15, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "来週金曜日買い物"', () {
      String input = "来週金曜日買い物";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      // 2025/2/8（土）の次の金曜は2025/2/14
      DateTime expected = DateTime(2025, 2, 14, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "明後日18時30分ジム"', () {
      String input = "明後日18時30分ジム";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      DateTime expected = DateTime(2025, 2, 10, 18, 30, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "今夜20時映画を観る"', () {
      String input = "今夜20時映画を観る";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      // 基準時刻より遅いため本日と解釈
      DateTime expected = DateTime(2025, 2, 8, 20, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "来月3日9時打ち合わせ"', () {
      String input = "来月3日9時打ち合わせ";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      // 来月は3月、3日なので 2025-03-03 09:00:00
      DateTime expected = DateTime(2025, 3, 3, 9, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "12月25日0時クリスマスパーティー"', () {
      String input = "12月25日0時クリスマスパーティー";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      DateTime expected = DateTime(2025, 12, 25, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    // 【中国語タスク】
    test('Virtual Task ZH: "明天上午8点开会"', () {
      String input = "明天上午8点开会";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 2, 9, 8, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task ZH: "后天中午12点吃饭"', () {
      String input = "后天中午12点吃饭";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 2, 10, 12, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task ZH: "周五下午3点去看电影"', () {
      String input = "周五下午3点去看电影";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      // 2025/2/8（土）の次の周五は2025/2/14
      DateTime expected = DateTime(2025, 2, 14, 15, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task ZH: "下周一早上7点跑步"', () {
      String input = "下周一早上7点跑步";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      // 下周一＝2025/2/10
      DateTime expected = DateTime(2025, 2, 10, 7, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task ZH: "3月5日下午2点去参加婚礼"', () {
      String input = "3月5日下午2点去参加婚礼";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 3, 5, 14, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task ZH: "明年2月14日情人节聚会"', () {
      String input = "明年2月14日情人节聚会";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      // 明年 = 2026年
      DateTime expected = DateTime(2026, 2, 14, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task ZH: "昨天晚上8点看比赛"', () {
      String input = "昨天晚上8点看比赛";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 2, 7, 20, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task ZH: "周日早上10点参加教堂"', () {
      String input = "周日早上10点参加教堂";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 2, 9, 10, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    // ──────────────────────────────
    // 追加の ISO 8601、タイムゾーン、相対時間テスト

    test('ISO 8601 with offset: "2025-05-01T10:00:00+02:00"', () {
      String input = "2025-05-01T10:00:00+02:00";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime.parse("2025-05-01T10:00:00+02:00");
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Timezone override: "明天 15:00 开发"', () {
      String input = "明天 15:00";
      List<ParsingResult> results = parse(input, referenceDate: DateTime.now(),language: 'zh');
      DateTime expected = DateTime(2025, 2, 9, 15, 0, 0);
      print("\nInput: $input with timezone 300\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Relative: "30 minutes ago"', () {
      String input = "30 minutes ago";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = reference.subtract(Duration(minutes: 30));
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Mixed: "Let\'s meet at 7pm tomorrow for dinner."', () {
      String input = "Let's meet at 7pm tomorrow for dinner.";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 9, 19, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Mixed: "週末午後8時パーティー"', () {
      String input = "週末午後8時にパーティ";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      DateTime expected = DateTime(2025, 2, 9, 20, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Mixed: "会议安排：下周三上午10点"', () {
      String input = "会议安排：下周三上午10点";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 2, 12, 10, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task (month range, Japanese): "来月の予定"', () {
      String input = "来月の予定";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja', rangeMode: true);
      // 基準日 2025-02-08 → 来月＝3月。3月1日～3月31日
      expect(results.length, 31);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, 31, 0, 0, 0));
    });

    test('Virtual Task (month range, English): "next month"', () {
      String input = "next month";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en', rangeMode: true);
      // 2025-02-08 → next month＝3月
      expect(results.length, 31);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, 31, 0, 0, 0));
    });

    test('Virtual Task (month range, Chinese): "下月去大学"', () {
      String input = "下月去大学";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh', rangeMode: true);
      // 2025-02-08 → 下月＝3月
      expect(results.length, 31);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, 31, 0, 0, 0));
    });

    test('Virtual Task (month range, Chinese): "下周去大学"', () {
      String input = "下月去大学";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh', rangeMode: true);
      expect(results.length, 7);
      expect(results.first.date, DateTime(2025, 2, 9, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 15, 0, 0, 0));
    });

    test('Virtual Task (month range, Chinese): "来週大学に行く"', () {
      String input = "来週大学に行く";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja', rangeMode: true);
      expect(results.length, 7);
      expect(results.first.date, DateTime(2025, 2, 10, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 16, 0, 0, 0));
    });


    test('Virtual Task (month range, Chinese): "next week go to university"', () {
      String input = "next week go to university";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en', rangeMode: true);
      expect(results.length, 7);
      expect(results.first.date, DateTime(2025, 2, 10, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 16, 0, 0, 0));
    });


    test('Virtual Task (month range, English): "march"', () {
      String input = "march";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'en', rangeMode: true);
      // "march" → 2025-03 (since reference is 2025-02-08)
      expect(results.length, 31);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, 31, 0, 0, 0));
    });

    test('Virtual Task (month range, Japanese): "五月"', () {
      String input = "五月";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja', rangeMode: true);
      // "五月" → May 2025 (May has 31 days)
      expect(results.length, 31);
      expect(results.first.date, DateTime(2025, 5, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 5, 31, 0, 0, 0));
    });

    test('Virtual Task (month range, Chinese): "六月"', () {
      String input = "六月";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh', rangeMode: true);
      // "六月" → June 2025 (June has 30 days)
      expect(results.length, 30);
      expect(results.first.date, DateTime(2025, 6, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 6, 30, 0, 0, 0));
    });
  });

}

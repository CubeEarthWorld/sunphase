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
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for 'Today'");
      expect(results.first.date, expected);
    });

    test('Japanese: 明日買い物をする', () {
      String input = "明日買い物をする";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '明日'");
      expect(results.first.date, expected);
    });

    test('Chiniese: 明天', () {
      String input = "明天";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '明天'");
      expect(results.first.date, expected);
    });

    test('English: Tomorrow', () {
      String input = "Tomorrow学校に行く";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for 'Tomorrow'");
      expect(results.first.date, expected);
    });

    test('Japanese: 明日', () {
      String input = "明日";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '明日の'");
      expect(results.first.date, expected);
    });

    test('Japanese: 4月26日4時8分', () {
      String input = "4月26日4時8分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 4, 26, 4, 8, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '4月26日4時8分'");
      expect(results.first.date, expected);
    });

    test('Japanese: 時刻のみ "21時31分"', () {
      String input = "21時31分カフェでお茶をする";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 21, 31, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '21時31分'");
      expect(results.first.date, expected);
    });

    test('English: 2 weeks from now', () {
      String input = "2 weeks from now";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 14));
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '2 weeks from now'");
      expect(results.first.date, expected);
    });

    test('English: 4 days later', () {
      String input = "4 days later";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.add(Duration(days: 4));
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '4 days later'");
      expect(results.first.date, expected);
    });

    test('English: 5 days ago', () {
      String input = "5 days ago";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = reference.subtract(Duration(days: 5));
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '5 days ago'");
      expect(results.first.date, expected);
    });

    test('English: Last Friday', () {
      String input = "Last Friday";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for 'Last Friday'");
      expect(results.first.date, expected);
    });

    test('Chinese: 今天', () {
      String input = "今天看私服";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '今天'");
      expect(results.first.date, expected);
    });

    test('English: Midnight', () {
      String input = "Midnight";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for 'Midnight'");
      expect(results.first.date, expected);
    });

    test('Universal: ISO 8601', () {
      String input = "2025-02-08T15:00:00Z";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime.parse("2025-02-08T15:00:00Z");
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for ISO 8601 input");
      expect(results.first.date, expected);
    });

    test('Test: "3日12時15分"', () {
      String input = "3日12時15分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 3, 12, 15, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '3日12時15分'");
      expect(results.first.date, expected);
    });

    test('Test: "四号一点"', () {
      String input = "四号一点";
      List<ParsingResult> results =
          parse(input, referenceDate: reference, language: "zh");
      DateTime expected = DateTime(2025, 3, 4, 1, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '四号一点'");
      expect(results.first.date, expected);
    });

    test('Test: "3月1号 14:24"', () {
      String input = "3月1号 14:24";
      List<ParsingResult> results =
          parse(input, referenceDate: reference, language: "zh");
      DateTime expected = DateTime(2025, 3, 1, 14, 24, 0);
      print(
        "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected",
      );
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '3月1号 14:24'");
      expect(results.first.date, expected);
    });

    test('Test: "3月23日 14:24"', () {
      String input = "3月23日 14:24";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 23, 14, 24, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '3月23日 14:24'");
      expect(results.first.date, expected);
    });

    test('Test: "明日14時25分 "', () {
      String input = "明日14時25分 ";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 2, 9, 14, 25, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '明日14時25分 '");
      expect(results.first.date, expected);
    });

    test('Test: "24日14時25分"', () {
      String input = "24日14時25分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 「24日」は同月内の24日と解釈
      DateTime expected = DateTime(2025, 2, 24, 14, 25, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '24日14時25分'");
      expect(results.first.date, expected);
    });

    test('Test: "木曜14時36分"', () {
      String input = "木曜14時36分";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 2025/2/8（土）を基準とすると、次の木曜は2025/2/13
      DateTime expected = DateTime(2025, 2, 13, 14, 36, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '木曜14時36分'");
      expect(results.first.date, expected);
    });

    test('Test: "10:10" (時間のみ)', () {
      String input = "10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      // 10:10 は基準時刻より前のため翌日と解釈
      DateTime expected = DateTime(2025, 2, 9, 10, 10, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '10:10'");
      expect(results.first.date, expected);
    });

    test('Test: "march 7 10:10"', () {
      String input = "march 7 10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference);
      DateTime expected = DateTime(2025, 3, 7, 10, 10, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for 'march 7 10:10'");
      expect(results.first.date, expected);
    });

    test('Test: "明日十時三十一分" (日本語)', () {
      String input = "明日十時三十一分";
      List<ParsingResult> results =
          parse(input, referenceDate: reference, language: 'ja');
      DateTime expected = DateTime(2025, 2, 9, 10, 31, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '明日十時三十一分'");
      expect(results.first.date, expected);
    });

    test('Test: "三月七号上午九点" (中国語)', () {
      String input = "三月七号上午九点";
      List<ParsingResult> results =
          parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 3, 7, 9, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '三月七号上午九点'");
      expect(results.first.date, expected);
    });

    test('Test: "Tomorrow" (英語)', () {
      String input = "Tomorrow";
      List<ParsingResult> results =
          parse(input, referenceDate: reference, language: 'en');
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for 'Tomorrow'");
      expect(results.first.date, expected);
    });

    test('Test: "三天后" (中国語)', () {
      String input = "三天后";
      List<ParsingResult> results =
          parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = reference.add(Duration(days: 3));
      print(
          "\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true,
          reason: "Result should not be empty for '三天后'");
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

    test('Virtual Task JA: "明日14時23分に会議"', () {
      String input = "明日14時23分に会議";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      DateTime expected = DateTime(2025, 2, 9, 14, 23, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "水曜午後3時に歯医者"', () {
      String input = "水曜午後3時に歯医者";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      // 2025/2/8（土）の次の水曜は2025/2/12
      DateTime expected = DateTime(2025, 2, 12, 15, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "水曜11時に歯医者"', () {
      String input = "水曜11時に歯医者";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja');
      DateTime expected = DateTime(2025, 2, 12, 11, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task JA: "来週金曜買い物"', () {
      String input = "来週金曜買い物";
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

    test('Virtual Task ZH: "周天早上10点参加教堂"', () {
      String input = "周天早上10点参加教堂";
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
      List<ParsingResult> results = parse(input, referenceDate: reference,language: 'zh');
      DateTime expected = DateTime(2025, 2, 9, 15, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Timezone override: "明天十一时三十四分"', () {
      String input = "明天十一时三十四分";
      List<ParsingResult> results = parse(input, referenceDate: reference,language: 'zh');
      DateTime expected = DateTime(2025, 2, 9, 11, 34, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Mixed: "会议安排：下周三上午五点"', () {
      String input = "会议安排：下周三上午五点";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh');
      DateTime expected = DateTime(2025, 2, 12, 5, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.first.date, expected);
    });

    test('Virtual Task (month range, Japanese): "再来月の予定"', () {
      String input = "再来月の予定";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja', rangeMode: true);
      expect(results.length, 30);
      expect(results.first.date, DateTime(2025, 4, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 4, 30, 0, 0, 0));
    });

    test('Virtual Task (month range, Japanese): "来月の予定"', () {
      String input = "来月の予定";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja', rangeMode: true);
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

    test('Virtual Task (month range, Chinese): "下周去大学"', () {
      String input = "下周去大学";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'zh', rangeMode: true);
      expect(results.length, 7);
      expect(results.first.date, DateTime(2025, 2, 10, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 16, 0, 0, 0));
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

    test('Virtual Task (month range, Japanese): "十二月"', () {
      String input = "十二月";
      List<ParsingResult> results = parse(input, referenceDate: reference, language: 'ja', rangeMode: true);
      expect(results.length, 31);
      expect(results.first.date, DateTime(2025, 12, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 12, 31, 0, 0, 0));
    });
  });

}

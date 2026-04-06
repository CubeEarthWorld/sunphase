import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';
import 'package:sunphase/utils/date_utils.dart';

void main() {
  // 固定基準日時: 2025年2月8日(土) 11:05:00
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);
  print("Reference Date: $reference\n");

  // ══════════════════════════════════════════════════════════════════
  // Hindi Tests
  // ══════════════════════════════════════════════════════════════════
  group('Sunphase Parser Tests for Hindi', () {
    test('Hindi: "आज"', () {
      String input = "आज";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true);
      expect(results.first.date, expected);
    });

    test('Hindi: "कल"', () {
      String input = "कल";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "परसों"', () {
      String input = "परसों";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "14 मार्च 2025"', () {
      String input = "14 मार्च 2025";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 3, 14, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "सुबह 10:10"', () {
      String input = "सुबह 10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 9, 10, 10, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "आज 14:30"', () {
      String input = "आज 14:30";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 8, 14, 30, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "अगले सोमवार"', () {
      String input = "अगले सोमवार";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "पिछले शुक्रवार"', () {
      String input = "पिछले शुक्रवार";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "2 सप्ताह बाद"', () {
      String input = "2 सप्ताह बाद";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 22, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "3 दिन पहले"', () {
      String input = "3 दिन पहले";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "15 तारीख"', () {
      String input = "15 तारीख";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi: "सोमवार"', () {
      String input = "सोमवार";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Hindi (Range): "अगले महीने की योजना"', () {
      String input = "अगले महीने की योजना";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi'], rangeMode: true);
      int daysInMarch = DateUtils.getMonthRange(DateTime(2025, 3, 1))['end']!.day;
      expect(results.length, daysInMarch);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // Spanish Tests
  // ══════════════════════════════════════════════════════════════════
  group('Sunphase Parser Tests for Spanish', () {
    test('Spanish: "Hoy"', () {
      String input = "Hoy";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "Mañana"', () {
      String input = "Mañana";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "Ayer"', () {
      String input = "Ayer";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "14 de marzo de 2025"', () {
      String input = "14 de marzo de 2025";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 3, 14, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "10:10" (time only)', () {
      String input = "10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 9, 10, 10, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "Esta noche 21:31"', () {
      String input = "Esta noche 21:31";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 8, 21, 31, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "próximo lunes"', () {
      String input = "próximo lunes";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "hace 3 días"', () {
      String input = "hace 3 días";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "2 semanas desde ahora"', () {
      String input = "2 semanas desde ahora";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 22, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "3 días atrás"', () {
      String input = "3 días atrás";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "15 de febrero"', () {
      String input = "15 de febrero";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "martes"', () {
      String input = "martes";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 11, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "el tercer lunes de marzo"', () {
      String input = "el tercer lunes de marzo";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 3, 17, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "el último viernes de abril"', () {
      String input = "el último viernes de abril";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 4, 25, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "sábado"', () {
      String input = "sábado";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish (Range): "el próximo mes"', () {
      String input = "el próximo mes";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es'], rangeMode: true);
      int daysInMarch = DateUtils.getMonthRange(DateTime(2025, 3, 1))['end']!.day;
      expect(results.length, daysInMarch);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });

    test('Spanish (Range): "la semana pasada"', () {
      String input = "la semana pasada";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es'], rangeMode: true);
      expect(results.length, 7);
      expect(results.first.date, DateTime(2025, 2, 3, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 9, 0, 0, 0));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // English Tests
  // ══════════════════════════════════════════════════════════════════
  group('Sunphase Parser Tests for English', () {
    test('English: "Today"', () {
      String input = "Today";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "Tomorrow"', () {
      String input = "Tomorrow";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "Yesterday"', () {
      String input = "Yesterday";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "Midnight"', () {
      String input = "Midnight";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "2 weeks from now"', () {
      String input = "2 weeks from now";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 22, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "4 days later"', () {
      String input = "4 days later";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 12, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "5 days ago"', () {
      String input = "5 days ago";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 3, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "Last Friday"', () {
      String input = "Last Friday";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "march 7 10:10"', () {
      String input = "march 7 10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 3, 7, 10, 10, 0);
      expect(results.first.date, expected);
    });

    test('English: "the 16th" (ordinal)', () {
      String input = "the 16th";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 16, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "February 28"', () {
      String input = "February 28";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 28, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('English: "Dentist on the 20th at 3pm"', () {
      String input = "Dentist on the 20th at 3pm";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 20, 15, 0, 0);
      expect(results.first.date, expected);
    });

    test('English (Range): "next week go to university"', () {
      String input = "next week go to university";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en'], rangeMode: true);
      expect(results.length, 7);
      // "next week" from Feb 8 (Saturday) = Feb 15 (Saturday, 7 days later)
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
  });

  // ══════════════════════════════════════════════════════════════════
  // Japanese Tests
  // ══════════════════════════════════════════════════════════════════
  group('Sunphase Parser Tests for Japanese', () {
    test('Japanese: "今日"', () {
      String input = "今日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "明日"', () {
      String input = "明日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "昨日"', () {
      String input = "昨日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "21時31分"', () {
      String input = "21時31分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 8, 21, 31, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "3日12時15分"', () {
      String input = "3日12時15分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 3, 3, 12, 15, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "明日14時25分"', () {
      String input = "明日14時25分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 9, 14, 25, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "24日14時25分"', () {
      String input = "24日14時25分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 24, 14, 25, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "木曜14時36分"', () {
      String input = "木曜14時36分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 13, 14, 36, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "明日十時三十一分"', () {
      String input = "明日十時三十一分";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 9, 10, 31, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "再来週土曜"', () {
      String input = "再来週土曜";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 22, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "明日5時"', () {
      String input = "明日5時";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 9, 5, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "来年五月十二日"', () {
      String input = "来年五月十二日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2026, 5, 12, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "16日"', () {
      String input = "16日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 16, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "3日" (past day → next month)', () {
      String input = "3日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 3, 3, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "十六日" (kanji number)', () {
      String input = "十六日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 16, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "8日" (same day as reference → next month)', () {
      String input = "8日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 3, 8, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "16日 14時"', () {
      String input = "16日 14時";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 16, 14, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "2月28日"', () {
      String input = "2月28日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 28, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "31日" (Feb has no 31st → March 31)', () {
      String input = "31日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 3, 31, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "1日" (already passed → next month)', () {
      String input = "1日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 3, 1, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese: "20日に歯医者"', () {
      String input = "20日に歯医者";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja']);
      DateTime expected = DateTime(2025, 2, 20, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Japanese (Range): "来月の予定"', () {
      String input = "来月の予定";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['ja'], rangeMode: true);
      int daysInMarch = DateUtils.getMonthRange(DateTime(2025, 3, 1))['end']!.day;
      expect(results.length, daysInMarch);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // Chinese Tests
  // ══════════════════════════════════════════════════════════════════
  group('Sunphase Parser Tests for Chinese', () {
    test('Chinese: "今天"', () {
      String input = "今天";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "明天"', () {
      String input = "明天";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "昨天"', () {
      String input = "昨天";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "四号一点"', () {
      String input = "四号一点";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 3, 4, 1, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "3月1号 14:24"', () {
      String input = "3月1号 14:24";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 3, 1, 14, 24, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "三月七号上午九点"', () {
      String input = "三月七号上午九点";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 3, 7, 9, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "三天后"', () {
      String input = "三天后";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 11, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "16号" (Arabic numeral)', () {
      String input = "16号";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 16, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "十六号" (Chinese numeral)', () {
      String input = "十六号";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 16, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "20号下午3点"', () {
      String input = "20号下午3点";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 20, 15, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "2月28日"', () {
      String input = "2月28日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 28, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "29日" (Feb 2025 has no 29th → March 29)', () {
      String input = "29日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 3, 29, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Chinese: "20号去看牙医"', () {
      String input = "20号去看牙医";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['zh']);
      DateTime expected = DateTime(2025, 2, 20, 0, 0, 0);
      expect(results.first.date, expected);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // Cross-Language Tests
  // ══════════════════════════════════════════════════════════════════
  group('Cross-Language Tests', () {
    test('Mixed: "Today買い物をする"', () {
      String input = "Today買い物をする";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en', 'ja', 'zh']);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Mixed: "2026年5月14日"', () {
      String input = "2026年5月14日";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en', 'ja', 'zh']);
      DateTime expected = DateTime(2026, 5, 14, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Universal: ISO 8601', () {
      String input = "2025-02-08T15:00:00Z";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en', 'ja', 'zh']);
      // "2025-02-08T15:00:00Z" is 15:00 UTC
      DateTime expected = DateTime.utc(2025, 2, 8, 15, 0, 0);
      expect(results.first.date, expected);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // Virtual Task Tests
  // ══════════════════════════════════════════════════════════════════
  group('Virtual Task Tests', () {
    test('EN: "Gym session at 06:00"', () {
      String input = "Gym session at 06:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 9, 6, 0, 0);
      expect(results.first.date, expected);
    });

    test('EN: "Lunch with client at noon"', () {
      String input = "Lunch with client at noon";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['en']);
      DateTime expected = DateTime(2025, 2, 8, 12, 0, 0);
      expect(results.first.date, expected);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // Day-Only in Sentences
  // ══════════════════════════════════════════════════════════════════
  group('Day-Only in Sentences', () {
    test('HI: "15 तारीख को मीटिंग"', () {
      String input = "15 तारीख को मीटिंग";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 15);
      expect(results.first.date, expected);
    });

    test('ES: "Cita el día 20 a las 15:00"', () {
      String input = "Cita el día 20 a las 15:00";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 20, 15, 0);
      expect(results.first.date, expected);
    });

    test('ES: "el día 20"', () {
      String input = "el día 20";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 20);
      expect(results.first.date, expected);
    });

    test('ES: "28 de febrero"', () {
      String input = "28 de febrero";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 28);
      expect(results.first.date, expected);
    });
  });
}

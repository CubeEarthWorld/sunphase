import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';
import 'package:sunphase/utils/date_utils.dart';

void main() {
  // 固定基準日時: 2025年2月8日(土) 11:05:00
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);
  print("Reference Date: $reference\n");

  group('Sunphase Parser Tests for Hindi', () {
    test('Hindi: "आज"', () {
      String input = "आज";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'आज'");
      expect(results.first.date, expected);
    });

    test('Hindi: "कल"', () {
      String input = "कल";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'कल'");
      expect(results.first.date, expected);
    });

    test('Hindi: "परसों"', () {
      String input = "परसों";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'परसों'");
      expect(results.first.date, expected);
    });

    test('Hindi: "14 मार्च 2025"', () {
      String input = "14 मार्च 2025";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 3, 14, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '14 मार्च 2025'");
      expect(results.first.date, expected);
    });

    test('Hindi: "सुबह 10:10"', () {
      String input = "सुबह 10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      // 基準時刻 11:05 より早いため翌日と解釈
      DateTime expected = DateTime(2025, 2, 9, 10, 10, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'सुबह 10:10'");
      expect(results.first.date, expected);
    });

    test('Hindi: "आज 14:30"', () {
      String input = "आज 14:30";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 8, 14, 30, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'आज 14:30'");
      expect(results.first.date, expected);
    });

    test('Hindi: "अगले सोमवार"', () {
      String input = "अगले सोमवार";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      // 基準日 2025/2/8（土）の次の月曜は 2025/2/10
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'अगले सोमवार'");
      expect(results.first.date, expected);
    });

    test('Hindi: "पिछले शुक्रवार"', () {
      String input = "पिछले शुक्रवार";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      // 基準日 2025/2/8（土）の前の शुक्रवारは 2025/2/7
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'पिछले शुक्रवार'");
      expect(results.first.date, expected);
    });

    test('Hindi: "2 सप्ताह बाद"', () {
      String input = "2 सप्ताह बाद";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 22, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2 सप्ताह बाद'");
      expect(results.first.date, expected);
    });

    test('Hindi: "3 दिन पहले"', () {
      String input = "3 दिन पहले";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '3 दिन पहले'");
      expect(results.first.date, expected);
    });

    // 追加：日付のみ、曜日のみ、いついつの何曜日 表現
    test('Hindi: "15 तारीख"', () {
      // 「15 तारीख」は当月15日と解釈（基準日 2025/2/8 → 2025/2/15）
      String input = "15 तारीख";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '15 तारीख'");
      expect(results.first.date, expected);
    });

    test('Hindi: "सोमवार"', () {
      // 単独の曜日表現の場合、基準日が शनिवारなら次の सोमवार (2025/2/10)
      String input = "सोमवार";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi']);
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'सोमवार'");
      expect(results.first.date, expected);
    });

    test('Hindi (Range): "अगले महीने की योजना"', () {
      String input = "अगले महीने की योजना";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['hi'], rangeMode: true);
      // अगले महीने = मार्च 2025 と解釈（基準が फरवरी ）
      int daysInMarch = DateUtils.getMonthRange(DateTime(2025, 3, 1))['end']!.day;
      expect(results.length, daysInMarch, reason: "Result length should equal number of days in March 2025");
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });
  });

  group('Sunphase Parser Tests for Spanish', () {
    test('Spanish: "Hoy"', () {
      String input = "Hoy";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Hoy'");
      expect(results.first.date, expected);
    });

    test('Spanish: "Mañana"', () {
      String input = "Mañana";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Mañana'");
      expect(results.first.date, expected);
    });

    test('Spanish: "Ayer"', () {
      String input = "Ayer";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Ayer'");
      expect(results.first.date, expected);
    });

    test('Spanish: "14 de marzo de 2025"', () {
      String input = "14 de marzo de 2025";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 3, 14, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '14 de marzo de 2025'");
      expect(results.first.date, expected);
    });

    test('Spanish: "10:10" (time only)', () {
      String input = "10:10";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      // 10:10 es anterior al 11:05 de referencia, por lo tanto se interpreta para el día siguiente.
      DateTime expected = DateTime(2025, 2, 9, 10, 10, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '10:10'");
      expect(results.first.date, expected);
    });

    test('Spanish: "Esta noche 21:31"', () {
      String input = "Esta noche 21:31";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 8, 21, 31, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'Esta noche 21:31'");
      expect(results.first.date, expected);
    });

    test('Spanish: "próximo lunes"', () {
      String input = "próximo lunes";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      // La siguiente lunes a partir de 2025/2/8 (sábado) es 2025/2/10
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'próximo lunes'");
      expect(results.first.date, expected);
    });

    test('Spanish: "hace 3 días"', () {
      String input = "hace 3 días";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'hace 3 días'");
      expect(results.first.date, expected);
    });

    test('Spanish: "2 semanas desde ahora"', () {
      String input = "2 semanas desde ahora";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 22, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '2 semanas desde ahora'");
      expect(results.first.date, expected);
    });

    test('Spanish: "3 días atrás"', () {
      String input = "3 días atrás";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '3 días atrás'");
      expect(results.first.date, expected);
    });

    // 追加：日付のみ、曜日のみ、いついつの何曜日 表現
    test('Spanish: "15 de febrero"', () {
      String input = "15 de febrero";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for '15 de febrero'");
      expect(results.first.date, expected);
    });

    test('Spanish: "martes"', () {
      // Si se ingresa sólo "martes" y la fecha de referencia es sábado (2025/2/8), se espera el próximo martes (2025/2/11)
      String input = "martes";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 11, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'martes'");
      expect(results.first.date, expected);
    });

    test('Spanish: "el tercer lunes de marzo"', () {
      String input = "el tercer lunes de marzo";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      // En marzo 2025, los lunes caen el 3, 10 y 17 → el tercer lunes es el 17 de marzo
      DateTime expected = DateTime(2025, 3, 17, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'el tercer lunes de marzo'");
      expect(results.first.date, expected);
    });

    test('Spanish: "el último viernes de abril"', () {
      String input = "el último viernes de abril";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      // En abril 2025, los viernes son 4, 11, 18 y 25 → el último es 25 de abril
      DateTime expected = DateTime(2025, 4, 25, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'el último viernes de abril'");
      expect(results.first.date, expected);
    });

    test('Spanish: "sábado"', () {
      // Si se ingresa sólo "sábado" y la fecha de referencia es sábado, se espera el siguiente sábado (2025/2/15)
      String input = "sábado";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es']);
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      print("\nInput: $input\nOutput: ${results.first.date}\nExpected: $expected");
      expect(results.isNotEmpty, true, reason: "Result should not be empty for 'sábado'");
      expect(results.first.date, expected);
    });

    test('Spanish (Range): "el próximo mes"', () {
      String input = "el próximo mes";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es'], rangeMode: true);
      // Next month relative to Feb 2025 is March 2025
      int daysInMarch = DateUtils.getMonthRange(DateTime(2025, 3, 1))['end']!.day;
      expect(results.length, daysInMarch, reason: "Result length should equal number of days in March 2025");
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });

    test('Spanish (Range): "la semana pasada"', () {
      String input = "la semana pasada";
      List<ParsingResult> results = parse(input, referenceDate: reference, languages: ['es'], rangeMode: true);
      // Suponiendo que la semana pasada empieza el lunes 3 de febrero y termina el domingo 9 de febrero
      expect(results.length, 7, reason: "Result length should be 7 for a week range");
      expect(results.first.date, DateTime(2025, 2, 3, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 9, 0, 0, 0));
    });
  });
}

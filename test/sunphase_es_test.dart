import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';
import 'package:sunphase/utils/date_utils.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);
  print("Reference Date: $reference\n");

  group('Sunphase Parser Tests for Spanish', () {
    test('Spanish: "Hoy"', () {
      String input = "Hoy";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 8, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "Mañana"', () {
      String input = "Mañana";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "Ayer"', () {
      String input = "Ayer";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "14 de marzo de 2025"', () {
      String input = "14 de marzo de 2025";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 3, 14, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "10:10"', () {
      String input = "10:10";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 9, 10, 10, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "Esta noche 21:31"', () {
      String input = "Esta noche 21:31";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 8, 21, 31, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "próximo lunes"', () {
      String input = "próximo lunes";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 10, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "domingo de la próxima semana"', () {
      String input = "domingo de la próxima semana";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 9, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "domingo de la próxima semana" with Monday week start', () {
      String input = "domingo de la próxima semana";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
        weekStartsOn: DateTime.monday,
      );
      DateTime expected = DateTime(2025, 2, 16, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "hace 3 días"', () {
      String input = "hace 3 días";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "2 semanas desde ahora"', () {
      String input = "2 semanas desde ahora";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 22, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "3 días atrás"', () {
      String input = "3 días atrás";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 5, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "15 de febrero"', () {
      String input = "15 de febrero";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "martes"', () {
      String input = "martes";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 11, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "el tercer lunes de marzo"', () {
      String input = "el tercer lunes de marzo";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 3, 17, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "el último viernes de abril"', () {
      String input = "el último viernes de abril";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 4, 25, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "sábado"', () {
      String input = "sábado";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 15, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish (Range): "el próximo mes"', () {
      String input = "el próximo mes";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
        rangeMode: true,
      );
      int daysInMarch = DateUtils.getMonthRange(
        DateTime(2025, 3, 1),
      )['end']!.day;
      expect(results.length, daysInMarch);
      expect(results.first.date, DateTime(2025, 3, 1, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 3, daysInMarch, 0, 0, 0));
    });

    test('Spanish (Range): "la semana pasada"', () {
      String input = "la semana pasada";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
        rangeMode: true,
      );
      expect(results.length, 7);
      expect(results.first.date, DateTime(2025, 1, 26, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 1, 0, 0, 0));
    });

    test('Spanish (Range): "la semana pasada" with Monday week start', () {
      String input = "la semana pasada";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
        rangeMode: true,
        weekStartsOn: DateTime.monday,
      );
      expect(results.length, 7);
      expect(results.first.date, DateTime(2025, 1, 27, 0, 0, 0));
      expect(results.last.date, DateTime(2025, 2, 2, 0, 0, 0));
    });

    test('ES Day-Only: "el día 20"', () {
      String input = "el día 20";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 20);
      expect(results.first.date, expected);
    });

    test('ES: "28 de febrero"', () {
      String input = "28 de febrero";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 28);
      expect(results.first.date, expected);
    });

    test('ES Sentence: "Cita el día 20 a las 15:00"', () {
      String input = "Cita el día 20 a las 15:00";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 20, 15, 0);
      expect(results.first.date, expected);
    });

    // --- Next/last week + weekday tests ---

    test('Spanish: "pasado viernes"', () {
      String input = "pasado viernes";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 7, 0, 0, 0);
      expect(results.first.date, expected);
    });

    test('Spanish: "pasado lunes"', () {
      String input = "pasado lunes";
      List<ParsingResult> results = parse(
        input,
        referenceDate: reference,
        languages: ['es'],
      );
      DateTime expected = DateTime(2025, 2, 3, 0, 0, 0);
      expect(results.first.date, expected);
    });
  });
}

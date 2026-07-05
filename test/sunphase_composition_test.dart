// Black-box composition tests.
//
// These tests were written from the *intended* semantics of each language
// (without reading the parser implementation) to verify that date
// components compose correctly: month/week anchors + day-of-month +
// time-of-day must merge into a single resolved instant.
//
// Reference date: Saturday 2025-02-08 11:05 (same as every other suite).
// Week-anchor + weekday follows the calendar-week convention already
// fixed by the existing suites (来週火曜日 → 2025-02-11, 再来週月曜日 →
// 2025-02-17, next week Sunday → 2025-02-09).

import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  DateTime reference = DateTime(2025, 2, 8, 11, 5, 0);

  ParsingResult first(String input, String lang) =>
      parse(input, referenceDate: reference, languages: [lang]).first;

  group('Japanese composition (mandatory cases)', () {
    test('JA: "再来月21日"', () {
      expect(first("再来月21日", 'ja').date, DateTime(2025, 4, 21, 0, 0, 0));
    });

    test('JA: "来月21日12時31分"', () {
      expect(first("来月21日12時31分", 'ja').date, DateTime(2025, 3, 21, 12, 31, 0));
    });

    test('JA: "来月21日14時"', () {
      expect(first("来月21日14時", 'ja').date, DateTime(2025, 3, 21, 14, 0, 0));
    });

    test('JA: "再来月14日12時41分"', () {
      expect(first("再来月14日12時41分", 'ja').date, DateTime(2025, 4, 14, 12, 41, 0));
    });

    test('JA: "来週火曜14時14分"', () {
      expect(first("来週火曜14時14分", 'ja').date, DateTime(2025, 2, 11, 14, 14, 0));
    });

    test('JA: "再来週火曜日14時31分"', () {
      expect(first("再来週火曜日14時31分", 'ja').date, DateTime(2025, 2, 18, 14, 31, 0));
    });
  });

  group('Japanese composition (broader coverage)', () {
    test('JA: "来月5日"', () {
      expect(first("来月5日", 'ja').date, DateTime(2025, 3, 5, 0, 0, 0));
    });

    test('JA: "再来月1日9時"', () {
      expect(first("再来月1日9時", 'ja').date, DateTime(2025, 4, 1, 9, 0, 0));
    });

    test('JA: "来週金曜18時30分"', () {
      expect(first("来週金曜18時30分", 'ja').date, DateTime(2025, 2, 14, 18, 30, 0));
    });

    test('JA: "再来週金曜日"', () {
      expect(first("再来週金曜日", 'ja').date, DateTime(2025, 2, 21, 0, 0, 0));
    });

    test('JA: "先週火曜14時"', () {
      expect(first("先週火曜14時", 'ja').date, DateTime(2025, 2, 4, 14, 0, 0));
    });

    test('JA: "来年3月21日14時"', () {
      expect(first("来年3月21日14時", 'ja').date, DateTime(2026, 3, 21, 14, 0, 0));
    });

    test('JA: "10日後14時"', () {
      expect(first("10日後14時", 'ja').date, DateTime(2025, 2, 18, 14, 0, 0));
    });

    test('JA: "来週の火曜日" (の connective)', () {
      expect(first("来週の火曜日", 'ja').date, DateTime(2025, 2, 11, 0, 0, 0));
    });

    test('JA: "明日午後3時"', () {
      expect(first("明日午後3時", 'ja').date, DateTime(2025, 2, 9, 15, 0, 0));
    });

    test('JA: "明後日午前9時30分"', () {
      expect(first("明後日午前9時30分", 'ja').date, DateTime(2025, 2, 10, 9, 30, 0));
    });

    test('JA: "3ヶ月後"', () {
      expect(first("3ヶ月後", 'ja').date, DateTime(2025, 5, 1, 0, 0, 0));
    });

    test('JA: "週末"', () {
      expect(first("週末", 'ja').date, DateTime(2025, 2, 9, 0, 0, 0));
    });

    test('JA: "15時" (future today)', () {
      expect(first("15時", 'ja').date, DateTime(2025, 2, 8, 15, 0, 0));
    });

    test('JA: "9時" (past → tomorrow)', () {
      expect(first("9時", 'ja').date, DateTime(2025, 2, 9, 9, 0, 0));
    });

    test('JA: kanji numerals compose: "来月二十一日十二時三十一分"', () {
      expect(
        first("来月二十一日十二時三十一分", 'ja').date,
        DateTime(2025, 3, 21, 12, 31, 0),
      );
    });

    test('JA: sentence embedding: "会議は来月21日14時から"', () {
      expect(first("会議は来月21日14時から", 'ja').date, DateTime(2025, 3, 21, 14, 0, 0));
    });
  });

  group('English composition', () {
    test('EN: "next month on the 21st"', () {
      expect(
        first("next month on the 21st", 'en').date,
        DateTime(2025, 3, 21, 0, 0, 0),
      );
    });

    test('EN: "next month on the 21st at 2pm"', () {
      expect(
        first("next month on the 21st at 2pm", 'en').date,
        DateTime(2025, 3, 21, 14, 0, 0),
      );
    });

    test('EN: "next Tuesday at 2:30pm"', () {
      expect(
        first("next Tuesday at 2:30pm", 'en').date,
        DateTime(2025, 2, 11, 14, 30, 0),
      );
    });

    test('EN: "next week Tuesday at 14:14"', () {
      expect(
        first("next week Tuesday at 14:14", 'en').date,
        DateTime(2025, 2, 11, 14, 14, 0),
      );
    });

    test('EN: "tomorrow at 14:00"', () {
      expect(
        first("tomorrow at 14:00", 'en').date,
        DateTime(2025, 2, 9, 14, 0, 0),
      );
    });

    test('EN: "the 21st at 14:00"', () {
      expect(
        first("the 21st at 14:00", 'en').date,
        DateTime(2025, 2, 21, 14, 0, 0),
      );
    });

    test('EN: "in 3 days at 9am"', () {
      expect(
        first("in 3 days at 9am", 'en').date,
        DateTime(2025, 2, 11, 9, 0, 0),
      );
    });
  });

  group('Chinese composition', () {
    test('ZH: "下个月21号"', () {
      expect(first("下个月21号", 'zh').date, DateTime(2025, 3, 21, 0, 0, 0));
    });

    test('ZH: "下个月21号14点31分"', () {
      expect(
        first("下个月21号14点31分", 'zh').date,
        DateTime(2025, 3, 21, 14, 31, 0),
      );
    });

    test('ZH: "下周二14点14分"', () {
      expect(first("下周二14点14分", 'zh').date, DateTime(2025, 2, 11, 14, 14, 0));
    });

    test('ZH: "明天15点30分"', () {
      expect(first("明天15点30分", 'zh').date, DateTime(2025, 2, 9, 15, 30, 0));
    });

    test('ZH: "后天上午9点"', () {
      expect(first("后天上午9点", 'zh').date, DateTime(2025, 2, 10, 9, 0, 0));
    });

    test('ZH: "3天后14点"', () {
      expect(first("3天后14点", 'zh').date, DateTime(2025, 2, 11, 14, 0, 0));
    });
  });

  group('Korean composition', () {
    test('KO: "다음 달 21일"', () {
      expect(first("다음 달 21일", 'ko').date, DateTime(2025, 3, 21, 0, 0, 0));
    });

    test('KO: "다음 주 화요일 14시 31분"', () {
      expect(
        first("다음 주 화요일 14시 31분", 'ko').date,
        DateTime(2025, 2, 11, 14, 31, 0),
      );
    });

    test('KO: "3일 후 14시"', () {
      expect(first("3일 후 14시", 'ko').date, DateTime(2025, 2, 11, 14, 0, 0));
    });

    test('KO: "14일 14시 30분"', () {
      expect(first("14일 14시 30분", 'ko').date, DateTime(2025, 2, 14, 14, 30, 0));
    });
  });

  group('Russian composition', () {
    test('RU: "завтра в 15:30"', () {
      expect(first("завтра в 15:30", 'ru').date, DateTime(2025, 2, 9, 15, 30, 0));
    });

    test('RU: "21 марта в 14:31"', () {
      expect(first("21 марта в 14:31", 'ru').date, DateTime(2025, 3, 21, 14, 31, 0));
    });

    test('RU: "через 2 дня в 15:00"', () {
      expect(
        first("через 2 дня в 15:00", 'ru').date,
        DateTime(2025, 2, 10, 15, 0, 0),
      );
    });

    test('RU: "понедельник в 9:00"', () {
      expect(
        first("понедельник в 9:00", 'ru').date,
        DateTime(2025, 2, 10, 9, 0, 0),
      );
    });
  });

  group('Spanish composition', () {
    test('ES: "mañana a las 15:30"', () {
      expect(
        first("mañana a las 15:30", 'es').date,
        DateTime(2025, 2, 9, 15, 30, 0),
      );
    });

    test('ES: "el próximo martes a las 14:30"', () {
      expect(
        first("el próximo martes a las 14:30", 'es').date,
        DateTime(2025, 2, 11, 14, 30, 0),
      );
    });

    test('ES: "21 de marzo a las 14:31"', () {
      expect(
        first("21 de marzo a las 14:31", 'es').date,
        DateTime(2025, 3, 21, 14, 31, 0),
      );
    });

    test('ES: "el 21 del próximo mes"', () {
      expect(
        first("el 21 del próximo mes", 'es').date,
        DateTime(2025, 3, 21, 0, 0, 0),
      );
    });
  });

  group('Hindi composition', () {
    test('HI: "कल 15 बजे"', () {
      expect(first("कल 15 बजे", 'hi').date, DateTime(2025, 2, 9, 15, 0, 0));
    });

    test('HI: "अगले महीने 21 तारीख"', () {
      expect(first("अगले महीने 21 तारीख", 'hi').date, DateTime(2025, 3, 21, 0, 0, 0));
    });

    test('HI: "परसों 10:30"', () {
      expect(first("परसों 10:30", 'hi').date, DateTime(2025, 2, 10, 10, 30, 0));
    });
  });
}

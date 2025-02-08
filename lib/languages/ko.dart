// lib/languages/ko.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// 한국어 주석
/// ----------
/// 한국어로 된 날짜(오늘, 내일, 어제 등)와 형식 (yyyy-mm-dd, etc.)
/// 를 처리하기 위한 클래스입니다.

class KoreanLanguage implements Language {
  @override
  String get code => 'ko';

  @override
  List<Parser> get parsers => [KoreanDateParser()];

  @override
  List<Refiner> get refiners => [KoreanRefiner()];
}

class KoreanDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // --------------------------------
    // 상대적 표현: 오늘, 내일, 어제
    // --------------------------------
    final RegExp relativeDayPattern = RegExp(r'(오늘|내일|어제)');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == '오늘') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == '내일') {
        date = referenceDate.add(const Duration(days: 1));
      } else if (matched == '어제') {
        date = referenceDate.subtract(const Duration(days: 1));
      } else {
        date = referenceDate;
      }

      results.add(
        ParsingResult(
          index: match.start,
          text: matched,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // --------------------------------
    // 절대 날짜: yyyy-mm-dd, dd/mm/yyyy 등
    // --------------------------------
    final RegExp absoluteDatePattern = RegExp(
      r'\b(\d{4})-(\d{2})-(\d{2})\b',
    );
    for (final match in absoluteDatePattern.allMatches(text)) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      DateTime date = DateTime(year, month, day);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    final RegExp altDatePattern = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b');
    for (final match in altDatePattern.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);
      DateTime date = DateTime(year, month, day);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // --------------------------------
    // DateTime.parse 시도
    // --------------------------------
    try {
      final parsedDate = DateTime.parse(text.trim());
      results.add(
        ParsingResult(
          index: 0,
          text: text,
          component: ParsedComponent(date: parsedDate),
        ),
      );
    } catch (_) {
      // 무시
    }

    return results;
  }
}

class KoreanRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ----------------------------------------
    // 추가 보정 없음
    // ----------------------------------------
    return results;
  }
}

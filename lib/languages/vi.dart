// lib/languages/vi.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// Chú thích bằng tiếng Việt
/// -------------------------
/// Lớp này phân tích ngày tháng bằng tiếng Việt,
/// bao gồm các từ chỉ ngày tương đối (hôm nay, ngày mai, hôm qua),
/// ngày tuyệt đối (dd/mm/yyyy), v.v.

class VietnameseLanguage implements Language {
  @override
  String get code => 'vi';

  @override
  List<Parser> get parsers => [VietnameseDateParser()];

  @override
  List<Refiner> get refiners => [VietnameseRefiner()];
}

class VietnameseDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------------
    // Từ ngữ chỉ ngày tương đối: hôm nay, ngày mai, hôm qua
    // ------------------------------------
    final RegExp relativeDayPattern = RegExp(r'\b(hôm nay|ngày mai|hôm qua)\b', caseSensitive: false);
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!.toLowerCase();
      DateTime date;
      if (matched == 'hôm nay') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'ngày mai') {
        date = referenceDate.add(const Duration(days: 1));
      } else if (matched == 'hôm qua') {
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

    // ------------------------------------
    // Định dạng ngày tuyệt đối: dd/mm/yyyy
    // ------------------------------------
    final RegExp absoluteDatePattern = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b');
    for (final match in absoluteDatePattern.allMatches(text)) {
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

    // ------------------------------------
    // Thử DateTime.parse
    // ------------------------------------
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
      // Bỏ qua
    }

    return results;
  }
}

class VietnameseRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ------------------------------------------------
    // Không có tinh chỉnh bổ sung nào
    // ------------------------------------------------
    return results;
  }
}

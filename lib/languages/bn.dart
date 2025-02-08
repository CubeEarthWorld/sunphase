// lib/languages/bn.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// বাংলা ভাষায় মন্তব্য
/// --------------------
/// এই ক্লাস বাংলা ভাষায় তারিখ পার্স করার জন্য ব্যবহার করা হয়,
/// যেমন (আজ, আগামীকাল, গতকাল), সম্পূর্ণ তারিখ (dd/mm/yyyy), ইত্যাদি।

class BengaliLanguage implements Language {
  @override
  String get code => 'bn';

  @override
  List<Parser> get parsers => [BengaliDateParser()];

  @override
  List<Refiner> get refiners => [BengaliRefiner()];
}

class BengaliDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // -------------------------------
    // আপেক্ষিক শব্দ: আজ, আগামীকাল, গতকাল
    // -------------------------------
    final RegExp relativeDayPattern = RegExp(r'(আজ|আগামীকাল|গতকাল)');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == 'আজ') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'আগামীকাল') {
        date = referenceDate.add(const Duration(days: 1));
      } else if (matched == 'গতকাল') {
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

    // -------------------------------
    // সম্পূর্ণ তারিখ (dd/mm/yyyy)
    // -------------------------------
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

    // -------------------------------
    // DateTime.parse ব্যবহার করা
    // -------------------------------
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
      // ডিফল্ট
    }

    return results;
  }
}

class BengaliRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // ---------------------------------
    // অতিরিক্ত কোনো রিফাইনমেন্ট নেই
    // ---------------------------------
    return results;
  }
}

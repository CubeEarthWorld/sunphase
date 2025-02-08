// lib/languages/hi.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// हिन्दी में टिप्पणियाँ
/// ---------------------
/// यह क्लास हिन्दी भाषा में तिथियों को पार्स करता है।
/// मुख्यतः (आज, कल, परसों, कल था) जैसे शब्द, सप्ताह के दिन,
/// पूर्ण तिथियाँ (dd/mm/yyyy) आदि को समझने का प्रयास करता है।

class HindiLanguage implements Language {
  @override
  String get code => 'hi';

  @override
  List<Parser> get parsers => [HindiDateParser()];

  @override
  List<Refiner> get refiners => [HindiRefiner()];
}

class HindiDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ----------------------------------------
    // सापेक्ष दिनों के शब्द (आज, कल, परसों, etc.)
    // ----------------------------------------
    final RegExp relativeDayPattern = RegExp(r'(आज|कल|परसों)');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched == 'आज') {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched == 'कल') {
        // संदर्भ: आमतौर पर "कल" कल के लिए या कभी-कभी "बीता कल" भी हो सकता है,
        // यहाँ सरल रूप में केवल "कल" को +1 दिन लेते हैं
        date = referenceDate.add(const Duration(days: 1));
      } else if (matched == 'परसों') {
        date = referenceDate.add(const Duration(days: 2));
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

    // ----------------------------------------
    // पूर्ण तिथि, उदाहरण: dd/mm/yyyy
    // ----------------------------------------
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

    // ----------------------------------------
    // DateTime.parse आज़माना
    // ----------------------------------------
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
      // कोई समस्या नहीं, आगे बढ़ें
    }

    return results;
  }
}

class HindiRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // -------------------------------
    // अभी कोई अतिरिक्त सुधार नहीं
    // -------------------------------
    return results;
  }
}

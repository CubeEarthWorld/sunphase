// lib/languages/ar.dart

import 'language_interface.dart';
import '../core/parser.dart';
import '../core/refiner.dart';
import '../core/result.dart';

/// تعليقات باللغة العربية
/// -----------------------
/// تقوم هذه الفئة بتحليل التواريخ باللغة العربية.
/// تشمل العبارات الشائعة مثل (اليوم، غدًا، أمس) وأيام الأسبوع والتواريخ المطلقة وغيرها.

class ArabicLanguage implements Language {
  @override
  String get code => 'ar';

  @override
  List<Parser> get parsers => [ArabicDateParser()];

  @override
  List<Refiner> get refiners => [ArabicRefiner()];
}

class ArabicDateParser implements Parser {
  @override
  List<ParsingResult> parse(String text, DateTime referenceDate) {
    List<ParsingResult> results = [];

    // ------------------------------------
    // تعابير زمنية نسبية: اليوم، غدًا، أمس
    // ------------------------------------
    final RegExp relativeDayPattern = RegExp(r'(اليوم|غدًا|غدا|أمس)');
    for (final match in relativeDayPattern.allMatches(text)) {
      String matched = match.group(0)!;
      DateTime date;
      if (matched.contains('اليوم')) {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      } else if (matched.contains('غد')) {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .add(const Duration(days: 1));
      } else if (matched.contains('أمس')) {
        date = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(const Duration(days: 1));
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

    // ------------------------------------------------
    // أيام الأسبوع (الاثنين، الثلاثاء... إلخ) مع عوامل
    // (الأسبوع القادم، الأسبوع الماضي، هذا الأسبوع)
    // ------------------------------------------------
    final RegExp weekdayPattern = RegExp(
      r'(الأسبوع\s+القادم|الأسبوع\s+الماضي|هذا\s+الأسبوع)?\s*(الاثنين|الثلاثاء|الأربعاء|الخميس|الجمعة|السبت|الأحد)',
    );
    for (final match in weekdayPattern.allMatches(text)) {
      String modifier = match.group(1) ?? '';
      String weekdayStr = match.group(2)!;
      int targetWeekday = _weekdayFromString(weekdayStr);
      DateTime date = _calculateWeekday(referenceDate, targetWeekday, modifier);
      results.add(
        ParsingResult(
          index: match.start,
          text: match.group(0)!,
          component: ParsedComponent(date: date),
        ),
      );
    }

    // ------------------------------------------------
    // تواريخ مطلقة: 2025-01-01 أو 01/01/2025
    // ------------------------------------------------
    final RegExp absoluteDatePattern = RegExp(
      r'\b(?:([0-3]?\d)/([0-1]?\d)/(\d{4})|(\d{4})-(\d{2})-(\d{2}))\b',
    );
    for (final match in absoluteDatePattern.allMatches(text)) {
      DateTime? date;
      if (match.group(1) != null) {
        // تنسيق: dd/mm/yyyy
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        date = DateTime(year, month, day);
      } else if (match.group(4) != null) {
        // تنسيق: yyyy-mm-dd
        int year = int.parse(match.group(4)!);
        int month = int.parse(match.group(5)!);
        int day = int.parse(match.group(6)!);
        date = DateTime(year, month, day);
      }
      if (date != null) {
        results.add(
          ParsingResult(
            index: match.start,
            text: match.group(0)!,
            component: ParsedComponent(date: date),
          ),
        );
      }
    }

    // ------------------------------------------------
    // محاولة تحويل النص كاملاً باستخدام DateTime.parse
    // ------------------------------------------------
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
      // تجاهل إذا لم ينجح التحويل
    }

    return results;
  }

  // ---------------------------------------
  // دوال مساعدة
  // ---------------------------------------
  int _weekdayFromString(String weekday) {
    switch (weekday) {
      case 'الاثنين':
        return DateTime.monday;
      case 'الثلاثاء':
        return DateTime.tuesday;
      case 'الأربعاء':
        return DateTime.wednesday;
      case 'الخميس':
        return DateTime.thursday;
      case 'الجمعة':
        return DateTime.friday;
      case 'السبت':
        return DateTime.saturday;
      case 'الأحد':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  DateTime _calculateWeekday(DateTime reference, int targetWeekday, String modifier) {
    DateTime current = DateTime(reference.year, reference.month, reference.day);
    int diff = targetWeekday - current.weekday;
    if (modifier.contains('هذا الأسبوع')) {
      if (diff <= 0) diff += 7;
    } else if (modifier.contains('القادم')) {
      if (diff <= 0) diff += 7;
      diff += 7;
    } else if (modifier.contains('الماضي')) {
      if (diff >= 0) diff -= 7;
    }
    return current.add(Duration(days: diff));
  }
}

class ArabicRefiner implements Refiner {
  @override
  List<ParsingResult> refine(List<ParsingResult> results, DateTime referenceDate) {
    // -----------------------
    // ليس هناك تعديل إضافي
    // -----------------------
    return results;
  }
}

// lib/languages/es.dart
import '../core/base_parser.dart';
import '../core/result.dart';
import '../core/parsing_context.dart';
import '../utils/date_utils.dart';

/// Spanish 固有の定数・ユーティリティ
class EsDateUtils {
  static const Map<String, int> monthMap = {
    "enero": 1,
    "febrero": 2,
    "marzo": 3,
    "abril": 4,
    "mayo": 5,
    "junio": 6,
    "julio": 7,
    "agosto": 8,
    "septiembre": 9,
    "setiembre": 9,
    "octubre": 10,
    "noviembre": 11,
    "diciembre": 12,
  };

  static const Map<String, int> weekdayMap = {
    "lunes": 1,
    "martes": 2,
    "miércoles": 3,
    "miercoles": 3,
    "jueves": 4,
    "viernes": 5,
    "sábado": 6,
    "sabado": 6,
    "domingo": 7,
  };

  static const Map<String, int> relativeDayOffsets = {
    "hoy": 0,
    "mañana": 1,
    "ayer": -1,
  };
}

/// Spanish 相対表現パーサー
class EsRelativeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    String lower = text.toLowerCase();
    // 単語 "hoy", "mañana", "ayer"
    EsDateUtils.relativeDayOffsets.forEach((word, offset) {
      if (lower.contains(word)) {
        int index = lower.indexOf(word);
        DateTime date = DateTime(
            context.referenceDate.year,
            context.referenceDate.month,
            context.referenceDate.day)
            .add(Duration(days: offset));
        results.add(ParsingResult(index: index, text: word, date: date));
      }
    });
    // 「hace 3 días」または「3 días atrás」
    RegExp relExp = RegExp(r'(\d+)\s*d[ií]as\s*(atr[aá]s|hace)', caseSensitive: false);
    for (final match in relExp.allMatches(lower)) {
      int num = int.parse(match.group(1)!);
      // どちらも「過去」を意味するので負のオフセット
      int offset = -num;
      DateTime date = DateTime(
          context.referenceDate.year,
          context.referenceDate.month,
          context.referenceDate.day)
          .add(Duration(days: offset));
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }
}

/// Spanish 絶対表現パーサー
class EsAbsoluteParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // パターン: "14 de marzo de 2025" または "14 de marzo"
    RegExp reg = RegExp(
        r'(\d{1,2})\s*de\s*([a-záéíóúñ]+)(?:\s*de\s*(\d{4}))?',
        caseSensitive: false);
    for (final match in reg.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      String monthStr = match.group(2)!.toLowerCase();
      int? month = EsDateUtils.monthMap[monthStr];
      if (month == null) continue;
      int year = match.group(3) != null
          ? int.parse(match.group(3)!)
          : context.referenceDate.year;
      DateTime date = DateTime(year, month, day);
      if (match.group(3) == null && date.isBefore(context.referenceDate)) {
        // 年指定がない場合、過ぎていれば翌年と解釈
        date = DateTime(year + 1, month, day);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }
}

/// Spanish 時刻表現パーサー
class EsTimeOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 例: "10:10"
    RegExp timeExp = RegExp(r'(\d{1,2}):(\d{2})');
    for (final match in timeExp.allMatches(text)) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      DateTime date = DateUtils.nextOccurrenceTime(context.referenceDate, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    // 例: "Esta noche 21:31"
    RegExp fixedExp = RegExp(r'(esta noche)\s*(\d{1,2}):(\d{2})', caseSensitive: false);
    for (final match in fixedExp.allMatches(text)) {
      int hour = int.parse(match.group(2)!);
      int minute = int.parse(match.group(3)!);
      if (hour < 12) hour += 12;
      DateTime date = DateUtils.nextOccurrenceTime(context.referenceDate, hour, minute);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }
}

/// Spanish 日付のみパーサー（"15 de febrero" など）
class EsDayOnlyParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    // 「15 de febrero」のパターン（年指定がない場合）
    RegExp reg = RegExp(
        r'(\d{1,2})\s*de\s*([a-záéíóúñ]+)',
        caseSensitive: false);
    for (final match in reg.allMatches(text)) {
      int day = int.parse(match.group(1)!);
      String monthStr = match.group(2)!.toLowerCase();
      int? month = EsDateUtils.monthMap[monthStr];
      if (month == null) continue;
      DateTime date = DateTime(context.referenceDate.year, month, day);
      if (date.isBefore(context.referenceDate)) {
        date = DateTime(context.referenceDate.year + 1, month, day);
      }
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: date));
    }
    return results;
  }
}

/// Spanish 曜日表現パーサー（単独の曜日）
class EsWeekdayParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    String lower = text.toLowerCase();
    EsDateUtils.weekdayMap.forEach((weekday, value) {
      if (lower.contains(weekday)) {
        int index = lower.indexOf(weekday);
        DateTime candidate = DateUtils.nextWeekday(context.referenceDate, value);
        results.add(ParsingResult(index: index, text: weekday, date: DateTime(candidate.year, candidate.month, candidate.day, 0, 0)));
      }
    });
    return results;
  }
}

/// Spanish 範囲表現パーサー（例："el próximo mes", "la semana pasada"）
class EsRangeParser extends BaseParser {
  @override
  List<ParsingResult> parse(String text, ParsingContext context) {
    List<ParsingResult> results = [];
    String lower = text.toLowerCase();

    // "el próximo mes" または "mes que viene"
    if (lower.contains("próximo mes") || lower.contains("mes que viene")) {
      DateTime firstDay = DateUtils.firstDayOfNextMonth(context.referenceDate);
      results.add(ParsingResult(index: 0, text: "próximo mes", date: firstDay, rangeType: "month"));
    }

    // "la semana pasada"
    if (lower.contains("la semana pasada")) {
      DateTime mondayThisWeek = DateUtils.firstDayOfWeek(context.referenceDate);
      DateTime mondayLastWeek = mondayThisWeek.subtract(Duration(days: 7));
      results.add(ParsingResult(index: 0, text: "la semana pasada", date: DateTime(mondayLastWeek.year, mondayLastWeek.month, mondayLastWeek.day, 0, 0, 0), rangeType: "week"));
    }
    // "el tercer lunes de marzo"
    RegExp thirdMondayMarch = RegExp(r'el tercer lunes de marzo', caseSensitive: false);
    for (final match in thirdMondayMarch.allMatches(lower)) {
      int year = context.referenceDate.year;
      DateTime firstDayOfMonth = DateTime(year, 3, 1);
      int firstMonday = (8 - firstDayOfMonth.weekday) % 7 + 1;
      DateTime thirdMonday = DateTime(year, 3, firstMonday + 14);

      if(thirdMonday.isBefore(context.referenceDate)){
        year = context.referenceDate.year + 1;
        firstDayOfMonth = DateTime(year, 3, 1);
        firstMonday = (8 - firstDayOfMonth.weekday) % 7 + 1;
        thirdMonday = DateTime(year, 3, firstMonday + 14);
      }

      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: DateTime(thirdMonday.year, thirdMonday.month, thirdMonday.day, 0, 0, 0)));
    }
    // "el último viernes de abril"
    RegExp lastFridayApril = RegExp(r'el último viernes de abril', caseSensitive: false);
    for (final match in lastFridayApril.allMatches(lower)) {
      int year = context.referenceDate.year;
      DateTime lastDayOfMonth = DateTime(year, 5, 0);
      int lastFriday = (lastDayOfMonth.weekday - DateTime.friday + 7) % 7;
      DateTime targetDate = lastDayOfMonth.subtract(Duration(days: lastFriday));

      if(targetDate.isBefore(context.referenceDate)){
        year = context.referenceDate.year + 1;
        lastDayOfMonth = DateTime(year, 5, 0);
        lastFriday = (lastDayOfMonth.weekday - DateTime.friday + 7) % 7;
        targetDate = lastDayOfMonth.subtract(Duration(days: lastFriday));
      }

      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0)));
    }

    // "próximo lunes"
    RegExp nextMondayRegex = RegExp(r'próximo lunes', caseSensitive: false);
    for(final match in nextMondayRegex.allMatches(lower)){
      DateTime nextMonday = DateUtils.nextWeekday(context.referenceDate, 1);
      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 0, 0, 0)));
    }

    // "primer lunes de febrero"
    RegExp firstMondayFebruaryRegex = RegExp(r'primer lunes de febrero', caseSensitive: false);
    for(final match in firstMondayFebruaryRegex.allMatches(lower)){
      int year = context.referenceDate.year;
      DateTime firstDayOfMonth = DateTime(year, 2, 1); // 2 for February
      int firstMonday = (8 - firstDayOfMonth.weekday) % 7 + 1;
      DateTime targetDate = DateTime(year, 2, firstMonday);

      if(targetDate.isBefore(context.referenceDate)){
        year = context.referenceDate.year + 1;
        firstDayOfMonth = DateTime(year, 2, 1);
        firstMonday = (8 - firstDayOfMonth.weekday) % 7 + 1;
        targetDate = DateTime(year, 2, firstMonday);
      }

      results.add(ParsingResult(index: match.start, text: match.group(0)!, date: DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0)));
    }

    return results;
  }
}

class EsParsers {
  static final List<BaseParser> parsers = [
    EsRelativeParser(),
    EsAbsoluteParser(),
    EsTimeOnlyParser(),
    EsDayOnlyParser(),
    EsWeekdayParser(),
    EsRangeParser(),
  ];
}
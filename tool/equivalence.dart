import 'dart:convert';
import 'dart:io';

import '../lib/sunphase.dart' as current;
import '../benchmark/baseline/lib/sunphase.dart' as baseline;
import '../lib/utils/date_utils.dart' as utils;
import '../benchmark/baseline/lib/utils/date_utils.dart' as oldUtils;
import '../lib/src/core/component.dart' as components;
import '../benchmark/baseline/lib/src/core/component.dart' as oldComponents;
import '../lib/src/core/expression.dart' as expressions;
import '../benchmark/baseline/lib/src/core/expression.dart' as oldExpressions;
import '../lib/src/core/token.dart' as tokens;
import '../benchmark/baseline/lib/src/core/token.dart' as oldTokens;
import 'workloads.dart';

Object canonical(dynamic r) => [
  r.index,
  r.text,
  r.date.microsecondsSinceEpoch,
  r.date.isUtc,
  r.rangeType,
  r.rangeDays,
];

void main() {
  var parseCount = 0;
  final snapshots = StringBuffer();
  final inputs = <String>{
    ...shortInputs,
    ...rangeInputs,
    ...languageInputs.values.expand((v) => v),
    longInput,
    noMatchInput,
    '１２月３１日😀',
    '😀明日午後３時',
    '来週火曜14時14分',
    'next month next month',
    '2024-02-29',
    '31日',
    '29日',
    'next week Sunday',
    '3日以内',
  };
  final fragments = [
    'tomorrow',
    'next month',
    'next week',
    '31st',
    'Monday',
    '3pm',
    '来月',
    '21日',
    '午後',
    '14時31分',
    '来週火曜',
    '下个月',
    '21号',
    '下午',
    '3点',
    '😀',
  ];
  for (final a in fragments) {
    for (final b in fragments) {
      inputs.add('$a $b');
      inputs.add('$a$b');
    }
  }
  final refs = [
    DateTime(2025, 2, 8, 11, 5),
    DateTime(2024, 2, 29, 23, 59),
    DateTime(2025, 12, 31),
    DateTime.utc(2000, 1, 31, 12),
  ];
  final languageSets = <List<String>?>[
    null,
    [],
    ['en'],
    ['ja'],
    ['zh'],
    ['es'],
    ['hi'],
    ['ko'],
    ['ru'],
    ['en', 'ja', 'zh', 'es', 'hi', 'ko', 'ru'],
    ['unknown'],
    ['en', 'en'],
  ];
  var index = 0;
  for (final input in inputs) {
    for (final ref in refs) {
      for (final range in [false, true]) {
        final languages = languageSets[index % languageSets.length];
        final weekStart = index.isEven ? DateTime.sunday : DateTime.monday;
        final timezone = [null, '480', '-300', 'invalid'][index % 4];
        final expected = baseline
            .parse(
              input,
              referenceDate: ref,
              languages: languages,
              rangeMode: range,
              timezone: timezone,
              weekStartsOn: weekStart,
            )
            .map(canonical)
            .toList();
        final actual = current
            .parse(
              input,
              referenceDate: ref,
              languages: languages,
              rangeMode: range,
              timezone: timezone,
              weekStartsOn: weekStart,
            )
            .map(canonical)
            .toList();
        if (jsonEncode(actual) != jsonEncode(expected)) {
          throw StateError(
            'Mismatch: $input $ref $languages $range\n$expected\n$actual',
          );
        }
        snapshots.writeln(
          jsonEncode({
            'text': input,
            'ref': ref.toIso8601String(),
            'languages': languages,
            'range': range,
            'timezone': timezone,
            'weekStart': weekStart,
            'expected': expected,
          }),
        );
        index++;
        parseCount++;
      }
    }
  }
  // Independently cover every selected language/options combination.
  for (final entry in languageInputs.entries) {
    for (final input in entry.value) {
      for (final start in [DateTime.sunday, DateTime.monday]) {
        for (final range in [false, true]) {
          final expected = baseline
              .parse(
                input,
                referenceDate: refs.first,
                languages: [entry.key],
                rangeMode: range,
                weekStartsOn: start,
              )
              .map(canonical)
              .toList();
          final actual = current
              .parse(
                input,
                referenceDate: refs.first,
                languages: [entry.key],
                rangeMode: range,
                weekStartsOn: start,
              )
              .map(canonical)
              .toList();
          if (jsonEncode(expected) != jsonEncode(actual)) {
            throw StateError(input);
          }
          parseCount++;
        }
      }
    }
  }
  var dateCount = 0;
  for (final year in [1900, 1999, 2000, 2024, 2025, 2100]) {
    for (var month = 1; month <= 12; month++) {
      for (final day in [1, 28, 29, 30, 31]) {
        for (final shift in [
          -1200,
          -25,
          -13,
          -12,
          -1,
          0,
          1,
          12,
          13,
          25,
          1200,
        ]) {
          final date = DateTime(year, month, day, 23, 59, 59, 123, 456);
          final expected = oldUtils.DateUtils.addMonths(date, shift);
          final actual = utils.DateUtils.addMonths(date, shift);
          if (expected != actual || expected.isUtc != actual.isUtc) {
            throw StateError('Month mismatch $date $shift');
          }
          dateCount++;
        }
      }
    }
  }
  // All 256 x 256 slot pairs, including invalid combined shapes.
  const cs = <components.DateComponent>[
    components.YearValue(2025),
    components.MonthValue(3),
    components.DayOfMonth(21),
    components.WeekdayRef(2),
    components.ClockTime(14),
    components.MeridiemMarker(components.Meridiem.pm),
    components.RelativeDay(1),
    components.WeekAnchor(1, calendar: true),
  ];
  const oldCs = <oldComponents.DateComponent>[
    oldComponents.YearValue(2025),
    oldComponents.MonthValue(3),
    oldComponents.DayOfMonth(21),
    oldComponents.WeekdayRef(2),
    oldComponents.ClockTime(14),
    oldComponents.MeridiemMarker(oldComponents.Meridiem.pm),
    oldComponents.RelativeDay(1),
    oldComponents.WeekAnchor(1, calendar: true),
  ];
  var slotCount = 0;
  for (var a = 0; a < 256; a++) {
    for (var b = 0; b < 256; b++) {
      final left = tokens.Token(
        start: 0,
        end: 1,
        text: 'a',
        components: [
          for (var i = 0; i < 8; i++)
            if ((a & (1 << i)) != 0) cs[i],
        ],
      );
      final right = tokens.Token(
        start: 1,
        end: 2,
        text: 'b',
        components: [
          for (var i = 0; i < 8; i++)
            if ((b & (1 << i)) != 0) cs[i],
        ],
      );
      final oldLeft = oldTokens.Token(
        start: 0,
        end: 1,
        text: 'a',
        components: [
          for (var i = 0; i < 8; i++)
            if ((a & (1 << i)) != 0) oldCs[i],
        ],
      );
      final oldRight = oldTokens.Token(
        start: 1,
        end: 2,
        text: 'b',
        components: [
          for (var i = 0; i < 8; i++)
            if ((b & (1 << i)) != 0) oldCs[i],
        ],
      );
      if (expressions.DateExpression.fromToken(left).canAccept(right) !=
          oldExpressions.DateExpression.fromToken(
            oldLeft,
          ).canAccept(oldRight)) {
        throw StateError('Slot mismatch $a $b');
      }
      slotCount++;
    }
  }
  for (final start in [-1, 0, 2, 8]) {
    for (final parser in [baseline.parse, current.parse]) {
      try {
        parser('tomorrow', weekStartsOn: start);
        throw StateError('accepted invalid week start');
      } on ArgumentError {
        /* Expected from both versions. */
      }
    }
  }
  File(
    'benchmark/baseline-snapshots.jsonl',
  ).writeAsStringSync(snapshots.toString());
  print(
    jsonEncode({
      'passed': true,
      'parse_comparisons': parseCount,
      'month_comparisons': dateCount,
      'slot_comparisons': slotCount,
      'invalid_week_start_checks': 8,
    }),
  );
}

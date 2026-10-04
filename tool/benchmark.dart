import 'dart:convert';
import 'dart:io';

import '../lib/sunphase.dart';
import '../lib/utils/date_utils.dart';
import 'workloads.dart';

int sink = 0;
final reference = DateTime(2025, 2, 8, 11, 5);

void consume(List<ParsingResult> results) {
  sink = (sink + results.length) & 0x7fffffff;
  if (results.isNotEmpty) {
    sink = (sink + results.first.date.day + results.last.index) & 0x7fffffff;
  }
}

void main(List<String> args) {
  final round = args.isEmpty ? 0 : int.parse(args.first);
  final cases = <({String name, int count, int chars, void Function(int) run})>[
    (
      name: 'parse_short_default',
      count: 2000,
      chars: shortInputs.fold(0, (n, s) => n + s.length),
      run: (i) => consume(
        parse(shortInputs[i % shortInputs.length], referenceDate: reference),
      ),
    ),
    (
      name: 'parse_seven_languages',
      count: 2000,
      chars: languageInputs.values
          .expand((v) => v)
          .fold(0, (n, s) => n + s.length),
      run: (i) {
        final code = languageInputs.keys.elementAt(i % languageInputs.length);
        final inputs = languageInputs[code]!;
        consume(
          parse(
            inputs[(i ~/ languageInputs.length) % inputs.length],
            referenceDate: reference,
            languages: [code],
          ),
        );
      },
    ),
    (
      name: 'parse_month_anchor',
      count: 2000,
      chars: 'next month on the 21st at 2pm'.length,
      run: (i) => consume(
        parse(
          'next month on the 21st at 2pm',
          referenceDate: reference,
          languages: ['en'],
        ),
      ),
    ),
    (
      name: 'parse_range',
      count: 1500,
      chars: rangeInputs.fold(0, (n, s) => n + s.length),
      run: (i) => consume(
        parse(
          rangeInputs[i % rangeInputs.length],
          referenceDate: reference,
          rangeMode: true,
        ),
      ),
    ),
    (
      name: 'parse_long_point',
      count: 50,
      chars: longInput.length,
      run: (i) => consume(parse(longInput, referenceDate: reference)),
    ),
    (
      name: 'parse_long_range',
      count: 40,
      chars: longInput.length,
      run: (i) =>
          consume(parse(longInput, referenceDate: reference, rangeMode: true)),
    ),
    (
      name: 'parse_long_no_match',
      count: 300,
      chars: noMatchInput.length,
      run: (i) => consume(parse(noMatchInput, referenceDate: reference)),
    ),
    (
      name: 'add_months',
      count: 20000,
      chars: 0,
      run: (i) {
        sink =
            (sink + DateUtils.addMonths(reference, i % 49 - 24).day) &
            0x7fffffff;
      },
    ),
  ];
  for (final c in cases) {
    // Warm each code path for at least 250ms; AOT has no JIT compilation.
    final warmup = Stopwatch()..start();
    var i = 0;
    while (warmup.elapsedMilliseconds < 250) {
      c.run(i++);
    }
    sink = 0;
    final timer = Stopwatch()..start();
    for (var j = 0; j < c.count; j++) {
      c.run(j);
    }
    timer.stop();
    print(
      jsonEncode({
        'round': round,
        'case': c.name,
        'iterations': c.count,
        'input_utf16_units': c.chars,
        'elapsed_us': timer.elapsedMicroseconds,
        'us_per_op': timer.elapsedMicroseconds / c.count,
        'checksum': sink,
        'rss_bytes': ProcessInfo.currentRss,
        'max_rss_bytes': ProcessInfo.maxRss,
      }),
    );
  }
  // Keep observable results outside the timed region.
  stderr.writeln('checksum=$sink');
}

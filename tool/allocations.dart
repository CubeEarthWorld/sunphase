// Allocation diagnostics run separately from the AOT timing benchmark.
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:vm_service/vm_service_io.dart';
import '../lib/sunphase.dart' as current;
import '../benchmark/baseline/lib/sunphase.dart' as baseline;
import '../lib/utils/date_utils.dart' as utils;
import '../benchmark/baseline/lib/utils/date_utils.dart' as oldUtils;
import 'workloads.dart';

int sink = 0;
final reference = DateTime(2025, 2, 8, 11, 5);

Future<void> main() async {
  final info = await Service.getInfo();
  final uri = info.serverUri;
  if (uri == null) throw StateError('Run with --enable-vm-service=0');
  final service = await vmServiceConnectUri(
    uri.replace(scheme: 'ws', path: '${uri.path}ws').toString(),
  );
  final isolateId = Service.getIsolateId(Isolate.current)!;
  final output = <Map<String, Object?>>[];
  for (final kind in ['short', 'month', 'add_months']) {
    void run(bool old, int count) {
      for (var i = 0; i < count; i++) {
        if (kind == 'add_months') {
          sink +=
              (old
                      ? oldUtils.DateUtils.addMonths(reference, i % 49 - 24)
                      : utils.DateUtils.addMonths(reference, i % 49 - 24))
                  .day;
        } else {
          final input = kind == 'short'
              ? shortInputs[i % shortInputs.length]
              : 'next month on the 21st at 2pm';
          final results = old
              ? baseline
                    .parse(
                      input,
                      referenceDate: reference,
                      languages: kind == 'month' ? ['en'] : null,
                    )
                    .map((r) => r.date)
                    .toList()
              : current
                    .parse(
                      input,
                      referenceDate: reference,
                      languages: kind == 'month' ? ['en'] : null,
                    )
                    .map((r) => r.date)
                    .toList();
          if (results.isNotEmpty) sink += results.first.day;
        }
      }
    }

    run(true, 3000);
    run(false, 3000);
    for (var round = 0; round < 3; round++) {
      for (final old in round.isEven ? [true, false] : [false, true]) {
        await service.getAllocationProfile(isolateId, gc: true, reset: true);
        run(old, 1000);
        final profile = await service.getAllocationProfile(isolateId, gc: true);
        output.add({
          'case': kind,
          'variant': old ? 'baseline' : 'optimized',
          'round': round,
          'iterations': 1000,
          'memoryUsage': profile.memoryUsage?.toJson(),
          'classes': [
            for (final c in profile.members!)
              if ((c.accumulatedSize ?? 0) != 0)
                {
                  'class': c.classRef!.name,
                  'bytes': c.accumulatedSize,
                  'instances': c.instancesAccumulated,
                },
          ],
        });
      }
    }
  }
  File('benchmark/allocations.json').writeAsStringSync(jsonEncode(output));
  print('Allocation profiles: ${output.length}; checksum=$sink');
  await service.dispose();
}

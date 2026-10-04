import '../lib/utils/date_utils.dart' as current;
import '../benchmark/baseline/lib/utils/date_utils.dart' as baseline;

String outcome(DateTime Function() fn) {
  try {
    return fn().toIso8601String();
  } catch (e) {
    return e.runtimeType.toString();
  }
}

void main() {
  var checked = 0;
  for (final edge in [-8640000000000000, 8640000000000000]) {
    for (final offset in [
      0,
      86400000,
      -86400000,
      30 * 86400000,
      -30 * 86400000,
    ]) {
      DateTime ref;
      try {
        ref = DateTime.fromMillisecondsSinceEpoch(edge + offset, isUtc: true);
      } catch (_) {
        continue;
      }
      for (final months in [-12, -1, 0, 1, 12]) {
        final before = outcome(() => baseline.DateUtils.addMonths(ref, months));
        final after = outcome(() => current.DateUtils.addMonths(ref, months));
        checked++;
        if (before != after) {
          throw StateError('$ref $months: $before -> $after');
        }
      }
    }
  }
  print('DateTime limit comparisons passed: ' + checked.toString());
}

import json
import statistics
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'benchmark'
rows = [json.loads(s) for s in (root / 'timings.jsonl').read_text(encoding='utf-8-sig').splitlines()]
rounds = json.loads((root / 'environment.json').read_text(encoding='utf-8-sig'))['rounds']
summary = []
for case in dict.fromkeys(r['case'] for r in rows):
    record = {'case': case}
    for variant in ('baseline', 'optimized'):
        measurements = [r['us_per_op'] for r in rows if r['case'] == case and r['variant'] == variant]
        assert len(measurements) == rounds, (case, variant, len(measurements))
        record[variant] = dict(median_us=statistics.median(measurements),
            min_us=min(measurements), max_us=max(measurements), samples=measurements)
    record['improvement_percent'] = 100 * (1 - record['optimized']['median_us'] / record['baseline']['median_us'])
    pairs = []
    for round_index in range(rounds):
        pair = {r['variant']:r for r in rows if r['case'] == case and r['round'] == round_index}
        assert pair['baseline']['checksum'] == pair['optimized']['checksum'], (case, round_index)
        pairs.append(100 * (1 - pair['optimized']['us_per_op'] / pair['baseline']['us_per_op']))
    record['paired_improvement_percent'] = dict(median=statistics.median(pairs), min=min(pairs), max=max(pairs))
    summary.append(record)
(root / 'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
for s in summary:
    print(f"{s['case']:24} {s['baseline']['median_us']:10.3f} -> {s['optimized']['median_us']:10.3f} us/op ({s['improvement_percent']:+.1f}%)")
memory = {}
for variant in ('baseline', 'optimized'):
    peaks = [max(r['max_rss_bytes'] for r in rows if r['variant'] == variant and r['round'] == i) for i in range(rounds)]
    memory[variant] = dict(median_peak_rss_bytes=statistics.median(peaks), min_peak_rss_bytes=min(peaks),
        max_peak_rss_bytes=max(peaks), samples=peaks)
(root / 'memory-summary.json').write_text(json.dumps(memory, indent=2), encoding='utf-8')
print('AOT process RSS:', memory)
if (root / 'allocations.json').exists():
    diagnostic = {
        'status': 'rejected_for_transient_allocation_comparison',
        'reason': 'After 1000 operations and GC, getAllocationProfile reports only 1 DateTime and 2 Sets. '
            'These counters do not account for the transient allocations under test in this environment. '
            'Profiler/protocol allocations also contaminate collection-class counts. '
            'No bytes-per-operation or total-allocation reduction is inferred from this diagnostic.',
        'raw_data': 'allocations.json', 'mode': 'JIT, separate from AOT timings',
    }
    (root / 'allocation-status.json').write_text(json.dumps(diagnostic, indent=2), encoding='utf-8')
    print('JIT transient allocation diagnostic rejected; use AOT RSS and binary size metrics.')

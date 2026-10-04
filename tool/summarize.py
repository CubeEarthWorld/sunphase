import json
import statistics
import sys
from pathlib import Path

path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / '.dart_tool/sunphase-check/timings.jsonl'
rows = [json.loads(s) for s in path.read_text(encoding='utf-8-sig').splitlines()]
rounds = sorted({r['round'] for r in rows})
for case in dict.fromkeys(r['case'] for r in rows):
    values = {}
    for variant in ('baseline', 'optimized'):
        samples = [r['us_per_op'] for r in rows if r['case'] == case and r['variant'] == variant]
        assert len(samples) == len(rounds), (case, variant)
        values[variant] = statistics.median(samples)
        print(f'{case} {variant}: {values[variant]:.3f} us/op [{min(samples):.3f}, {max(samples):.3f}], n={len(samples)}')
    for round_index in rounds:
        pair = {r['variant']: r for r in rows if r['case'] == case and r['round'] == round_index}
        assert pair['baseline']['checksum'] == pair['optimized']['checksum'], (case, round_index)
    print(f"Median time reduction: {100 * (1 - values['optimized'] / values['baseline']):.1f}%")
if len(rounds) < 3:
    print('Smoke run only: too few samples to establish a performance improvement.')

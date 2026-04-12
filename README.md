[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

[README.jp.md](README.jp.md) | [README.zh.md](README.zh.md)

Sunphase is a powerful and flexible Dart library for extracting and parsing dates from natural language text. It supports multiple languages, timezones, and provides a range mode for extracting date ranges.

There is a sample project at https://github.com/CubeEarthWorld/sunphase_sample

## Features

*   **Natural Language Parsing:** Extract dates from strings like "tomorrow", "next week", "last month", etc.
*   **Multi-language Support:** Supports English, Japanese, Chinese, Spanish, Hindi, Korean, and Russian. [Language definitions](lib/languages)
*   **Timezone Support:** Specify a UTC offset in minutes for date parsing.
*   **Range Mode:** Expand span expressions (e.g. "next week") into one date per day in the range.

## Reference date

Every parse is anchored to a single **reference date** — the point in time that relative expressions such as *today*, *tomorrow*, *next week*, or bare times like *10:10* are resolved against.

| Situation | Reference date used |
|-----------|-------------------|
| `referenceDate` argument is omitted | `DateTime.now()` — the current local wall-clock time at the moment `parse` is called |
| `referenceDate` is explicitly provided | Exactly the value you passed |

> **Example:** if you call `parse('tomorrow')` at 09:00 on 2025-03-07, the reference date is `2025-03-07 09:00:00` and the result will be `2025-03-08 00:00:00`. If you pass `referenceDate: DateTime(2021, 2, 4)`, "tomorrow" resolves to `2021-02-05 00:00:00` regardless of the current time.

When only a **time** is given (e.g. `"10:10"`) and no date context is present, the resolver returns the *next* occurrence of that time after the reference date — i.e. today if the time has not yet passed, otherwise tomorrow.

## Usage
```dart
import 'package:sunphase/sunphase.dart';

void main() {
  // Parse a relative day — reference date defaults to DateTime.now()
  List<ParsingResult> results = parse('Today');
  print(results); // [[0] "today" -> 2025-02-09 00:00:00.000]

  // Parse a bare time — resolves to the next occurrence of 10:10
  List<ParsingResult> results_time = parse('10:10');
  print(results_time); // [[0] "10:10" -> 2025-02-10 10:10:00.000]

  // Parse date + time together
  List<ParsingResult> results_data = parse('march 7 10:10');
  print(results_data); // [[0] "march 7" -> 2025-03-07 10:10:00.000]

  // Japanese natural language
  List<ParsingResult> results_data_ja = parse('明日12時14分');
  print(results_data_ja); // [[0] "明日12時14分" -> 2025-02-10 12:14:00.000]

  // Chinese natural language
  List<ParsingResult> results_data_zh = parse('三月七号上午九点');
  print(results_data_zh); // [[0] "三月七号上午九点" -> 2025-03-07 09:00:00.000]

  // Restrict to a specific language
  List<ParsingResult> resultsEn = parse('Tomorrow', languages: ['en']);
  print(resultsEn); // [[0] "tomorrow" -> 2025-02-10 00:00:00.000]

  // Restrict to Chinese parser
  List<ParsingResult> resultsZh = parse('三天后', languages: ['zh']);
  print(resultsZh); // [[0] "三天后" -> 2025-02-12 21:13:33.382038]

  // Supply an explicit reference date
  List<ParsingResult> resultsRef = parse('Next Tuesday', referenceDate: DateTime(2021, 2, 4));
  print(resultsRef); // [[0] "next tuesday" -> 2021-02-09 00:00:00.000]

  // Range mode — expand "next week" into one date per day
  List<ParsingResult> resultsRange = parse('Next week', rangeMode: true);
  print(resultsRange);
  // [[0] "next week" -> 2025-02-10, [0] "next week" -> 2025-02-11, … (7 dates)]

  // Timezone — offset in minutes from UTC (e.g. 480 = UTC+8)
  List<ParsingResult> resultsTimezone = parse('明天', timezone: '480');
  print(resultsTimezone); // [[0] "明天" -> 2025-02-10 08:00:00.000]
}
```

## Supported languages

| Code | Language |
|------|----------|
| `en` | English |
| `ja` | Japanese (日本語) |
| `zh` | Chinese — Simplified (中文) |
| `es` | Spanish (Español) |
| `hi` | Hindi (हिन्दी) |
| `ko` | Korean (한국어) |
| `ru` | Russian (Русский) |

Pass one or more codes to the `languages` parameter to restrict parsing.
When omitted, `['en', 'ja', 'zh']` is used as the default.

## Installation
Add `sunphase` to your `pubspec.yaml`:

```yaml
dependencies:
  sunphase:
    git:
      url: https://github.com/CubeEarthWorld/sunphase.git
```
Then run `pub get`.

## License

This project is licensed under the BSD 3-Clause License.

## Contact
Developer: [cubeearthworld](https://x.com/cubeearthworld)

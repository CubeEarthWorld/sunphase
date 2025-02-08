[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

[README.jp.md](README.jp.md) | [README.zh.md](README.zh.md)

Sunphase is a powerful and flexible Dart library for extracting and parsing dates from natural language text. It supports multiple languages, timezones, and provides a range mode for extracting date ranges.

There is a sample project at https://github.com/CubeEarthWorld/sunphase_sample

## Features

*   **Natural Language Parsing:** Extract dates from strings like "tomorrow", "next week", "last month", etc.
*   **Multi-language Support:** Supports English, Japanese, and Chinese etc... (More to come).[Language](lib/languages)
*   **Timezone Support:** Specify a timezone for date parsing.
*   **Range Mode:** Extract date ranges (e.g., "next week" will return a list of dates for the next week).

## Usage
```dart

import 'package:sunphase/sunphase.dart';

void main() {
// Parse the date
List<ParsingResult> results = parse('Today');
print(results);

// Parse the time
List<ParsingResult> results_time = parse('10:10');
print(results_time);

// Parse the date and time
List<ParsingResult> results_data = parse('march 7 10:10');
print(results_data);

// Parse the date and time in Japanese
List<ParsingResult> results_data_ja = parse('明日12時14分');
print(results_data_ja);

// Parse the date and time in Chinese
List<ParsingResult> results_data_zh = parse('三月七号上午九点');
print(results_data_zh);

// Parse the date in English
List<ParsingResult> resultsEn = parse('Tomorrow', language: 'en');
print(resultsEn);

// Parse the date in Chinese
List<ParsingResult> resultsJa = parse('三天后', language: 'zh');
print(resultsJa);

// Parse the date based on a reference date
List<ParsingResult> resultsRef = parse('Next Tuesday', referenceDate: DateTime(2021, 2, 4));
print(resultsRef);

// Parse the date in range mode
List<ParsingResult> resultsRange = parse('Next week', rangeMode: true);
print(resultsRange);

// Parse the date with a specific time zone. The time zone must be specified as an offset in minutes from UTC. For example, UTC+8 is "480".
List<ParsingResult> resultsTimezone = parse('明天', timezone: '480');
print(resultsTimezone);
}

// Executed at 2025-02-08 11:05:00.000
//[[0] "today" -> 2025-02-09 00:00:00.000]
//[[0] "10:10" -> 2025-02-09 10:10:00.000]
//[[0] "march 7" -> 2025-03-07 10:10:00.000]
//[[0] "明日12時14分" -> 2025-02-10 12:14:00.000, [0] "明日12時14分" -> 2025-02-10 12:14:00.000, [2] "12時14分" -> 2025-02-09 12:14:00.000]
//[0] "三月七号" -> 2025-03-07 00:00:00.000, [2] "七号" -> 2025-03-07 00:00:00.000, [0] "三月七号上午九点" -> 2025-03-07 09:00:00.000]
//[0] "tomorrow" -> 2025-02-10 00:00:00.000]
//[0] "三天后" -> 2025-02-12 04:46:31.708556]
//[0] "next tuesday" -> 2021-02-09 00:00:00.000]
//[0] "next week" -> 2025-02-10 00:00:00.000, [0] "next week" -> 2025-02-11 00:00:00.000, [0] "next week" -> 2025-02-12 00:00:00.000, [0] "next week" -> 2025-02-13 00:00:00.000, [0] "next week" -> 2025-02-14 00:00:00.000, [0] "next week" -> 2025-02-15 00:00:00.000, [0] "next week" -> 2025-02-16 00:00:00.000]
//[0] "明天" -> 2025-02-10 08:00:00.000]

```

## Installation
Add `sunphase` to your `pubspec.yaml`:

```yaml
dependencies:
  sunphase:
    git:
      url: https://github.com/CubeEarthWorld/sunphase.git
```
Then, run `pub get`.

## License

This project is licensed under the BSD 3-Clause License.

## Contact
Developer: [cubeearthworld](https://x.com/cubeearthworld)

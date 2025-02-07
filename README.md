[![License: CC0](https://img.shields.io/badge/License-CC0_1.0-lightgrey.svg)](http://creativecommons.org/publicdomain/zero/1.0/)

[README.jp.md](README.jp.md) | [README.zh.md](README.zh.md)

Sunphase is a powerful and flexible Dart library for extracting and parsing dates from natural language text. It supports multiple languages, timezones, and provides a range mode for extracting date ranges.

There is a sample project at https://github.com/CubeEarthWorld/sunphase_sample

## Features

*   **Natural Language Parsing:** Extract dates from strings like "tomorrow", "next week", "last month", etc.
*   **Multi-language Support:** Supports English, Japanese, and Chinese (More to come).
*   **Timezone Support:** Specify a timezone for date parsing.
*   **Range Mode:** Extract date ranges (e.g., "next week" will return a list of dates for the next week).

## Usage
```dart
import 'package:sunphase/sunphase.dart';

void main() {

    // Parse a date
  List<ParsingResult> results = parse('Today');
  print(results);

  // Parse a date in English
  List<ParsingResult> resultsEn = parse('Tomorrow', language: 'en');
  print(resultsEn);

  // Parse a date in Japanese
  List<ParsingResult> resultsJa = parse('明日', language: 'ja');
  print(resultsJa);

  // Parse a date with a specific reference date
  List<ParsingResult> resultsRef = parse('Next week', referenceDate: DateTime(2021, 2, 4));
  print(resultsRef);

    // Parse a date with range mode
  List<ParsingResult> resultsRange = parse('Next week', language: 'en', rangeMode: true);
  print(resultsRange);

  // Parse a date with a specific timezone. The timezone should be provided as a string representing the offset in minutes from UTC, e.g. "-480" for America/Los_Angeles.
  List<ParsingResult> resultsTimezone = parse('Tomorrow', language: 'en', timezone: '-480');
  print(resultsTimezone);
}

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

This project is licensed under the CC0 License - see the [LICENSE](LICENSE) file for details.

## Contact
Developer: [cubeearthworld](https://x.com/cubeearthworld)

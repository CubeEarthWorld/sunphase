#### README_en.md


###

Currently in early development! Do not use!

###
```markdown
# Sunphase

Sunphase is a natural language date parser package for Dart/Flutter. It supports parsing date expressions in multiple languages including English, Japanese, and Chinese. With Sunphase, you can easily extract dates from textual input and work with them in your applications.

## Features

- Parses natural language date expressions such as "today", "tomorrow", "yesterday", "next week", "last month", "Monday", "January 1, 2025", etc.
- Supports multiple languages: English, Japanese, Chinese.
- Customizable parsing and refining pipelines.
- Provides both single date and range mode parsing.
- Extensible architecture for adding new parsers and refiners.

## Getting Started

### Prerequisites

- Dart or Flutter SDK installed.
- Basic knowledge of Dart/Flutter.

### Installation

Add `sunphase` to your `pubspec.yaml` file:

```yaml
dependencies:
  sunphase: ^1.0.0
```

Then run:

```bash
dart pub get
# or
flutter pub get
```

## Usage

Import the package and call the `parse` function:

```dart
import 'package:sunphase/sunphase.dart';

void main() {
  final text = "next week, Monday and January 1, 2025";
  // If no language is specified, all supported languages (en, ja, zh) are used by default.
  final results = parse(text, language: 'en', rangeMode: true);
  for (var result in results) {
    print(result);
  }
}
```

## Additional Information

For more details on extending Sunphase by adding new parsers or refiners, please refer to the documentation within the source code. If you have any issues or suggestions, feel free to file an issue on the project's repository.

## License

This project is released under the CC0 1.0 Universal license.
```

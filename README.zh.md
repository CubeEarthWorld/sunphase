# Sunphase

[![License: CC0](https://img.shields.io/badge/License-CC0_1.0-lightgrey.svg)](http://creativecommons.org/publicdomain/zero/1.0/)

[README.md](README.md) | [README.jp.md](README.jp.md)

Sunphase 是一个强大而灵活的 Dart 库，用于从自然语言文本中提取和解析日期。它支持多种语言、时区，并提供用于提取日期范围的范围模式。

## 功能特点

*   **自然语言解析：** 从“明天”、“下周”、“上个月”等字符串中提取日期。
*   **多语言支持：** 支持英语、日语和中文（更多语言即将添加）。
*   **时区支持：** 指定日期解析的时区。
*   **范围模式：** 提取日期范围（例如，“下周”将返回下周的日期列表）。

## 用法

```dart
import 'package:sunphase/sunphase.dart';

void main() {
    // 解析日期
  List<ParsingResult> resultsEn = parse('今天');
  print(resultsEn);

  // 解析英文日期
  List<ParsingResult> resultsEn = parse('Tomorrow', language: 'en');
  print(resultsEn);

  // 解析中文日期
  List<ParsingResult> resultsZh = parse('明天', language: 'zh');
  print(resultsZh);

  // 使用特定参考日期解析日期
  List<ParsingResult> resultsRef = parse('下周', referenceDate: DateTime(2024, 1, 1));
  print(resultsRef);

  // 使用范围模式解析日期
  List<ParsingResult> resultsRange = parse('下周', language: 'zh', rangeMode: true);
  print(resultsRange);

  // 使用特定时区解析日期(UTC)。时区应以字符串形式提供，表示与 UTC 的分钟偏移量，例如，Asia/Shanghai 为 "480"。
  List<ParsingResult> resultsTimezone = parse('明天', language: 'zh', timezone: '480');
  print(resultsTimezone);
}
```

## 安装

将 `sunphase` 添加到您的 `pubspec.yaml`：

```yaml
dependencies:
  sunphase:
    git:
      url: https://github.com/CubeEarthWorld/sunphase.git
```

然后，运行 `pub get`。

## 许可证

本项目根据 CC0 许可证授权 - 有关详细信息，请参阅 [LICENSE](LICENSE) 文件。

## 联系方式

开发者： [cubeearthworld](https://x.com/cubeearthworld)

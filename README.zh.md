# Sunphase

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

[README.md](README.md) | [README.jp.md](README.jp.md)

Sunphase 是一个强大而灵活的 Dart 库，用于从自然语言文本中提取和解析日期。它支持多种语言、时区，并提供用于提取日期范围的范围模式。

示例项目 https://github.com/CubeEarthWorld/sunphase_sample

## 功能特点

*   **自然语言解析：** 从“明天”、“下周”、“上个月”等字符串中提取日期。
*   **多语言支持：** 支持英语、日语和中文 etc（更多语言即将添加）。[语言](lib/languages)
*   **时区支持：** 指定日期解析的时区。
*   **范围模式：** 提取日期范围（例如，“下周”将返回下周的日期列表）。

## 用法

```dart
import 'package:sunphase/sunphase.dart';

void main() {
  // 解析日期
  List<ParsingResult> results = parse('Today');
  print(results);

// 解析时间
  List<ParsingResult> results_time = parse('10:10');
  print(results_time);

// 解析日期和时间
  List<ParsingResult> results_data = parse('march 7 10:10');
  print(results_data);

// 解析日语的日期和时间
  List<ParsingResult> results_data_ja = parse('明日12时14分');
  print(results_data_ja);

// 解析中文的日期和时间
  List<ParsingResult> results_data_zh = parse('三月七号上午九点');
  print(results_data_zh);

// 解析英文的日期
  List<ParsingResult> resultsEn = parse('Tomorrow', language: 'en');
  print(resultsEn);

// 解析中文的日期
  List<ParsingResult> resultsJa = parse('三天后', language: 'zh');
  print(resultsJa);

// 基于参考日期解析日期
  List<ParsingResult> resultsRef = parse('Next Tuesday', referenceDate: DateTime(2021, 2, 4));
  print(resultsRef);

// 在范围模式下解析日期
  List<ParsingResult> resultsRange = parse('Next week', rangeMode: true);
  print(resultsRange);

// 使用特定时区解析日期。时区必须以与UTC的分钟偏移量表示。例如，UTC+8表示为 "480"。
  List<ParsingResult> resultsTimezone = parse('明天', timezone: '480');
  print(resultsTimezone);
}

// 在2025-02-08 11:05:00.000执行时
//[[0] "today" -> 2025-02-09 00:00:00.000]
//[[0] "10:10" -> 2025-02-09 10:10:00.000]
//[[0] "march 7" -> 2025-03-07 10:10:00.000]
//[[0] "明日12时14分" -> 2025-02-10 12:14:00.000, [0] "明日12时14分" -> 2025-02-10 12:14:00.000, [2] "12时14分" -> 2025-02-09 12:14:00.000]
//[0] "三月七号" -> 2025-03-07 00:00:00.000, [2] "七号" -> 2025-03-07 00:00:00.000, [0] "三月七号上午九点" -> 2025-03-07 09:00:00.000]
//[0] "tomorrow" -> 2025-02-10 00:00:00.000]
//[0] "三天后" -> 2025-02-12 04:46:31.708556]
//[0] "next tuesday" -> 2021-02-09 00:00:00.000]
//[0] "next week" -> 2025-02-10 00:00:00.000, [0] "next week" -> 2025-02-11 00:00:00.000, [0] "next week" -> 2025-02-12 00:00:00.000, [0] "next week" -> 2025-02-13 00:00:00.000, [0] "next week" -> 2025-02-14 00:00:00.000, [0] "next week" -> 2025-02-15 00:00:00.000, [0] "next week" -> 2025-02-16 00:00:00.000]
//[0] "明天" -> 2025-02-10 08:00:00.000]

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

本项目根据 BSD 3-Clause License 授权。

## 联系方式

开发者： [cubeearthworld](https://x.com/cubeearthworld)

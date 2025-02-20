# Sunphase

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

[README.md](README.md) | [README.zh.md](README.zh.md)

Sunphaseは、自然言語のテキストから日付を抽出して解析するための、強力で柔軟なDartライブラリです。複数の言語、タイムゾーンをサポートし、日付範囲を抽出するための範囲モードを提供します。

サンプルプロジェクト https://github.com/CubeEarthWorld/sunphase_sample

## 特徴

*   **自然言語解析:** "明日"、"来週"、"先月"などの文字列から日付を抽出します。
*   **多言語サポート:** 英語、日本語、中国語、その他をサポートします（追加予定）。[対応言語](lib/languages)
*   **タイムゾーンサポート:** 日付解析のタイムゾーンを指定できます。
*   **範囲モード:** 日付範囲を抽出します（例えば、"来週"は来週の日付のリストを返します）。

## 使用方法

```dart
import 'package:sunphase/sunphase.dart';

void main() {

  // 日付を解析
  List<ParsingResult> results = parse('Today');
  print(results);//[[0] "today" -> 2025-02-09 00:00:00.000]

  // 時間を解析
  List<ParsingResult> results_time = parse('10:10');
  print(results_time);//[[0] "10:10" -> 2025-02-10 10:10:00.000]

  // 日時を解析
  List<ParsingResult> results_data = parse('march 7 10:10');
  print(results_data);//[[0] "march 7" -> 2025-03-07 10:10:00.000]

  // 日本語で日時を解析
  List<ParsingResult> results_data_ja = parse('明日12時14分');
  print(results_data_ja);//[[0] "明日12時14分" -> 2025-02-10 12:14:00.000]

  // 中国語で日時を解析
  List<ParsingResult> results_data_zh = parse('三月七号上午九点');
  print(results_data_zh);//[[0] "三月七号上午九点" -> 2025-03-07 09:00:00.000]

  // 英語で日付を解析
  List<ParsingResult> resultsEn = parse('Tomorrow', languages: ['en']);
  print(resultsEn);//[[0] "tomorrow" -> 2025-02-10 00:00:00.000]

  // 中国語で日付を解析
  List<ParsingResult> resultsJa = parse('三天后', languages: ['zh']);
  print(resultsJa);//[[0] "三天后" -> 2025-02-12 21:13:33.382038]

  // 特定の基準日で日付を解析
  List<ParsingResult> resultsRef = parse('Next Tuesday', referenceDate: DateTime(2021, 2, 4));
  print(resultsRef);//[[0] "next tuesday" -> 2021-02-09 00:00:00.000]

  // 範囲モードで日付を解析
  List<ParsingResult> resultsRange = parse('Next week', rangeMode: true);
  print(resultsRange);//[[0] "next week" -> 2025-02-10 00:00:00.000, [0] "next week" -> 2025-02-11 00:00:00.000, [0] "next week" -> 2025-02-12 00:00:00.000, [0] "next week" -> 2025-02-13 00:00:00.000, [0] "next week" -> 2025-02-14 00:00:00.000, [0] "next week" -> 2025-02-15 00:00:00.000, [0] "next week" -> 2025-02-16 00:00:00.000]

  // 特定のタイムゾーンで日付を解析。タイムゾーンは、UTCからの分単位オフセットを表す文字列として指定する必要があります。例：UTC+8の場合は "480"。
  List<ParsingResult> resultsTimezone = parse('明天', timezone: '480');
  print(resultsTimezone);//[[0] "明天" -> 2025-02-10 08:00:00.000]
}

```

## インストール

`pubspec.yaml`に`sunphase`を追加します。

```yaml
dependencies:
  sunphase:
    git:
      url: https://github.com/CubeEarthWorld/sunphase.git
```

その後、`pub get`を実行します。

## License

This project is licensed under the BSD 3-Clause License.

## 連絡先

開発者: [cubeearthworld](https://x.com/cubeearthworld)

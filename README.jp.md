# Sunphase

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

[README.md](README.md) | [README.zh.md](README.zh.md)

Sunphaseは、自然言語のテキストから日付を抽出して解析するための、強力で柔軟なDartライブラリです。複数の言語、タイムゾーンをサポートし、日付範囲を抽出するための範囲モードを提供します。

サンプルプロジェクト https://github.com/CubeEarthWorld/sunphase_sample

## 特徴

*   **自然言語解析:** "明日"、"来週"、"先月"などの文字列から日付を抽出します。
*   **多言語サポート:** 英語、日本語、中国語をサポートします（追加予定）。
*   **タイムゾーンサポート:** 日付解析のタイムゾーンを指定できます。
*   **範囲モード:** 日付範囲を抽出します（例えば、"来週"は来週の日付のリストを返します）。

## 使用方法

```dart
import 'package:sunphase/sunphase.dart';

void main() {

  // 日付を解析
  List<ParsingResult> results = parse('今日');
  print(results);

  // 英語で日付を解析
  List<ParsingResult> resultsEn = parse('Tomorrow', language: 'en');
  print(resultsEn);

  // 日本語で日付を解析
  List<ParsingResult> resultsJa = parse('明日', language: 'ja');
  print(resultsJa);

  // 特定の基準日で日付を解析
  List<ParsingResult> resultsRef = parse('来週', referenceDate: DateTime(2021, 2, 4));
  print(resultsRef);

  // 範囲モードで日付を解析
  List<ParsingResult> resultsRange = parse('来週', language: 'ja', rangeMode: true);
  print(resultsRange);

  // 特定のタイムゾーンで日付を解析。タイムゾーンは、UTCからの分単位オフセットを表す文字列として指定する必要があります。例：UTC+9の場合は "540"。
  List<ParsingResult> resultsTimezone = parse('明日', language: 'ja', timezone: '540');
  print(resultsTimezone);
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

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

**Language / 言語 / 语言:**
[English](#english) | [日本語](#japanese) | [中文](#chinese)

---

<a id="english"></a>

# Sunphase

Sunphase is a powerful and flexible Dart library for extracting and parsing dates from natural language text. It supports multiple languages, timezones, and provides a range mode for extracting date ranges.

There is a sample project at https://github.com/CubeEarthWorld/sunphase_sample

## Features

*   **Natural Language Parsing:** Extract dates from strings like "tomorrow", "next week", "last month", etc.
*   **Multi-language Support:** Supports English, Japanese, Chinese, Spanish, Hindi, Korean, and Russian. [Language definitions](lib/languages)
*   **Timezone Support:** Specify a UTC offset in minutes for date parsing.
*   **Range Mode:** Expand span expressions (e.g. "next week") into one date per day in the range.
*   **Configurable Week Start:** Choose Sunday or Monday for named week expressions. The default is Sunday.

## Reference date

Every parse is anchored to a single **reference date** — the point in time that relative expressions such as *today*, *tomorrow*, *next week*, or bare times like *10:10* are resolved against.

| Situation | Reference date used |
|-----------|-------------------|
| `referenceDate` argument is omitted | `DateTime.now()` — the current local wall-clock time at the moment `parse` is called |
| `referenceDate` is explicitly provided | Exactly the value you passed |

> **Example:** if you call `parse('tomorrow')` at 09:00 on 2025-03-07, the reference date is `2025-03-07 09:00:00` and the result will be `2025-03-08 00:00:00`. If you pass `referenceDate: DateTime(2021, 2, 4)`, "tomorrow" resolves to `2021-02-05 00:00:00` regardless of the current time.

When only a **time** is given (e.g. `"10:10"`) and no date context is present, the resolver returns the *next* occurrence of that time after the reference date — i.e. today if the time has not yet passed, otherwise tomorrow.

## Week start

Named week expressions use Sunday as the first day of the week by default. Pass `weekStartsOn: DateTime.monday` to use Monday instead.

For example, with `referenceDate: DateTime(2025, 2, 8)` (Saturday), `parse('next week Sunday')` resolves to `2025-02-09` by default, while `parse('next week Sunday', weekStartsOn: DateTime.monday)` resolves to `2025-02-16`.

## Usage

```dart
import 'package:sunphase/sunphase.dart';

void main() {
  // NOTE: All examples below assume the current date/time is
  //   2025-02-09 21:13:33 (local time, no timezone specified).
  // When no `referenceDate` is provided, DateTime.now() is used
  // as the anchor. Your actual output will differ accordingly.

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

  // Range mode — expand "next week" into one date per day.
  // Week start defaults to Sunday.
  List<ParsingResult> resultsRange = parse('Next week', rangeMode: true);
  print(resultsRange);
  // [[0] "next week" -> 2025-02-16, [0] "next week" -> 2025-02-17, … (7 dates)]

  // Use Monday as the start of the week
  List<ParsingResult> resultsRangeMonday = parse(
    'Next week',
    rangeMode: true,
    weekStartsOn: DateTime.monday,
  );
  print(resultsRangeMonday);
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

---

<a id="japanese"></a>

# Sunphase（日本語）

Sunphase は、自然言語テキストから日付・時刻を抽出・解析する Dart ライブラリです。複数言語・タイムゾーンに対応し、日付範囲を展開する範囲モードも備えています。

サンプルプロジェクト: https://github.com/CubeEarthWorld/sunphase_sample

## 特徴

*   **自然言語解析:** 「明日」「来週」「先月」などの文字列から日付を抽出します。
*   **多言語サポート:** 英語・日本語・中国語・スペイン語・ヒンディー語・韓国語・ロシア語に対応。[対応言語一覧](lib/languages)
*   **タイムゾーンサポート:** UTC からの分単位オフセットでタイムゾーンを指定できます。
*   **範囲モード:** 「来週」などのスパン表現を 1 日 1 件ずつ展開して返します。
*   **週の始まり設定:** 週の始まりを日曜日または月曜日に設定できます。デフォルトは日曜日です。

## 基準日時について

すべての解析は **基準日時（referenceDate）** を起点として行われます。「今日」「明日」「来週」や「10:10」のような相対表現は、この基準日時を基に解決されます。

| 状況 | 使われる基準日時 |
|------|----------------|
| `referenceDate` を省略した場合 | `DateTime.now()` — `parse` を呼び出した瞬間の現地時刻 |
| `referenceDate` を明示した場合 | 渡した値がそのまま使われます |

> **例:** 2025-03-07 09:00:00 に `parse('明日')` を呼ぶと基準日時は `2025-03-07 09:00:00` となり、結果は `2025-03-08 00:00:00` になります。`referenceDate: DateTime(2021, 2, 4)` を渡した場合は現在時刻に関わらず `2021-02-05 00:00:00` になります。

時刻のみの表現（例: `"10:10"`）が与えられ、日付の文脈がない場合は、基準日時より後に来る**次回の発生時刻**（その日の指定時刻がまだ過ぎていなければ当日、過ぎていれば翌日）が返されます。

## 週の始まり

「来週」「来週日曜日」のような週指定の表現は、デフォルトでは日曜日始まりの週として解決されます。月曜日始まりにしたい場合は `weekStartsOn: DateTime.monday` を指定します。

たとえば `referenceDate: DateTime(2025, 2, 8)`（土曜日）で `parse('来週日曜日')` を呼ぶと、デフォルトでは `2025-02-09` になります。`parse('来週日曜日', weekStartsOn: DateTime.monday)` の場合は `2025-02-16` になります。

## 使用方法

```dart
import 'package:sunphase/sunphase.dart';

void main() {
  // 注意: 以下のサンプル出力はすべて現在日時を
  //   2025-02-09 21:13:33（ローカル時刻・タイムゾーン未指定）
  // と仮定しています。`referenceDate` を省略すると DateTime.now() が
  // 基準になるため、実際の出力は異なる場合があります。

  // 相対日付を解析（基準日時は DateTime.now() がデフォルト）
  List<ParsingResult> results = parse('Today');
  print(results); // [[0] "today" -> 2025-02-09 00:00:00.000]

  // 時刻のみを解析 — 10:10 の次回発生時刻に解決
  List<ParsingResult> results_time = parse('10:10');
  print(results_time); // [[0] "10:10" -> 2025-02-10 10:10:00.000]

  // 日付と時刻を同時に解析
  List<ParsingResult> results_data = parse('march 7 10:10');
  print(results_data); // [[0] "march 7" -> 2025-03-07 10:10:00.000]

  // 日本語の日時を解析
  List<ParsingResult> results_data_ja = parse('明日12時14分');
  print(results_data_ja); // [[0] "明日12時14分" -> 2025-02-10 12:14:00.000]

  // 中国語の日時を解析
  List<ParsingResult> results_data_zh = parse('三月七号上午九点');
  print(results_data_zh); // [[0] "三月七号上午九点" -> 2025-03-07 09:00:00.000]

  // 使用言語を限定する
  List<ParsingResult> resultsEn = parse('Tomorrow', languages: ['en']);
  print(resultsEn); // [[0] "tomorrow" -> 2025-02-10 00:00:00.000]

  // 中国語パーサーに限定する
  List<ParsingResult> resultsZh = parse('三天后', languages: ['zh']);
  print(resultsZh); // [[0] "三天后" -> 2025-02-12 21:13:33.382038]

  // 基準日時を明示して解析
  List<ParsingResult> resultsRef = parse('Next Tuesday', referenceDate: DateTime(2021, 2, 4));
  print(resultsRef); // [[0] "next tuesday" -> 2021-02-09 00:00:00.000]

  // 範囲モード — 「来週」を 1 日 1 件に展開。
  // 週の始まりはデフォルトで日曜日です。
  List<ParsingResult> resultsRange = parse('Next week', rangeMode: true);
  print(resultsRange);
  // [[0] "next week" -> 2025-02-16, [0] "next week" -> 2025-02-17, … (7件)]

  // 月曜日始まりにする
  List<ParsingResult> resultsRangeMonday = parse(
    'Next week',
    rangeMode: true,
    weekStartsOn: DateTime.monday,
  );
  print(resultsRangeMonday);
  // [[0] "next week" -> 2025-02-10, [0] "next week" -> 2025-02-11, … (7件)]

  // タイムゾーン指定 — UTC からの分単位オフセット（例: 480 = UTC+8）
  List<ParsingResult> resultsTimezone = parse('明天', timezone: '480');
  print(resultsTimezone); // [[0] "明天" -> 2025-02-10 08:00:00.000]
}
```

## 対応言語

| コード | 言語 |
|--------|------|
| `en` | English（英語） |
| `ja` | 日本語 |
| `zh` | 中文・簡体字（中国語） |
| `es` | Español（スペイン語） |
| `hi` | हिन्दी（ヒンディー語） |
| `ko` | 한국어（韓国語） |
| `ru` | Русский（ロシア語） |

`languages` パラメータに 1 つ以上のコードを渡すと、使用するパーサーを限定できます。省略時は `['en', 'ja', 'zh']` がデフォルトで使用されます。

## インストール

`pubspec.yaml` に `sunphase` を追加します:

```yaml
dependencies:
  sunphase:
    git:
      url: https://github.com/CubeEarthWorld/sunphase.git
```

その後 `pub get` を実行してください。

## ライセンス

このプロジェクトは BSD 3-Clause License のもとで公開されています。

## 連絡先

開発者: [cubeearthworld](https://x.com/cubeearthworld)

---

<a id="chinese"></a>

# Sunphase（中文）

Sunphase 是一个强大且灵活的 Dart 库，用于从自然语言文本中提取和解析日期时间。支持多种语言、时区，并提供将日期范围展开为每日列表的范围模式。

示例项目: https://github.com/CubeEarthWorld/sunphase_sample

## 功能特点

*   **自然语言解析：** 从"明天"、"下周"、"上个月"等字符串中提取日期。
*   **多语言支持：** 支持英语、日语、中文、西班牙语、印地语、韩语和俄语。[语言定义](lib/languages)
*   **时区支持：** 以 UTC 分钟偏移量指定时区。
*   **范围模式：** 将跨度表达式（如"下周"）展开为每天一条记录。
*   **可配置周起始日：** 可选择周日或周一作为一周的开始。默认是周日。

## 基准日期说明

所有解析均以**基准日期（referenceDate）**为起点。"今天"、"明天"、"下周"或裸时间"10:10"等相对表达式均相对于该基准日期进行解析。

| 情况 | 使用的基准日期 |
|------|--------------|
| 省略 `referenceDate` 参数 | `DateTime.now()` — 调用 `parse` 时的本地时间 |
| 显式传入 `referenceDate` | 使用传入的值 |

> **示例：** 在 2025-03-07 09:00:00 调用 `parse('明天')`，基准日期为 `2025-03-07 09:00:00`，结果为 `2025-03-08 00:00:00`。若传入 `referenceDate: DateTime(2021, 2, 4)`，则无论当前时间如何，"明天"均解析为 `2021-02-05 00:00:00`。

仅给出**时间**（如 `"10:10"`）且没有日期上下文时，解析器返回基准日期之后该时刻的**下一次出现时间**——如果今天的该时刻尚未过去则返回今天，否则返回明天。

## 周起始日

"下周"、"下周日"等周表达式默认按周日作为一周的开始来解析。若要使用周一作为一周的开始，请传入 `weekStartsOn: DateTime.monday`。

例如，在 `referenceDate: DateTime(2025, 2, 8)`（周六）时，`parse('下周日')` 默认解析为 `2025-02-09`；`parse('下周日', weekStartsOn: DateTime.monday)` 则解析为 `2025-02-16`。

## 使用方法

```dart
import 'package:sunphase/sunphase.dart';

void main() {
  // 注意：以下示例输出均假设当前日期时间为
  //   2025-02-09 21:13:33（本地时间，未指定时区）。
  // 省略 `referenceDate` 时使用 DateTime.now() 作为基准，
  // 实际输出结果将有所不同。

  // 解析相对日期 — 基准日期默认为 DateTime.now()
  List<ParsingResult> results = parse('Today');
  print(results); // [[0] "today" -> 2025-02-09 00:00:00.000]

  // 解析裸时间 — 解析为 10:10 的下一次出现时间
  List<ParsingResult> results_time = parse('10:10');
  print(results_time); // [[0] "10:10" -> 2025-02-10 10:10:00.000]

  // 同时解析日期和时间
  List<ParsingResult> results_data = parse('march 7 10:10');
  print(results_data); // [[0] "march 7" -> 2025-03-07 10:10:00.000]

  // 解析日语日期时间
  List<ParsingResult> results_data_ja = parse('明日12時14分');
  print(results_data_ja); // [[0] "明日12時14分" -> 2025-02-10 12:14:00.000]

  // 解析中文日期时间
  List<ParsingResult> results_data_zh = parse('三月七号上午九点');
  print(results_data_zh); // [[0] "三月七号上午九点" -> 2025-03-07 09:00:00.000]

  // 限定使用特定语言
  List<ParsingResult> resultsEn = parse('Tomorrow', languages: ['en']);
  print(resultsEn); // [[0] "tomorrow" -> 2025-02-10 00:00:00.000]

  // 限定使用中文解析器
  List<ParsingResult> resultsZh = parse('三天后', languages: ['zh']);
  print(resultsZh); // [[0] "三天后" -> 2025-02-12 21:13:33.382038]

  // 指定基准日期进行解析
  List<ParsingResult> resultsRef = parse('Next Tuesday', referenceDate: DateTime(2021, 2, 4));
  print(resultsRef); // [[0] "next tuesday" -> 2021-02-09 00:00:00.000]

  // 范围模式 — 将"下周"展开为每天一条。
  // 周起始日默认为周日。
  List<ParsingResult> resultsRange = parse('Next week', rangeMode: true);
  print(resultsRange);
  // [[0] "next week" -> 2025-02-16, [0] "next week" -> 2025-02-17, … (共7条)]

  // 使用周一作为一周的开始
  List<ParsingResult> resultsRangeMonday = parse(
    'Next week',
    rangeMode: true,
    weekStartsOn: DateTime.monday,
  );
  print(resultsRangeMonday);
  // [[0] "next week" -> 2025-02-10, [0] "next week" -> 2025-02-11, … (共7条)]

  // 时区 — UTC 分钟偏移量（如 480 = UTC+8）
  List<ParsingResult> resultsTimezone = parse('明天', timezone: '480');
  print(resultsTimezone); // [[0] "明天" -> 2025-02-10 08:00:00.000]
}
```

## 支持的语言

| 代码 | 语言 |
|------|------|
| `en` | English（英语） |
| `ja` | 日本語（日语） |
| `zh` | 中文（简体） |
| `es` | Español（西班牙语） |
| `hi` | हिन्दी（印地语） |
| `ko` | 한국어（韩语） |
| `ru` | Русский（俄语） |

向 `languages` 参数传入一个或多个代码可限制使用的解析器。省略时默认使用 `['en', 'ja', 'zh']`。

## 安装

将 `sunphase` 添加到您的 `pubspec.yaml`：

```yaml
dependencies:
  sunphase:
    git:
      url: https://github.com/CubeEarthWorld/sunphase.git
```

然后运行 `pub get`。

## 许可证

本项目基于 BSD 3-Clause License 授权。

## 联系方式

开发者：[cubeearthworld](https://x.com/cubeearthworld)

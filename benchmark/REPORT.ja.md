# Sunphase 最適化・計測記録

配置先: `C:\Users\mosim\AndroidStudioProjects\sunphase`。
remote: `https://github.com/CubeEarthWorld/sunphase.git`、branch: `master`。
基準commit: `6d2a063cc36ac353fc7a941a82303685df9c1aac`。新規clone時の作業ツリーはクリーン。この計測作業では既存の別プロジェクトを変更していない。計測後の1.0.0リリース変更はCHANGELOG.mdに記載。

リポジトリ内・親ディレクトリに適用するAGENTS.mdや `.agents/skills/*/SKILL.md` は確認されなかった。ローカルCodexのAGENTS.mdは空、memoryディレクトリもないため、現在コード・README・docs/EXTENDING.md・既存テストを判断の根拠にした。

## 採用した変更

- `lib/utils/date_utils.dart`: `lastDayOfMonth` を共通ヘルパーにし、月末日だけ必要な `addMonths` では範囲Mapを作らない。月初の正規化を残すため、DateTimeの下限付近の例外動作も維持する。1回の月末取得につきMap 1個と重複した月初DateTime 1個の生成箇所を除去した。
- `lib/src/core/resolver.dart`: 日のみの解決でも同じ月末ヘルパーを利用。既存の日付推論ルールは維持した。
- `lib/src/core/expression.dart`: 交差Setの生成を `any` に、許可スロットとの差分Setを `every` に置換。競合・形状検証に使い捨てSetを作る必要をなくした。結合後に保持するスロットSetは従来通り。
- 依存追加、キャッシュ、ファイル分割、設定変更はなし。公開エントリーポイントのparseシグネチャ・ParsingResultは変更していない。

## 調査と設計判断

既存の LanguageSpec/NumberReader、Tokenizer、Composer、Resolver、Selector は責務を分離しており、多言語の構成・日時推論も共通化済み。SOLID/DRYの原則だけを理由に新たな層を追加する必要はなかった。測定対象の月アンカーでは月加算が繰り返されるため、月末取得の一時オブジェクト削減を優先した。

| 対象 | 判断 |
|---|---|
| トークンの重なり検索 | 一致終了位置からだけの検索に変えると、CJKの曜日に含まれる数詞が時刻に重なるケースの意味が変わるため維持。 |
| 単一結果の選択sort | 同順位の選択順が変わる可能性があり、今回の実装は維持。 |
| 言語ごとの時刻パターン | 言語別のglueと成分結合に関係するため、単純な重複削除は採用しない。 |
| 月オフセットのループ | 代表的な小さいオフセットでは日付生成が支配的。不要な算術変更は行わない。 |
| 結果キャッシュ | 参照日時・言語・週開始・タイムゾーン依存であり、無効化や上限の責務を増やすため追加しない。 |

## 同条件のAOTベンチマーク

開始UTC: `2026-10-03T17:59:07.9664215Z`。Windows 11 Pro、AMD Ryzen 7 5700G（8コア/16スレッド）、約32 GiB RAM。既存Flutter 3.47.5 / Dart 3.13.4、windows_x64。WindowsローカルタイムゾーンはTokyo Standard Time。

両版とも `dart compile exe` で生成したAOT実行ファイル。driver・SDK・入力・反復数が同じ。参照日時は `DateTime(2025, 2, 8, 11, 5)` に固定。各ケース250 ms以上ウォームアップ後に計測。9回ずつ別プロセスで実行し、baseline→optimized / optimized→baseline の順を交互にした。時間は1呼び出し当たり。範囲モードの出力件数が多い場合も1呼び出しの意味で比較し、全測定ペアのchecksumが一致することを集計時に検証した。

複数入力の文字数は入力集合の合計（各呼び出しでは1入力を循環使用）。正確な入力は [workloads.dart](../tool/workloads.dart) にある。長文は同じ多言語断片を40回繰り返したもの。

| 処理 / 入力 | 反復/回 | 前 中央値 µs [最小–最大] | 後 中央値 µs [最小–最大] | 中央値の時間短縮 |
|---|---:|---:|---:|---:|
| 短文・既定3言語 / 11種・計147 UTF-16単位 | 2000 | 221.679 [217.209–226.945] | 208.918 [203.646–213.412] | 5.8% |
| 7言語・各1言語指定 / 21種・計230 UTF-16単位 | 2000 | 153.654 [150.131–157.952] | 142.450 [141.100–147.164] | 7.3% |
| 月アンカー＋日＋時刻 / 28 UTF-16単位 | 2000 | 282.342 [280.165–289.851] | 254.935 [249.327–263.505] | 9.7% |
| 範囲展開 / 5種・計23 UTF-16単位 | 1500 | 461.739 [452.026–471.648] | 439.758 [425.502–450.704] | 4.8% |
| 長文・単一結果 / 2240 UTF-16単位 | 50 | 43494.080 [43160.200–45253.060] | 38477.120 [37899.220–38628.480] | 11.5% |
| 長文・範囲モード / 2240 UTF-16単位 | 40 | 43661.075 [42823.775–45644.200] | 38560.250 [37422.225–39053.875] | 11.7% |
| 長文・一致なし / 2600 UTF-16単位 | 300 | 3747.937 [3677.030–3827.773] | 3726.903 [3670.147–3770.503] | 差を確認できず |
| 月加算単体 / 月オフセット -24〜+24 | 20000 | 149.511 [146.756–154.597] | 121.238 [119.163–123.750] | 18.9% |

採用した処理の9測定ペアはすべて時間が短縮し、前後の最小–最大範囲も分離した。一致なしの差は測定ばらつき内であり、高速化とは判断しない。

計測中は別のfindプロセス、ChatGPT、Code、claude、msedgewebview2などのCPU活動を検出。ベンチ実行プロセスの外部CPU活動は [activity.json](activity.json) に記録した。これらを停止したりユーザー設定を変更したりしていない。完全なアイドル環境での測定ではないため、数値はこのPC・この負荷条件の結果として扱う。GPU負荷は計測しておらず、このベンチ自体はGPUを使用しない。

## メモリ・サイズ

AOT実行ファイル: 6,426,624 → 6,425,088 bytes（1,536 bytes減、約0.024%）。SDKランタイムを含むベンチ実行ファイルの値で、アプリ配布サイズではない。

- baseline: プロセス最大RSSの中央値 17.023 MiB、範囲 16.977–17.113 MiB。
- optimized: プロセス最大RSSの中央値 16.977 MiB、範囲 16.945–17.047 MiB。

RSS差は約48 KiBで範囲が重なるため、メモリ使用量の実測改善とは判断しない。RSSはVM等も含むプロセス全体であり、操作単位の割り当て量ではない。

JITのVM service診断も試みたが、1000回の操作後・GC後にDateTime=1個、Set=2個など、一時割り当てを反映しない値になった。プロファイラ自身のcollection生成も混在する。この診断からbytes/opや総割り当て削減率は算出しない。詳細は [allocation-status.json](allocation-status.json)。診断の生データはローカルにのみ保存し、リリースの成果物からは除外した。ソース上で不要な生成箇所を除去した事実と、実測の総割り当て量を区別する。

## 検証

| 検証 | 結果 |
|---|---|
| 変更前のflutter test | passed: 259件 |
| 最終版のflutter test | passed: 259件 |
| dart analyze lib test tool | passed: No issues found |
| 基準ソースとの全結果フィールド比較 | passed: 4,484ケース（日時のmicrosecondsSinceEpoch/isUtc、位置、文字列、rangeType/rangeDays、結果順序） |
| 月加算の比較 | passed: 3,960ケース（1900/2000/2024/2100等、28〜31日、負・正の月オフセット） |
| スロット結合の比較 | passed: 65,536通り（256×256） |
| 無効な週開始の例外 | passed: 8チェック |
| DateTimeの絶対上下限付近 | passed: 30比較（正常値と例外型） |
| AOTビルド・実行 | passed: 2版×9回、同じ入力のchecksum一致 |
| git diff --check | passed |
| UI・実アプリ体感 | not-run: このリポジトリはライブラリで、実行可能なアプリ/UIがない |

## 再現手順と成果物

[baseline-source.zip](baseline-source.zip) は基準commitのlibを保存した隔離ソース。SHA-256: `9BB8BC658F936660DEB3BDF10A9EBBDE1B67AE3000DDD3A8F155089C588844CC`。zip内のgit archive commitコメントも基準commitを指す。比較ツールを新規checkoutでも解析できるよう、baseline/libの23ファイル（合計97,296 bytes）は変更しない固定fixtureとして同梱した。生成driverとexeは.gitignoreで除外し、原本zip・計測driver・最終JSON生データも同梱した。

依存状態は [dependencies.lock](dependencies.lock) に保存。テスト再現時に必要ならpubspec.lockにコピーしてから同じSDKでpub getする。通常のライブラリpubspec.lock自体は従来通りgitignore対象。

```powershell
Set-Location C:\Users\mosim\AndroidStudioProjects\sunphase
$sunphaseDart = 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe'
& 'C:\flutter\bin\flutter.bat' pub get
.\tool\run-benchmarks.ps1 -Dart $sunphaseDart -Rounds 9
python tool\summarize.py
& $sunphaseDart run tool\equivalence.dart
& $sunphaseDart run tool\date_limits.dart
& 'C:\flutter\bin\flutter.bat' test --reporter expanded
& $sunphaseDart analyze lib test tool
# 任意: 総割り当て改善の証拠としては使用しないVM診断
& $sunphaseDart --enable-vm-service=0 --disable-service-auth-codes run tool\allocations.dart
```

再実行はbenchmark内の計測JSON・exeを更新する。元結果を残したい場合は先にそれらをコピーする。最終測定の生データは [timings.jsonl](timings.jsonl)、集計は [summary.json](summary.json)、環境は [environment.json](environment.json)、解析の比較用baseline出力は [baseline-snapshots.jsonl](baseline-snapshots.jsonl)。テスト・analyzer・同等性・上下限のログも同じディレクトリに保存した。境界確認前の初期候補データ `*-initial.jsonl` は最終数値に使用せず、ローカルにのみ保存した。

残る制約は、操作単位の総割り当て量を信頼できる形で計測できなかったことと、Android/iOS等の実機・実アプリで未計測であること。今回のmicrobenchmarkの改善率を、そのままアプリ体感の改善率とは解釈しない。

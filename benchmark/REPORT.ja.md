# Sunphase 1.0.0 最適化・再現記録

2026-10-04整理: 解析本体・公開API・既存テストは維持。基準ソース23ファイル/ZIP、生成スナップショット・ログ・重複集計、古いtest_results、総割り当てを測れなかった診断コードを除去した。基準はGit履歴から取得し、検証・測定の生成物は `.dart_tool/sunphase-check/` に置く。日時上下限検証を同等性チェックへ統合した。
実装に使われていないFlutter runtime依存、Flutter SDK環境制約、test直接依存も除去。Flutter testは開発依存として保持。公開DateUtilsユーティリティは互換性のため削除しない。

基準: `6d2a063cc36ac353fc7a941a82303685df9c1aac`。以下は旧公開commit `0ac9cc5efd302eb3ef50350a565be6d3aa0bc5d0` での実測。今回、lib/と測定driverの内容は変更していない。
Windows 11 Pro、Ryzen 7 5700G（8コア/16スレッド）、約32 GiB、Flutter 3.47.5/Dart 3.13.4、windows_x64 AOT。参照日時2025-02-08 11:05、ローカルTZはTokyo Standard Time。各ケース250ms以上ウォームアップ、同じ入力/反復数で前後交互9回。表は1回のparse/addMonths当たりの中央値[最小–最大]。文字単位はUTF-16。

| 入力・1測定の反復 | 前 µs/操作 | 後 µs/操作 | 中央値の時間短縮 |
|---|---:|---:|---:|
| 短文11種/2,000回 | 221.679 [217.209–226.945] | 208.918 [203.646–213.412] | 5.8% |
| 7言語×3入力/2,000回 | 153.654 [150.131–157.952] | 142.450 [141.100–147.164] | 7.3% |
| 月指定28文字単位/2,000回 | 282.342 [280.165–289.851] | 254.935 [249.327–263.505] | 9.7% |
| 範囲5種/1,500回 | 461.739 [452.026–471.648] | 439.758 [425.502–450.704] | 4.8% |
| 長文2,240文字単位/50回 | 43494.080 [43160.200–45253.060] | 38477.120 [37899.220–38628.480] | 11.5% |
| 同長文・範囲/40回 | 43661.075 [42823.775–45644.200] | 38560.250 [37422.225–39053.875] | 11.7% |
| 一致なし2,600文字単位/300回 | 3747.937 [3677.030–3827.773] | 3726.903 [3670.147–3770.503] | 差を確認できず |
| 月加算−24〜＋24か月/20,000回 | 149.511 [146.756–154.597] | 121.238 [119.163–123.750] | 18.9% |

一致なしを除く7ケースは9組すべて短縮し前後範囲も分離。別プロセスのCPU活動があり、完全なアイドル条件の結果ではない。実機/実アプリの体感改善率を示す値ではない。最大RSS中央値は17.024→16.977 MiBだが範囲が重なるため改善未確認。総割り当て量も未確認。ベンチexeは6,426,624→6,425,088 bytes（アプリ配布サイズではない）。
過去の[生データ](https://github.com/CubeEarthWorld/sunphase/blob/0ac9cc5efd302eb3ef50350a565be6d3aa0bc5d0/benchmark/timings.jsonl)、[環境/外部CPU活動](https://github.com/CubeEarthWorld/sunphase/tree/0ac9cc5efd302eb3ef50350a565be6d3aa0bc5d0/benchmark)、[全9回の集計](https://github.com/CubeEarthWorld/sunphase/blob/0ac9cc5efd302eb3ef50350a565be6d3aa0bc5d0/benchmark/summary.json)は旧commitに保持。履歴の書き換えは行わない。

## 再現と検証

```powershell
& C:\flutter\bin\flutter.bat pub get
& C:\flutter\bin\flutter.bat test --reporter expanded
& C:\flutter\bin\flutter.bat analyze --no-pub
.\tool\verify.ps1
.\tool\run-benchmarks.ps1 -Rounds 9
python tool\summarize.py
```

浅いcloneで基準commitがない場合: `git fetch origin 6d2a063cc36ac353fc7a941a82303685df9c1aac`。Dartパスは両ps1の `-Dart` で指定できる。比較コードは `.in` テンプレートから生成し、基準の展開は検証専用フォルダーに限る。再実行はその生成物のみ更新する。benchmark.dart/workloads.dartは同じ固定入力・コードパスを保持。性能比較は同一PC/SDK/入力で複数回行い、ばらつき内の差を改善と解釈しない。
整理後も既存259テスト、静的解析、解析4,484・月加算3,960・スロット65,536通り・無効週開始8・日時上下限30の比較がpassed。生成比較コードも静的解析する。純Dart利用側でも依存解決、AOTビルド、公開parse API実行がpassed。AOT基準/現行両版の1回smoke実行はスクリプト検証であり、新しい速度改善の根拠にはしない。テストCIは未設定、UI/Android/iOS実機は未検証。
公開V1.0.0の旧参照先は `0ac9cc5efd302eb3ef50350a565be6d3aa0bc5d0`。ユーザー依頼によりcleanup commitへタグを更新し、同じGitHubリリースを更新する。pub.dev公開は行わない。

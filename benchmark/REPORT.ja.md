# Dart AOT → Rust release 比較（2026-10-07）

同じWindows x64マシン（AMD Ryzen 7 5700G）、Dart 3.13.4 AOTとRust 1.98.1 release。
旧版は48dbb87、Rustは外部クレートなし・標準ライブラリのみの最終実装。入力・基準日時・言語・反復数を揃え、
各ケースを250msウォームアップして5回測定。表は中央値。ケースごとのチェックサムはすべて一致。
コンパイル時間・初回の正規表現コンパイル・ワーカー転送時間は測定区間に含めていない。

| ケース | Dart μs/回 | Rust μs/回 | 倍率 |
|---|---:|---:|---:|
| parse_short_default | 128.10 | 45.01 | 2.8× |
| parse_seven_languages | 84.20 | 28.02 | 3.0× |
| parse_month_anchor | 149.13 | 42.95 | 3.5× |
| parse_range | 241.79 | 18.04 | 13.4× |
| parse_long_point | 22312.04 | 5249.66 | 4.3× |
| parse_long_range | 22045.88 | 5258.35 | 4.2× |
| parse_long_no_match | 2626.85 | 1459.92 | 1.8× |

全ケース実行後のプロセスRSS中央値：Dart 17.00 MiB、Rust 5.02 MiB
（70.5%減）。両者ともWindowsのWorking Setを読む。
これは独立プロセス全体の比較であり、Zenist Todo全体のメモリ削減率ではない。
Rustはネイティブ実行、DartはAOT VMを含むため、RSS差を解析器単体の割り当て量とは扱わない。
Zenist Todoの非同期往復は別途アプリ側で測定する。本体・テスト・ベンチマークのCargo依存はゼロ。Cargoを使わないrustc単独ビルドも検証済み。

## 再現

旧Dart版はGit履歴から48dbb87を別ディレクトリへ展開し、そこで
`flutter pub get`、`dart compile exe tool/benchmark.dart -o benchmark.exe`、
`benchmark.exe 0` を実行する（旧コードをRust版リポジトリへ復元しない）。
Rust版は `cargo run --release --locked --example benchmark`。
共有入力は `benchmark/workloads.json`。旧版の `add_months` は公開APIから削除したため比較対象外。

## 正確性と修正

- 旧259テストは移植前に全成功。250件の異なる解析呼び出しを `tests/legacy_cases.json` に保存してRustで検証。
- 韓国語 `그끄제` の旧期待値は誤り（2日前）だったため3日前に修正。`그제` は2日前。
- 存在しない日時を翌月・翌日へ丸めない。裸の31日は存在する月まで進め、年なしの2月29日は次の閏年を選ぶ。
- 数値の途中から巨大な数の末尾を拾う誤認識を防止。数値計算と日時の範囲を検証。
- 第N曜日表現と時刻の合成を修正。韓国語漢数詞の対応を追加。
- 全角数字・絵文字を含む原文の位置を維持。UTF-8バイト位置をAPIで明示。
- 範囲展開は1表現36,600日まで。超過をエラーとして返して無制限のメモリ消費を防ぐ。

`cargo test --locked`、`cargo clippy --all-targets --locked -- -D warnings`、
`cargo fmt --check`、Wasmターゲット検査、`cargo package --locked` で検証。

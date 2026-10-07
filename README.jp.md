# Sunphase — Rust版

7言語（英語、日本語、中国語、スペイン語、ヒンディー語、韓国語、ロシア語）に対応する日時解析クレートです。Cargoで管理し、ネイティブとWasmで同じコードを使います。

```toml
[dependencies]
sunphase = { git = "https://github.com/CubeEarthWorld/sunphase", tag = "v1.0.0" }
```

基準日時は明示的に指定します。戻り値の位置は元の文字列のUTF-8バイト位置です。全角数字を含む原文もそのまま取り出せます。
語彙・パターンと共通の日時計算を分離し、独自言語の追加にも対応します。非同期実行は利用アプリ側のワーカーで行ってください。

[Rust API・使用例](README.md) / [拡張方法](docs/EXTENDING.md) / [速度・メモリ比較](benchmark/REPORT.ja.md)

v1.0.0はRustへの破壊的置き換えです。Dartパッケージと旧APIは削除しています。BSD 3-Clauseライセンス。

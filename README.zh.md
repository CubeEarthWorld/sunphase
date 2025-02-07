

#### README_ja.md

```markdown
# Sunphase

Sunphase は、Dart/Flutter 向けの自然言語日付解析パッケージです。英語、日本語、中国語など複数の言語に対応しており、テキストから日付情報を簡単に抽出できます。Sunphase を利用することで、ユーザー入力のテキストから日付を抽出し、アプリケーション内で扱うことが可能です。

## 機能

- 「今日」「明日」「昨日」「来週」「先月」「月曜日」「2025年1月1日」などの自然言語による日付表現を解析
- 対応言語：英語、日本語、中国語
- パーサーおよびリファイナーのパイプラインをカスタマイズ可能
- 単一日付モードとレンジ（日付範囲）モードの両方に対応
- 新しいパーサーやリファイナーを容易に追加できる拡張性の高い設計

## はじめに

### 前提条件

- Flutter または Dart SDK がインストールされていること
- Dart/Flutter の基本的な知識

### インストール

`pubspec.yaml` に以下の依存関係を追加してください:

```yaml
dependencies:
  sunphase: ^1.0.0
```

その後、以下のコマンドを実行してください:

```bash
dart pub get
# または
flutter pub get
```

## 使い方

パッケージをインポートして、`parse` 関数を利用します:

```dart
import 'package:sunphase/sunphase.dart';

void main() {
  final text = "来週 月曜日 および 2025年1月1日";
  // 言語を指定しない場合は、デフォルトで全対応言語（英語、日本語、中国語）で解析します。
  final results = parse(text, language: 'ja', rangeMode: true);
  for (var result in results) {
    print(result);
  }
}
```

## 追加情報

Sunphase のパーサーやリファイナーの拡張方法については、ソースコード内のドキュメントを参照してください。問題や提案がある場合は、プロジェクトのリポジトリで issue を登録してください。

## ライセンス

本プロジェクトは CC0 1.0 Universal ライセンスの下で公開されています。
```
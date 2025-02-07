// test/sunphase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sunphase/sunphase.dart';

void main() {
  test('parses "today" in English', () {
    // 解析時に言語指定 "en" を与える（指定しない場合は全言語で解析される）
    final results = parse("today", language: "en");
    expect(results.isNotEmpty, true);
    // 返却された結果の中に "today" が含まれているか確認
    expect(results.any((r) => r.text.toLowerCase().contains("today")), true);
  });

  test('parses "今日" in Japanese', () {
    final results = parse("今日はいい天気", language: "ja");
    expect(results.isNotEmpty, true);
    expect(results.any((r) => r.text.contains("今日")), true);
  });

  // レンジモードの簡易テスト例
  test('applies range mode correctly', () {
    // "next week" の例で、レンジモードで複数の日付が返ることを確認
    final results = parse("next week", language: "en", rangeMode: true);
    // 例として、7件の結果が返ると期待する（実装により異なる場合は調整）
    expect(results.length, 7);
  });
}

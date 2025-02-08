// lib/core/result.dart
/// 解析結果を保持するクラス。
class ParsingResult {
  final int index;      // 入力テキスト内での抽出開始位置
  final String text;    // 抽出された文字列
  final DateTime date;  // 解析された日付

  ParsingResult({required this.index, required this.text, required this.date});

  @override
  String toString() => '[$index] "$text" -> $date';
}

// lib/core/result.dart
class ParsingResult {
  final int index;      // 入力テキスト内での抽出開始位置
  final String text;    // 抽出された文字列
  final DateTime date;  // 解析された日付
  final int? rangeDays; // 範囲指定の場合の日数
  final String? rangeType; // 範囲指定の場合のタイプ（例："week", "month"）

  ParsingResult({
    required this.index,
    required this.text,
    required this.date,
    this.rangeDays,
    this.rangeType,
  });

  @override
  String toString() => '[$index] "$text" -> $date';
}

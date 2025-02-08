/// 解析結果を保持するクラス。
class ParsingResult {
  final int index;      // 入力テキスト内での抽出開始位置
  final String text;    // 抽出された文字列
  final DateTime date;  // 解析された日付

  /// 範囲指定の場合、範囲内の日数（例："in 5 days"なら今日を含めて6日分の場合は6）
  final int? rangeDays;
  /// 範囲指定の場合のタイプ。例："week"（次週）や "month"（次月）など。
  final String? rangeType;

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

// lib/core/result.dart

/// 解析結果のコンポーネント。日付情報に加えて、時刻情報が明示されているかどうかを [hasTime] で保持します。
class ParsedComponent {
  final DateTime date;
  final bool hasTime; // 時刻情報が明示されている場合は true

  ParsedComponent({required this.date, this.hasTime = false});

  ParsedComponent copyWith({DateTime? date, bool? hasTime}) {
    return ParsedComponent(
      date: date ?? this.date,
      hasTime: hasTime ?? this.hasTime,
    );
  }
}

/// 解析結果そのものを保持します。
class ParsingResult {
  final int index;
  final String text;
  final ParsedComponent component;

  ParsingResult({
    required this.index,
    required this.text,
    required this.component,
  });

  ParsingResult copyWith({DateTime? date, bool? hasTime}) {
    return ParsingResult(
      index: this.index,
      text: this.text,
      component: this.component.copyWith(date: date, hasTime: hasTime),
    );
  }

  DateTime get date => component.date;

  @override
  String toString() =>
      'ParsingResult(index: $index, text: "$text", date: $date, hasTime: ${component.hasTime})';
}

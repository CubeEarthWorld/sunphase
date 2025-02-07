class ParsingResult {
  final int index;
  final String text;
  final ParsedComponent component;

  ParsingResult({
    required this.index,
    required this.text,
    required this.component,
  });

  DateTime get date => component.date;

  @override
  String toString() => 'ParsingResult(index: $index, text: "$text", date: $date)';
}

class ParsedComponent {
  final DateTime date;

  ParsedComponent({required this.date});

  ParsedComponent copyWith({DateTime? date}) {
    return ParsedComponent(date: date ?? this.date);
  }
}

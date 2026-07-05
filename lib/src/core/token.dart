// lib/src/core/token.dart
//
// A token is one recognised component (or fused component group) with
// its position in the input text.

import 'component.dart';

class Token {
  final int start;
  final int end;
  final String text;
  final List<DateComponent> components;

  Token({
    required this.start,
    required this.end,
    required this.text,
    required this.components,
  });

  /// Union of the slots filled by all components in this token.
  Set<Slot> get slots => components.expand((c) => c.slots).toSet();

  bool overlaps(Token other) => start < other.end && other.start < end;

  @override
  String toString() => '[$start,$end) "$text" $components';
}

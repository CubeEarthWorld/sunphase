// lib/src/core/expression.dart
//
// A DateExpression is one or more merged tokens forming a single
// semantic date/time statement (e.g. 来月 + 21日 + 14時).

import 'component.dart';
import 'token.dart';

class DateExpression {
  final int start;
  final int end;
  final List<DateComponent> components;
  final Set<Slot> slots;

  DateExpression._(this.start, this.end, this.components, this.slots);

  factory DateExpression.fromToken(Token token) => DateExpression._(
    token.start,
    token.end,
    List.of(token.components),
    token.slots,
  );

  /// Whether [token] can extend this expression: no slot may be filled
  /// twice, and the combined slot set must form a valid shape.
  bool canAccept(Token token) {
    final other = token.slots;
    if (slots.intersection(other).isNotEmpty) return false;
    return _shapeValid(slots.union(other));
  }

  DateExpression merge(Token token) => DateExpression._(
    start,
    token.end,
    [...components, ...token.components],
    slots.union(token.slots),
  );

  int get length => end - start;

  int get specificity =>
      components.fold(0, (sum, c) => sum + c.specificity);

  /// The universal grammar of date semantics: which slot combinations
  /// form one coherent expression.
  ///
  /// - A relative day (明日, "in 3 days") fixes the calendar date fully,
  ///   so only a time may follow.
  /// - A relative week (来週) combines only with a weekday and a time.
  /// - Everything else (year/month/day/weekday/time in any mix) is a
  ///   calendar-date expression.
  static bool _shapeValid(Set<Slot> s) {
    if (s.contains(Slot.dayRel)) {
      return s.difference(const {Slot.dayRel, Slot.time, Slot.meridiem}).isEmpty;
    }
    if (s.contains(Slot.weekRel)) {
      return s
          .difference(const {Slot.weekRel, Slot.weekday, Slot.time, Slot.meridiem})
          .isEmpty;
    }
    return true;
  }
}

// lib/src/core/composer.dart
//
// Language-neutral composition: merges adjacent, semantically
// compatible tokens into one expression.
//
// Two tokens belong to the same expression when
//   1. the text between them consists only of connective "glue"
//      (whitespace and language-specific particles: の, "on", "de", …),
//   2. their semantic slots don't collide, and
//   3. the merged slot set forms a valid shape (see DateExpression).
//
// This is where 来月 + 21日 + 12時31分 becomes a single expression —
// combination coverage falls out of the algebra instead of being
// enumerated pattern by pattern per language.

import '../language/language.dart';
import 'expression.dart';
import 'token.dart';

class Composer {
  final LanguageSpec language;

  const Composer(this.language);

  List<DateExpression> compose(String text, List<Token> tokens) {
    final expressions = <DateExpression>[];
    DateExpression? current;

    for (final token in tokens) {
      if (current != null &&
          _isGlue(text.substring(current.end, token.start)) &&
          current.canAccept(token)) {
        current = current.merge(token);
      } else {
        if (current != null) expressions.add(current);
        current = DateExpression.fromToken(token);
      }
    }
    if (current != null) expressions.add(current);
    return expressions;
  }

  bool _isGlue(String gap) => gap.isEmpty || language.glue.hasMatch(gap);
}

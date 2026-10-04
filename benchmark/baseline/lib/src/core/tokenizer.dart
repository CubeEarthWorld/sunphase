// lib/src/core/tokenizer.dart
//
// Runs every token pattern of one language over the input and resolves
// overlapping candidates by maximal munch: at each position the longest
// candidate wins (ties broken by pattern declaration order), which is
// why 明々後日 beats 明後日 and 10日後 beats 10日.

import '../language/language.dart';
import 'token.dart';

class Tokenizer {
  final LanguageSpec language;

  const Tokenizer(this.language);

  List<Token> tokenize(String text, DateTime referenceDate) {
    final ctx = TokenContext(language.numbers, referenceDate);
    final candidates = <({Token token, int order})>[];

    for (var i = 0; i < language.patterns.length; i++) {
      final pattern = language.patterns[i];
      for (final match in _overlappingMatches(pattern.regex, text)) {
        final components = pattern.build(match, ctx);
        if (components == null || components.isEmpty) continue;
        candidates.add((
          token: Token(
            start: match.start,
            end: match.end,
            text: match.group(0)!,
            components: components,
          ),
          order: i,
        ));
      }
    }

    candidates.sort((a, b) {
      if (a.token.start != b.token.start) {
        return a.token.start.compareTo(b.token.start);
      }
      if (a.token.end != b.token.end) {
        return b.token.end.compareTo(a.token.end); // longer first
      }
      return a.order.compareTo(b.order);
    });

    final kept = <Token>[];
    for (final c in candidates) {
      if (kept.isEmpty || !kept.last.overlaps(c.token)) {
        kept.add(c.token);
      }
    }
    return kept;
  }

  /// Like `allMatches`, but also yields matches that begin inside an
  /// earlier match. Plain `allMatches` resumes scanning after each match
  /// end, which can hide the correct token: in 下周二14点14分 the time
  /// pattern first matches 二14点14分 (二 is a numeral), and the real
  /// token 14点14分 would never be produced. Scanning from every start
  /// position lets overlap resolution pick the right combination.
  static Iterable<RegExpMatch> _overlappingMatches(
    RegExp regex,
    String text,
  ) sync* {
    var pos = 0;
    var lastStart = -1;
    while (pos <= text.length) {
      final iterator = regex.allMatches(text, pos).iterator;
      if (!iterator.moveNext()) break;
      final match = iterator.current;
      if (match.start != lastStart) {
        yield match;
        lastStart = match.start;
      }
      pos = match.start + 1;
    }
  }
}

// lib/sunphase.dart
//
// Sunphase — a natural-language date and time parser for Dart/Flutter.
//
// This file is the public entry point of the library. Application code
// should only need to import `package:sunphase/sunphase.dart` and call
// the top-level `parse` function defined below.
//
// The heavy lifting (language detection, pattern matching, date
// resolution, range expansion, timezone application) is delegated to the
// `ParserManager`. See `lib/core/parser_manager.dart` for the pipeline.

import 'core/result.dart'; // Used internally as the return type.
export 'core/result.dart'; // Re-exported so callers can use `ParsingResult`.
import 'core/parser_manager.dart';

/// Parses natural-language date and time expressions from [text] and returns
/// a list of [ParsingResult]s.
///
/// ## Reference date
/// Every parse is anchored to a single "reference date" — the point in time
/// that expressions like *today*, *tomorrow*, *next week*, or bare times such
/// as *10:10* are interpreted relative to. If [referenceDate] is omitted, the
/// current local wall-clock time (`DateTime.now()`) is used.
///
/// ## Languages
/// Pass a list of ISO-639-1 codes in [languages] to restrict which language
/// parsers run (e.g. `['en']` for English only). When omitted, the default set
/// `['en', 'ja', 'zh']` is used so mixed-language input is handled out of the
/// box. Currently supported codes: `en`, `ja`, `zh`, `es`, `hi`, `ko`, `ru`.
///
/// ## Range mode
/// When [rangeMode] is `true`, expressions that denote a span (for example
/// *next week* or *march*) are expanded into one [ParsingResult] per day in
/// the range. When `false` (the default), the single best-matching result is
/// returned.
///
/// ## Timezone
/// [timezone] is a string containing a UTC offset in **minutes**
/// (e.g. `"480"` for UTC+8, `"-300"` for UTC-5). When supplied, the resolved
/// `DateTime`s are shifted by that offset.
List<ParsingResult> parse(
  String text, {
  DateTime? referenceDate,
  List<String>? languages,
  bool rangeMode = false,
  String? timezone,
}) {
  return ParserManager.parse(
    text,
    referenceDate: referenceDate,
    languages: languages,
    rangeMode: rangeMode,
    timezone: timezone,
  );
}

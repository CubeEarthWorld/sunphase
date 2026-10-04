// lib/src/language/registry.dart
//
// Central registry of supported languages. Adding a language to
// Sunphase means writing one LanguageSpec file and listing it here —
// the engine needs no changes.

import 'en.dart';
import 'es.dart';
import 'hi.dart';
import 'ja.dart';
import 'ko.dart';
import 'language.dart';
import 'ru.dart';
import 'universal.dart';
import 'zh.dart';

class LanguageRegistry {
  static final Map<String, LanguageSpec> _byCode = {
    'en': EnLanguage.spec,
    'ja': JaLanguage.spec,
    'zh': ZhLanguage.spec,
    'ko': KoLanguage.spec,
    'ru': RuLanguage.spec,
    'es': EsLanguage.spec,
    'hi': HiLanguage.spec,
  };

  /// The always-on spec for machine-readable formats.
  static final LanguageSpec universal = UniversalLanguage.spec;

  /// Returns the spec for an ISO-639-1 [code], or null if unsupported.
  static LanguageSpec? byCode(String code) => _byCode[code];

  /// Supported ISO-639-1 codes.
  static Iterable<String> get supportedCodes => _byCode.keys;
}

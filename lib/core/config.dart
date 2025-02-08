// lib/core/config.dartimport '../languages/en.dart';import '../languages/ja.dart';import '../languages/zh.dart';import '../languages/es.dart';import '../languages/ar.dart';import '../languages/fr.dart';import '../languages/hi.dart';import '../languages/id.dart';import '../languages/pt.dart';import '../languages/bn.dart';import '../languages/ru.dart';import '../languages/de.dart';import '../languages/ko.dart';import '../languages/vi.dart';import '../languages/not_language.dart';import '../languages/language_interface.dart';/// Config クラスは、sunphase パッケージのグローバルな設定です。class Config { /// デフォルトで利用する言語（各言語＋非言語のパーサー） static List<Language> defaultLanguages = [  EnglishLanguage(),  JapaneseLanguage(),  ChineseLanguage(),  SpanishLanguage(),  ArabicLanguage(),  FrenchLanguage(),  HindiLanguage(),  IndonesianLanguage(),  PortugueseLanguage(),  BengaliLanguage(),  RussianLanguage(),  GermanLanguage(),  KoreanLanguage(),  VietnameseLanguage(),  // 非言語形式を処理するパーサーを追加  NonLanguage(), ]; /// 指定された言語コードに一致する言語リストを返す static List<Language> getLanguage(String code) {  return defaultLanguages.where((lang) => lang.code == code).toList(); }}
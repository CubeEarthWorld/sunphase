// lib/core/config.dartimport '../languages/en.dart';import '../languages/ja.dart';import '../languages/zh.dart';import '../languages/not_language.dart';import '../languages/language_interface.dart';/// Config クラスは、sunphase パッケージのグローバルな設定です。class Config { /// デフォルトで利用する言語（全言語） static List<Language> defaultLanguages = [  EnglishLanguage(),  JapaneseLanguage(),  ChineseLanguage(),  NonLanguage(), // 非言語パーサーを追加 ]; /// 指定された言語コードに一致する言語リストを返す。 static List<Language> getLanguage(String code) {  return defaultLanguages.where((lang) => lang.code == code).toList(); }}
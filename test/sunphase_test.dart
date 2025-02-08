import 'package:sunphase/sunphase.dart';

void main() {

  // 日付を解析
  List<ParsingResult> results = parse('Today');
  print(results);

  // 日付を解析
  List<ParsingResult> results_time = parse('10:10');
  print(results_time);

  // 日付を解析
  List<ParsingResult> results_data = parse('march 7 10:10');
  print(results_data);


  // 英語で日付を解析
  List<ParsingResult> resultsEn = parse('Tomorrow', language: 'en');
  print(resultsEn);

  // 中国語で日付を解析
  List<ParsingResult> resultsJa = parse('三天后', language: 'zh');
  print(resultsJa);

  // 特定の基準日で日付を解析
  List<ParsingResult> resultsRef = parse('Next Tuesday', referenceDate: DateTime(2021, 2, 4));
  print(resultsRef);

  // 範囲モードで日付を解析
  List<ParsingResult> resultsRange = parse('Next week', rangeMode: true);
  print(resultsRange);

  // 特定のタイムゾーンで日付を解析。タイムゾーンは、UTCからの分単位オフセットを表す文字列として指定する必要があります。例：UTC+9の場合は "540"。
  List<ParsingResult> resultsTimezone = parse('明天', timezone: '480');
  print(resultsTimezone);
}
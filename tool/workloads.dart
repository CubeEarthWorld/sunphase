// Fixed inputs shared by the AOT benchmark and equivalence check.
const shortInputs = [
  'tomorrow at 3pm',
  'next month on the 21st at 2pm',
  'March 7 10:10',
  '来月21日12時31分',
  '来週火曜14時14分',
  '明日午後３時３０分',
  '下个月21号下午3点',
  '明天上午九点',
  '2025-03-07T10:10:00Z',
  'no date in this sentence',
  '',
];

const languageInputs = {
  'en': ['tomorrow at 3pm', 'next month on the 21st at 2pm', 'last Friday'],
  'ja': ['来月21日12時31分', '来週火曜14時14分', '明日午後３時３０分'],
  'zh': ['下个月21号下午3点', '明天上午九点', '三天后'],
  'es': ['mañana a las 3pm', 'el próximo mes', 'el tercer lunes de marzo'],
  'hi': ['कल', 'अगले सोमवार', '3 दिन बाद'],
  'ko': ['내일', '다음 달 21일', '오후 3시'],
  'ru': ['завтра', 'в следующем месяце', 'через 3 дня'],
};

const rangeInputs = ['next week', 'march', '来月', '3日以内', '下个月'];
final longInput = List.filled(
  40,
  'tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. ',
).join();
final noMatchInput = List.filled(100, 'nothing to schedule here. ').join();

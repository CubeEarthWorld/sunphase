use crate::{Captures, Component, Language, Pattern};

const MONTHS_OPT_DOT: &str = "сентября|сентябре|сентябрю|сентябрём|сентябрем|сентябрь|февраля|феврале|февралю|февралём|февралем|февраль|декабря|декабре|декабрю|декабрём|декабрем|декабрь|октября|октябре|октябрю|октябрём|октябрем|октябрь|января|январе|январю|январём|январем|январь|апреля|апреле|апрелю|апрелем|апрель|августа|августе|августу|августом|август|ноября|ноябре|ноябрю|ноябрём|ноябрем|ноябрь|марта|марте|марту|мартом|март|июня|июне|июню|июнем|июнь|июля|июле|июлю|июлем|июль|февр\\.?|сент\\.?|нояб\\.?|янв\\.?|фев\\.?|мар\\.?|апр\\.?|июн\\.?|июл\\.?|авг\\.?|сен\\.?|окт\\.?|ноя\\.?|дек\\.?|маем|мая|мае|маю|май";

const WEEKDAYS: &str = "понедельником|понедельника|понедельнику|понедельнике|понедельник|воскресеньем|воскресением|воскресенья|воскресенье|воскресенью|воскресеньи|воскресения|воскресение|воскресению|воскресении|четвергом|четверга|четвергу|четверге|четверг|вторником|вторника|вторнику|вторнике|вторник|пятницей|пятницею|пятницой|пятница|пятницы|пятницу|пятнице|субботой|субботою|суббота|субботы|субботу|субботе|средой|средою|среда|среды|среду|среде|пнд|втр|чтв|птн|суб|вск|пн|вт|ср|чт|пт|сб|вс";

const ORD_SUFFIX: &str = "(?:ого|ому|ой|ый|ая|ое|ую|ом|ым)";
const ORD_STEMS_1_9: &str = "(?:перв|втор|четв[её]рт|пят|шест|седьм|восьм|девят)";
const ORD_STEMS_1_30: &str = "(?:перв|втор|четв[её]рт|пят|шест|седьм|восьм|девят|десят|одиннадцат|двенадцат|тринадцат|четырнадцат|пятнадцат|шестнадцат|семнадцат|восемнадцат|девятнадцат|двадцат|тридцат)";
const TRET_FORMS: &str = "трет(?:ьего|ьему|ьей|ьий|ьем|ьим|ья|ье|ью|ий)";

const ORD_1_12_GEN: &str = "(?:первого|второго|третьего|четв[её]ртого|пятого|шестого|седьмого|восьмого|девятого|десятого|одиннадцатого|двенадцатого)";

const CARD_1_9_NOM: &str =
    "(?:один|одна|одно|одну|два|две|три|четыре|пять|шесть|семь|восемь|девять)";
const CARD_TENS_NOM: &str = "(?:двадцать|тридцать|сорок|пятьдесят)";
const CARD_MINS_NOM: &str = "(?:(?:двадцать|тридцать|сорок|пятьдесят)\\s+(?:один|одна|одно|одну|два|две|три|четыре|пять|шесть|семь|восемь|девять)|одиннадцать|двенадцать|тринадцать|четырнадцать|пятнадцать|шестнадцать|семнадцать|восемнадцать|девятнадцать|двадцать|тридцать|пятьдесят|четыре|девять|десять|восемь|сорок|один|одна|одно|одну|пять|шесть|семь|ноль|нуль|два|две|три)";

const CARD_HOURS: &str = "(?:двадцать\\s+(?:четыре|четыр[её]х|четыр[её]м|один|одного|одному|два|двух|двум|три|тр[её]х|тр[её]м)|одиннадцат[иь]|двенадцат[иь]|тринадцат[иь]|четырнадцат[иь]|пятнадцат[иь]|шестнадцат[иь]|семнадцат[иь]|восемнадцат[иь]|девятнадцат[иь]|двадцат[иь]|четыр[её]х|четыр[её]м|четыре|десят[иь]|девят[иь]|восьм[и]|восемь|сем[иь]|шест[иь]|пят[иь]|тр[её]х|тр[её]м|три|двух|двум|два|две|ноль|нуль)";

const GEN_MINS: &str = "(?:(?:двадцати|тридцати|сорока|пятидесяти)\\s+(?:одной|двух|тр[её]х|четыр[её]х|пяти|шести|семи|восьми|девяти)|одиннадцати|двенадцати|тринадцати|четырнадцати|пятнадцати|шестнадцати|семнадцати|восемнадцати|девятнадцати|двадцати|тридцати|пятидесяти|четыр[её]х|десяти|девяти|восьми|сорока|одной|пяти|шести|семи|тр[её]х|двух)";

const WORD_NUMS_WITH_PAIR: &str = "(?:(?:двадцать|тридцать|сорок|пятьдесят|двадцати|тридцати|сорока|пятидесяти)\\s+(?:один|одна|одно|одну|одного|одной|два|две|двух|три|тр[её]х|четыре|четыр[её]х|пять|пяти|шесть|шести|семь|семи|восемь|восьми|девять|девяти)|одиннадцат[иь]|двенадцат[иь]|тринадцат[иь]|четырнадцат[иь]|пятнадцат[иь]|шестнадцат[иь]|семнадцат[иь]|восемнадцат[иь]|девятнадцат[иь]|двадцат[иь]|тридцат[иь]|пятьдесят|пятидесяти|четыр[её]х|четыре|десят[иь]|девят[иь]|восьми|восемь|сем[иь]|шест[иь]|пят[иь]|сорока|сорок|одного|одной|одним|одну|один|одна|одно|тр[её]х|двух|два|две|три|пару|пара|пары)";

const OFFSET_UNITS: &str = "сутки|суток|день|дня|дней|недел[яиюь]|месяц(?:а|ев)?|год(?:а|ов)?|лет";
const SINGULAR_UNITS: &str = "сутки|день|неделю|неделя|месяц|год";

fn cap<'a>(c: &'a Captures<'_>, name: &str) -> Option<&'a str> {
    c.name(name).map(|m| m.as_str())
}

fn parse_weekday(raw: &str) -> Option<i32> {
    let w = raw.to_lowercase();
    if w.starts_with("понедельник") || w == "пн" || w == "пнд" {
        Some(1)
    } else if w.starts_with("вторник") || w == "вт" || w == "втр" {
        Some(2)
    } else if w.starts_with("сред") || w == "ср" {
        Some(3)
    } else if w.starts_with("четверг") || w == "чт" || w == "чтв" {
        Some(4)
    } else if w.starts_with("пятниц") || w == "пт" || w == "птн" {
        Some(5)
    } else if w.starts_with("суббот") || w == "сб" || w == "суб" {
        Some(6)
    } else if w.starts_with("воскресен") || w == "вс" || w == "вск" {
        Some(7)
    } else {
        None
    }
}

fn parse_month(raw: &str) -> Option<i32> {
    let m = raw.to_lowercase();
    let m = m.trim_end_matches('.');
    if m.starts_with("янв") {
        Some(1)
    } else if m.starts_with("фев") {
        Some(2)
    } else if m.starts_with("мар") {
        Some(3)
    } else if m.starts_with("апр") {
        Some(4)
    } else if matches!(m, "май" | "мая" | "мае" | "маю" | "маем") {
        Some(5)
    } else if m.starts_with("июн") {
        Some(6)
    } else if m.starts_with("июл") {
        Some(7)
    } else if m.starts_with("авг") {
        Some(8)
    } else if m.starts_with("сен") {
        Some(9)
    } else if m.starts_with("окт") {
        Some(10)
    } else if m.starts_with("ноя") {
        Some(11)
    } else if m.starts_with("дек") {
        Some(12)
    } else {
        None
    }
}

fn single_ru_cardinal(w: &str, allow_pair: bool) -> Option<i32> {
    Some(match w {
        "ноль" | "нуль" | "ноля" | "нуля" => 0,
        "один" | "одна" | "одно" | "одну" | "одного" | "одной" | "одному" | "одним" | "одном" => {
            1
        }
        "два" | "две" | "двух" | "двум" | "двумя" => 2,
        "пара" | "пару" | "пары" if allow_pair => 2,
        "три" | "трёх" | "трех" | "трём" | "трем" | "тремя" => 3,
        "четыре" | "четырёх" | "четырех" | "четырём" | "четырем" | "четырьмя" => {
            4
        }
        "пять" | "пяти" | "пятью" => 5,
        "шесть" | "шести" | "шестью" => 6,
        "семь" | "семи" | "семью" => 7,
        "восемь" | "восьми" | "восемью" | "восьмью" => 8,
        "девять" | "девяти" | "девятью" => 9,
        "десять" | "десяти" | "десятью" => 10,
        "одиннадцать" | "одиннадцати" => 11,
        "двенадцать" | "двенадцати" => 12,
        "тринадцать" | "тринадцати" => 13,
        "четырнадцать" | "четырнадцати" => 14,
        "пятнадцать" | "пятнадцати" => 15,
        "шестнадцать" | "шестнадцати" => 16,
        "семнадцать" | "семнадцати" => 17,
        "восемнадцать" | "восемнадцати" => 18,
        "девятнадцать" | "девятнадцати" => 19,
        "двадцать" | "двадцати" => 20,
        "тридцать" | "тридцати" => 30,
        "сорок" | "сорока" => 40,
        "пятьдесят" | "пятидесяти" => 50,
        _ => return None,
    })
}

fn parse_ru_cardinal(raw: &str, allow_pair: bool) -> Option<i32> {
    let trimmed = raw.trim();
    if let Some(n) = crate::number(trimmed) {
        return Some(n);
    }
    let lower = trimmed.to_lowercase();
    let parts: Vec<&str> = lower.split_whitespace().collect();
    match parts.as_slice() {
        [w] => single_ru_cardinal(w, allow_pair),
        [tens, ones] => {
            let t = single_ru_cardinal(tens, false)?;
            let u = single_ru_cardinal(ones, false)?;
            if matches!(t, 20 | 30 | 40 | 50) && (1..=9).contains(&u) {
                Some(t + u)
            } else {
                None
            }
        }
        _ => None,
    }
}

fn strip_ord_stem(w: &str) -> Option<i32> {
    if let Some(stem) = w
        .strip_suffix("ьего")
        .or_else(|| w.strip_suffix("ьему"))
        .or_else(|| w.strip_suffix("ьей"))
        .or_else(|| w.strip_suffix("ьий"))
        .or_else(|| w.strip_suffix("ьем"))
        .or_else(|| w.strip_suffix("ьим"))
        .or_else(|| w.strip_suffix("ья"))
        .or_else(|| w.strip_suffix("ье"))
        .or_else(|| w.strip_suffix("ью"))
        .or_else(|| w.strip_suffix("ий"))
        && stem == "трет"
    {
        return Some(3);
    }
    let stem = w
        .strip_suffix("ого")
        .or_else(|| w.strip_suffix("ому"))
        .or_else(|| w.strip_suffix("ой"))
        .or_else(|| w.strip_suffix("ый"))
        .or_else(|| w.strip_suffix("ая"))
        .or_else(|| w.strip_suffix("ое"))
        .or_else(|| w.strip_suffix("ую"))
        .or_else(|| w.strip_suffix("ом"))
        .or_else(|| w.strip_suffix("ым"))?;
    Some(match stem {
        "перв" => 1,
        "втор" => 2,
        "четвёрт" | "четверт" => 4,
        "пят" => 5,
        "шест" => 6,
        "седьм" => 7,
        "восьм" => 8,
        "девят" => 9,
        "десят" => 10,
        "одиннадцат" => 11,
        "двенадцат" => 12,
        "тринадцат" => 13,
        "четырнадцат" => 14,
        "пятнадцат" => 15,
        "шестнадцат" => 16,
        "семнадцат" => 17,
        "восемнадцат" => 18,
        "девятнадцат" => 19,
        "двадцат" => 20,
        "тридцат" => 30,
        _ => return None,
    })
}

fn parse_ru_ordinal(raw: &str) -> Option<i32> {
    let trimmed = raw.trim();
    if let Some(first) = trimmed.chars().next()
        && first.is_ascii_digit()
    {
        let digits: String = trimmed.chars().take_while(|c| c.is_ascii_digit()).collect();
        return crate::number(&digits);
    }
    let lower = trimmed.to_lowercase();
    let parts: Vec<&str> = lower.split_whitespace().collect();
    let val = match parts.as_slice() {
        [w] => strip_ord_stem(w)?,
        [tens, ones] => {
            let t = match *tens {
                "двадцать" => 20,
                "тридцать" => 30,
                _ => return None,
            };
            let u = strip_ord_stem(ones)?;
            if (1..=9).contains(&u) {
                t + u
            } else {
                return None;
            }
        }
        _ => return None,
    };
    (1..=31).contains(&val).then_some(val)
}

fn pm_for(mer: &str, hour: i32) -> bool {
    let m = mer.to_lowercase();
    if m.starts_with("утр") || m == "до полудня" || m == "после полуночи" {
        false
    } else if m.starts_with("ноч") {
        (8..=11).contains(&hour)
    } else {
        true
    }
}

fn parse_year_opt(c: &Captures<'_>) -> Option<i32> {
    cap(c, "y").or_else(|| cap(c, "y2")).and_then(crate::number)
}

fn offset_unit_component(unit: &str, n: i32) -> Option<Component> {
    let u = unit.to_lowercase();
    if u.starts_with('д') || u.starts_with("сут") {
        Some(Component::RelativeDay(n))
    } else if u.starts_with("недел") {
        Some(Component::Week(n, false))
    } else if u.starts_with("месяц") {
        Some(Component::MonthOffset(n))
    } else if u.starts_with("год") || u == "лет" {
        Some(Component::YearOffset(n))
    } else {
        None
    }
}

fn anchor_offset(mod_word: &str) -> Option<i32> {
    let m = mod_word.to_lowercase();
    if m.starts_with("позапрошл") {
        Some(-2)
    } else if m.starts_with("прошл") || m.starts_with("предыдущ") || m.starts_with("минувш")
    {
        Some(-1)
    } else if m.starts_with("эт") || m.starts_with("текущ") || m.starts_with("нынешн")
    {
        Some(0)
    } else if m.starts_with("следующ") || m.starts_with("будущ") || m.starts_with("грядущ")
    {
        Some(1)
    } else {
        None
    }
}

fn parse_hour_token(s: &str) -> Option<i32> {
    let lower = s.trim().to_lowercase();
    if lower == "час" || lower == "часа" || lower == "часу" {
        Some(1)
    } else {
        parse_ru_cardinal(&lower, false)
    }
}

pub fn language() -> Language {
    let ord_1_31_word = format!(
        "(?:(?:двадцать|тридцать)\\s+(?:{ORD_STEMS_1_9}{ORD_SUFFIX}|{TRET_FORMS})|{ORD_STEMS_1_30}{ORD_SUFFIX}|{TRET_FORMS})"
    );
    let card_0_59 = format!("(?:{CARD_TENS_NOM}\\s+{CARD_1_9_NOM}|{CARD_MINS_NOM})");

    Language::new(
        "ru",
        "(?i)(?:[\\s,]|около|во|на|ко|в|к)+",
        vec![
            Pattern::with_builder(
                "ru_isoDate",
                "(?P<guard0>)(?P<y>[0-9]{4})-(?P<m>[0-9]{2})-(?P<d>[0-9]{2})(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Zа-яёА-ЯЁ./-]"),
                    ("guard1", false, "[0-9a-zA-Zа-яёА-ЯЁT:-]"),
                ],
                |c, _| {
                    let y = crate::number(cap(c, "y")?)?;
                    let m = crate::number(cap(c, "m")?)?;
                    let d = crate::number(cap(c, "d")?)?;
                    Some(vec![
                        Component::Year(y),
                        Component::Month(m),
                        Component::Day(d),
                    ])
                },
            ),
            Pattern::new(
                "ru_dotDate",
                "(?i)(?P<guard0>)([0-9]{1,2})[./]([0-9]{1,2})[./]([0-9]{4})(?:\\s*(?:года?|г\\.?))?(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Zа-яёА-ЯЁ./-]"),
                    ("guard1", false, "[0-9a-zA-Zа-яёА-ЯЁ/-]|\\.[0-9]"),
                ],
                &[],
            ),
            Pattern::with_builder(
                "ru_shortDate",
                "(?i)(?P<guard0>)(?:(?P<d>[0-9]{1,2})\\.(?P<m>[0-9]{1,2})\\.(?P<y>[0-9]{2})(?:\\s*(?:года?|г\\.?))?|(?P<d2>[0-9]{1,2})/(?P<m2>[0-9]{1,2})/(?P<y2>[0-9]{2})(?:\\s*(?:года?|г\\.?))?|(?P<d3>[0-9]{1,2})\\.(?P<m3>[0-9]{2}))(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Zа-яёА-ЯЁ./-]"),
                    ("guard1", false, "[0-9a-zA-Zа-яёА-ЯЁ%/-]|\\.[0-9]"),
                ],
                |c, _| {
                    if let Some((d, m, yy)) = cap(c, "d")
                        .zip(cap(c, "m"))
                        .zip(cap(c, "y"))
                        .map(|((d, m), y)| (d, m, y))
                        .or_else(|| Some((cap(c, "d2")?, cap(c, "m2")?, cap(c, "y2")?)))
                    {
                        let day = crate::number(d)?;
                        let month = crate::number(m)?;
                        let yy = crate::number(yy)?;
                        let year = if yy >= 70 { 1900 + yy } else { 2000 + yy };
                        Some(vec![
                            Component::Year(year),
                            Component::Month(month),
                            Component::Day(day),
                        ])
                    } else {
                        let day = crate::number(cap(c, "d3")?)?;
                        let month = crate::number(cap(c, "m3")?)?;
                        Some(vec![Component::Month(month), Component::Day(day)])
                    }
                },
            ),
            Pattern::with_builder(
                "ru_nthWeekday",
                &format!(
                    "(?i)(?P<guard0>)(?P<ord>[1-5]-(?:й|я|е|ю|го|му|м|ой)|перв{ORD_SUFFIX}|втор{ORD_SUFFIX}|{TRET_FORMS}|четв[её]рт{ORD_SUFFIX}|пят{ORD_SUFFIX}|последн(?:его|ему|ее|ей|ем|ий|яя|юю|им))\\s+(?P<w>{WEEKDAYS})\\s+(?:в\\s+)?(?P<m>{MONTHS_OPT_DOT})(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ0-9]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    let ord_raw = cap(c, "ord")?.to_lowercase();
                    let ord = if ord_raw.starts_with("последн") {
                        -1
                    } else {
                        parse_ru_ordinal(&ord_raw)?
                    };
                    if !(ord == -1 || (1..=5).contains(&ord)) {
                        return None;
                    }
                    let wd = parse_weekday(cap(c, "w")?)?;
                    let month = parse_month(cap(c, "m")?)?;
                    Some(vec![Component::Nth(ord, wd, month)])
                },
            ),
            Pattern::with_builder(
                "ru_dayMonth",
                &format!(
                    "(?i)(?P<guard0>)(?:(?P<d>[0-9]{{1,2}})(?:-(?:го|ого|ее|е|му|ому|м|ом|й|я))?|(?P<dword>{ord_1_31_word}))\\s+(?P<m>{MONTHS_OPT_DOT})(?P<guard1>)(?:(?:\\s+|,\\s*)(?:(?P<y>[0-9]{{4}})\\s*(?:года?|г\\.?)|(?P<y2>(?:19|20|21)[0-9]{{2}}))(?P<guard2>))?"
                ),
                &[
                    ("guard0", true, "[a-zA-Zа-яёА-ЯЁ0-9.:/-]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                    ("guard2", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let day = if let Some(d) = cap(c, "d") {
                        crate::number(d)?
                    } else {
                        parse_ru_ordinal(cap(c, "dword")?)?
                    };
                    let month = parse_month(cap(c, "m")?)?;
                    let mut out = vec![Component::Month(month), Component::Day(day)];
                    if let Some(y) = parse_year_opt(c) {
                        out.push(Component::Year(y));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "ru_monthDay",
                &format!(
                    "(?i)(?P<guard0>)(?P<m>{MONTHS_OPT_DOT})\\s+(?P<d>[0-9]{{1,2}})(?:-(?:го|ого|е|му|м))?(?P<guard1>)(?:(?:\\s+|,\\s*)(?:(?P<y>[0-9]{{4}})\\s*(?:года?|г\\.?)|(?P<y2>(?:19|20|21)[0-9]{{2}}))(?P<guard2>))?"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    (
                        "guard1",
                        false,
                        "[0-9:./а-яёА-ЯЁ-]|\\s+(?:[чЧ][аА]?[сС]?|[уУ][тТ][рР][аА]|[дД][нН][яЯ]|[вВ][еЕ][чЧ][еЕ][рР][аА]|[нН][оО][чЧ][иИ]|[мМ][иИ][нН])",
                    ),
                    ("guard2", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let month = parse_month(cap(c, "m")?)?;
                    let day = crate::number(cap(c, "d")?)?;
                    let mut out = vec![Component::Month(month), Component::Day(day)];
                    if let Some(y) = parse_year_opt(c) {
                        out.push(Component::Year(y));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "ru_monthYear",
                &format!(
                    "(?i)(?P<guard0>)(?P<m>{MONTHS_OPT_DOT})(?:\\s+|,\\s*)(?:(?P<y>[0-9]{{4}})\\s*(?:года?|г\\.?)|(?P<y2>(?:19|20|21)[0-9]{{2}}))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let month = parse_month(cap(c, "m")?)?;
                    let year = parse_year_opt(c)?;
                    Some(vec![Component::Month(month), Component::Year(year)])
                },
            ),
            Pattern::with_builder(
                "ru_yearExpr",
                "(?i)(?P<guard0>)(?P<y>[12][0-9]{3})(?:-(?:й|м|ом|го))?\\s*(?:год(?:а|у|е|ом)?|г\\.?)(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Zа-яёА-ЯЁ./-]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| Some(vec![Component::Year(crate::number(cap(c, "y")?)?)]),
            ),
            Pattern::with_builder(
                "ru_withinDays",
                &format!(
                    "(?i)(?P<guard0>)(?:в\\s+течени[еи](?:\\s+ближайши[ех])?|в\\s+пределах|за\\s+ближайши[ех]|(?:в\\s+)?ближайши[ех])\\s+(?:(?P<n>[0-9]+|{WORD_NUMS_WITH_PAIR})\\s+(?P<u>дн(?:я|ей|ю)|день|сут(?:ок|ки)|недел[июь])|(?P<su>дн(?:я|ей)|день|сут(?:ок|ки)|недел[июь]))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    if let (Some(n_raw), Some(u)) = (cap(c, "n"), cap(c, "u")) {
                        let n = parse_ru_cardinal(n_raw, true)?;
                        let days = if u.to_lowercase().starts_with("недел") {
                            n.checked_mul(7)?
                        } else {
                            n
                        };
                        Some(vec![Component::Within(days)])
                    } else if let Some(su) = cap(c, "su") {
                        let days = if su.to_lowercase().starts_with("недел") {
                            7
                        } else {
                            0
                        };
                        Some(vec![Component::Within(days)])
                    } else {
                        None
                    }
                },
            ),
            Pattern::new(
                "ru_offsetAhead",
                "(?i)(?P<guard0>)через\\s+([0-9]+)\\s+(день|дня|дней|недел[июь]|месяц(?:а|ев)?|год(?:а)?|лет)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[],
            ),
            Pattern::new(
                "ru_offsetAgo",
                "(?i)(?P<guard0>)([0-9]+)\\s+(день|дня|дней|недел[июь]|месяц(?:а|ев)?|год(?:а)?|лет)\\s+назад(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ0-9]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[],
            ),
            Pattern::with_builder(
                "ru_offsetAheadExtra",
                &format!(
                    "(?i)(?P<guard0>)(?:через\\s+(?:(?P<half>полтора\\s+года|полгода|полмесяца)|(?P<nw>{WORD_NUMS_WITH_PAIR})\\s+(?P<uw>{OFFSET_UNITS})|(?P<su>{SINGULAR_UNITS}))|спустя\\s+(?:(?P<half2>полтора\\s+года|полгода|полмесяца)|(?P<n>[0-9]+|{WORD_NUMS_WITH_PAIR})\\s+(?P<u>{OFFSET_UNITS})|(?P<su2>{SINGULAR_UNITS}))|(?P<n3>[0-9]+|{WORD_NUMS_WITH_PAIR})\\s+(?P<u3>{OFFSET_UNITS})\\s+спустя|(?P<su3>{SINGULAR_UNITS})\\s+спустя)(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ0-9]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    if let Some(h) = cap(c, "half").or_else(|| cap(c, "half2")) {
                        let hl = h.to_lowercase();
                        return Some(vec![if hl.starts_with("полтора") {
                            Component::MonthOffset(18)
                        } else if hl == "полгода" {
                            Component::MonthOffset(6)
                        } else {
                            Component::RelativeDay(15)
                        }]);
                    }
                    if let Some((n, u)) = cap(c, "nw")
                        .zip(cap(c, "uw"))
                        .or_else(|| cap(c, "n").zip(cap(c, "u")))
                        .or_else(|| cap(c, "n3").zip(cap(c, "u3")))
                    {
                        let val = parse_ru_cardinal(n, true)?;
                        return Some(vec![offset_unit_component(u, val)?]);
                    }
                    let su = cap(c, "su")
                        .or_else(|| cap(c, "su2"))
                        .or_else(|| cap(c, "su3"))?;
                    Some(vec![offset_unit_component(su, 1)?])
                },
            ),
            Pattern::with_builder(
                "ru_offsetAgoExtra",
                &format!(
                    "(?i)(?P<guard0>)(?:(?P<half>полтора\\s+года|полгода|полмесяца)\\s+(?:тому\\s+)?назад|(?P<n>[0-9]+)\\s+(?P<u>{OFFSET_UNITS})\\s+тому\\s+назад|(?P<nw>{WORD_NUMS_WITH_PAIR})\\s+(?P<uw>{OFFSET_UNITS})\\s+(?:тому\\s+)?назад|(?P<su>{SINGULAR_UNITS})\\s+(?:тому\\s+)?назад)(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ0-9]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    if let Some(h) = cap(c, "half") {
                        let hl = h.to_lowercase();
                        return Some(vec![if hl.starts_with("полтора") {
                            Component::MonthOffset(-18)
                        } else if hl == "полгода" {
                            Component::MonthOffset(-6)
                        } else {
                            Component::RelativeDay(-15)
                        }]);
                    }
                    if let Some((n, u)) = cap(c, "n")
                        .zip(cap(c, "u"))
                        .or_else(|| cap(c, "nw").zip(cap(c, "uw")))
                    {
                        let val = parse_ru_cardinal(n, true)?.checked_neg()?;
                        return Some(vec![offset_unit_component(u, val)?]);
                    }
                    let su = cap(c, "su")?;
                    Some(vec![offset_unit_component(su, -1)?])
                },
            ),
            Pattern::with_builder(
                "ru_tonight",
                "(?i)(?P<guard0>)(?:эт(?:им|ой)|нынешн(?:им|ей)|сегодняшн(?:им|ей))\\s+(?P<mer>утром|дн[её]м|вечером|ночью)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    let mer = cap(c, "mer")?.to_lowercase();
                    let pm = mer.starts_with("вечер") || mer.starts_with("дн");
                    Some(vec![Component::RelativeDay(0), Component::Meridiem(pm)])
                },
            ),
            Pattern::new(
                "ru_relativeDay",
                "(?i)(?P<guard0>)(послепослезавтра|позапозавчера|послезавтра|позавчера|сегодня|завтра|вчера|нынче)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[
                    ("сегодня", &[Component::RelativeDay(0)]),
                    ("нынче", &[Component::RelativeDay(0)]),
                    ("завтра", &[Component::RelativeDay(1)]),
                    ("послезавтра", &[Component::RelativeDay(2)]),
                    ("послепослезавтра", &[Component::RelativeDay(3)]),
                    ("вчера", &[Component::RelativeDay(-1)]),
                    ("позавчера", &[Component::RelativeDay(-2)]),
                    ("позапозавчера", &[Component::RelativeDay(-3)]),
                ],
            ),
            Pattern::with_builder(
                "ru_weekend",
                "(?i)(?P<guard0>)(?:(?P<mod>прошл(?:ые|ых|ым|ыми)|минувш(?:ие|их|им|ими)|предыдущ(?:ие|их|им|ими)|следующ(?:ие|их|им|ими)|будущ(?:ие|их|им|ими)|эт(?:и|их|им|ими)|ближайш(?:ие|их|им|ими))\\s+)?(?:выходн(?:ые|ых|ым|ыми)|уик-?энд(?:ы|ах|ов|а|е|у|ом)?|уикенд(?:ы|ах|ов|а|е|у|ом)?)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    if let Some(m) = cap(c, "mod")
                        && anchor_offset(m) == Some(-1)
                    {
                        return Some(vec![Component::Week(-1, false), Component::Weekday(7)]);
                    }
                    Some(vec![Component::Weekend])
                },
            ),
            Pattern::new(
                "ru_weekAnchor",
                "(?i)(?P<guard0>)(следующей|прошлой|этой)\\s+недел[еи](?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[],
            ),
            Pattern::new(
                "ru_monthAnchor",
                "(?i)(?P<guard0>)(следующем|прошлом|этом)\\s+месяце(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[],
            ),
            Pattern::new(
                "ru_yearAnchor",
                "(?i)(?P<guard0>)(следующем|прошлом|этом)\\s+году(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[],
            ),
            Pattern::with_builder(
                "ru_anchorExtra",
                "(?i)(?P<guard0>)(?P<mod>позапрошл(?:ой|ую|ая|ом|ого|ый)|следующ(?:ей|ую|ая|ий|ем|его)|будущ(?:ей|ую|ая|ий|ем|его)|грядущ(?:ей|ую|ая|ий|ем|его)|прошл(?:ой|ую|ая|ый|ом|ого)|предыдущ(?:ей|ую|ая|ий|ем|его)|минувш(?:ей|ую|ая|ий|ем|его)|эт(?:ой|у|а|от|ом|ого)|текущ(?:ей|ую|ая|ий|ем|его)|нынешн(?:ей|ую|ая|ий|ем|его))\\s+(?P<u>недел[еюяи]|месяц[еа]?|год[ау]?)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    let off = anchor_offset(cap(c, "mod")?)?;
                    let u = cap(c, "u")?.to_lowercase();
                    if u.starts_with("недел") {
                        Some(vec![Component::Week(off, true)])
                    } else if u.starts_with("месяц") {
                        Some(vec![Component::MonthOffset(off)])
                    } else {
                        Some(vec![Component::YearOffset(off)])
                    }
                },
            ),
            Pattern::new(
                "ru_nextLastWeekday",
                "(?i)(?P<guard0>)(следующ(?:ий|ую|ая)|прошл(?:ый|ую|ая|ое))\\s+(понедельник|воскресенье|воскресение|воскресенья|пятницой|субботой|вторник|четверг|пятница|пятницу|пятнице|суббота|субботу|субботе|среда|среду|среде|пн|вт|ср|чт|пт|сб|вс)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[],
            ),
            Pattern::with_builder(
                "ru_weekdayMod",
                &format!(
                    "(?i)(?P<guard0>)(?P<mod>позапрошл(?:ый|ую|ая|ое|ой|ом|ого)|следующ(?:ий|ую|ая|ее|ей|ем|его)|будущ(?:ий|ую|ая|ее|ей|ем|его)|грядущ(?:ий|ую|ая|ее|ей|ем|его)|прошл(?:ый|ую|ая|ое|ой|ом|ого)|минувш(?:ий|ую|ая|ее|ей|ем|ого)|предыдущ(?:ий|ую|ая|ее|ей|ем|ого)|эт(?:от|у|а|о|ой|ом|ого)|ближайш(?:ий|ую|ая|ее|ей|ем|ого))\\s+(?P<w>{WEEKDAYS})(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    let m = cap(c, "mod")?.to_lowercase();
                    let w = parse_weekday(cap(c, "w")?)?;
                    if m.starts_with("ближайш") {
                        Some(vec![Component::Weekday(w)])
                    } else if m.starts_with("эт") {
                        Some(vec![Component::Week(0, true), Component::Weekday(w)])
                    } else {
                        let off = anchor_offset(&m)?;
                        Some(vec![Component::Week(off, false), Component::Weekday(w)])
                    }
                },
            ),
            Pattern::new(
                "ru_weekday",
                &format!("(?i)(?P<guard0>)({WEEKDAYS})(?P<guard1>)"),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[
                    ("понедельник", &[Component::Weekday(1)]),
                    ("понедельника", &[Component::Weekday(1)]),
                    ("понедельнику", &[Component::Weekday(1)]),
                    ("понедельником", &[Component::Weekday(1)]),
                    ("понедельнике", &[Component::Weekday(1)]),
                    ("пнд", &[Component::Weekday(1)]),
                    ("пн", &[Component::Weekday(1)]),
                    ("вторник", &[Component::Weekday(2)]),
                    ("вторника", &[Component::Weekday(2)]),
                    ("вторнику", &[Component::Weekday(2)]),
                    ("вторником", &[Component::Weekday(2)]),
                    ("вторнике", &[Component::Weekday(2)]),
                    ("втр", &[Component::Weekday(2)]),
                    ("вт", &[Component::Weekday(2)]),
                    ("среда", &[Component::Weekday(3)]),
                    ("среды", &[Component::Weekday(3)]),
                    ("среду", &[Component::Weekday(3)]),
                    ("среде", &[Component::Weekday(3)]),
                    ("средой", &[Component::Weekday(3)]),
                    ("средою", &[Component::Weekday(3)]),
                    ("ср", &[Component::Weekday(3)]),
                    ("четверг", &[Component::Weekday(4)]),
                    ("четверга", &[Component::Weekday(4)]),
                    ("четвергу", &[Component::Weekday(4)]),
                    ("четвергом", &[Component::Weekday(4)]),
                    ("четверге", &[Component::Weekday(4)]),
                    ("чтв", &[Component::Weekday(4)]),
                    ("чт", &[Component::Weekday(4)]),
                    ("пятница", &[Component::Weekday(5)]),
                    ("пятницы", &[Component::Weekday(5)]),
                    ("пятницу", &[Component::Weekday(5)]),
                    ("пятнице", &[Component::Weekday(5)]),
                    ("пятницей", &[Component::Weekday(5)]),
                    ("пятницею", &[Component::Weekday(5)]),
                    ("пятницой", &[Component::Weekday(5)]),
                    ("птн", &[Component::Weekday(5)]),
                    ("пт", &[Component::Weekday(5)]),
                    ("суббота", &[Component::Weekday(6)]),
                    ("субботы", &[Component::Weekday(6)]),
                    ("субботу", &[Component::Weekday(6)]),
                    ("субботе", &[Component::Weekday(6)]),
                    ("субботой", &[Component::Weekday(6)]),
                    ("субботою", &[Component::Weekday(6)]),
                    ("суб", &[Component::Weekday(6)]),
                    ("сб", &[Component::Weekday(6)]),
                    ("воскресенье", &[Component::Weekday(7)]),
                    ("воскресение", &[Component::Weekday(7)]),
                    ("воскресенья", &[Component::Weekday(7)]),
                    ("воскресения", &[Component::Weekday(7)]),
                    ("воскресенью", &[Component::Weekday(7)]),
                    ("воскресению", &[Component::Weekday(7)]),
                    ("воскресеньем", &[Component::Weekday(7)]),
                    ("воскресением", &[Component::Weekday(7)]),
                    ("воскресеньи", &[Component::Weekday(7)]),
                    ("воскресении", &[Component::Weekday(7)]),
                    ("вск", &[Component::Weekday(7)]),
                    ("вс", &[Component::Weekday(7)]),
                ],
            ),
            Pattern::new(
                "ru_month",
                "(?i)(?P<guard0>)(сентября|сентябре|сентябрю|сентябрём|сентябрем|сентябрь|февраля|феврале|февралю|февралём|февралем|февраль|декабря|декабре|декабрю|декабрём|декабрем|декабрь|октября|октябре|октябрю|октябрём|октябрем|октябрь|января|январе|январю|январём|январем|январь|апреля|апреле|апрелю|апрелем|апрель|августа|августе|августу|августом|август|ноября|ноябре|ноябрю|ноябрём|ноябрем|ноябрь|марта|марте|марту|мартом|март|июня|июне|июню|июнем|июнь|июля|июле|июлю|июлем|июль|февр\\.?|сент\\.?|нояб\\.?|янв\\.?|фев\\.?|мар\\.|апр\\.?|июн\\.?|июл\\.?|авг\\.?|сен\\.?|окт\\.?|ноя\\.?|дек\\.?|маем|мая|мае|маю|май)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[
                    ("января", &[Component::Month(1)]),
                    ("январь", &[Component::Month(1)]),
                    ("январе", &[Component::Month(1)]),
                    ("январю", &[Component::Month(1)]),
                    ("январём", &[Component::Month(1)]),
                    ("январем", &[Component::Month(1)]),
                    ("янв", &[Component::Month(1)]),
                    ("янв.", &[Component::Month(1)]),
                    ("февраля", &[Component::Month(2)]),
                    ("февраль", &[Component::Month(2)]),
                    ("феврале", &[Component::Month(2)]),
                    ("февралю", &[Component::Month(2)]),
                    ("февралём", &[Component::Month(2)]),
                    ("февралем", &[Component::Month(2)]),
                    ("февр", &[Component::Month(2)]),
                    ("февр.", &[Component::Month(2)]),
                    ("фев", &[Component::Month(2)]),
                    ("фев.", &[Component::Month(2)]),
                    ("марта", &[Component::Month(3)]),
                    ("март", &[Component::Month(3)]),
                    ("марте", &[Component::Month(3)]),
                    ("марту", &[Component::Month(3)]),
                    ("мартом", &[Component::Month(3)]),
                    ("мар.", &[Component::Month(3)]),
                    ("апреля", &[Component::Month(4)]),
                    ("апрель", &[Component::Month(4)]),
                    ("апреле", &[Component::Month(4)]),
                    ("апрелю", &[Component::Month(4)]),
                    ("апрелем", &[Component::Month(4)]),
                    ("апр", &[Component::Month(4)]),
                    ("апр.", &[Component::Month(4)]),
                    ("мая", &[Component::Month(5)]),
                    ("май", &[Component::Month(5)]),
                    ("мае", &[Component::Month(5)]),
                    ("маю", &[Component::Month(5)]),
                    ("маем", &[Component::Month(5)]),
                    ("июня", &[Component::Month(6)]),
                    ("июнь", &[Component::Month(6)]),
                    ("июне", &[Component::Month(6)]),
                    ("июню", &[Component::Month(6)]),
                    ("июнем", &[Component::Month(6)]),
                    ("июн", &[Component::Month(6)]),
                    ("июн.", &[Component::Month(6)]),
                    ("июля", &[Component::Month(7)]),
                    ("июль", &[Component::Month(7)]),
                    ("июле", &[Component::Month(7)]),
                    ("июлю", &[Component::Month(7)]),
                    ("июлем", &[Component::Month(7)]),
                    ("июл", &[Component::Month(7)]),
                    ("июл.", &[Component::Month(7)]),
                    ("августа", &[Component::Month(8)]),
                    ("август", &[Component::Month(8)]),
                    ("августе", &[Component::Month(8)]),
                    ("августу", &[Component::Month(8)]),
                    ("августом", &[Component::Month(8)]),
                    ("авг", &[Component::Month(8)]),
                    ("авг.", &[Component::Month(8)]),
                    ("сентября", &[Component::Month(9)]),
                    ("сентябрь", &[Component::Month(9)]),
                    ("сентябре", &[Component::Month(9)]),
                    ("сентябрю", &[Component::Month(9)]),
                    ("сентябрём", &[Component::Month(9)]),
                    ("сентябрем", &[Component::Month(9)]),
                    ("сент", &[Component::Month(9)]),
                    ("сент.", &[Component::Month(9)]),
                    ("сен", &[Component::Month(9)]),
                    ("сен.", &[Component::Month(9)]),
                    ("октября", &[Component::Month(10)]),
                    ("октябрь", &[Component::Month(10)]),
                    ("октябре", &[Component::Month(10)]),
                    ("октябрю", &[Component::Month(10)]),
                    ("октябрём", &[Component::Month(10)]),
                    ("октябрем", &[Component::Month(10)]),
                    ("окт", &[Component::Month(10)]),
                    ("окт.", &[Component::Month(10)]),
                    ("ноября", &[Component::Month(11)]),
                    ("ноябрь", &[Component::Month(11)]),
                    ("ноябре", &[Component::Month(11)]),
                    ("ноябрю", &[Component::Month(11)]),
                    ("ноябрём", &[Component::Month(11)]),
                    ("ноябрем", &[Component::Month(11)]),
                    ("нояб", &[Component::Month(11)]),
                    ("нояб.", &[Component::Month(11)]),
                    ("ноя", &[Component::Month(11)]),
                    ("ноя.", &[Component::Month(11)]),
                    ("декабря", &[Component::Month(12)]),
                    ("декабрь", &[Component::Month(12)]),
                    ("декабре", &[Component::Month(12)]),
                    ("декабрю", &[Component::Month(12)]),
                    ("декабрём", &[Component::Month(12)]),
                    ("декабрем", &[Component::Month(12)]),
                    ("дек", &[Component::Month(12)]),
                    ("дек.", &[Component::Month(12)]),
                ],
            ),
            Pattern::with_builder(
                "ru_colonTimeAmPm",
                "(?i)(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<min>[0-9]{2})\\s*(?P<mer>p\\.?m\\.?|a\\.?m\\.?)(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Zа-яёА-ЯЁ./-]"),
                    ("guard1", false, "[a-zA-Zа-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let h = crate::number(cap(c, "h")?)?;
                    let min = crate::number(cap(c, "min")?)?;
                    let pm = cap(c, "mer")?.to_lowercase().starts_with('p');
                    Some(vec![Component::Time(h, Some(min), Some(pm))])
                },
            ),
            Pattern::with_builder(
                "ru_colonTimeNochi",
                "(?i)(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<min>[0-9]{2})\\s+ночи(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Zа-яёА-ЯЁ./-]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    let h = crate::number(cap(c, "h")?)?;
                    let min = crate::number(cap(c, "min")?)?;
                    Some(vec![Component::Time(h, Some(min), Some(pm_for("ночи", h)))])
                },
            ),
            Pattern::new("ru_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
            Pattern::with_builder(
                "ru_halfQuarterPast",
                &format!(
                    "(?i)(?P<guard0>)(?:(?:пол-?\\s*|половин[аеу]\\s+)|(?P<q>четверть)\\s+|(?P<m>[0-9]{{1,2}}|{card_0_59})\\s+минут(?:[аы])?\\s+)(?P<ord>{ORD_1_12_GEN})(?:\\s+(?P<mer>утра|дня|вечера|ночи))?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ0-9]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    let ord = parse_ru_ordinal(cap(c, "ord")?)?;
                    if !(1..=12).contains(&ord) {
                        return None;
                    }
                    let h = if ord == 1 { 12 } else { ord - 1 };
                    let min = if cap(c, "q").is_some() {
                        15
                    } else if let Some(m_raw) = cap(c, "m") {
                        let m = parse_ru_cardinal(m_raw, false)?;
                        if !(1..60).contains(&m) {
                            return None;
                        }
                        m
                    } else {
                        30
                    };
                    let pm = cap(c, "mer").map(|mer| pm_for(mer, h));
                    Some(vec![Component::Time(h, Some(min), pm)])
                },
            ),
            Pattern::with_builder(
                "ru_bezTime",
                &format!(
                    "(?i)(?P<guard0>)без\\s+(?:(?P<q>четверти)|(?P<m>[0-9]{{1,2}}|{GEN_MINS})(?:\\s+минут)?)\\s+(?P<h>полноч[иь]|полдень|час|[0-9]{{1,2}}|{CARD_HOURS})(?:\\s+час(?:а|ов)?)?(?:\\s+(?P<mer>утра|дня|вечера|ночи))?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let min = if cap(c, "q").is_some() {
                        45
                    } else {
                        let m = parse_ru_cardinal(cap(c, "m")?, false)?;
                        if !(1..60).contains(&m) {
                            return None;
                        }
                        60 - m
                    };
                    let h_raw = cap(c, "h")?.to_lowercase();
                    let h = if h_raw.starts_with("полноч") {
                        23
                    } else if h_raw == "полдень" {
                        11
                    } else if h_raw == "час" {
                        12
                    } else {
                        let target = parse_ru_cardinal(&h_raw, false)?;
                        if !(0..=23).contains(&target) {
                            return None;
                        }
                        if target == 0 {
                            23
                        } else if target == 1 {
                            12
                        } else {
                            target - 1
                        }
                    };
                    let pm = cap(c, "mer").map(|mer| pm_for(mer, h));
                    Some(vec![Component::Time(h, Some(min), pm)])
                },
            ),
            Pattern::with_builder(
                "ru_hourMinText",
                &format!(
                    "(?i)(?P<guard0>)(?:(?:в|во|к|ко|около|после|до)\\s+)?(?:(?P<h>[0-9]{{1,2}})\\s*(?:час(?:а|ов)?|ч\\.?)\\s*(?P<m>[0-9]{{1,2}}|{card_0_59})\\s*(?:минут[ауы]?|мин\\.?|м\\.?)|(?P<hc>[0-9]{{1,2}})ч(?P<mc>[0-9]{{2}})м?)(?:\\s+(?P<mer>утра|дня|вечера|ночи))?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ0-9]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let (h_raw, m_raw) = cap(c, "h")
                        .zip(cap(c, "m"))
                        .or_else(|| cap(c, "hc").zip(cap(c, "mc")))?;
                    let h = crate::number(h_raw)?;
                    let m = parse_ru_cardinal(m_raw, false)?;
                    let pm = cap(c, "mer").map(|mer| pm_for(mer, h));
                    Some(vec![Component::Time(h, Some(m), pm)])
                },
            ),
            Pattern::with_builder(
                "ru_wordHourMinText",
                &format!(
                    "(?i)(?P<guard0>)(?:(?:(?:в|во|к|ко|около|после|до)\\s+)?(?P<hw>час|{CARD_HOURS})\\s+час(?:а|ов)?\\s+(?:(?P<md>[0-9]{{1,2}})\\s*(?:минут[ауы]?|мин\\.?)|(?P<mw>{card_0_59})(?:\\s*(?:минут[ауы]?|мин\\.?))?)|(?:в|во)\\s+(?P<hw2>час|{CARD_HOURS})\\s+(?P<mw2>{card_0_59})(?:\\s*(?:минут[ауы]?|мин\\.?))?)(?:\\s+(?P<mer>утра|дня|вечера|ночи))?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let (h_raw, m_raw) = if let Some(hw) = cap(c, "hw") {
                        (hw, cap(c, "md").or_else(|| cap(c, "mw"))?)
                    } else {
                        (cap(c, "hw2")?, cap(c, "mw2")?)
                    };
                    let h = parse_hour_token(h_raw)?;
                    let m = parse_ru_cardinal(m_raw, false)?;
                    let pm = cap(c, "mer").map(|mer| pm_for(mer, h));
                    Some(vec![Component::Time(h, Some(m), pm)])
                },
            ),
            Pattern::with_builder(
                "ru_hourAmPm",
                "(?i)(?P<guard0>)(?P<h>[0-9]{1,2})\\s*(?P<mer>p\\.?m\\.?|a\\.?m\\.?)(?P<guard1>)",
                &[
                    ("guard0", true, "[0-9a-zA-Zа-яёА-ЯЁ./-]"),
                    ("guard1", false, "[a-zA-Zа-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let h = crate::number(cap(c, "h")?)?;
                    let pm = cap(c, "mer")?.to_lowercase().starts_with('p');
                    Some(vec![Component::Time(h, Some(0), Some(pm))])
                },
            ),
            Pattern::with_builder(
                "ru_hourMeridiem",
                &format!(
                    "(?i)(?P<guard0>)(?:(?:(?:в|во|к|ко|около|после|до)\\s+)?(?P<h>час|{CARD_HOURS}|[0-9]{{1,2}})\\s+(?:час(?:а|ов)?\\s+)?(?P<mer>утра|вечера|ночи|до\\s+полудня|после\\s+полудня|пополудни)|(?:(?:в|во|к|ко|около|после|до)\\s+)?(?P<h2_>час|{CARD_HOURS}|[0-9]{{1,2}})\\s+час(?:а|ов)?\\s+(?P<mer2>дня)|(?:в|во|к|ко|около|после|до)\\s+(?P<h3_>час|{CARD_HOURS}|[0-9]{{1,2}})\\s+(?P<mer3>дня))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ0-9]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let (h_raw, mer) = cap(c, "h")
                        .zip(cap(c, "mer"))
                        .or_else(|| cap(c, "h2_").zip(cap(c, "mer2")))
                        .or_else(|| cap(c, "h3_").zip(cap(c, "mer3")))?;
                    let h = parse_hour_token(h_raw)?;
                    Some(vec![Component::Time(h, Some(0), Some(pm_for(mer, h)))])
                },
            ),
            Pattern::with_builder(
                "ru_hourOnlyPrep",
                &format!(
                    "(?i)(?P<guard0>)(?:(?:в|во|к|ко|около|после|до)\\s+(?P<hp>[0-9]{{1,2}}|{CARD_HOURS})\\s*(?:час(?:а|ов|у|ам)?|ч\\.?)|(?:в\\s+час|к\\s+часу)(?P<h1_>)|(?P<h24>[0-9]{{1,2}})\\s*(?:час(?:а|ов)?|ч\\.?))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[а-яёА-ЯЁ0-9]"),
                    (
                        "guard1",
                        false,
                        "[а-яёА-ЯЁ0-9]|\\s*(?:[пП][иИ][кК]|[нН][аА][зЗ][аА][дД]|[сС][пП][уУ][сС][тТ][яЯ]|[пП][оО][дД][рР][яЯ][дД]|[тТ][оО][мМ][уУ]\\s+[нН][аА][зЗ][аА][дД])",
                    ),
                ],
                |c, _| {
                    if let Some(hp) = cap(c, "hp") {
                        let h = parse_hour_token(hp)?;
                        Some(vec![Component::Time(h, Some(0), None)])
                    } else if cap(c, "h1_").is_some() {
                        Some(vec![Component::Time(1, Some(0), None)])
                    } else {
                        let h = crate::number(cap(c, "h24")?)?;
                        if h == 0 || (13..=23).contains(&h) {
                            Some(vec![Component::Time(h, Some(0), None)])
                        } else {
                            None
                        }
                    }
                },
            ),
            Pattern::with_builder(
                "ru_hourOnlyBare",
                "(?i)(?P<guard0>)(?:в|во)\\s+(?P<h>[0-9]{1,2})(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[^,.;!?)]|\\.[0-9]"),
                ],
                |c, _| {
                    let h = crate::number(cap(c, "h")?)?;
                    Some(vec![Component::Time(h, Some(0), None)])
                },
            ),
            Pattern::with_builder(
                "ru_noonMidnight",
                "(?i)(?P<guard0>)(?P<w>после\\s+полудня|до\\s+полудня|после\\s+полуночи|до\\s+полуночи|пополудни|полдень|полудня|полудню|полуднем|полночь|полуночи)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                |c, _| {
                    let w = cap(c, "w")?.to_lowercase();
                    if w == "после полудня" || w == "пополудни" {
                        Some(vec![Component::Meridiem(true)])
                    } else if w == "до полудня" || w == "после полуночи" {
                        Some(vec![Component::Meridiem(false)])
                    } else if w.starts_with("полд") || w.starts_with("полуд") {
                        Some(vec![Component::Time(12, Some(0), None)])
                    } else {
                        Some(vec![Component::Time(0, Some(0), None)])
                    }
                },
            ),
            Pattern::new(
                "ru_meridiem",
                "(?i)(?P<guard0>)(вечером|вечера|утром|утра|ночью|ночи|днём|днем|дня)(?P<guard1>)",
                &[
                    ("guard0", true, "[а-яёА-ЯЁ]"),
                    ("guard1", false, "[а-яёА-ЯЁ]"),
                ],
                &[
                    ("утра", &[Component::Meridiem(false)]),
                    ("утром", &[Component::Meridiem(false)]),
                    ("дня", &[Component::Meridiem(true)]),
                    ("днём", &[Component::Meridiem(true)]),
                    ("днем", &[Component::Meridiem(true)]),
                    ("вечера", &[Component::Meridiem(true)]),
                    ("вечером", &[Component::Meridiem(true)]),
                    ("ночи", &[Component::Meridiem(false)]),
                    ("ночью", &[Component::Meridiem(false)]),
                ],
            ),
            Pattern::new(
                "ru_dayOnly",
                "(?i)(?P<guard0>)([0-9]{1,2})(?:-го|\\s+числа)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-Zа-яёА-ЯЁ0-9.:/-]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                ],
                &[],
            ),
            Pattern::with_builder(
                "ru_dayOnlyExtra",
                &format!(
                    "(?i)(?P<guard0>)(?:(?P<d>[0-9]{{1,2}})(?:-(?:ого|ому|го|му|е)(?:\\s+числ[аоуе])?|(?:-?(?:ом|м))?\\s+числ[аоуе])|(?P<dword>{ord_1_31_word})\\s+числ[аоуе])(?P<guard1>)"
                ),
                &[
                    ("guard0", true, "[a-zA-Zа-яёА-ЯЁ0-9.:/-]"),
                    ("guard1", false, "[а-яёА-ЯЁ0-9]"),
                ],
                |c, _| {
                    let day = if let Some(d) = cap(c, "d") {
                        crate::number(d)?
                    } else {
                        parse_ru_ordinal(cap(c, "dword")?)?
                    };
                    Some(vec![Component::Day(day)])
                },
            ),
        ],
    )
}

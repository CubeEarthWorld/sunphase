use crate::{Component, Language, Pattern};

// Devanagari letters, vowel signs, and combining marks, excluding punctuation
// (। U+0964, ॥ U+0965, ॰ U+0970) and Devanagari digits (०-९ U+0966..=U+096F).
const DEV_LETTER: &str = "[ऀ-ॣॱ-ॿ]";
const WORD_CHAR: &str = "[0-9a-zA-Zऀ-ॣॱ-ॿ]";

const DEV_GUARDS: &[(&str, bool, &str)] =
    &[("guard0", true, DEV_LETTER), ("guard1", false, DEV_LETTER)];
const NUM_DEV_GUARDS: &[(&str, bool, &str)] =
    &[("guard0", true, WORD_CHAR), ("guard1", false, DEV_LETTER)];
const WORD_GUARDS: &[(&str, bool, &str)] =
    &[("guard0", true, WORD_CHAR), ("guard1", false, WORD_CHAR)];
const DATE_GUARDS: &[(&str, bool, &str)] = &[
    ("guard0", true, "[0-9a-zA-Zऀ-ॣॱ-ॿ./-]"),
    ("guard1", false, "[0-9a-zA-Zऀ-ॣॱ-ॿ]|[./-][0-9]"),
];

const WEEKDAYS: &[(&str, &[Component])] = &[
    ("सोमवार", &[Component::Weekday(1)]),
    ("मंगलवार", &[Component::Weekday(2)]),
    ("बुधवार", &[Component::Weekday(3)]),
    ("बृहस्पतिवार", &[Component::Weekday(4)]),
    ("गुरुवार", &[Component::Weekday(4)]),
    ("वीरवार", &[Component::Weekday(4)]),
    ("शुक्रवार", &[Component::Weekday(5)]),
    ("शनिवार", &[Component::Weekday(6)]),
    ("शनीचर", &[Component::Weekday(6)]),
    ("शनिचर", &[Component::Weekday(6)]),
    ("रविवार", &[Component::Weekday(7)]),
    ("इतवार", &[Component::Weekday(7)]),
];

const MONTHS: &[(&str, &[Component])] = &[
    ("जनवरी", &[Component::Month(1)]),
    ("जन॰", &[Component::Month(1)]),
    ("फ़रवरी", &[Component::Month(2)]),
    ("फरवरी", &[Component::Month(2)]),
    ("फ़र.", &[Component::Month(2)]),
    ("फर.", &[Component::Month(2)]),
    ("फ़र॰", &[Component::Month(2)]),
    ("फर॰", &[Component::Month(2)]),
    ("मार्च", &[Component::Month(3)]),
    ("अप्रैल", &[Component::Month(4)]),
    ("अप्रै.", &[Component::Month(4)]),
    ("अप्रै॰", &[Component::Month(4)]),
    ("मई", &[Component::Month(5)]),
    ("जून", &[Component::Month(6)]),
    ("जुलाई", &[Component::Month(7)]),
    ("जुला.", &[Component::Month(7)]),
    ("जुल.", &[Component::Month(7)]),
    ("जुला॰", &[Component::Month(7)]),
    ("जुल॰", &[Component::Month(7)]),
    ("अगस्त", &[Component::Month(8)]),
    ("अग॰", &[Component::Month(8)]),
    ("सितम्बर", &[Component::Month(9)]),
    ("सितंबर", &[Component::Month(9)]),
    ("सितं.", &[Component::Month(9)]),
    ("सित.", &[Component::Month(9)]),
    ("सितं॰", &[Component::Month(9)]),
    ("सित॰", &[Component::Month(9)]),
    ("अक्टूबर", &[Component::Month(10)]),
    ("अक्तूबर", &[Component::Month(10)]),
    ("अक्टू.", &[Component::Month(10)]),
    ("अक्तू.", &[Component::Month(10)]),
    ("अक्टू॰", &[Component::Month(10)]),
    ("अक्तू॰", &[Component::Month(10)]),
    ("नवम्बर", &[Component::Month(11)]),
    ("नवंबर", &[Component::Month(11)]),
    ("नवं.", &[Component::Month(11)]),
    ("नवं॰", &[Component::Month(11)]),
    ("नव॰", &[Component::Month(11)]),
    ("दिसम्बर", &[Component::Month(12)]),
    ("दिसंबर", &[Component::Month(12)]),
    ("दिसं.", &[Component::Month(12)]),
    ("दिस.", &[Component::Month(12)]),
    ("दिसं॰", &[Component::Month(12)]),
    ("दिस॰", &[Component::Month(12)]),
];

const WEEKDAY_ALT: &str =
    "बृहस्पतिवार|मंगलवार|शुक्रवार|सोमवार|बुधवार|गुरुवार|वीरवार|शनिवार|रविवार|शनीचर|शनिचर|इतवार";
const MONTH_ALT: &str = "जनवरी|जन॰|फ़रवरी|फरवरी|फ़र\\.|फ़र॰|फर\\.|फर॰|मार्च|अप्रैल|अप्रै\\.|अप्रै॰|मई|जून|जुलाई|जुला\\.|जुला॰|जुल\\.|जुल॰|अगस्त|अग॰|सितम्बर|सितंबर|सितं\\.|सितं॰|सित\\.|सित॰|अक्टूबर|अक्तूबर|अक्टू\\.|अक्टू॰|अक्तू\\.|अक्तू॰|नवम्बर|नवंबर|नवं\\.|नवं॰|नव॰|दिसम्बर|दिसंबर|दिसं\\.|दिसं॰|दिस\\.|दिस॰";
const WORD_NUM_ALT: &str = "(?:इक्कीस|बाईस|तेईस|चौबीस|पच्चीस|छब्बीस|सत्ताईस|अट्ठाईस|अठाईस|उनतीस|उनत्तीस|इकतीस|इकत्तीस|ग्यारह|बारह|तेरह|चौदह|पंद्रह|पन्द्रह|सोलह|सत्रह|अठारह|अट्ठारह|उन्नीस|चालीस|पैंतालीस|पचास|तीसरा|तीसरी|तीसरे|तीस|बीस|साठ|पहला|पहली|पहले|प्रथम|दूसरा|दूसरी|दूसरे|द्वितीय|तृतीय|चौथा|चौथी|चौथे|चतुर्थ|छठवाँ|छठवां|छठवीं|छठवें|छठा|छठी|छठे|नवाँ|नवां|नवीं|नवें|पांच|पाँच|सात|आठ|दस|नौ|एक|दो|तीन|चार|छह|छः|छ)(?:वाँ|वां|वीं|वें|वे)?";
const HOUR_ALT: &str = "[0-9]{1,2}|इक्कीस|बाईस|तेईस|ग्यारह|बारह|तेरह|चौदह|पंद्रह|पन्द्रह|सोलह|सत्रह|अठारह|अट्ठारह|उन्नीस|बीस|एक|दो|तीन|चार|पांच|पाँच|छह|छः|छ|सात|आठ|नौ|दस";

fn lookup_weekday(s: &str) -> Option<i32> {
    WEEKDAYS
        .iter()
        .find(|(w, _)| crate::eq_word(s, w))
        .and_then(|(_, cs)| match cs.first()? {
            Component::Weekday(n) => Some(*n),
            _ => None,
        })
}

fn lookup_month(s: &str) -> Option<i32> {
    MONTHS
        .iter()
        .find(|(w, _)| crate::eq_word(s, w))
        .and_then(|(_, cs)| match cs.first()? {
            Component::Month(n) => Some(*n),
            _ => None,
        })
}

fn hi_number(s: &str) -> Option<i32> {
    if let Some(n) = crate::number(s) {
        return Some(n);
    }
    if s.as_bytes().first().is_some_and(u8::is_ascii_digit) {
        for suffix in [
            "वाँ",
            "वां",
            "वीं",
            "वें",
            "वे",
            "ला",
            "ली",
            "ले",
            "रा",
            "री",
            "रे",
            "था",
            "थी",
            "थे",
            "ठा",
            "ठी",
            "ठे",
        ] {
            if let Some(stem) = s.strip_suffix(suffix) {
                return crate::number(stem);
            }
        }
    }
    match s {
        "शून्य" | "सिफर" | "सिफ़र" => return Some(0),
        "एक" | "पहला" | "पहली" | "पहले" | "प्रथम" => {
            return Some(1);
        }
        "दो" | "दूसरा" | "दूसरी" | "दूसरे" | "द्वितीय" => {
            return Some(2);
        }
        "तीन" | "तीसरा" | "तीसरी" | "तीसरे" | "तृतीय" => {
            return Some(3);
        }
        "चार" | "चौथा" | "चौथी" | "चौथे" | "चतुर्थ" => {
            return Some(4);
        }
        "छठा" | "छठी" | "छठे" | "छठवाँ" | "छठवां" | "छठवीं" | "छठवें" | "छह" | "छः" | "छ" =>
        {
            return Some(6);
        }
        "नवाँ" | "नवां" | "नवीं" | "नवें" | "नौ" => {
            return Some(9);
        }
        _ => {}
    }
    let stem = ["वाँ", "वां", "वीं", "वें", "वे"]
        .iter()
        .find_map(|sfx| s.strip_suffix(sfx))
        .unwrap_or(s);
    Some(match stem {
        "पांच" | "पाँच" => 5,
        "सात" => 7,
        "आठ" => 8,
        "नौ" => 9,
        "दस" => 10,
        "ग्यारह" => 11,
        "बारह" => 12,
        "तेरह" => 13,
        "चौदह" => 14,
        "पंद्रह" | "पन्द्रह" => 15,
        "सोलह" => 16,
        "सत्रह" => 17,
        "अठारह" | "अट्ठारह" => 18,
        "उन्नीस" => 19,
        "बीस" => 20,
        "इक्कीस" => 21,
        "बाईस" => 22,
        "तेईस" => 23,
        "चौबीस" => 24,
        "पच्चीस" => 25,
        "छब्बीस" => 26,
        "सत्ताईस" => 27,
        "अट्ठाईस" | "अठाईस" => 28,
        "उनतीस" | "उनत्तीस" => 29,
        "तीस" => 30,
        "इकतीस" | "इकत्तीस" => 31,
        "चालीस" => 40,
        "पैंतालीस" => 45,
        "पचास" => 50,
        "साठ" => 60,
        _ => return None,
    })
}

fn triple_group<'t>(
    c: &crate::Captures<'t>,
    a: &str,
    b: &str,
    d: &str,
) -> Option<(&'t str, &'t str, &'t str)> {
    Some((
        c.name(a)?.as_str(),
        c.name(b)?.as_str(),
        c.name(d)?.as_str(),
    ))
}

pub fn language() -> Language {
    Language::new(
        "hi",
        "(?:[\\s,]|को|के|की|का|में)+",
        vec![
            Pattern::with_builder(
                "hi_ymdDate",
                "(?P<guard0>)(?:(?P<y1>[0-9]{4})-(?P<m1>[0-9]{1,2})-(?P<d1>[0-9]{1,2})|(?P<y2>[0-9]{4})/(?P<m2>[0-9]{1,2})/(?P<d2>[0-9]{1,2})|(?P<y3>[0-9]{4})\\.(?P<m3>[0-9]{1,2})\\.(?P<d3>[0-9]{1,2}))(?P<guard1>)",
                DATE_GUARDS,
                |c, _| {
                    let (ys, ms, ds) = triple_group(c, "y1", "m1", "d1")
                        .or_else(|| triple_group(c, "y2", "m2", "d2"))
                        .or_else(|| triple_group(c, "y3", "m3", "d3"))?;
                    Some(vec![
                        Component::Year(crate::number(ys)?),
                        Component::Month(crate::number(ms)?),
                        Component::Day(crate::number(ds)?),
                    ])
                },
            ),
            Pattern::with_builder(
                "hi_dmyDate",
                "(?P<guard0>)(?:(?P<d1>[0-9]{1,2})-(?P<m1>[0-9]{1,2})-(?P<y1>[0-9]{4}|[0-9]{2})|(?P<d2>[0-9]{1,2})/(?P<m2>[0-9]{1,2})/(?P<y2>[0-9]{4}|[0-9]{2})|(?P<d3>[0-9]{1,2})\\.(?P<m3>[0-9]{1,2})\\.(?P<y3>[0-9]{4}|[0-9]{2}))(?P<guard1>)",
                DATE_GUARDS,
                |c, _| {
                    let (ds, ms, ys) = triple_group(c, "d1", "m1", "y1")
                        .or_else(|| triple_group(c, "d2", "m2", "y2"))
                        .or_else(|| triple_group(c, "d3", "m3", "y3"))?;
                    let mut y = crate::number(ys)?;
                    if ys.len() == 2 {
                        y += if y >= 70 { 1900 } else { 2000 };
                    }
                    Some(vec![
                        Component::Year(y),
                        Component::Month(crate::number(ms)?),
                        Component::Day(crate::number(ds)?),
                    ])
                },
            ),
            Pattern::with_builder(
                "hi_nthWeekday",
                &format!(
                    "(?P<guard0>)(?P<month>{MONTH_ALT})(?:\\s+(?:महीने|माह))?\\s+(?:का|के|की|में)\\s+(?P<ord>पहला|पहली|पहले|प्रथम|1ला|1ली|1ले|दूसरा|दूसरी|दूसरे|द्वितीय|2रा|2री|2रे|तीसरा|तीसरी|तीसरे|तृतीय|3रा|3री|3रे|चौथा|चौथी|चौथे|चतुर्थ|4था|4थी|4थे|पांचवाँ|पांचवां|पांचवा|पांचवीं|पांचवें|पाँचवाँ|पाँचवां|पाँचवा|पाँचवीं|पाँचवें|5वाँ|5वां|5वीं|5वें|आख़िरी|आखिरी|अन्तिम|अंतिम)\\s+(?P<wd>{WEEKDAY_ALT})(?P<guard1>)"
                ),
                DEV_GUARDS,
                |c, _| {
                    let month = lookup_month(c.name("month")?.as_str())?;
                    let ord_str = c.name("ord")?.as_str();
                    let ord = if matches!(ord_str, "आख़िरी" | "आखिरी" | "अन्तिम" | "अंतिम")
                    {
                        -1
                    } else {
                        hi_number(ord_str)?
                    };
                    let wd = lookup_weekday(c.name("wd")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, month)])
                },
            ),
            Pattern::new(
                "hi_dayMonth",
                &format!(
                    "(?P<guard0>)([0-9]{{1,2}})(?:वाँ|वां|वीं|वें|वे|ला|ली|ले|रा|री|रे|था|थी|थे|ठा|ठी|ठे)?\\s+({MONTH_ALT})(?P<guard1>)(?:,?\\s+([0-9]{{4}})(?P<guard2>))?"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, DEV_LETTER),
                    ("guard2", false, WORD_CHAR),
                ],
                &[],
            ),
            Pattern::with_builder(
                "hi_wordDayMonth",
                &format!(
                    "(?P<guard0>)(?P<day>{WORD_NUM_ALT})\\s+(?P<month>{MONTH_ALT})(?P<guard1>)(?:,?\\s+(?P<year>[0-9]{{4}})(?P<guard2>))?"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, DEV_LETTER),
                    ("guard2", false, WORD_CHAR),
                ],
                |c, _| {
                    let day = hi_number(c.name("day")?.as_str())?;
                    let month = lookup_month(c.name("month")?.as_str())?;
                    let mut comps = vec![Component::Month(month), Component::Day(day)];
                    if let Some(ym) = c.name("year") {
                        comps.push(Component::Year(crate::number(ym.as_str())?));
                    }
                    Some(comps)
                },
            ),
            Pattern::with_builder(
                "hi_monthDay",
                &format!(
                    "(?P<guard0>)(?P<month>{MONTH_ALT})(?:\\s+की\\s+|\\s+)(?P<day>[0-9]{{1,2}})(?:वाँ|वां|वीं|वें|वे|ला|ली|ले|रा|री|रे|था|थी|थे|ठा|ठी|ठे|\\s*तारीख़?)?(?P<guard1>)(?:,?\\s+(?P<year>[0-9]{{4}})(?P<guard2>))?"
                ),
                &[
                    ("guard0", true, DEV_LETTER),
                    (
                        "guard1",
                        false,
                        "[:0-9a-zA-Zऀ-ॣॱ-ॿ]|\\s*(?:बजे|मिनट|सेकंड|दिनों|दिन|सप्ताह|हफ़्तों|हफ़्ते|हफ्ते|हफ़्ता|हफ्ता|हफ्तों|महीनों|महीने|महीना|माह|मास|सालों|साल|वर्षों|वर्ष|बरस|[aA][mM]|[pP][mM]|[aA]\\.[mM]\\.|[pP]\\.[mM]\\.|ए\\.?एम\\.?|पी\\.?एम\\.?)",
                    ),
                    ("guard2", false, WORD_CHAR),
                ],
                |c, _| {
                    let month = lookup_month(c.name("month")?.as_str())?;
                    let day = crate::number(c.name("day")?.as_str())?;
                    let mut comps = vec![Component::Month(month), Component::Day(day)];
                    if let Some(ym) = c.name("year") {
                        comps.push(Component::Year(crate::number(ym.as_str())?));
                    }
                    Some(comps)
                },
            ),
            Pattern::with_builder(
                "hi_monthYear",
                &format!(
                    "(?P<guard0>)(?P<month>{MONTH_ALT})(?:,?\\s+|\\s+के\\s+)(?P<year>[0-9]{{4}})(?P<guard1>)"
                ),
                &[("guard0", true, DEV_LETTER), ("guard1", false, WORD_CHAR)],
                |c, _| {
                    Some(vec![
                        Component::Month(lookup_month(c.name("month")?.as_str())?),
                        Component::Year(crate::number(c.name("year")?.as_str())?),
                    ])
                },
            ),
            Pattern::with_builder(
                "hi_namedYear",
                "(?P<guard0>)(?:साल|वर्ष|सन्|सन)\\s+(?P<year>[0-9]{4})(?P<guard1>)",
                &[("guard0", true, DEV_LETTER), ("guard1", false, WORD_CHAR)],
                |c, _| {
                    Some(vec![Component::Year(crate::number(
                        c.name("year")?.as_str(),
                    )?)])
                },
            ),
            Pattern::with_builder(
                "hi_relativeDayPhrase",
                "(?P<guard0>)(?:(?P<future>आने\\s*वाले|आने\\s*वाला|आनेवाले|आनेवाला|अगले|अगला|आगामी)|(?P<past>बीता\\s*हुआ|बीते\\s*हुए|बीता|बीते|पिछले|पिछला|गया|गए|गुज़रा|गुजरा))\\s+(?P<day>परसों|परसो|नरसों|नरसो|तरसों|तरसो|कल)(?P<guard1>)",
                DEV_GUARDS,
                |c, _| {
                    let base = match c.name("day")?.as_str() {
                        "कल" => 1,
                        "परसों" | "परसो" => 2,
                        "नरसों" | "नरसो" => 3,
                        "तरसों" | "तरसो" => 4,
                        _ => return None,
                    };
                    let offset = if c.name("past").is_some() {
                        -base
                    } else {
                        base
                    };
                    Some(vec![Component::RelativeDay(offset)])
                },
            ),
            Pattern::new(
                "hi_relativeDay",
                "(?P<guard0>)(परसों|परसो|नरसों|नरसो|तरसों|तरसो|आज|कल)(?P<guard1>)",
                DEV_GUARDS,
                &[
                    ("आज", &[Component::RelativeDay(0)]),
                    ("कल", &[Component::RelativeDay(1)]),
                    ("परसों", &[Component::RelativeDay(2)]),
                    ("परसो", &[Component::RelativeDay(2)]),
                    ("नरसों", &[Component::RelativeDay(3)]),
                    ("नरसो", &[Component::RelativeDay(3)]),
                    ("तरसों", &[Component::RelativeDay(4)]),
                    ("तरसो", &[Component::RelativeDay(4)]),
                ],
            ),
            Pattern::with_builder(
                "hi_within",
                &format!(
                    "(?P<guard0>)(?:(?P<n1>[0-9]+|{WORD_NUM_ALT})\\s*(?P<u1>दिनों|दिन|सप्ताह|हफ़्तों|हफ़्ते|हफ्ते|हफ़्ता|हफ्ता|हफ्तों)\\s+(?:के\\s+)?(?:अंदर|अन्दर|भीतर)|(?:अगले|आने\\s*वाले|आगामी)\\s+(?P<n2>[0-9]+|{WORD_NUM_ALT})\\s*(?P<u2>दिनों|दिन|सप्ताह|हफ़्तों|हफ़्ते|हफ्ते|हफ़्ता|हफ्ता|हफ्तों)(?:\\s+(?:में|के\\s+अंदर|के\\s+अन्दर|के\\s+भीतर))?)(?P<guard1>)"
                ),
                NUM_DEV_GUARDS,
                |c, _| {
                    let (n_str, u_str) = if let (Some(n), Some(u)) = (c.name("n1"), c.name("u1")) {
                        (n.as_str(), u.as_str())
                    } else {
                        (c.name("n2")?.as_str(), c.name("u2")?.as_str())
                    };
                    let n = hi_number(n_str)?;
                    let days = match u_str {
                        "दिन" | "दिनों" => n,
                        _ => n.checked_mul(7)?,
                    };
                    Some(vec![Component::Within(days)])
                },
            ),
            Pattern::with_builder(
                "hi_relativeOffset",
                &format!(
                    "(?P<guard0>)(?P<n>[0-9]+|{WORD_NUM_ALT})\\s*(?P<u>दिनों|दिन|सप्ताह|हफ़्तों|हफ़्ते|हफ्ते|हफ़्ता|हफ्ता|हफ्तों|महीनों|महीने|महीना|माह|मास|सालों|साल|वर्षों|वर्ष|बरस)\\s*(?:के\\s+(?P<d1>बाद|पहले)|से\\s+(?P<d2>पहले)|(?P<d3>बाद|पहले|में|पश्चात्|पश्चात|पूर्व))(?P<guard1>)"
                ),
                NUM_DEV_GUARDS,
                |c, _| {
                    let n = hi_number(c.name("n")?.as_str())?;
                    let dir = c
                        .name("d1")
                        .or_else(|| c.name("d2"))
                        .or_else(|| c.name("d3"))?
                        .as_str();
                    let val = if matches!(dir, "पहले" | "पूर्व") {
                        n.checked_neg()?
                    } else {
                        n
                    };
                    let comp = match c.name("u")?.as_str() {
                        "दिन" | "दिनों" => Component::RelativeDay(val),
                        "महीने" | "महीना" | "महीनों" | "माह" | "मास" => {
                            Component::MonthOffset(val)
                        }
                        "साल" | "सालों" | "वर्ष" | "वर्षों" | "बरस" => {
                            Component::YearOffset(val)
                        }
                        _ => Component::Week(val, false),
                    };
                    Some(vec![comp])
                },
            ),
            Pattern::new(
                "hi_offset",
                "(?P<guard0>)([0-9]+)\\s*(दिन|(?:सप्ताह|हफ़्ते|हफ्ते|हफ्ता)|महीने|साल)\\s*(बाद|पहले)(?P<guard1>)",
                NUM_DEV_GUARDS,
                &[],
            ),
            Pattern::with_builder(
                "hi_doubleAnchor",
                "(?P<guard0>)(?:(?P<next>अगले\\s+से\\s+अगले|उससे\\s+अगले)|(?P<prev>पिछले\\s+से\\s+पिछले|उससे\\s+पिछले))\\s+(?:(?P<w>सप्ताह|हफ़्ते|हफ्ते|हफ़्ता|हफ्ता)|(?P<m>महीने|महीना|माह|मास)|(?P<y>साल|वर्ष|बरस))(?P<guard1>)",
                DEV_GUARDS,
                |c, _| {
                    let off = if c.name("prev").is_some() { -2 } else { 2 };
                    let comp = if c.name("w").is_some() {
                        Component::Week(off, true)
                    } else if c.name("m").is_some() {
                        Component::MonthOffset(off)
                    } else {
                        Component::YearOffset(off)
                    };
                    Some(vec![comp])
                },
            ),
            Pattern::with_builder(
                "hi_weekend",
                "(?P<guard0>)(?:(?P<past>पिछले|पिछला|बीते|बीता|गत)\\s+|(?:अगले|अगला|आने\\s*वाले|आने\\s*वाला|आगामी|इस|इसी)\\s+)?(?:सप्ताहांत|सप्ताहान्त|वीकेंड|(?:सप्ताह|हफ़्ते|हफ्ते)\\s+के\\s+अंत)(?P<guard1>)",
                DEV_GUARDS,
                |c, _| {
                    if c.name("past").is_some() {
                        Some(vec![Component::Week(-1, false), Component::Weekday(7)])
                    } else {
                        Some(vec![Component::Weekend])
                    }
                },
            ),
            Pattern::new(
                "hi_weekAnchor",
                "(?P<guard0>)(अगले|पिछले|इस)\\s+(?:सप्ताह|हफ़्ते|हफ्ते|हफ्ता)(?P<guard1>)",
                DEV_GUARDS,
                &[],
            ),
            Pattern::new(
                "hi_monthAnchor",
                "(?P<guard0>)(अगले|पिछले|इस)\\s+(?:महीने|महीना)(?P<guard1>)",
                DEV_GUARDS,
                &[],
            ),
            Pattern::new(
                "hi_yearAnchor",
                "(?P<guard0>)(अगले|पिछले|इस)\\s+(?:साल|वर्ष)(?P<guard1>)",
                DEV_GUARDS,
                &[],
            ),
            Pattern::with_builder(
                "hi_extraAnchor",
                "(?P<guard0>)(?:(?P<next>अगले|अगला|आने\\s*वाले|आने\\s*वाला|आनेवाले|आनेवाला|आगामी)|(?P<prev>पिछले|पिछला|बीते\\s*हुए|बीता\\s*हुआ|बीते|बीता|गए|गया|गत)|(?P<this>इसी|इस|मौजूदा|वर्तमान|चालू))\\s+(?:(?P<w>सप्ताह|हफ़्ते|हफ्ते|हफ़्ता|हफ्ता)|(?P<m>महीने|महीना|माह|मास)|(?P<y>साल|वर्ष|बरस))(?P<guard1>)",
                DEV_GUARDS,
                |c, _| {
                    let off = if c.name("next").is_some() {
                        1
                    } else if c.name("prev").is_some() {
                        -1
                    } else {
                        0
                    };
                    let comp = if c.name("w").is_some() {
                        Component::Week(off, true)
                    } else if c.name("m").is_some() {
                        Component::MonthOffset(off)
                    } else {
                        Component::YearOffset(off)
                    };
                    Some(vec![comp])
                },
            ),
            Pattern::new(
                "hi_nextLastWeekday",
                &format!("(?P<guard0>)(अगले|पिछले)\\s+({WEEKDAY_ALT})(?P<guard1>)"),
                DEV_GUARDS,
                &[],
            ),
            Pattern::with_builder(
                "hi_extraNextLastWeekday",
                &format!(
                    "(?P<guard0>)(?:(?P<next>अगला|आने\\s*वाले|आने\\s*वाला|आनेवाले|आनेवाला|आगामी)|(?P<prev>पिछला|बीते\\s*हुए|बीता\\s*हुआ|बीते|बीता|गए|गया|गत)|(?P<this>इसी|इस))\\s+(?P<wd>{WEEKDAY_ALT})(?P<guard1>)"
                ),
                DEV_GUARDS,
                |c, _| {
                    let wd = lookup_weekday(c.name("wd")?.as_str())?;
                    if c.name("next").is_some() {
                        Some(vec![Component::Week(1, false), Component::Weekday(wd)])
                    } else if c.name("prev").is_some() {
                        Some(vec![Component::Week(-1, false), Component::Weekday(wd)])
                    } else {
                        Some(vec![Component::Weekday(wd)])
                    }
                },
            ),
            Pattern::new(
                "hi_weekday",
                &format!("(?P<guard0>)({WEEKDAY_ALT})(?P<guard1>)"),
                DEV_GUARDS,
                WEEKDAYS,
            ),
            Pattern::new(
                "hi_month",
                &format!("(?P<guard0>)({MONTH_ALT})(?P<guard1>)"),
                DEV_GUARDS,
                MONTHS,
            ),
            Pattern::with_builder(
                "hi_dayExtra",
                &format!(
                    "(?P<guard0>)(?:(?P<d1>[0-9]{{1,2}})(?:वाँ|वां|वीं|वें|वे|ला|ली|ले|रा|री|रे|था|थी|थे|ठा|ठी|ठे)\\s*तारीख़?|(?P<d2>[0-9]{{1,2}})\\s*तारीख़|(?P<d3>{WORD_NUM_ALT})\\s*तारीख़?)(?P<guard1>)"
                ),
                NUM_DEV_GUARDS,
                |c, _| {
                    let raw = c
                        .name("d1")
                        .or_else(|| c.name("d2"))
                        .or_else(|| c.name("d3"))?
                        .as_str();
                    Some(vec![Component::Day(hi_number(raw)?)])
                },
            ),
            Pattern::new(
                "hi_day",
                "(?P<guard0>)([0-9]{1,2})\\s*तारीख(?P<guard1>)",
                NUM_DEV_GUARDS,
                &[],
            ),
            Pattern::with_builder(
                "hi_noonMidnight",
                "(?P<guard0>)(?:(?P<midnight>आधी\\s*रात|मध्यरात्रि|मध्य\\s*रात्रि|अर्धरात्रि|अर्ध\\s*रात्रि)|(?P<noon>ठीक\\s+दोपहर|मध्याह्न|मध्यान्ह))(?:\\s*(?:के|को)?\\s*12(?::00)?\\s*बजे)?(?P<guard1>)",
                DEV_GUARDS,
                |c, _| {
                    let h = if c.name("midnight").is_some() { 0 } else { 12 };
                    Some(vec![Component::Time(h, Some(0), None)])
                },
            ),
            Pattern::with_builder(
                "hi_fracTime",
                &format!(
                    "(?P<guard0>)(?:(?P<dedh>डेढ़\\s*बजे|डेढ\\u{{093c}}\\s*बजे)|(?P<dhai>(?:ढाई|अढ़ाई|अढ\\u{{093c}}ाई)\\s*बजे)|(?P<sadhe>सा(?:ढ़|ढ\\u{{093c}}?)े\\s*(?P<hs>{HOUR_ALT})\\s*बजे)|(?P<sawa>सवा\\s*(?:(?P<hq>{HOUR_ALT})\\s*)?बजे)|(?P<paune>पौने\\s*(?:(?P<hp>{HOUR_ALT})\\s*)?बजे))(?P<guard1>)"
                ),
                DEV_GUARDS,
                |c, _| {
                    let (h, m) = if c.name("dedh").is_some() {
                        (1, 30)
                    } else if c.name("dhai").is_some() {
                        (2, 30)
                    } else if c.name("sadhe").is_some() {
                        (hi_number(c.name("hs")?.as_str())?, 30)
                    } else if c.name("sawa").is_some() {
                        let h = match c.name("hq") {
                            Some(m) => hi_number(m.as_str())?,
                            None => 1,
                        };
                        (h, 15)
                    } else {
                        let h = match c.name("hp") {
                            Some(m) => hi_number(m.as_str())?,
                            None => 1,
                        };
                        if !(0..24).contains(&h) {
                            return None;
                        }
                        ((h - 1).rem_euclid(24), 45)
                    };
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "hi_toHourTime",
                &format!(
                    "(?P<guard0>)(?P<h>[0-9]{{1,2}}|{WORD_NUM_ALT})\\s*बजने\\s+में\\s+(?P<m>[0-9]{{1,2}}|{WORD_NUM_ALT})\\s*मिनट(?P<guard1>)"
                ),
                NUM_DEV_GUARDS,
                |c, _| {
                    let h = hi_number(c.name("h")?.as_str())?;
                    let m = hi_number(c.name("m")?.as_str())?;
                    if !(0..24).contains(&h) || !(1..60).contains(&m) {
                        return None;
                    }
                    let total = (h * 60 - m).rem_euclid(24 * 60);
                    Some(vec![Component::Time(total / 60, Some(total % 60), None)])
                },
            ),
            Pattern::with_builder(
                "hi_bajkarTime",
                &format!(
                    "(?P<guard0>)(?P<h>[0-9]{{1,2}}|{WORD_NUM_ALT})\\s*(?:बज\\s*कर|बजे)\\s+(?P<m>[0-9]{{1,2}}|{WORD_NUM_ALT})\\s*मिनट(?P<guard1>)"
                ),
                NUM_DEV_GUARDS,
                |c, _| {
                    let h = hi_number(c.name("h")?.as_str())?;
                    let m = hi_number(c.name("m")?.as_str())?;
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "hi_timeAmPm",
                "(?P<guard0>)(?P<h>[0-9]{1,2})(?::(?P<m>[0-9]{2})(?::(?P<s>[0-9]{2}))?)?\\s*(?:(?P<am>[aA][mM]|[aA]\\.[mM]\\.|ए\\.?एम\\.?)|(?P<pm>[pP][mM]|[pP]\\.[mM]\\.|पी\\.?एम\\.?))(?P<guard1>)",
                WORD_GUARDS,
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    if !(1..=12).contains(&h) {
                        return None;
                    }
                    let m = match c.name("m") {
                        Some(mm) => Some(crate::number(mm.as_str())?),
                        None => None,
                    };
                    if let Some(sm) = c.name("s")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    Some(vec![Component::Time(h, m, Some(c.name("pm").is_some()))])
                },
            ),
            Pattern::with_builder(
                "hi_colonBaje",
                "(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<m>[0-9]{2})(?::(?P<s>[0-9]{2}))?\\s*बजे(?P<guard1>)",
                NUM_DEV_GUARDS,
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = crate::number(c.name("m")?.as_str())?;
                    if let Some(sm) = c.name("s")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "hi_hmsTime",
                "(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<m>[0-9]{2}):(?P<s>[0-9]{2})(?P<guard1>)",
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, "[0-9a-zA-Zऀ-ॣॱ-ॿ:]"),
                ],
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = crate::number(c.name("m")?.as_str())?;
                    let s = crate::number(c.name("s")?.as_str())?;
                    if !(0..60).contains(&s) {
                        return None;
                    }
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "hi_wordBaje",
                &format!("(?P<guard0>)(?P<h>{WORD_NUM_ALT})\\s*बजे(?P<guard1>)"),
                DEV_GUARDS,
                |c, _| {
                    Some(vec![Component::Time(
                        hi_number(c.name("h")?.as_str())?,
                        None,
                        None,
                    )])
                },
            ),
            Pattern::new(
                "hi_baje",
                "(?P<guard0>)([0-9]{1,2})\\s*बजे(?P<guard1>)",
                NUM_DEV_GUARDS,
                &[],
            ),
            Pattern::new("hi_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
            Pattern::new(
                "hi_meridiem",
                "(?P<guard0>)(प्रातःकाल|प्रातः|प्रात:|प्रात|पूर्वाह्ण|पूर्वाह्न|अपराह्ण|अपराह्न|सायंकाल|सायं|दोपहर|संध्या|सवेरे|रात्रि|सुबह|शाम|भोर|तड़के|रात)(?P<guard1>)",
                DEV_GUARDS,
                &[
                    ("प्रातःकाल", &[Component::Meridiem(false)]),
                    ("प्रातः", &[Component::Meridiem(false)]),
                    ("प्रात:", &[Component::Meridiem(false)]),
                    ("प्रात", &[Component::Meridiem(false)]),
                    ("पूर्वाह्ण", &[Component::Meridiem(false)]),
                    ("पूर्वाह्न", &[Component::Meridiem(false)]),
                    ("सुबह", &[Component::Meridiem(false)]),
                    ("सवेरे", &[Component::Meridiem(false)]),
                    ("भोर", &[Component::Meridiem(false)]),
                    ("तड़के", &[Component::Meridiem(false)]),
                    ("दोपहर", &[Component::Meridiem(true)]),
                    ("अपराह्ण", &[Component::Meridiem(true)]),
                    ("अपराह्न", &[Component::Meridiem(true)]),
                    ("सायंकाल", &[Component::Meridiem(true)]),
                    ("सायं", &[Component::Meridiem(true)]),
                    ("संध्या", &[Component::Meridiem(true)]),
                    ("शाम", &[Component::Meridiem(true)]),
                    ("रात्रि", &[Component::Meridiem(true)]),
                    ("रात", &[Component::Meridiem(true)]),
                ],
            ),
        ],
    )
}

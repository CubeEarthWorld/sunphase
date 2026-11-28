use crate::{Capture, Component, Language, Pattern};

macro_rules! fr_chars {
    () => {
        "a-zA-Z0-9À-ÖØ-öø-ÿŒœŸ"
    };
}

macro_rules! word_end {
    () => {
        "(?:[^a-zA-ZÀ-ÖØ-öø-ÿŒœŸ]|$)"
    };
}

macro_rules! month_all {
    () => {
        "septembre|d[eéÉ]cembre|novembre|f[eéÉ]vrier|janvier|octobre|juillet|avril|ao[uûÛ]t|mars|juin|mai|juill\\.?|sept\\.?|janv\\.?|f[eéÉ]vr\\.?|juil\\.?|f[eéÉ]v\\.?|jan\\.?|avr\\.?|sep\\.?|oct\\.?|nov\\.?|d[eéÉ]c\\.?"
    };
}

macro_rules! wd_full {
    () => {
        "mercredi|vendredi|dimanche|lundi|mardi|jeudi|samedi"
    };
}

macro_rules! wd_nextlast {
    () => {
        "mercredi|vendredi|dimanche|lundi|mardi|jeudi|samedi|mercr\\.?|merc\\.?|vend\\.?|jeud\\.?|lun\\.?|mar\\.?|mer\\.?|jeu\\.?|ven\\.?|sam\\.?|dim\\.?"
    };
}

macro_rules! num_any {
    () => {
        "(?:[0-9]+|quatre[\\s-]+vingts?(?:[\\s-]+(?:dix[\\s-]+(?:sept|huit|neuf)|quatorze|quinze|douze|treize|seize|onze|dix|quatre|trois|cinq|sept|huit|neuf|deux|une?|six))?|(?:soixante|cinquante|quarante|trente|vingt|septante|huitante|octante|nonante)(?:(?:[\\s-]+et)?[\\s-]+(?:dix[\\s-]+(?:sept|huit|neuf)|quatorze|quinze|douze|treize|seize|onze|dix|quatre|trois|cinq|sept|huit|neuf|deux|une?|six))?|dix[\\s-]+(?:sept|huit|neuf)|quatorze|quinze|douze|treize|seize|onze|dix|quatre|trois|cinq|sept|huit|neuf|deux|une?|six|cent)"
    };
}

macro_rules! num_1_59 {
    () => {
        "(?:[0-9]{1,2}|(?:cinquante|quarante|trente|vingt)(?:(?:[\\s-]+et)?[\\s-]+(?:quatre|trois|cinq|sept|huit|neuf|deux|une?|six))?|dix[\\s-]+(?:sept|huit|neuf)|quatorze|quinze|douze|treize|seize|onze|dix|quatre|trois|cinq|sept|huit|neuf|deux|une?|six)"
    };
}

macro_rules! h_0_23 {
    () => {
        "(?:[0-9]{1,2}|vingt(?:[\\s-]+(?:et[\\s-]+une?|deux|trois))?|dix[\\s-]+(?:sept|huit|neuf)|quatorze|quinze|douze|treize|seize|onze|dix|quatre|trois|cinq|sept|huit|neuf|deux|une?|six|z[eéÉ]ro)"
    };
}

macro_rules! day_part {
    () => {
        "(?:1(?:er|[eèÈ]?re|e)|[0-9]{1,2}(?:i?[eèÈ]me|e)?|trente(?:(?:[\\s-]+et)?[\\s-]+une?)?|vingt(?:(?:[\\s-]+et)?[\\s-]+(?:quatre|trois|cinq|sept|huit|neuf|deux|une?|six))?|dix[\\s-]+(?:sept|huit|neuf)|quatorze|quinze|douze|treize|seize|onze|dix|premi[eèÈ]re?|premier|quatre|trois|cinq|sept|huit|neuf|deux|six)"
    };
}

const FR_ALNUM: &str = concat!("[", fr_chars!(), "]");
const TIME_GUARD0: &str = concat!("[.:/\\-", fr_chars!(), "]");

fn fr_word_num(w: &str) -> Option<i32> {
    Some(match w {
        "zéro" | "zero" => 0,
        "un" | "une" | "premier" | "première" | "premiere" => 1,
        "deux" | "deuxième" | "deuxieme" | "second" | "seconde" => 2,
        "trois" | "troisième" | "troisieme" => 3,
        "quatre" | "quatrième" | "quatrieme" => 4,
        "cinq" | "cinquième" | "cinquieme" => 5,
        "six" => 6,
        "sept" => 7,
        "huit" => 8,
        "neuf" => 9,
        "dix" => 10,
        "onze" => 11,
        "douze" => 12,
        "treize" => 13,
        "quatorze" => 14,
        "quinze" => 15,
        "seize" => 16,
        "vingt" | "vingts" => 20,
        "trente" => 30,
        "quarante" => 40,
        "cinquante" => 50,
        "soixante" => 60,
        "septante" => 70,
        "huitante" | "octante" => 80,
        "nonante" => 90,
        "cent" => 100,
        _ => return None,
    })
}

fn parse_fr_num(s: &str) -> Option<i32> {
    if let Some(n) = crate::number(s) {
        return Some(n);
    }
    let lower = s.to_lowercase();
    let mut it = lower
        .split(|c: char| c.is_whitespace() || c == '-')
        .filter(|t| !t.is_empty() && *t != "et");
    let first = fr_word_num(it.next()?)?;
    let Some(second_raw) = it.next() else {
        return Some(first);
    };
    let second = fr_word_num(second_raw)?;
    // French "quatre-vingt..." represents 4 * 20 rather than 4 + 20.
    let mut acc = if first == 4 && second == 20 {
        80
    } else {
        first.checked_add(second)?
    };
    for tok in it {
        acc = acc.checked_add(fr_word_num(tok)?)?;
    }
    Some(acc)
}

fn parse_fr_day_unbounded(s: &str) -> Option<i32> {
    let lower = s.to_lowercase();
    if lower.as_bytes().first().is_some_and(u8::is_ascii_digit) {
        let stem = lower
            .strip_suffix("ième")
            .or_else(|| lower.strip_suffix("ieme"))
            .or_else(|| lower.strip_suffix("ème"))
            .or_else(|| lower.strip_suffix("eme"))
            .or_else(|| lower.strip_suffix("ère"))
            .or_else(|| lower.strip_suffix("ere"))
            .or_else(|| lower.strip_suffix("er"))
            .or_else(|| lower.strip_suffix("re"))
            .or_else(|| lower.strip_suffix('e'))
            .unwrap_or(&lower);
        crate::number(stem)
    } else {
        if matches!(lower.as_str(), "un" | "une") {
            return None;
        }
        parse_fr_num(&lower)
    }
}

fn parse_fr_day(s: &str) -> Option<i32> {
    let d = parse_fr_day_unbounded(s)?;
    (1..=31).contains(&d).then_some(d)
}

fn invalid_date_sentinel() -> Vec<Component> {
    // Consumes an out-of-range day+month span so trailing month/year patterns don't match,
    // while failing calendar resolution in resolve::resolve.
    vec![
        Component::Year(2025),
        Component::Month(2),
        Component::Day(30),
    ]
}

fn parse_fr_ord(s: &str) -> Option<i32> {
    Some(match s.to_lowercase().as_str() {
        "1er" | "1ère" | "1ere" | "1re" | "1e" | "premier" | "première" | "premiere" => 1,
        "2e" | "2ème" | "2eme" | "2ième" | "2ieme" | "deuxième" | "deuxieme" | "second"
        | "seconde" => 2,
        "3e" | "3ème" | "3eme" | "3ième" | "3ieme" | "troisième" | "troisieme" => 3,
        "4e" | "4ème" | "4eme" | "4ième" | "4ieme" | "quatrième" | "quatrieme" => 4,
        "5e" | "5ème" | "5eme" | "5ième" | "5ieme" | "cinquième" | "cinquieme" => 5,
        "dernier" | "dernière" | "derniere" => -1,
        _ => return None,
    })
}

fn parse_fr_month(s: &str) -> Option<i32> {
    let lower = s.trim_end_matches('.').to_lowercase();
    Some(match lower.as_str() {
        "janvier" | "janv" | "jan" => 1,
        "février" | "fevrier" | "févr" | "fevr" | "fév" | "fev" => 2,
        "mars" => 3,
        "avril" | "avr" => 4,
        "mai" => 5,
        "juin" => 6,
        "juillet" | "juill" | "juil" => 7,
        "août" | "aout" => 8,
        "septembre" | "sept" | "sep" => 9,
        "octobre" | "oct" => 10,
        "novembre" | "nov" => 11,
        "décembre" | "decembre" | "déc" | "dec" => 12,
        _ => return None,
    })
}

fn parse_fr_weekday(s: &str) -> Option<i32> {
    let lower = s.trim_end_matches('.').to_lowercase();
    Some(match lower.as_str() {
        "lundi" | "lun" => 1,
        "mardi" | "mar" => 2,
        "mercredi" | "merc" | "mercr" | "mer" => 3,
        "jeudi" | "jeud" | "jeu" => 4,
        "vendredi" | "vend" | "ven" => 5,
        "samedi" | "sam" => 6,
        "dimanche" | "dim" => 7,
        _ => return None,
    })
}

fn parse_fr_offset(value: i32, unit: &str) -> Option<Component> {
    let lower = unit.to_lowercase();
    if lower.starts_with('j') {
        Some(Component::RelativeDay(value))
    } else if lower.starts_with('s') {
        Some(Component::Week(value, false))
    } else if lower.starts_with('m') {
        Some(Component::MonthOffset(value))
    } else if lower.starts_with('a') {
        Some(Component::YearOffset(value))
    } else {
        None
    }
}

fn parse_2_or_4_year(s: &str) -> Option<i32> {
    if s.len() != 2 && s.len() != 4 {
        return None;
    }
    let y = crate::number(s)?;
    Some(if s.len() == 2 {
        if y >= 70 { 1900 + y } else { 2000 + y }
    } else {
        y
    })
}

fn parse_ap(m: Option<Capture<'_>>) -> Option<bool> {
    m.map(|v| v.as_str().as_bytes()[0].eq_ignore_ascii_case(&b'p'))
}

fn parse_fr_meridiem(s: &str) -> bool {
    let lower = s.to_lowercase();
    !(lower.contains("matin") || lower.contains("nuit"))
}

fn valid_h_ap(h: i32, ap: Option<bool>) -> bool {
    match ap {
        Some(true) => (1..=23).contains(&h),
        Some(false) => (0..=12).contains(&h),
        None => (0..24).contains(&h),
    }
}

fn is_past_modifier(s: &str) -> bool {
    let lower = s.to_lowercase();
    lower.starts_with("derni")
        || lower.starts_with("pass")
        || lower.starts_with("préc")
        || lower.starts_with("prec")
}

pub fn language() -> Language {
    let alnum_guards = [("guard0", true, FR_ALNUM), ("guard1", false, FR_ALNUM)];

    Language::new(
        "fr",
        r"(?i)(?:[\s,]+|(?:[àaÀ]|au|aux|vers|pour|de|du|des|le|la|les|en|d['’]|l['’])(?:\s+|,|$))+",
        vec![
            Pattern::with_builder(
                "fr_partOfDay",
                r"(?i)(?P<guard0>)(?:(?P<rel>avant[\s-]+hier|apr[eèÈ]s[\s-]+demain|hier|demain)\s+(?P<pod>matin(?:[eéÉ]e)?|apr[eèÈ]s[\s-]+midi|apr[eèÈ]m|aprem|soir(?:[eéÉ]e)?|nuit)|ce\s+(?P<cem>matin(?:[eéÉ]e)?|soir(?:[eéÉ]e)?)|cet(?:te)?\s+(?P<cetm>apr[eèÈ]s[\s-]+midi|apr[eèÈ]m|aprem)|cette\s+(?P<cettem>matin[eéÉ]e|soir[eéÉ]e|nuit)|ce\s+midi(?:\s+(?P<cmkw>et\s+demie?|et\s+quart|moins\s+(?:le\s+)?quart|pile|pr[eéÉ]cis|juste))?)(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    if c.name("rel").is_some()
                        || c.name("cem").is_some()
                        || c.name("cetm").is_some()
                        || c.name("cettem").is_some()
                    {
                        let day = match c.name("rel").map(|m| m.as_str().to_lowercase()).as_deref()
                        {
                            Some(s) if s.starts_with("avant") => -2,
                            Some(s) if s.starts_with("apr") => 2,
                            Some("hier") => -1,
                            Some("demain") => 1,
                            _ => 0,
                        };
                        let pod = c
                            .name("pod")
                            .or_else(|| c.name("cem"))
                            .or_else(|| c.name("cetm"))
                            .or_else(|| c.name("cettem"))?
                            .as_str();
                        return Some(vec![
                            Component::RelativeDay(day),
                            Component::Meridiem(parse_fr_meridiem(pod)),
                        ]);
                    }
                    let (h, min) =
                        match c.name("cmkw").map(|m| m.as_str().to_lowercase()).as_deref() {
                            Some(s) if s.ends_with("demi") || s.ends_with("demie") => (12, 30),
                            Some(s) if s.starts_with("et") => (12, 15),
                            Some(s) if s.starts_with("moins") => (11, 45),
                            _ => (12, 0),
                        };
                    Some(vec![
                        Component::RelativeDay(0),
                        Component::Time(h, Some(min), None),
                    ])
                },
            ),
            Pattern::with_builder(
                "fr_relativeDayPhrase",
                r"(?i)(?P<guard0>)(?P<rel>apr[eèÈ]s[\s-]+apr[eèÈ]s[\s-]+demain|avant[\s-]+avant[\s-]+hier|apr[eèÈ]s[\s-]+demain|avant[\s-]+hier)(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let lower = c.name("rel")?.as_str().to_lowercase();
                    let offset = if lower.starts_with("avant") {
                        if lower.matches("avant").count() >= 2 {
                            -3
                        } else {
                            -2
                        }
                    } else if lower.matches("apr").count() >= 2 {
                        3
                    } else {
                        2
                    };
                    Some(vec![Component::RelativeDay(offset)])
                },
            ),
            Pattern::new(
                "fr_relativeDay",
                r"(?i)(?P<guard0>)(apr[eèÈ]s[\s-]+demain|apresdemain|avant[\s-]+hier|avanthier|aujourd['’]?hui|demain|hier|auj\.)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("aujourd'hui", &[Component::RelativeDay(0)]),
                    ("aujourd’hui", &[Component::RelativeDay(0)]),
                    ("aujourdhui", &[Component::RelativeDay(0)]),
                    ("auj.", &[Component::RelativeDay(0)]),
                    ("demain", &[Component::RelativeDay(1)]),
                    ("hier", &[Component::RelativeDay(-1)]),
                    ("après-demain", &[Component::RelativeDay(2)]),
                    ("apres-demain", &[Component::RelativeDay(2)]),
                    ("après demain", &[Component::RelativeDay(2)]),
                    ("apres demain", &[Component::RelativeDay(2)]),
                    ("apresdemain", &[Component::RelativeDay(2)]),
                    ("avant-hier", &[Component::RelativeDay(-2)]),
                    ("avant hier", &[Component::RelativeDay(-2)]),
                    ("avanthier", &[Component::RelativeDay(-2)]),
                ],
            ),
            Pattern::with_builder(
                "fr_nthWeekday",
                concat!(
                    "(?i)(?P<guard0>)(?:le\\s+)?(?P<ord>1(?:er|[eèÈ]?re|e)|premier|premi[eèÈ]re|[2-5](?:i?[eèÈ]me|e)|deuxi[eèÈ]me|seconde?|troisi[eèÈ]me|quatri[eèÈ]me|cinqui[eèÈ]me|derni[eèÈ]re?)\\s+(?P<wd>",
                    wd_full!(),
                    ")\\s+(?:du\\s+mois\\s+(?:de\\s+|d['’]\\s*)|de\\s+|d['’]\\s*|en\\s+)(?P<mo>",
                    month_all!(),
                    ")(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let ord = parse_fr_ord(c.name("ord")?.as_str())?;
                    let wd = parse_fr_weekday(c.name("wd")?.as_str())?;
                    let mo = parse_fr_month(c.name("mo")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, mo)])
                },
            ),
            Pattern::with_builder(
                "fr_nextLastWeekday",
                concat!(
                    "(?i)(?P<guard0>)(?:(?P<wd_w>",
                    wd_nextlast!(),
                    ")\\s+(?:de\\s+)?(?:la\\s+)?semaine\\s+(?P<wmod>prochaine|qui\\s+vient|suivante|derni[eèÈ]re|pass[eéÉ]e|pr[eéÉ]c[eéÉ]dente|courante|en\\s+cours)|(?P<wd_cw>",
                    wd_nextlast!(),
                    ")\\s+de\\s+cette\\s+semaine|(?:le\\s+)?(?:(?:ce\\s+)?(?P<post_wd>",
                    wd_nextlast!(),
                    ")\\s+(?P<post_mod>prochaine?|qui\\s+vient|suivante?|derni[eèÈ]re?|pass[eéÉ]e?|pr[eéÉ]c[eéÉ]dente?)|(?P<pre_mod>prochaine?|suivante?|derni[eèÈ]re?|pass[eéÉ]e?|pr[eéÉ]c[eéÉ]dente?|ce)\\s+(?P<pre_wd>",
                    wd_nextlast!(),
                    ")))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    if let Some(wd_cw) = c.name("wd_cw") {
                        let wd = parse_fr_weekday(wd_cw.as_str())?;
                        return Some(vec![Component::Week(0, true), Component::Weekday(wd)]);
                    }
                    if let Some(wd_w) = c.name("wd_w") {
                        let wd = parse_fr_weekday(wd_w.as_str())?;
                        let lower = c.name("wmod")?.as_str().to_lowercase();
                        let off = if is_past_modifier(&lower) {
                            -1
                        } else if lower == "courante" || lower.starts_with("en") {
                            0
                        } else {
                            1
                        };
                        return Some(vec![Component::Week(off, true), Component::Weekday(wd)]);
                    }
                    let (mod_s, wd_s) = if let Some(m) = c.name("post_mod") {
                        (m.as_str(), c.name("post_wd")?.as_str())
                    } else {
                        (c.name("pre_mod")?.as_str(), c.name("pre_wd")?.as_str())
                    };
                    let wd = parse_fr_weekday(wd_s)?;
                    let lower = mod_s.to_lowercase();
                    if lower == "ce" {
                        return Some(vec![Component::Weekday(wd)]);
                    }
                    let off = if is_past_modifier(&lower) { -1 } else { 1 };
                    Some(vec![Component::Week(off, false), Component::Weekday(wd)])
                },
            ),
            Pattern::with_builder(
                "fr_weekend",
                r"(?i)(?P<guard0>)(?:(?:le|la)\s+)?(?:(?P<past>(?:derni[eèÈ]re?|pass[eéÉ]e?|pr[eéÉ]c[eéÉ]dente?)\s+(?:week[\s-]?end|fin\s+de\s+semaine)|(?:week[\s-]?end|fin\s+de\s+semaine)\s+(?:derni[eèÈ]re?|pass[eéÉ]e?|pr[eéÉ]c[eéÉ]dente?))|(?P<next>(?:(?:ce|cette|prochaine?)\s+)?(?:week[\s-]?end|fin\s+de\s+semaine)(?:\s+(?:prochaine?|qui\s+vient|suivante?))?))(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    if c.name("past").is_some() {
                        Some(vec![Component::Week(-1, false), Component::Weekday(7)])
                    } else {
                        Some(vec![Component::Weekend])
                    }
                },
            ),
            Pattern::with_builder(
                "fr_anchor",
                r"(?i)(?P<guard0>)(?:(?:(?:la\s+)?(?P<wmod1>prochaine|derni[eèÈ]re)\s+semaine|(?:la\s+)?semaine\s+(?P<wmod2>prochaine|suivante|qui\s+vient|derni[eèÈ]re|pass[eéÉ]e|pr[eéÉ]c[eéÉ]dente|en\s+cours|courante)|(?P<wthis>cette\s+semaine))|(?:(?:le\s+)?(?P<mmod1>prochain|dernier)\s+mois|(?:le\s+)?mois\s+(?P<mmod2>prochain|suivant|qui\s+vient|dernier|pass[eéÉ]|pr[eéÉ]c[eéÉ]dent|en\s+cours|courant)|(?P<mthis>ce\s+mois(?:[\s-]+ci)?))|(?:(?:la\s+)?(?P<ymod1>prochaine|derni[eèÈ]re)\s+ann[eéÉ]e|(?:le\s+)?(?P<ymod2>prochain|dernier)\s+an|(?:l['’])?ann[eéÉ]e\s+(?P<ymod3>prochaine|suivante|qui\s+vient|derni[eèÈ]re|pass[eéÉ]e|pr[eéÉ]c[eéÉ]dente|en\s+cours|courante)|(?:l['’])?an\s+(?P<ymod4>prochain|suivant|qui\s+vient|dernier|pass[eéÉ]|pr[eéÉ]c[eéÉ]dent)|(?P<ythis>cette\s+ann[eéÉ]e(?:[\s-]+ci)?|cet\s+an(?:[\s-]+ci)?)))(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let off_from = |s: &str| {
                        let lower = s.to_lowercase();
                        if is_past_modifier(&lower) {
                            -1
                        } else if lower == "courant"
                            || lower == "courante"
                            || lower.starts_with("en")
                        {
                            0
                        } else {
                            1
                        }
                    };
                    if c.name("wthis").is_some() {
                        Some(vec![Component::Week(0, true)])
                    } else if let Some(m) = c.name("wmod1").or_else(|| c.name("wmod2")) {
                        Some(vec![Component::Week(off_from(m.as_str()), true)])
                    } else if c.name("mthis").is_some() {
                        Some(vec![Component::MonthOffset(0)])
                    } else if let Some(m) = c.name("mmod1").or_else(|| c.name("mmod2")) {
                        Some(vec![Component::MonthOffset(off_from(m.as_str()))])
                    } else if c.name("ythis").is_some() {
                        Some(vec![Component::YearOffset(0)])
                    } else {
                        let m = c
                            .name("ymod1")
                            .or_else(|| c.name("ymod2"))
                            .or_else(|| c.name("ymod3"))
                            .or_else(|| c.name("ymod4"))?;
                        Some(vec![Component::YearOffset(off_from(m.as_str()))])
                    }
                },
            ),
            Pattern::with_builder(
                "fr_monthNextLast",
                concat!(
                    "(?i)(?P<guard0>)(?:(?P<pre>prochain|dernier|pass[eéÉ]|pr[eéÉ]c[eéÉ]dent)\\s+(?P<m1>",
                    month_all!(),
                    ")|(?P<m2>",
                    month_all!(),
                    ")\\s+(?P<post>prochain|qui\\s+vient|dernier|pass[eéÉ]|pr[eéÉ]c[eéÉ]dent))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, reference| {
                    let (mod_s, mo_s) = if let Some(pre) = c.name("pre") {
                        (pre.as_str(), c.name("m1")?.as_str())
                    } else {
                        (c.name("post")?.as_str(), c.name("m2")?.as_str())
                    };
                    let mo = parse_fr_month(mo_s)?;
                    let ref_m = reference.month() as i32;
                    let y_off = if is_past_modifier(mod_s) {
                        if mo < ref_m { 0 } else { -1 }
                    } else if mo > ref_m {
                        0
                    } else {
                        1
                    };
                    Some(vec![Component::YearOffset(y_off), Component::Month(mo)])
                },
            ),
            Pattern::with_builder(
                "fr_within",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:d['’]ici(?:\\s+[aàÀ])?|sous|dans\\s+un\\s+d[eéÉ]lai\\s+(?:de\\s+|d['’]\\s*)|en\\s+l['’]espace\\s+(?:de\\s+|d['’]\\s*)|en\\s+moins\\s+(?:de\\s+|d['’]\\s*))\\s*(?P<n1>",
                    num_any!(),
                    ")\\s+(?P<u1>journ[eéÉ]es?|jours?|semaines?)|(?:(?:dans|pendant|durant|sur)\\s+les|au\\s+cours\\s+des)\\s+(?:(?P<n2>",
                    num_any!(),
                    ")\\s+(?:prochain(?:e?s)?|suivant(?:e?s)?)\\s+(?P<u2>journ[eéÉ]es?|jours?|semaines?)|(?:prochain(?:e?s)?|suivant(?:e?s)?)\\s+(?P<n3>",
                    num_any!(),
                    ")\\s+(?P<u3>journ[eéÉ]es?|jours?|semaines?)|(?P<n4>",
                    num_any!(),
                    ")\\s+(?P<u4>journ[eéÉ]es?|jours?|semaines?)\\s+(?:qui\\s+viennent|[aàÀ]\\s+venir|prochain(?:e?s)?|suivant(?:e?s)?)))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let (n_s, u_s) = if let Some(n) = c.name("n1") {
                        (n.as_str(), c.name("u1")?.as_str())
                    } else if let Some(n) = c.name("n2") {
                        (n.as_str(), c.name("u2")?.as_str())
                    } else if let Some(n) = c.name("n3") {
                        (n.as_str(), c.name("u3")?.as_str())
                    } else {
                        (c.name("n4")?.as_str(), c.name("u4")?.as_str())
                    };
                    let mut n = parse_fr_num(n_s)?;
                    if u_s.as_bytes()[0].eq_ignore_ascii_case(&b's') {
                        n = n.checked_mul(7)?;
                    }
                    Some(vec![Component::Within(n)])
                },
            ),
            Pattern::with_builder(
                "fr_offset",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:dans|d['’]ici(?:\\s+[aàÀ])?)\\s+(?P<fn1>",
                    num_any!(),
                    ")\\s+(?P<fu1>journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?)|(?P<fn2>",
                    num_any!(),
                    ")\\s+(?P<fu2>journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?)\\s+(?:plus\\s+tard|apr[eèÈ]s)|il\\s+y\\s+a\\s+(?P<pn1>",
                    num_any!(),
                    ")\\s+(?P<pu1>journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?)|(?P<pn2>",
                    num_any!(),
                    ")\\s+(?P<pu2>journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?)\\s+(?:plus\\s+t[oôÔ]t|auparavant|avant|en\\s+arri[eèÈ]re))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let (neg, n_s, u_s) = if let Some(n) = c.name("fn1") {
                        (false, n.as_str(), c.name("fu1")?.as_str())
                    } else if let Some(n) = c.name("fn2") {
                        (false, n.as_str(), c.name("fu2")?.as_str())
                    } else if let Some(n) = c.name("pn1") {
                        (true, n.as_str(), c.name("pu1")?.as_str())
                    } else {
                        (true, c.name("pn2")?.as_str(), c.name("pu2")?.as_str())
                    };
                    let raw = parse_fr_num(n_s)?;
                    let val = if neg { raw.checked_neg()? } else { raw };
                    Some(vec![parse_fr_offset(val, u_s)?])
                },
            ),
            Pattern::with_builder(
                "fr_dayMonth",
                concat!(
                    "(?i)(?P<guard0>)(?:le\\s+)?(?P<d>",
                    day_part!(),
                    ")(?:\\s+(?:du\\s+mois\\s+(?:de\\s+|d['’]\\s*))?|\\s*[-/]\\s*)(?P<m>",
                    month_all!(),
                    ")(?P<guard1>)(?:(?:\\s*,\\s*|\\s+|[-/])(?P<y>(?:1[0-9]|2[0-9])[0-9]{2})(?P<guard2>)|\\s+(?P<mod>prochain|qui\\s+vient|dernier|pass[eéÉ]|pr[eéÉ]c[eéÉ]dent)(?P<guard3>))?"
                ),
                &[
                    ("guard0", true, FR_ALNUM),
                    ("guard1", false, FR_ALNUM),
                    ("guard2", false, concat!("[:/%€$\\-", fr_chars!(), "]")),
                    ("guard3", false, FR_ALNUM),
                ],
                |c, reference| {
                    let d = parse_fr_day_unbounded(c.name("d")?.as_str())?;
                    if !(1..=31).contains(&d) {
                        return Some(invalid_date_sentinel());
                    }
                    let m = parse_fr_month(c.name("m")?.as_str())?;
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(y_m) = c.name("y") {
                        out.push(Component::Year(crate::number(y_m.as_str())?));
                    } else if let Some(mod_m) = c.name("mod") {
                        let ref_md = (reference.month() as i32, reference.day() as i32);
                        let y_off = if is_past_modifier(mod_m.as_str()) {
                            if (m, d) < ref_md { 0 } else { -1 }
                        } else if (m, d) > ref_md {
                            0
                        } else {
                            1
                        };
                        out.push(Component::YearOffset(y_off));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "fr_monthDay",
                concat!(
                    "(?i)(?P<guard0>)(?P<m>",
                    month_all!(),
                    ")(?:\\s+|[-/])(?P<d>1(?:er|[eèÈ]?re|e)|[0-9]{1,2}(?:i?[eèÈ]me|e)?)(?:(?:\\s*,\\s*|\\s+|[-/])(?P<y>(?:1[0-9]|2[0-9])[0-9]{2})(?P<guard2>)|(?P<guard1>))"
                ),
                &[
                    ("guard0", true, FR_ALNUM),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[:/\\-%€$",
                            fr_chars!(),
                            "]|\\.[0-9]|\\s*(?:heures?|h",
                            word_end!(),
                            "|min(?:utes?)?|sec(?:ondes?)?|journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?|euros?|dollars?|km|kg))"
                        ),
                    ),
                    ("guard2", false, concat!("[:/%€$\\-", fr_chars!(), "]")),
                ],
                |c, _| {
                    let m = parse_fr_month(c.name("m")?.as_str())?;
                    let d = parse_fr_day_unbounded(c.name("d")?.as_str())?;
                    if !(1..=31).contains(&d) {
                        return Some(invalid_date_sentinel());
                    }
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(y_m) = c.name("y") {
                        out.push(Component::Year(crate::number(y_m.as_str())?));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "fr_monthYear",
                concat!(
                    "(?i)(?P<guard0>)(?P<m>",
                    month_all!(),
                    ")(?:\\s+(?:de|en)\\s+(?P<y1>[0-9]{4})|(?:\\s*,\\s*|\\s+)(?P<y2>(?:1[0-9]|2[0-9])[0-9]{2}))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, FR_ALNUM),
                    ("guard1", false, concat!("[:", fr_chars!(), "]")),
                ],
                |c, _| {
                    let m = parse_fr_month(c.name("m")?.as_str())?;
                    let y = crate::number(c.name("y1").or_else(|| c.name("y2"))?.as_str())?;
                    Some(vec![Component::Month(m), Component::Year(y)])
                },
            ),
            Pattern::with_builder(
                "fr_namedYear",
                r"(?i)(?P<guard0>)(?:en|l['’]an(?:n[eéÉ]e)?|ann[eéÉ]e)\s+(?P<y>(?:1[0-9]|2[0-9])[0-9]{2})(?P<guard1>)",
                &[
                    ("guard0", true, FR_ALNUM),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[:/\\-%€$",
                            fr_chars!(),
                            "]|\\.[0-9]|\\s*(?:euros?|dollars?|km|kg|heures?|h",
                            word_end!(),
                            "|min(?:utes?)?|jours?|semaines?|mois|ans?|personnes?|fois))"
                        ),
                    ),
                ],
                |c, _| Some(vec![Component::Year(crate::number(c.name("y")?.as_str())?)]),
            ),
            Pattern::with_builder(
                "fr_numericDate",
                r"(?P<guard0>)(?:(?P<iy>[0-9]{4})[-/.](?P<im>[0-9]{1,2})[-/.](?P<id>[0-9]{1,2})|(?P<sd>[0-9]{1,2})/(?P<sm>[0-9]{1,2})/(?P<sy>[0-9]{2,4})|(?P<dd>[0-9]{1,2})-(?P<dm>[0-9]{1,2})-(?P<dy>[0-9]{2,4})|(?P<pd>[0-9]{1,2})\.(?P<pm>[0-9]{1,2})\.(?P<py>[0-9]{2,4})|(?P<yd>[0-9]{1,2})/(?P<ym>0[1-9]|1[0-2]))(?P<guard1>)",
                &[
                    ("guard0", true, concat!("[./\\-", fr_chars!(), "]")),
                    (
                        "guard1",
                        false,
                        concat!("(?:[:/", fr_chars!(), "]|\\.[0-9]|-[0-9])"),
                    ),
                ],
                |c, _| {
                    if let Some(iy) = c.name("iy") {
                        let y = crate::number(iy.as_str())?;
                        let m = crate::number(c.name("im")?.as_str())?;
                        let d = crate::number(c.name("id")?.as_str())?;
                        Some(vec![
                            Component::Year(y),
                            Component::Month(m),
                            Component::Day(d),
                        ])
                    } else if let Some(yd) = c.name("yd") {
                        let d = crate::number(yd.as_str())?;
                        let m = crate::number(c.name("ym")?.as_str())?;
                        Some(vec![Component::Month(m), Component::Day(d)])
                    } else {
                        let (ds, ms, ys) = if let Some(sd) = c.name("sd") {
                            (sd.as_str(), c.name("sm")?.as_str(), c.name("sy")?.as_str())
                        } else if let Some(dd) = c.name("dd") {
                            (dd.as_str(), c.name("dm")?.as_str(), c.name("dy")?.as_str())
                        } else {
                            (
                                c.name("pd")?.as_str(),
                                c.name("pm")?.as_str(),
                                c.name("py")?.as_str(),
                            )
                        };
                        let y = parse_2_or_4_year(ys)?;
                        let m = crate::number(ms)?;
                        let d = crate::number(ds)?;
                        Some(vec![
                            Component::Year(y),
                            Component::Month(m),
                            Component::Day(d),
                        ])
                    }
                },
            ),
            Pattern::with_builder(
                "fr_timeAmPm",
                r"(?i)(?P<guard0>)(?P<h>[0-9]{1,2})(?::(?P<m>[0-9]{2})(?::(?P<s>[0-9]{2}))?)?\s*(?P<ap>a\.?\s*m\.?|p\.?\s*m\.?)(?P<guard1>)",
                &[("guard0", true, TIME_GUARD0), ("guard1", false, FR_ALNUM)],
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = match c.name("m") {
                        Some(v) => Some(crate::number(v.as_str())?),
                        None => None,
                    };
                    if let Some(sm) = c.name("s")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    let ap = parse_ap(c.name("ap"));
                    if !valid_h_ap(h, ap) {
                        return None;
                    }
                    Some(vec![Component::Time(h, m, ap)])
                },
            ),
            Pattern::with_builder(
                "fr_spokenTime",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:(?:[àÀ]|vers|pour)\\s+)?(?P<base>midi|minuit)\\s+(?:(?P<bkw>et\\s+demie?|et\\s+quart|moins\\s+(?:le\\s+)?quart|pile|pr[eéÉ]cis(?:es)?|juste)|moins\\s+(?P<bsub>",
                    num_1_59!(),
                    ")(?:\\s+minutes?)?|(?P<badd>",
                    num_1_59!(),
                    ")(?:\\s+minutes?)?)|(?:(?:[àÀ]|vers|pour)\\s+)?(?P<h1>",
                    h_0_23!(),
                    ")\\s*(?:heures?|h)\\s+(?:(?P<kw1>et\\s+demie?|et\\s+quart|moins\\s+(?:le\\s+)?quart|pile|pr[eéÉ]cis(?:es)?|juste)|moins\\s+(?P<sub1>",
                    num_1_59!(),
                    ")(?:\\s+minutes?)?|(?P<add1>",
                    num_1_59!(),
                    ")(?:\\s+minutes?)?)(?:\\s*(?P<ap1>a\\.?\\s*m\\.?|p\\.?\\s*m\\.?)|\\s+(?P<mer1>du\\s+matin|de\\s+la\\s+matin[eéÉ]e|de\\s+l['’](?:apr[eèÈ]s[\\s-]+midi|apr[eèÈ]m|aprem)|du\\s+soir|de\\s+la\\s+nuit))?|(?P<h2>",
                    h_0_23!(),
                    ")\\s*(?:heures?|h)(?:\\s*(?P<ap2>a\\.?\\s*m\\.?|p\\.?\\s*m\\.?)|\\s+(?P<mer2>du\\s+matin|de\\s+la\\s+matin[eéÉ]e|de\\s+l['’](?:apr[eèÈ]s[\\s-]+midi|apr[eèÈ]m|aprem)|du\\s+soir|de\\s+la\\s+nuit)))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, TIME_GUARD0),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[",
                            fr_chars!(),
                            "]|\\s+(?:",
                            month_all!(),
                            "|journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?|%|€|\\$))"
                        ),
                    ),
                ],
                |c, _| {
                    if let Some(base) = c.name("base") {
                        let base_h: i32 = if base.as_str().to_lowercase() == "midi" {
                            12
                        } else {
                            0
                        };
                        if let Some(kw) = c.name("bkw") {
                            let l = kw.as_str().to_lowercase();
                            let (h, m) = if l.ends_with("demi") || l.ends_with("demie") {
                                (base_h, 30)
                            } else if l.starts_with("et") {
                                (base_h, 15)
                            } else if l.starts_with("moins") {
                                ((base_h - 1).rem_euclid(24), 45)
                            } else {
                                (base_h, 0)
                            };
                            return Some(vec![Component::Time(h, Some(m), None)]);
                        }
                        if let Some(sub) = c.name("bsub") {
                            let min = parse_fr_num(sub.as_str())?;
                            if !(1..60).contains(&min) {
                                return None;
                            }
                            return Some(vec![Component::Time(
                                (base_h - 1).rem_euclid(24),
                                Some(60 - min),
                                None,
                            )]);
                        }
                        let min = parse_fr_num(c.name("badd")?.as_str())?;
                        if !(0..60).contains(&min) {
                            return None;
                        }
                        return Some(vec![Component::Time(base_h, Some(min), None)]);
                    }
                    if let Some(hs) = c.name("h1") {
                        let h = parse_fr_num(hs.as_str())?;
                        let ap = parse_ap(c.name("ap1"))
                            .or_else(|| c.name("mer1").map(|m| parse_fr_meridiem(m.as_str())));
                        if !valid_h_ap(h, ap) {
                            return None;
                        }
                        if let Some(kw) = c.name("kw1") {
                            let l = kw.as_str().to_lowercase();
                            return Some(vec![if l.ends_with("demi") || l.ends_with("demie") {
                                Component::Time(h, Some(30), ap)
                            } else if l.starts_with("et") {
                                Component::Time(h, Some(15), ap)
                            } else if l.starts_with("moins") {
                                Component::Time((h - 1).rem_euclid(24), Some(45), ap)
                            } else {
                                Component::Time(h, Some(0), ap)
                            }]);
                        }
                        if let Some(sub) = c.name("sub1") {
                            let min = parse_fr_num(sub.as_str())?;
                            if !(1..60).contains(&min) {
                                return None;
                            }
                            return Some(vec![Component::Time(
                                (h - 1).rem_euclid(24),
                                Some(60 - min),
                                ap,
                            )]);
                        }
                        let min = parse_fr_num(c.name("add1")?.as_str())?;
                        if !(0..60).contains(&min) {
                            return None;
                        }
                        return Some(vec![Component::Time(h, Some(min), ap)]);
                    }
                    let h = parse_fr_num(c.name("h2")?.as_str())?;
                    let ap = parse_ap(c.name("ap2"))
                        .or_else(|| c.name("mer2").map(|m| parse_fr_meridiem(m.as_str())));
                    if !valid_h_ap(h, ap) {
                        return None;
                    }
                    Some(vec![Component::Time(h, Some(0), ap)])
                },
            ),
            Pattern::with_builder(
                "fr_timeHmFormat",
                r"(?i)(?P<guard0>)(?:(?P<h1>[0-9]{1,2})\s*h(?P<m1>[0-9]{2})(?P<guard1>)|(?P<h2>[0-9]{1,2})\s*h\s+(?P<m2>[0-9]{2})(?P<guard2>)|(?P<h3>[0-9]{1,2}):(?P<m3>[0-9]{2})(?::(?P<s3>[0-9]{2}))?\s*(?:heures?|hrs?\.?|hs?\.?|h)(?P<guard3>))",
                &[
                    ("guard0", true, TIME_GUARD0),
                    ("guard1", false, concat!("(?:[", fr_chars!(), "]|:[0-9])")),
                    (
                        "guard2",
                        false,
                        concat!(
                            "(?i)(?:[",
                            fr_chars!(),
                            "]|:[0-9]|\\s*(?:",
                            month_all!(),
                            "|journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?|min(?:utes?)?|sec(?:ondes?)?|%|€|\\$))"
                        ),
                    ),
                    ("guard3", false, concat!("(?:[", fr_chars!(), "]|:[0-9])")),
                ],
                |c, _| {
                    if let Some(sm) = c.name("s3")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    let (hs, ms) = if let Some(h1) = c.name("h1") {
                        (h1.as_str(), c.name("m1")?.as_str())
                    } else if let Some(h2) = c.name("h2") {
                        (h2.as_str(), c.name("m2")?.as_str())
                    } else {
                        (c.name("h3")?.as_str(), c.name("m3")?.as_str())
                    };
                    Some(vec![Component::Time(
                        crate::number(hs)?,
                        Some(crate::number(ms)?),
                        None,
                    )])
                },
            ),
            Pattern::with_builder(
                "fr_timeHFormat",
                r"(?i)(?P<guard0>)(?P<h>[0-9]{1,2})\s*h(?P<guard1>)",
                &[
                    ("guard0", true, TIME_GUARD0),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[",
                            fr_chars!(),
                            "]|:[0-9]|\\s*(?:de\\s+(?:vol|route|trajet|marche|sommeil|travail|cours|attente|retard|avance)|par\\s+(?:jour|semaine|mois|an)|plus\\s+(?:tard|t[oôÔ]t)|avant|apr[eèÈ]s|auparavant|d['’]affil[eéÉ]e|minimum|maximum|min|max)",
                            word_end!(),
                            ")"
                        ),
                    ),
                ],
                |c, _| {
                    Some(vec![Component::Time(
                        crate::number(c.name("h")?.as_str())?,
                        Some(0),
                        None,
                    )])
                },
            ),
            Pattern::with_builder(
                "fr_aHour",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:[àÀ]|vers|pour)\\s+)?(?P<h>",
                    h_0_23!(),
                    ")\\s+heures?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, FR_ALNUM),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[:%€$",
                            fr_chars!(),
                            "]|\\.[0-9]|\\s*(?:[0-9]{1,2}|",
                            num_1_59!(),
                            "|a\\.?\\s*m\\.?|p\\.?\\s*m\\.?|et\\s+demie?|et\\s+quart|moins|pile|pr[eéÉ]cis(?:es)?|juste|du\\s+matin|de\\s+la\\s+matin[eéÉ]e|de\\s+l['’]|du\\s+soir|de\\s+la\\s+nuit|de\\s+(?:route|vol|trajet|marche|train|voiture|bus|bateau|avion|chemin|distance|ici)|d['’]ici|plus\\s+(?:tard|t[oôÔ]t)|avant|apr[eèÈ]s|d['’]intervalle|journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?|minutes?|secondes?|personnes?|fois|km|kg|euros?|dollars?))"
                        ),
                    ),
                ],
                |c, _| {
                    let h = parse_fr_num(c.name("h")?.as_str())?;
                    (0..24)
                        .contains(&h)
                        .then(|| vec![Component::Time(h, Some(0), None)])
                },
            ),
            Pattern::with_builder(
                "fr_hmsTime",
                r"(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<m>[0-9]{2}):(?P<s>[0-9]{2})(?P<guard1>)",
                &[
                    ("guard0", true, concat!("[:", fr_chars!(), "]")),
                    ("guard1", false, concat!("[:", fr_chars!(), "]")),
                ],
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = crate::number(c.name("m")?.as_str())?;
                    let s = crate::number(c.name("s")?.as_str())?;
                    (0..60)
                        .contains(&s)
                        .then(|| vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::new("fr_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
            Pattern::new(
                "fr_fixedTime",
                r"(?i)(?P<guard0>)(minuit|midi)(?P<guard1>)",
                &[
                    ("guard0", true, concat!("[-", fr_chars!(), "]")),
                    ("guard1", false, FR_ALNUM),
                ],
                &[
                    ("midi", &[Component::Time(12, Some(0), None)]),
                    ("minuit", &[Component::Time(0, Some(0), None)]),
                ],
            ),
            Pattern::with_builder(
                "fr_meridiem",
                r"(?i)(?P<guard0>)(?:(?:du|le|au)\s+(?P<m1>matin|soir)|(?:dans|de)\s+la\s+(?P<m2>matin[eéÉ]e|soir[eéÉ]e|nuit)|(?:(?:de|dans)\s+l['’]\s*|l['’]\s*)?(?P<m3>apr[eèÈ]s[\s-]+midi|apr[eèÈ]m|aprem)|(?P<m4>matin|soir))(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let s = c
                        .name("m1")
                        .or_else(|| c.name("m2"))
                        .or_else(|| c.name("m3"))
                        .or_else(|| c.name("m4"))?
                        .as_str();
                    Some(vec![Component::Meridiem(parse_fr_meridiem(s))])
                },
            ),
            Pattern::with_builder(
                "fr_leJour",
                r"(?i)(?P<guard0>)(?:le\s+(?:jour\s+)?(?P<d1>1(?:er|[eèÈ]?re|e)|premier|premi[eèÈ]re|[0-9]{1,2}(?:i?[eèÈ]me|e)?)|(?P<d2>1(?:er|[eèÈ]?re)|(?:[2-9]|[12][0-9]|3[01])(?:i?[eèÈ]me|e)))(?P<guard1>)",
                &[
                    ("guard0", true, FR_ALNUM),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[:/\\-+%€$",
                            fr_chars!(),
                            "]|\\.[0-9]|\\s*(?:",
                            month_all!(),
                            "|",
                            wd_full!(),
                            "|heures?|h",
                            word_end!(),
                            "|min(?:utes?)?|sec(?:ondes?)?|journ[eéÉ]es?|jours?|semaines?|mois|ann[eéÉ]es?|ans?|euros?|dollars?|km|kg|fois|tour|si[eèÈ]cle|arrondissement|[eéÉ]tage|trimestre|semestre|rang|chapitre|tome|volume|acte|[eéÉ]pisode|niveau|degr[eéÉ]s?|place|prix|choix|cas|pas|point|nom|mot|lieu|plan|guerre|r[eéÉ]publique|ligne|article|classe)",
                            word_end!(),
                            ")"
                        ),
                    ),
                ],
                |c, _| {
                    let raw = c.name("d1").or_else(|| c.name("d2"))?.as_str();
                    Some(vec![Component::Day(parse_fr_day(raw)?)])
                },
            ),
            Pattern::new(
                "fr_weekday",
                r"(?i)(?P<guard0>)(mercredi|vendredi|dimanche|lundi|mardi|jeudi|samedi|mercr\.?|merc\.?|vend\.?|jeud\.?|lun\.|mar\.|mer\.|jeu\.|ven\.|sam\.|dim\.)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("lundi", &[Component::Weekday(1)]),
                    ("lun.", &[Component::Weekday(1)]),
                    ("mardi", &[Component::Weekday(2)]),
                    ("mar.", &[Component::Weekday(2)]),
                    ("mercredi", &[Component::Weekday(3)]),
                    ("mercr.", &[Component::Weekday(3)]),
                    ("mercr", &[Component::Weekday(3)]),
                    ("merc.", &[Component::Weekday(3)]),
                    ("merc", &[Component::Weekday(3)]),
                    ("mer.", &[Component::Weekday(3)]),
                    ("jeudi", &[Component::Weekday(4)]),
                    ("jeud.", &[Component::Weekday(4)]),
                    ("jeud", &[Component::Weekday(4)]),
                    ("jeu.", &[Component::Weekday(4)]),
                    ("vendredi", &[Component::Weekday(5)]),
                    ("vend.", &[Component::Weekday(5)]),
                    ("vend", &[Component::Weekday(5)]),
                    ("ven.", &[Component::Weekday(5)]),
                    ("samedi", &[Component::Weekday(6)]),
                    ("sam.", &[Component::Weekday(6)]),
                    ("dimanche", &[Component::Weekday(7)]),
                    ("dim.", &[Component::Weekday(7)]),
                ],
            ),
            Pattern::new(
                "fr_month",
                r"(?i)(?P<guard0>)(septembre|d[eéÉ]cembre|novembre|f[eéÉ]vrier|janvier|octobre|juillet|avril|ao[uûÛ]t|mars|juin|mai|juill\.?|sept\.?|janv\.?|f[eéÉ]vr\.?|juil\.?|f[eéÉ]v\.?|jan\.|avr\.?|sep\.?|oct\.?|nov\.?|d[eéÉ]c\.?)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("janvier", &[Component::Month(1)]),
                    ("janv.", &[Component::Month(1)]),
                    ("janv", &[Component::Month(1)]),
                    ("jan.", &[Component::Month(1)]),
                    ("février", &[Component::Month(2)]),
                    ("fevrier", &[Component::Month(2)]),
                    ("févr.", &[Component::Month(2)]),
                    ("févr", &[Component::Month(2)]),
                    ("fevr.", &[Component::Month(2)]),
                    ("fevr", &[Component::Month(2)]),
                    ("fév.", &[Component::Month(2)]),
                    ("fév", &[Component::Month(2)]),
                    ("fev.", &[Component::Month(2)]),
                    ("fev", &[Component::Month(2)]),
                    ("mars", &[Component::Month(3)]),
                    ("avril", &[Component::Month(4)]),
                    ("avr.", &[Component::Month(4)]),
                    ("avr", &[Component::Month(4)]),
                    ("mai", &[Component::Month(5)]),
                    ("juin", &[Component::Month(6)]),
                    ("juillet", &[Component::Month(7)]),
                    ("juill.", &[Component::Month(7)]),
                    ("juill", &[Component::Month(7)]),
                    ("juil.", &[Component::Month(7)]),
                    ("juil", &[Component::Month(7)]),
                    ("août", &[Component::Month(8)]),
                    ("aout", &[Component::Month(8)]),
                    ("septembre", &[Component::Month(9)]),
                    ("sept.", &[Component::Month(9)]),
                    ("sept", &[Component::Month(9)]),
                    ("sep.", &[Component::Month(9)]),
                    ("sep", &[Component::Month(9)]),
                    ("octobre", &[Component::Month(10)]),
                    ("oct.", &[Component::Month(10)]),
                    ("oct", &[Component::Month(10)]),
                    ("novembre", &[Component::Month(11)]),
                    ("nov.", &[Component::Month(11)]),
                    ("nov", &[Component::Month(11)]),
                    ("décembre", &[Component::Month(12)]),
                    ("decembre", &[Component::Month(12)]),
                    ("déc.", &[Component::Month(12)]),
                    ("déc", &[Component::Month(12)]),
                    ("dec.", &[Component::Month(12)]),
                    ("dec", &[Component::Month(12)]),
                ],
            ),
        ],
    )
}

use crate::{Capture, Component, Language, Pattern};

macro_rules! pt_chars {
    () => {
        "a-zA-Z0-9À-ÖØ-öø-ÿ"
    };
}

macro_rules! word_end {
    () => {
        "(?:[^a-zA-Z0-9À-ÖØ-öø-ÿ]|$)"
    };
}

macro_rules! month_comp_all {
    () => {
        "setembro|fevereiro|novembro|dezembro|janeiro|outubro|agosto|mar[cçÇ]o|abril|junho|julho|maio|jan\\.?|fev\\.?|mar\\.?|abr\\.?|mai\\.?|jun\\.?|jul\\.?|ago\\.?|set\\.?|out\\.?|nov\\.?|dez\\.?"
    };
}

macro_rules! wd_comp {
    () => {
        "segundas[-\\s]+feiras|segunda[-\\s]+feira|segunda|ter[cçÇ]as[-\\s]+feiras|ter[cçÇ]a[-\\s]+feira|ter[cçÇ]a|quartas[-\\s]+feiras|quarta[-\\s]+feira|quarta|quintas[-\\s]+feiras|quinta[-\\s]+feira|quinta|sextas[-\\s]+feiras|sexta[-\\s]+feira|sexta|s[aáÁ]bado|domingo|2[ªaA][-\\s]+feira|3[ªaA][-\\s]+feira|4[ªaA][-\\s]+feira|5[ªaA][-\\s]+feira|6[ªaA][-\\s]+feira|seg\\.?|ter\\.?|qua\\.?|qui\\.?|sex\\.?|s[aáÁ]b\\.?|dom\\.?"
    };
}

macro_rules! num_any {
    () => {
        "(?:[0-9]+|(?:cinq[uüÜ]enta|quarenta|sessenta|oitenta|noventa|setenta|trinta|vinte)(?:\\s+e\\s+(?:uma?|dois|duas|tr[eêÊ]s|quatro|cinco|seis|sete|oito|nove))?|dez[ae]sseis|dez[ae]ssete|dez[ae]nove|quatorze|catorze|dezoito|quinze|cento|onze|doze|treze|cem|dez|uma?|dois|duas|tr[eêÊ]s|quatro|cinco|seis|sete|oito|nove)"
    };
}

macro_rules! num_1_59 {
    () => {
        "(?:[0-9]{1,2}|(?:cinq[uüÜ]enta|quarenta|trinta|vinte)(?:\\s+e\\s+(?:uma?|dois|duas|tr[eêÊ]s|quatro|cinco|seis|sete|oito|nove))?|dez[ae]sseis|dez[ae]ssete|dez[ae]nove|quatorze|catorze|dezoito|quinze|onze|doze|treze|dez|uma?|dois|duas|tr[eêÊ]s|quatro|cinco|seis|sete|oito|nove)"
    };
}

macro_rules! hour_0_23 {
    () => {
        "(?:[0-9]{1,2}|vinte(?:\\s+e\\s+(?:uma?|dois|duas|tr[eêÊ]s))?|dez[ae]sseis|dez[ae]ssete|dez[ae]nove|quatorze|catorze|dezoito|quinze|onze|doze|treze|dez|uma?|dois|duas|tr[eêÊ]s|quatro|cinco|seis|sete|oito|nove|zero)"
    };
}

macro_rules! day_part {
    () => {
        "(?:[0-9]{1,2}[ºª°]?|primeir[oa]|trinta(?:\\s+e\\s+uma?)?|vinte(?:\\s+e\\s+(?:uma?|dois|duas|tr[eêÊ]s|quatro|cinco|seis|sete|oito|nove))?|dez[ae]sseis|dez[ae]ssete|dez[ae]nove|quatorze|catorze|dezoito|quinze|onze|doze|treze|dez|dois|duas|tr[eêÊ]s|quatro|cinco|seis|sete|oito|nove)"
    };
}

macro_rules! unit_guard_words {
    () => {
        "horas?|minutos?|min(?:\\.|[^a-zA-Z0-9À-ÖØ-öø-ÿ]|$)|segundos?|seg(?:\\.|[^a-zA-Z0-9À-ÖØ-öø-ÿ]|$)|dias?|semanas?|m[eêÊ]s|meses|anos?|km|kg|metros?|litros?|vezes|pessoas?|crian[cçÇ]as?|itens|coisas|reais|euros?|d[oóÓ]lares?|por\\s+cento|%"
    };
}

const PT_ALNUM: &str = concat!("[", pt_chars!(), "]");
const TIME_GUARD0: &str = concat!("[.:/\\-", pt_chars!(), "]");

fn pt_word_num(w: &str) -> Option<i32> {
    Some(match w {
        "zero" => 0,
        "um" | "uma" | "primeiro" | "primeira" => 1,
        "dois" | "duas" => 2,
        "três" | "tres" => 3,
        "quatro" => 4,
        "cinco" => 5,
        "seis" => 6,
        "sete" => 7,
        "oito" => 8,
        "nove" => 9,
        "dez" => 10,
        "onze" => 11,
        "doze" => 12,
        "treze" => 13,
        "catorze" | "quatorze" => 14,
        "quinze" => 15,
        "dezesseis" | "dezasseis" => 16,
        "dezessete" | "dezassete" => 17,
        "dezoito" => 18,
        "dezenove" | "dezanove" => 19,
        "vinte" => 20,
        "trinta" => 30,
        "quarenta" => 40,
        "cinquenta" | "cinqüenta" => 50,
        "sessenta" => 60,
        "setenta" => 70,
        "oitenta" => 80,
        "noventa" => 90,
        "cem" | "cento" => 100,
        _ => return None,
    })
}

fn parse_pt_num(s: &str) -> Option<i32> {
    if let Some(n) = crate::number(s) {
        return Some(n);
    }
    let lower = s.to_lowercase();
    let mut it = lower.split_whitespace();
    let first = it.next()?;
    match it.next() {
        None => pt_word_num(first),
        Some("e") => {
            let third = it.next()?;
            if it.next().is_some() {
                return None;
            }
            pt_word_num(first)?.checked_add(pt_word_num(third)?)
        }
        _ => None,
    }
}

fn parse_pt_day_unbounded(s: &str) -> Option<i32> {
    if s.as_bytes().first().is_some_and(u8::is_ascii_digit) {
        let trimmed = s.trim_end_matches(|c: char| matches!(c, 'º' | 'ª' | '°'));
        crate::number(trimmed)
    } else {
        parse_pt_num(s)
    }
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

fn parse_pt_month(s: &str) -> Option<i32> {
    let lower = s.trim_end_matches('.').to_lowercase();
    Some(match lower.as_str() {
        "janeiro" | "jan" => 1,
        "fevereiro" | "fev" => 2,
        "março" | "marco" | "mar" => 3,
        "abril" | "abr" => 4,
        "maio" | "mai" => 5,
        "junho" | "jun" => 6,
        "julho" | "jul" => 7,
        "agosto" | "ago" => 8,
        "setembro" | "set" => 9,
        "outubro" | "out" => 10,
        "novembro" | "nov" => 11,
        "dezembro" | "dez" => 12,
        _ => return None,
    })
}

fn parse_pt_weekday(s: &str) -> Option<i32> {
    let lower = s.trim_end_matches('.').to_lowercase();
    let head = lower
        .split(|c: char| c == '-' || c.is_whitespace())
        .next()?;
    Some(match head {
        "segunda" | "segundas" | "seg" | "2ª" | "2a" => 1,
        "terça" | "terca" | "terças" | "tercas" | "ter" | "3ª" | "3a" => 2,
        "quarta" | "quartas" | "qua" | "4ª" | "4a" => 3,
        "quinta" | "quintas" | "qui" | "5ª" | "5a" => 4,
        "sexta" | "sextas" | "sex" | "6ª" | "6a" => 5,
        "sábado" | "sabado" | "sáb" | "sab" => 6,
        "domingo" | "dom" => 7,
        _ => return None,
    })
}

fn parse_pt_ord(s: &str) -> Option<i32> {
    Some(match s.to_lowercase().as_str() {
        "1º" | "1ª" | "1°" | "primeiro" | "primeira" => 1,
        "2º" | "2ª" | "2°" | "segundo" | "segunda" => 2,
        "3º" | "3ª" | "3°" | "terceiro" | "terceira" => 3,
        "4º" | "4ª" | "4°" | "quarto" | "quarta" => 4,
        "5º" | "5ª" | "5°" | "quinto" | "quinta" => 5,
        "último" | "ultimo" | "última" | "ultima" => -1,
        _ => return None,
    })
}

fn parse_pt_offset(value: i32, unit: &str) -> Option<Component> {
    let lower = unit.to_lowercase();
    if lower.starts_with('d') {
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

fn parse_pt_meridiem(s: &str) -> bool {
    let lower = s.to_lowercase();
    lower.contains("tarde") || lower.contains("noite")
}

fn is_pt_night(s: &str) -> bool {
    let lower = s.to_lowercase();
    lower.contains("noite") || lower.contains("madrugada")
}

fn is_past_mod(s: &str) -> bool {
    let lower = s.to_lowercase();
    lower.contains("passad")
        || lower.contains("últim")
        || lower.contains("ultim")
        || lower.contains("anterior")
}

fn is_this_mod(s: &str) -> bool {
    let lower = s.to_lowercase();
    lower.starts_with("est")
        || lower.starts_with("ess")
        || lower.starts_with("nest")
        || lower.starts_with("ness")
        || lower.starts_with("dest")
        || lower.starts_with("dess")
        || lower == "atual"
        || lower == "corrente"
}

fn is_padded_or_24h(raw: &str, h: i32) -> bool {
    h == 0 || h >= 13 || (raw.len() == 2 && raw.bytes().all(|b| b.is_ascii_digit()))
}

fn valid_h_meridiem(h: i32, pm: Option<bool>) -> bool {
    match pm {
        Some(true) => (1..=23).contains(&h),
        Some(false) => (0..=12).contains(&h),
        None => (0..24).contains(&h),
    }
}

pub fn language() -> Language {
    let alnum_guards = [("guard0", true, PT_ALNUM), ("guard1", false, PT_ALNUM)];

    Language::new(
        "pt",
        r"(?i)(?:[\s,]+|(?:[àÀ]s?|[aA]os?|[aA]s|d[aeo]s?|em|n[aeo]s?|para(?:\s+[ao]s?)?|pras?|pel[aeo]s?|por(?:\s+volta\s+d[aeo]s?)?|cerca\s+d[aeo]s?)(?:\s+|,|$))+",
        vec![
            Pattern::with_builder(
                "pt_partOfDay",
                r"(?i)(?P<guard0>)(?:(?P<rel>depois\s+de\s+amanh[aãÃ]|antes\s+de\s+ontem|ante[-\s]?ontem|amanh[aãÃ]|ontem|hoje)\s+(?P<pod>(?:de|pela|na)\s+manh[aãÃ]|(?:de|pela|na)\s+madrugada|(?:[aàÀ]|de|pela|na)\s+tarde|(?:[aàÀ]|de|pela|na)\s+noite)|(?P<est>[dn]?est[ae]|[dn]?ess[ae])\s+(?P<epod>manh[aãÃ]|madrugada|tarde|noite))(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    if let Some(rel) = c.name("rel") {
                        let r = rel.as_str().to_lowercase();
                        let day = if r.starts_with("depois") {
                            2
                        } else if r.starts_with("ante") {
                            -2
                        } else if r.starts_with("amanh") {
                            1
                        } else if r == "ontem" {
                            -1
                        } else {
                            0
                        };
                        let pod = c.name("pod")?.as_str();
                        return Some(vec![
                            Component::RelativeDay(day),
                            Component::Meridiem(parse_pt_meridiem(pod)),
                        ]);
                    }
                    let _ = c.name("est")?;
                    let pod = c.name("epod")?.as_str();
                    Some(vec![
                        Component::RelativeDay(0),
                        Component::Meridiem(parse_pt_meridiem(pod)),
                    ])
                },
            ),
            Pattern::with_builder(
                "pt_relativeDayPhrase",
                r"(?i)(?P<guard0>)(?P<rel>depois\s+de\s+amanh[aãÃ]|antes\s+de\s+ontem|tr[aáÁ]s[-\s]?anteontem|ante[-\s]+ontem)(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let lower = c.name("rel")?.as_str().to_lowercase();
                    let offset = if lower.starts_with("depois") {
                        2
                    } else if lower.starts_with("tr") {
                        -3
                    } else {
                        -2
                    };
                    Some(vec![Component::RelativeDay(offset)])
                },
            ),
            Pattern::new(
                "pt_relativeDay",
                r"(?i)(?P<guard0>)(depois de amanh[aãÃ]|antes de ontem|tr[aáÁ]s-?anteontem|ante-?ontem|amanh[aãÃ]|ontem|hoje)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("hoje", &[Component::RelativeDay(0)]),
                    ("amanhã", &[Component::RelativeDay(1)]),
                    ("amanha", &[Component::RelativeDay(1)]),
                    ("depois de amanhã", &[Component::RelativeDay(2)]),
                    ("depois de amanha", &[Component::RelativeDay(2)]),
                    ("ontem", &[Component::RelativeDay(-1)]),
                    ("anteontem", &[Component::RelativeDay(-2)]),
                    ("ante-ontem", &[Component::RelativeDay(-2)]),
                    ("antes de ontem", &[Component::RelativeDay(-2)]),
                    ("trás-anteontem", &[Component::RelativeDay(-3)]),
                    ("tras-anteontem", &[Component::RelativeDay(-3)]),
                    ("trásanteontem", &[Component::RelativeDay(-3)]),
                    ("trasanteontem", &[Component::RelativeDay(-3)]),
                ],
            ),
            Pattern::with_builder(
                "pt_nthWeekday",
                concat!(
                    "(?i)(?P<guard0>)(?:[oa]\\s+)?(?P<ord>1[ºª°]|primeir[oa]|2[ºª°]|segund[oa]|3[ºª°]|terceir[oa]|4[ºª°]|quart[oa]|5[ºª°]|quint[oa]|[uúÚ]ltim[oa])\\s+(?P<wd>",
                    wd_comp!(),
                    ")\\s+(?:do\\s+m[eêÊ]s\\s+de|de|em)\\s+(?P<mo>",
                    month_comp_all!(),
                    ")(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let ord = parse_pt_ord(c.name("ord")?.as_str())?;
                    let wd = parse_pt_weekday(c.name("wd")?.as_str())?;
                    let mo = parse_pt_month(c.name("mo")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, mo)])
                },
            ),
            Pattern::with_builder(
                "pt_nextLastWeekday",
                concat!(
                    "(?i)(?P<guard0>)(?:(?P<wd_w>",
                    wd_comp!(),
                    ")\\s+(?:(?:d[ae]\\s+)?(?P<wmod>pr[oóÓ]xima\\s+semana|semana\\s+(?:que\\s+vem|pr[oóÓ]xima|seguinte|passada|anterior|atual|corrente)|(?:passada|[uúÚ]ltima)\\s+semana)|(?P<wthis>[dn]?est[ae]\\s+semana|[dn]?ess[ae]\\s+semana))|(?P<post_wd>",
                    wd_comp!(),
                    ")\\s+(?P<post_mod>pr[oóÓ]xim[oa]|que\\s+vem|seguinte|passad[oa]|anterior)|(?P<pre_mod>pr[oóÓ]xim[oa]|seguinte|[dn]?est[ae]|[dn]?ess[ae]|passad[oa]|[uúÚ]ltim[oa]|anterior)\\s+(?P<pre_wd>",
                    wd_comp!(),
                    "))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    if let Some(wd_w) = c.name("wd_w") {
                        let wd = parse_pt_weekday(wd_w.as_str())?;
                        let off = if c.name("wthis").is_some() {
                            0
                        } else {
                            let wmod = c.name("wmod")?.as_str().to_lowercase();
                            if is_past_mod(&wmod) {
                                -1
                            } else if wmod.contains("atual") || wmod.contains("corrente") {
                                0
                            } else {
                                1
                            }
                        };
                        return Some(vec![Component::Week(off, true), Component::Weekday(wd)]);
                    }
                    let (mod_s, wd_s) = if let Some(m) = c.name("post_mod") {
                        (m.as_str(), c.name("post_wd")?.as_str())
                    } else {
                        (c.name("pre_mod")?.as_str(), c.name("pre_wd")?.as_str())
                    };
                    let wd = parse_pt_weekday(wd_s)?;
                    if is_this_mod(mod_s) {
                        return Some(vec![Component::Weekday(wd)]);
                    }
                    let off = if is_past_mod(mod_s) { -1 } else { 1 };
                    Some(vec![Component::Week(off, false), Component::Weekday(wd)])
                },
            ),
            Pattern::with_builder(
                "pt_weekend",
                r"(?i)(?P<guard0>)(?:(?P<past>(?:passad[oa]|[uúÚ]ltim[oa]|anterior)\s+(?:fim[-\s]+de[-\s]+semana|final\s+de\s+semana)|(?:fim[-\s]+de[-\s]+semana|final\s+de\s+semana)\s+(?:retrasad[oa]|passad[oa]|anterior))|(?P<next>(?:(?:[dn]?est[ae]|[dn]?ess[ae]|pr[oóÓ]xim[oa]|seguinte)\s+)?(?:fim[-\s]+de[-\s]+semana|final\s+de\s+semana)(?:\s+(?:que\s+vem|pr[oóÓ]xim[oa]|seguinte))?))(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    if let Some(p) = c.name("past") {
                        let off = if p.as_str().to_lowercase().contains("retrasad") {
                            -2
                        } else {
                            -1
                        };
                        Some(vec![Component::Week(off, false), Component::Weekday(7)])
                    } else {
                        Some(vec![Component::Weekend])
                    }
                },
            ),
            Pattern::with_builder(
                "pt_doubleAnchor",
                r"(?i)(?P<guard0>)(?:(?P<w>semana\s+retrasada)|(?P<m>m[eêÊ]s\s+retrasado)|(?P<y>ano\s+retrasado))(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    Some(vec![if c.name("w").is_some() {
                        Component::Week(-2, true)
                    } else if c.name("m").is_some() {
                        Component::MonthOffset(-2)
                    } else {
                        Component::YearOffset(-2)
                    }])
                },
            ),
            Pattern::with_builder(
                "pt_anchor",
                r"(?i)(?P<guard0>)(?:(?:(?P<wmod1>pr[oóÓ]xima|seguinte|passada|[uúÚ]ltima)\s+semana|semana\s+(?P<wmod2>que\s+vem|pr[oóÓ]xima|seguinte|passada|anterior|atual|corrente)|(?P<wthis>(?:[dn]?est[ae]|[dn]?ess[ae])\s+semana))|(?:(?P<mmod1>pr[oóÓ]xim[oa]|seguinte|passado|[uúÚ]ltimo)\s+m[eêÊ]s|m[eêÊ]s\s+(?P<mmod2>que\s+vem|pr[oóÓ]ximo|seguinte|passado|anterior|atual|corrente)|(?P<mthis>(?:[dn]?este|[dn]?esse)\s+m[eêÊ]s))|(?:(?P<ymod1>pr[oóÓ]ximo|seguinte|passado|[uúÚ]ltimo)\s+ano|ano\s+(?P<ymod2>que\s+vem|pr[oóÓ]ximo|seguinte|passado|anterior|atual|corrente)|(?P<ythis>(?:[dn]?este|[dn]?esse)\s+ano)))(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let off_from = |s: &str| {
                        let lower = s.to_lowercase();
                        if is_past_mod(&lower) {
                            -1
                        } else if lower == "atual" || lower == "corrente" {
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
                        let m = c.name("ymod1").or_else(|| c.name("ymod2"))?;
                        Some(vec![Component::YearOffset(off_from(m.as_str()))])
                    }
                },
            ),
            Pattern::with_builder(
                "pt_monthNextLast",
                concat!(
                    "(?i)(?P<guard0>)(?:(?P<pre>pr[oóÓ]ximo|seguinte|passado|[uúÚ]ltimo|anterior)\\s+(?P<m1>",
                    month_comp_all!(),
                    ")|(?P<m2>",
                    month_comp_all!(),
                    ")\\s+(?P<post>que\\s+vem|pr[oóÓ]ximo|seguinte|passado|anterior))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, reference| {
                    let (mod_s, mo_s) = if let Some(pre) = c.name("pre") {
                        (pre.as_str(), c.name("m1")?.as_str())
                    } else {
                        (c.name("post")?.as_str(), c.name("m2")?.as_str())
                    };
                    let mo = parse_pt_month(mo_s)?;
                    let ref_m = reference.month() as i32;
                    let y_off = if is_past_mod(mod_s) {
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
                "pt_within",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:nos|durante\\s+os|pelos|para\\s+os|dentro\\s+dos|ao\\s+longo\\s+dos)\\s+(?:pr[oóÓ]ximos|seguintes)\\s+(?P<n1>",
                    num_any!(),
                    ")\\s+(?P<u1>dias?)|(?:nas|durante\\s+as|pelas|para\\s+as|dentro\\s+das|ao\\s+longo\\s+das)\\s+(?:pr[oóÓ]ximas|seguintes)\\s+(?P<n2>",
                    num_any!(),
                    ")\\s+(?P<u2>semanas?)|(?:no\\s+prazo\\s+de|em\\s+(?:um\\s+)?prazo\\s+de|num\\s+prazo\\s+de|dentro\\s+(?:de\\s+um|do)\\s+prazo\\s+de|em\\s+at[eéÉ]|dentro\\s+de\\s+at[eéÉ]|em)\\s+(?P<n3>",
                    num_any!(),
                    ")\\s+(?P<u3>dias?|semanas?))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let (n_s, u_s) = if let Some(n) = c.name("n1") {
                        (n.as_str(), c.name("u1")?.as_str())
                    } else if let Some(n) = c.name("n2") {
                        (n.as_str(), c.name("u2")?.as_str())
                    } else {
                        (c.name("n3")?.as_str(), c.name("u3")?.as_str())
                    };
                    let mut n = parse_pt_num(n_s)?;
                    if u_s.as_bytes()[0].eq_ignore_ascii_case(&b's') {
                        n = n.checked_mul(7)?;
                    }
                    Some(vec![Component::Within(n)])
                },
            ),
            Pattern::with_builder(
                "pt_offset",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:h[aáÁ]|faz(?:em)?)\\s+(?P<pn0>",
                    num_any!(),
                    ")\\s+(?P<pu0>dias?|semanas?|meses|m[eêÊ]s|anos?)\\s+atr[aáÁ]s|(?:daqui\\s+(?:a\\s+)?|de\\s+hoje\\s+a\\s+|dentro\\s+de\\s+)(?P<fn1>",
                    num_any!(),
                    ")\\s+(?P<fu1>dias?|semanas?|meses|m[eêÊ]s|anos?)|em\\s+(?P<fn3>",
                    num_any!(),
                    ")\\s+(?P<fu3>meses|m[eêÊ]s|anos?)|(?P<fn2>",
                    num_any!(),
                    ")\\s+(?P<fu2>dias?|semanas?|meses|m[eêÊ]s|anos?)\\s+(?:depois|mais\\s+tarde|a\\s+partir\\s+de\\s+agora|[aàÀ]\\s+frente|adiante)|(?:h[aáÁ]|faz(?:em)?)\\s+(?P<pn1>",
                    num_any!(),
                    ")\\s+(?P<pu1>dias?|semanas?|meses|m[eêÊ]s|anos?)|(?P<pn2>",
                    num_any!(),
                    ")\\s+(?P<pu2>dias?|semanas?|meses|m[eêÊ]s|anos?)\\s+(?:atr[aáÁ]s|antes|mais\\s+cedo))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let (neg, n_s, u_s) = if let Some(n) = c.name("pn0") {
                        (true, n.as_str(), c.name("pu0")?.as_str())
                    } else if let Some(n) = c.name("fn1") {
                        (false, n.as_str(), c.name("fu1")?.as_str())
                    } else if let Some(n) = c.name("fn3") {
                        (false, n.as_str(), c.name("fu3")?.as_str())
                    } else if let Some(n) = c.name("fn2") {
                        (false, n.as_str(), c.name("fu2")?.as_str())
                    } else if let Some(n) = c.name("pn1") {
                        (true, n.as_str(), c.name("pu1")?.as_str())
                    } else {
                        (true, c.name("pn2")?.as_str(), c.name("pu2")?.as_str())
                    };
                    let raw = parse_pt_num(n_s)?;
                    let val = if neg { raw.checked_neg()? } else { raw };
                    Some(vec![parse_pt_offset(val, u_s)?])
                },
            ),
            Pattern::with_builder(
                "pt_dayMonth",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:o\\s+)?dia\\s+)?(?P<d>",
                    day_part!(),
                    ")(?:\\s+de\\s+(?P<m1>",
                    month_comp_all!(),
                    ")(?P<g_m1>)(?:(?:\\s+de\\s+(?P<y1>[0-9]{4})|(?:\\s*,\\s*|\\s+)(?P<y2>(?:19|20|21)[0-9]{2}))(?P<g_y1>)|\\s+(?P<mod1>pr[oóÓ]xim[oa]|que\\s+vem|seguinte|passad[oa]|[uúÚ]ltim[oa]|anterior)(?P<g_mod1>))?|(?:\\s*[-/]\\s*(?P<m2>",
                    month_comp_all!(),
                    ")|\\s+(?P<m3>",
                    month_comp_all!(),
                    "))(?P<g_m2>)(?:(?:\\s+de\\s+(?P<y3>[0-9]{4})|(?:\\s*,\\s*|\\s+|[-/])(?P<y4>(?:19|20|21)[0-9]{2}))(?P<g_y2>)|\\s+(?P<mod2>pr[oóÓ]xim[oa]|que\\s+vem|seguinte|passad[oa]|[uúÚ]ltim[oa]|anterior)(?P<g_mod2>))?)"
                ),
                &[
                    ("guard0", true, PT_ALNUM),
                    ("g_m1", false, PT_ALNUM),
                    ("g_m2", false, PT_ALNUM),
                    ("g_mod1", false, PT_ALNUM),
                    ("g_mod2", false, PT_ALNUM),
                    (
                        "g_y1",
                        false,
                        concat!("(?:[:/%€$", pt_chars!(), "]|:[0-9]|-[0-9])"),
                    ),
                    (
                        "g_y2",
                        false,
                        concat!("(?:[:/%€$", pt_chars!(), "]|:[0-9]|-[0-9])"),
                    ),
                ],
                |c, reference| {
                    let d = parse_pt_day_unbounded(c.name("d")?.as_str())?;
                    if !(1..=31).contains(&d) {
                        return Some(invalid_date_sentinel());
                    }
                    let mo_str = c
                        .name("m1")
                        .or_else(|| c.name("m2"))
                        .or_else(|| c.name("m3"))?
                        .as_str();
                    let m = parse_pt_month(mo_str)?;
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(y_m) = c
                        .name("y1")
                        .or_else(|| c.name("y2"))
                        .or_else(|| c.name("y3"))
                        .or_else(|| c.name("y4"))
                    {
                        out.push(Component::Year(crate::number(y_m.as_str())?));
                    } else if let Some(mod_m) = c.name("mod1").or_else(|| c.name("mod2")) {
                        let ref_md = (reference.month() as i32, reference.day() as i32);
                        let y_off = if is_past_mod(mod_m.as_str()) {
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
                "pt_monthDay",
                concat!(
                    "(?i)(?P<guard0>)(?P<m>",
                    month_comp_all!(),
                    ")\\s+(?P<d>[0-9]{1,2}[ºª°]?)(?:(?:\\s+de\\s+|\\s*,\\s*|\\s+)(?P<y>(?:19|20|21)[0-9]{2})(?P<guard2>)|(?P<guard1>))"
                ),
                &[
                    ("guard0", true, PT_ALNUM),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[:/\\-%€$",
                            pt_chars!(),
                            "]|\\.[0-9]|\\s*(?:",
                            unit_guard_words!(),
                            "))"
                        ),
                    ),
                    (
                        "guard2",
                        false,
                        concat!("(?:[:/%€$", pt_chars!(), "]|:[0-9]|-[0-9])"),
                    ),
                ],
                |c, _| {
                    let m = parse_pt_month(c.name("m")?.as_str())?;
                    let d = parse_pt_day_unbounded(c.name("d")?.as_str())?;
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
                "pt_monthYear",
                concat!(
                    "(?i)(?P<guard0>)(?P<m>",
                    month_comp_all!(),
                    ")(?:\\s+de\\s+(?P<y1>[0-9]{4})|(?:\\s*,\\s*|\\s+|/)(?P<y2>(?:19|20|21)[0-9]{2}))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, PT_ALNUM),
                    (
                        "guard1",
                        false,
                        concat!("(?:[", pt_chars!(), "]|:[0-9]|/[0-9]|-[0-9]|\\.[0-9])"),
                    ),
                ],
                |c, _| {
                    let m = parse_pt_month(c.name("m")?.as_str())?;
                    let y = crate::number(c.name("y1").or_else(|| c.name("y2"))?.as_str())?;
                    Some(vec![Component::Month(m), Component::Year(y)])
                },
            ),
            Pattern::with_builder(
                "pt_namedYear",
                concat!(
                    "(?i)(?P<guard0>)(?:em|n?o\\s+ano(?:\\s+de)?|ano(?:\\s+de)?)\\s+(?P<y>(?:1[0-9]|2[0-9])[0-9]{2})(?P<guard1>)"
                ),
                &[
                    ("guard0", true, PT_ALNUM),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[:/\\-%€$",
                            pt_chars!(),
                            "]|\\.[0-9]|\\s*(?:",
                            unit_guard_words!(),
                            "))"
                        ),
                    ),
                ],
                |c, _| Some(vec![Component::Year(crate::number(c.name("y")?.as_str())?)]),
            ),
            Pattern::with_builder(
                "pt_numericDate",
                r"(?P<guard0>)(?:(?P<iy>[0-9]{4})[-/.](?P<im>[0-9]{1,2})[-/.](?P<id>[0-9]{1,2})|(?P<sd>[0-9]{1,2})/(?P<sm>[0-9]{1,2})/(?P<sy>[0-9]{2,4})|(?P<dd>[0-9]{1,2})-(?P<dm>[0-9]{1,2})-(?P<dy>[0-9]{2,4})|(?P<pd>[0-9]{1,2})\.(?P<pm>[0-9]{1,2})\.(?P<py>[0-9]{2,4})|(?P<yd>[0-9]{1,2})/(?P<ym>0[1-9]|1[0-2]))(?P<guard1>)",
                &[
                    ("guard0", true, concat!("[./\\-", pt_chars!(), "]")),
                    (
                        "guard1",
                        false,
                        concat!("(?:[:/", pt_chars!(), "]|\\.[0-9]|-[0-9])"),
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
                "pt_timeAmPm",
                r"(?i)(?P<guard0>)(?P<h>[0-9]{1,2})(?::(?P<m>[0-9]{2})(?::(?P<s>[0-9]{2}))?|h(?P<hm>[0-9]{2})?)?\s*(?P<ap>a\.?\s*m\.?|p\.?\s*m\.?)(?P<guard1>)",
                &[("guard0", true, TIME_GUARD0), ("guard1", false, PT_ALNUM)],
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = match c.name("m").or_else(|| c.name("hm")) {
                        Some(v) => Some(crate::number(v.as_str())?),
                        None => None,
                    };
                    if let Some(sm) = c.name("s")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    let ap = parse_ap(c.name("ap"));
                    let ok = match ap {
                        Some(false) => (0..=12).contains(&h),
                        Some(true) => (1..=12).contains(&h),
                        None => false,
                    };
                    ok.then(|| vec![Component::Time(h, m, ap)])
                },
            ),
            Pattern::with_builder(
                "pt_spokenTime",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:[àaÀ]s?\\s+)?(?P<tnt>12(?::(?P<tnt_m>[0-9]{2})|h(?P<tnt_hm>[0-9]{2})?)?|doze(?:\\s+horas?)?)\\s+da\\s+(?:noite|madrugada)|(?:[àaÀ]s?\\s+|ao\\s+)?(?P<tn>12(?::(?P<tn_m>[0-9]{2})|h(?P<tn_hm>[0-9]{2})?)?|doze(?:\\s+horas?)?)\\s+(?:do\\s+dia|da\\s+tarde|do\\s+meio[-\\s]+dia)|(?:[àaÀ]s?\\s+|ao\\s+)?(?P<base>mei[oO][-\\s]+dia|mei[aA][-\\s]+noite)\\s+(?:(?P<bkw>em\\s+ponto|e\\s+meia|e\\s+(?:um\\s+)?quarto)|e\\s+(?P<badd>",
                    num_1_59!(),
                    ")(?:\\s+(?:minutos?|min\\.?))?)|(?:(?P<mp_q>um\\s+quarto)|(?P<mp_m>",
                    num_1_59!(),
                    ")(?:\\s+(?:minutos?|min\\.?))?)\\s+(?:para\\s+(?:o\\s+(?P<mp_md1>mei[oO][-\\s]+dia)|a\\s+(?P<mp_mn1>mei[aA][-\\s]+noite)|as?\\s+(?P<mph1>",
                    hour_0_23!(),
                    ")(?:\\s*(?:horas?|h))?)|pro\\s+(?P<mp_md2>mei[oO][-\\s]+dia)|pra\\s+(?P<mp_mn2>mei[aA][-\\s]+noite)|pras?\\s+(?P<mph2>",
                    hour_0_23!(),
                    ")(?:\\s*(?:horas?|h))?)(?:\\s*(?P<mpap>a\\.?\\s*m\\.?|p\\.?\\s*m\\.?)|\\s+(?:d[ae]\\s+|pel[ao]\\s+)(?P<mpmer>manh[aãÃ]|madrugada|tarde|noite))?|(?:(?P<l_at>[àÀ]s?\\s+)?(?P<lh_u>",
                    hour_0_23!(),
                    ")\\s*(?P<l_unit>horas?|h)|(?P<l_at2>[àÀ]s?\\s+)(?P<lh_nu>",
                    hour_0_23!(),
                    "))\\s+(?:(?P<l_kw>em\\s+ponto|e\\s+meia|e\\s+(?:um\\s+)?quarto)|e\\s+(?P<l_add>",
                    num_1_59!(),
                    ")(?:\\s+(?:minutos?|min\\.?))?)(?:\\s*(?P<lap>a\\.?\\s*m\\.?|p\\.?\\s*m\\.?)|\\s+(?:d[ae]\\s+|pel[ao]\\s+)(?P<lmer>manh[aãÃ]|madrugada|tarde|noite))?|(?P<bh>",
                    hour_0_23!(),
                    ")\\s+(?P<bkw2>em\\s+ponto|e\\s+meia|e\\s+um\\s+quarto|e\\s+quinze)(?:\\s*(?P<bap>a\\.?\\s*m\\.?|p\\.?\\s*m\\.?)|\\s+(?:d[ae]\\s+|pel[ao]\\s+)(?P<bmer>manh[aãÃ]|madrugada|tarde|noite))?|(?P<ch>[0-9]{1,2})(?::(?P<cm>[0-9]{2})|h(?P<chm>[0-9]{2})?(?:\\s*min(?:ut[oa]s?)?)?)\\s+(?:d[ae]\\s+|pel[ao]\\s+)(?P<cmer>manh[aãÃ]|madrugada|tarde|noite)|(?:(?P<m_at>[àÀ]s?\\s+))?(?P<mh>",
                    hour_0_23!(),
                    ")(?:\\s*horas?)?\\s+(?:d[ae]\\s+|pel[ao]\\s+)(?P<mmer>manh[aãÃ]|madrugada|tarde|noite)|(?:(?P<ha_at>[àÀ]s?\\s+))?(?P<hah>",
                    hour_0_23!(),
                    ")\\s*horas?(?:\\s*(?P<ha_ap>a\\.?\\s*m\\.?|p\\.?\\s*m\\.?))?)(?P<guard1>)"
                ),
                &[
                    ("guard0", true, TIME_GUARD0),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[",
                            pt_chars!(),
                            "]|\\s*(?:",
                            unit_guard_words!(),
                            "))"
                        ),
                    ),
                ],
                |c, _| {
                    if c.name("tnt").is_some() {
                        let m = match c.name("tnt_m").or_else(|| c.name("tnt_hm")) {
                            Some(v) => crate::number(v.as_str())?,
                            None => 0,
                        };
                        return Some(vec![Component::Time(0, Some(m), Some(false))]);
                    }
                    if c.name("tn").is_some() {
                        let m = match c.name("tn_m").or_else(|| c.name("tn_hm")) {
                            Some(v) => crate::number(v.as_str())?,
                            None => 0,
                        };
                        return Some(vec![Component::Time(12, Some(m), None)]);
                    }
                    if let Some(base) = c.name("base") {
                        let base_h = if base.as_str().to_lowercase().ends_with("dia") {
                            12
                        } else {
                            0
                        };
                        if let Some(kw) = c.name("bkw") {
                            let l = kw.as_str().to_lowercase();
                            let min = if l.ends_with("meia") {
                                30
                            } else if l.ends_with("quarto") {
                                15
                            } else {
                                0
                            };
                            return Some(vec![Component::Time(base_h, Some(min), None)]);
                        }
                        let min = parse_pt_num(c.name("badd")?.as_str())?;
                        if !(1..60).contains(&min) {
                            return None;
                        }
                        return Some(vec![Component::Time(base_h, Some(min), None)]);
                    }
                    if c.name("mp_q").is_some() || c.name("mp_m").is_some() {
                        let min = if c.name("mp_q").is_some() {
                            15
                        } else {
                            let m = parse_pt_num(c.name("mp_m")?.as_str())?;
                            if !(1..60).contains(&m) {
                                return None;
                            }
                            m
                        };
                        let mer = c.name("mpmer").map(|m| m.as_str());
                        let mut ap =
                            parse_ap(c.name("mpap")).or_else(|| mer.map(parse_pt_meridiem));
                        let h = if c.name("mp_md1").is_some() || c.name("mp_md2").is_some() {
                            ap = None;
                            12
                        } else if c.name("mp_mn1").is_some() || c.name("mp_mn2").is_some() {
                            ap = None;
                            0
                        } else {
                            let hs = c.name("mph1").or_else(|| c.name("mph2"))?.as_str();
                            let raw_h = parse_pt_num(hs)?;
                            if raw_h == 12 && mer.is_some_and(is_pt_night) {
                                ap = Some(false);
                            }
                            raw_h
                        };
                        if !valid_h_meridiem(h, ap) {
                            return None;
                        }
                        let h24 = match ap {
                            Some(true) if h < 12 => h + 12,
                            Some(false) if h == 12 => 0,
                            _ => h,
                        };
                        return Some(vec![Component::Time(
                            (h24 - 1).rem_euclid(24),
                            Some(60 - min),
                            None,
                        )]);
                    }
                    if let Some(hs) = c.name("lh_u").or_else(|| c.name("lh_nu")) {
                        let raw_h = hs.as_str();
                        let mut h = parse_pt_num(raw_h)?;
                        let mer = c.name("lmer").map(|m| m.as_str());
                        let mut ap = parse_ap(c.name("lap")).or_else(|| mer.map(parse_pt_meridiem));
                        if !valid_h_meridiem(h, ap) {
                            return None;
                        }
                        // Bare "2 horas e meia" / "2h e meia" without "às" or meridiem is usually a duration.
                        if c.name("l_unit").is_some()
                            && c.name("l_at").is_none()
                            && ap.is_none()
                            && !is_padded_or_24h(raw_h, h)
                        {
                            return None;
                        }
                        if c.name("l_at2").is_some()
                            && raw_h.eq_ignore_ascii_case("vinte")
                            && (c.name("l_add").is_some()
                                || c.name("l_kw")
                                    .is_some_and(|k| k.as_str().to_lowercase().ends_with("quarto")))
                        {
                            return None;
                        }
                        if h == 12 && mer.is_some_and(is_pt_night) {
                            h = 0;
                            ap = Some(false);
                        }
                        let min = if let Some(kw) = c.name("l_kw") {
                            let l = kw.as_str().to_lowercase();
                            if l.ends_with("meia") {
                                30
                            } else if l.ends_with("quarto") {
                                15
                            } else {
                                0
                            }
                        } else {
                            let m = parse_pt_num(c.name("l_add")?.as_str())?;
                            if !(1..60).contains(&m) {
                                return None;
                            }
                            m
                        };
                        return Some(vec![Component::Time(h, Some(min), ap)]);
                    }
                    if let Some(bh) = c.name("bh") {
                        let raw_bh = bh.as_str();
                        let mut h = parse_pt_num(raw_bh)?;
                        let mer = c.name("bmer").map(|m| m.as_str());
                        let mut ap = parse_ap(c.name("bap")).or_else(|| mer.map(parse_pt_meridiem));
                        if !valid_h_meridiem(h, ap) {
                            return None;
                        }
                        if h == 12 && mer.is_some_and(is_pt_night) {
                            h = 0;
                            ap = Some(false);
                        }
                        let kw = c.name("bkw2")?.as_str().to_lowercase();
                        if raw_bh.eq_ignore_ascii_case("vinte") && kw.ends_with("quarto") {
                            return None;
                        }
                        let min = if kw.ends_with("meia") {
                            30
                        } else if kw.ends_with("quarto") || kw.ends_with("quinze") {
                            15
                        } else {
                            0
                        };
                        return Some(vec![Component::Time(h, Some(min), ap)]);
                    }
                    if let Some(ch) = c.name("ch") {
                        let mut h = crate::number(ch.as_str())?;
                        let m = match c.name("cm").or_else(|| c.name("chm")) {
                            Some(v) => crate::number(v.as_str())?,
                            None => 0,
                        };
                        let mer = c.name("cmer")?.as_str();
                        let mut pm = parse_pt_meridiem(mer);
                        if !valid_h_meridiem(h, Some(pm)) {
                            return None;
                        }
                        if h == 12 && is_pt_night(mer) {
                            h = 0;
                            pm = false;
                        }
                        return Some(vec![Component::Time(h, Some(m), Some(pm))]);
                    }
                    if let Some(mh) = c.name("mh") {
                        let mut h = parse_pt_num(mh.as_str())?;
                        let mer = c.name("mmer")?.as_str();
                        let mut pm = parse_pt_meridiem(mer);
                        if !valid_h_meridiem(h, Some(pm)) {
                            return None;
                        }
                        if h == 12 && is_pt_night(mer) {
                            h = 0;
                            pm = false;
                        }
                        return Some(vec![Component::Time(h, Some(0), Some(pm))]);
                    }
                    let raw_h = c.name("hah")?.as_str();
                    let h = parse_pt_num(raw_h)?;
                    let ap = parse_ap(c.name("ha_ap"));
                    if !valid_h_meridiem(h, ap) {
                        return None;
                    }
                    if c.name("ha_at").is_none() && ap.is_none() && !is_padded_or_24h(raw_h, h) {
                        return None;
                    }
                    Some(vec![Component::Time(h, Some(0), ap)])
                },
            ),
            Pattern::with_builder(
                "pt_timeHFormat",
                concat!(
                    "(?i)(?P<guard0>)(?:(?P<h1>[0-9]{1,2})h(?P<m1>[0-9]{2})(?:min(?:ut[oa]s?)?|m)?(?P<g1>)|(?P<h2>[0-9]{1,2})\\s*h\\s+(?P<m2>[0-9]{2})(?P<g2>)|(?P<h3>[0-9]{1,2}):(?P<m3>[0-9]{2})(?::(?P<s3>[0-9]{2}))?\\s*(?:horas?|hrs?\\.?|hs\\.?|h)(?P<g3>)|(?P<h4>[0-9]{1,2})\\s*(?:hrs\\.?|hs\\.?|h)(?P<g4>))"
                ),
                &[
                    ("guard0", true, TIME_GUARD0),
                    ("g1", false, concat!("(?:[", pt_chars!(), "]|:[0-9])")),
                    (
                        "g2",
                        false,
                        concat!(
                            "(?i)(?:[",
                            pt_chars!(),
                            "]|:[0-9]|\\s*(?:",
                            unit_guard_words!(),
                            "))"
                        ),
                    ),
                    ("g3", false, concat!("(?:[", pt_chars!(), "]|:[0-9])")),
                    (
                        "g4",
                        false,
                        concat!(
                            "(?i)(?:[",
                            pt_chars!(),
                            "]|:[0-9]|\\s*(?:[0-9]{1,2}\\s*(?:min(?:ut[oa]s?)?|seg(?:und[oa]s?)?|dias?|semanas?|m[eêÊ]s|meses|anos?)|de\\s+(?:viagem|v[oôÔ]o|dura[cçÇ][aãÃ]o|espera|atraso|anteced[eêÊ]ncia|trabalho|estrada|caminhada|carro|trem|comboio|[oôÔ]nibus|autocarro|avi[aãÃ]o|sono|curso|aula)|por\\s+(?:dia|semana|m[eêÊ]s|ano)|(?:a\\s+)?mais|atr[aáÁ]s|depois|antes|mais\\s+(?:tarde|cedo))",
                            word_end!(),
                            ")"
                        ),
                    ),
                ],
                |c, _| {
                    if let Some(sm) = c.name("s3")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    if let Some(h4) = c.name("h4") {
                        return Some(vec![Component::Time(
                            crate::number(h4.as_str())?,
                            Some(0),
                            None,
                        )]);
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
                "pt_aHour",
                concat!(
                    "(?i)(?P<guard0>)(?:[àÀ]s\\s+(?P<h2>",
                    hour_0_23!(),
                    ")|[àÀ]\\s+(?P<h1>uma|1))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, PT_ALNUM),
                    (
                        "guard1",
                        false,
                        concat!(
                            "(?i)(?:[:%",
                            pt_chars!(),
                            "]|[.,][0-9]|\\s*(?:a\\.?\\s*m\\.?|p\\.?\\s*m\\.?|",
                            unit_guard_words!(),
                            "))"
                        ),
                    ),
                ],
                |c, _| {
                    let h = parse_pt_num(c.name("h1").or_else(|| c.name("h2"))?.as_str())?;
                    (0..24)
                        .contains(&h)
                        .then(|| vec![Component::Time(h, Some(0), None)])
                },
            ),
            Pattern::new(
                "pt_fixedTime",
                r"(?i)(?P<guard0>)(mei[oO][- ]dia|mei[aA][- ]noite)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("meio-dia", &[Component::Time(12, Some(0), None)]),
                    ("meio dia", &[Component::Time(12, Some(0), None)]),
                    ("meia-noite", &[Component::Time(0, Some(0), None)]),
                    ("meia noite", &[Component::Time(0, Some(0), None)]),
                ],
            ),
            Pattern::with_builder(
                "pt_hmsTime",
                r"(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<m>[0-9]{2}):(?P<s>[0-9]{2})(?P<guard1>)",
                &[
                    ("guard0", true, concat!("[:", pt_chars!(), "]")),
                    ("guard1", false, concat!("[:", pt_chars!(), "]")),
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
            Pattern::with_builder(
                "pt_meridiem",
                r"(?i)(?P<guard0>)(?:(?:d[ae]|pel[ao]|n[ao])\s+(?P<am1>manh[aãÃ]|madrugada)|(?:d[ae]|pel[ao]|n[ao]|[àÀ])\s+(?P<pm1>tarde|noite))(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let pm = c.name("pm1").is_some();
                    Some(vec![Component::Meridiem(pm)])
                },
            ),
            Pattern::with_builder(
                "pt_dayOnly",
                concat!(
                    "(?i)(?P<guard0>)(?:(?:o\\s+)?dia\\s+(?P<d1>",
                    day_part!(),
                    ")(?P<g1>)|(?P<d2>1[ºª°])(?P<g2>))"
                ),
                &[
                    ("guard0", true, PT_ALNUM),
                    (
                        "g1",
                        false,
                        concat!(
                            "(?i)(?:[:/\\-%€$",
                            pt_chars!(),
                            "]|\\.[0-9]|\\s*(?:",
                            unit_guard_words!(),
                            "))"
                        ),
                    ),
                    (
                        "g2",
                        false,
                        concat!(
                            "(?i)(?:[:/\\-%€$ºª°",
                            pt_chars!(),
                            "]|\\.[0-9]|\\s*(?:lugar|andar|piso|turno|semestre|trimestre|bimestre|grau|cap[iíÍ]tulo|artigo|item|bloco|grupo|lote|colocado|pr[eêÉÊ]mio|s[eéÉ]rie|",
                            unit_guard_words!(),
                            ")",
                            word_end!(),
                            ")"
                        ),
                    ),
                ],
                |c, _| {
                    let raw = c.name("d1").or_else(|| c.name("d2"))?.as_str();
                    let d = parse_pt_day_unbounded(raw)?;
                    (1..=31).contains(&d).then(|| vec![Component::Day(d)])
                },
            ),
            Pattern::new(
                "pt_weekday",
                r"(?i)(?P<guard0>)(segundas[- ]feiras|segunda[- ]feira|segunda|ter[cçÇ]as[- ]feiras|ter[cçÇ]a[- ]feira|ter[cçÇ]a|quartas[- ]feiras|quarta[- ]feira|quarta|quintas[- ]feiras|quinta[- ]feira|quinta|sextas[- ]feiras|sexta[- ]feira|sexta|s[aáÁ]bado|domingo|2[ªaA][- ]feira|3[ªaA][- ]feira|4[ªaA][- ]feira|5[ªaA][- ]feira|6[ªaA][- ]feira|seg\.?|ter\.?|qua\.?|qui\.?|sex\.?|s[aáÁ]b\.?|dom\.?)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("segunda-feira", &[Component::Weekday(1)]),
                    ("segunda feira", &[Component::Weekday(1)]),
                    ("segundas-feiras", &[Component::Weekday(1)]),
                    ("segundas feiras", &[Component::Weekday(1)]),
                    ("segunda", &[Component::Weekday(1)]),
                    ("2ª-feira", &[Component::Weekday(1)]),
                    ("2ª feira", &[Component::Weekday(1)]),
                    ("2a-feira", &[Component::Weekday(1)]),
                    ("2a feira", &[Component::Weekday(1)]),
                    ("seg.", &[Component::Weekday(1)]),
                    ("seg", &[Component::Weekday(1)]),
                    ("terça-feira", &[Component::Weekday(2)]),
                    ("terça feira", &[Component::Weekday(2)]),
                    ("tercas-feiras", &[Component::Weekday(2)]),
                    ("terças-feiras", &[Component::Weekday(2)]),
                    ("terças feiras", &[Component::Weekday(2)]),
                    ("terca-feira", &[Component::Weekday(2)]),
                    ("terca feira", &[Component::Weekday(2)]),
                    ("tercas feiras", &[Component::Weekday(2)]),
                    ("terça", &[Component::Weekday(2)]),
                    ("terca", &[Component::Weekday(2)]),
                    ("3ª-feira", &[Component::Weekday(2)]),
                    ("3ª feira", &[Component::Weekday(2)]),
                    ("3a-feira", &[Component::Weekday(2)]),
                    ("3a feira", &[Component::Weekday(2)]),
                    ("ter.", &[Component::Weekday(2)]),
                    ("ter", &[Component::Weekday(2)]),
                    ("quarta-feira", &[Component::Weekday(3)]),
                    ("quarta feira", &[Component::Weekday(3)]),
                    ("quartas-feiras", &[Component::Weekday(3)]),
                    ("quartas feiras", &[Component::Weekday(3)]),
                    ("quarta", &[Component::Weekday(3)]),
                    ("4ª-feira", &[Component::Weekday(3)]),
                    ("4ª feira", &[Component::Weekday(3)]),
                    ("4a-feira", &[Component::Weekday(3)]),
                    ("4a feira", &[Component::Weekday(3)]),
                    ("qua.", &[Component::Weekday(3)]),
                    ("qua", &[Component::Weekday(3)]),
                    ("quinta-feira", &[Component::Weekday(4)]),
                    ("quinta feira", &[Component::Weekday(4)]),
                    ("quintas-feiras", &[Component::Weekday(4)]),
                    ("quintas feiras", &[Component::Weekday(4)]),
                    ("quinta", &[Component::Weekday(4)]),
                    ("5ª-feira", &[Component::Weekday(4)]),
                    ("5ª feira", &[Component::Weekday(4)]),
                    ("5a-feira", &[Component::Weekday(4)]),
                    ("5a feira", &[Component::Weekday(4)]),
                    ("qui.", &[Component::Weekday(4)]),
                    ("qui", &[Component::Weekday(4)]),
                    ("sexta-feira", &[Component::Weekday(5)]),
                    ("sexta feira", &[Component::Weekday(5)]),
                    ("sextas-feiras", &[Component::Weekday(5)]),
                    ("sextas feiras", &[Component::Weekday(5)]),
                    ("sexta", &[Component::Weekday(5)]),
                    ("6ª-feira", &[Component::Weekday(5)]),
                    ("6ª feira", &[Component::Weekday(5)]),
                    ("6a-feira", &[Component::Weekday(5)]),
                    ("6a feira", &[Component::Weekday(5)]),
                    ("sex.", &[Component::Weekday(5)]),
                    ("sex", &[Component::Weekday(5)]),
                    ("sábado", &[Component::Weekday(6)]),
                    ("sabado", &[Component::Weekday(6)]),
                    ("sáb.", &[Component::Weekday(6)]),
                    ("sáb", &[Component::Weekday(6)]),
                    ("sab.", &[Component::Weekday(6)]),
                    ("sab", &[Component::Weekday(6)]),
                    ("domingo", &[Component::Weekday(7)]),
                    ("dom.", &[Component::Weekday(7)]),
                    ("dom", &[Component::Weekday(7)]),
                ],
            ),
            Pattern::new(
                "pt_month",
                concat!("(?i)(?P<guard0>)(", month_comp_all!(), ")(?P<guard1>)"),
                &alnum_guards,
                &[
                    ("janeiro", &[Component::Month(1)]),
                    ("jan.", &[Component::Month(1)]),
                    ("jan", &[Component::Month(1)]),
                    ("fevereiro", &[Component::Month(2)]),
                    ("fev.", &[Component::Month(2)]),
                    ("fev", &[Component::Month(2)]),
                    ("março", &[Component::Month(3)]),
                    ("marco", &[Component::Month(3)]),
                    ("mar.", &[Component::Month(3)]),
                    ("mar", &[Component::Month(3)]),
                    ("abril", &[Component::Month(4)]),
                    ("abr.", &[Component::Month(4)]),
                    ("abr", &[Component::Month(4)]),
                    ("maio", &[Component::Month(5)]),
                    ("mai.", &[Component::Month(5)]),
                    ("mai", &[Component::Month(5)]),
                    ("junho", &[Component::Month(6)]),
                    ("jun.", &[Component::Month(6)]),
                    ("jun", &[Component::Month(6)]),
                    ("julho", &[Component::Month(7)]),
                    ("jul.", &[Component::Month(7)]),
                    ("jul", &[Component::Month(7)]),
                    ("agosto", &[Component::Month(8)]),
                    ("ago.", &[Component::Month(8)]),
                    ("ago", &[Component::Month(8)]),
                    ("setembro", &[Component::Month(9)]),
                    ("set.", &[Component::Month(9)]),
                    ("set", &[Component::Month(9)]),
                    ("outubro", &[Component::Month(10)]),
                    ("out.", &[Component::Month(10)]),
                    ("out", &[Component::Month(10)]),
                    ("novembro", &[Component::Month(11)]),
                    ("nov.", &[Component::Month(11)]),
                    ("nov", &[Component::Month(11)]),
                    ("dezembro", &[Component::Month(12)]),
                    ("dez.", &[Component::Month(12)]),
                    ("dez", &[Component::Month(12)]),
                ],
            ),
            Pattern::new("pt_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

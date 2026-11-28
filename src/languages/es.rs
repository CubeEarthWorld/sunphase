use crate::{Capture, Component, Language, Pattern};

const G_ALNUM: &str = "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ0-9]";

const MONTH_ALL: &str = "septiembre|setiembre|noviembre|diciembre|febrero|octubre|agosto|enero|marzo|abril|junio|julio|mayo|sept\\.?|ene\\.?|feb\\.?|mar\\.?|abr\\.?|may\\.?|jun\\.?|jul\\.?|ago\\.?|sep\\.?|set\\.?|oct\\.?|nov\\.?|dic\\.?";
const WD_FULL: &str = "mi[éÉe]rcoles|viernes|domingo|martes|jueves|s[áÁa]bado|lunes";
const WD_NEXTLAST_ALL: &str = "mi[éÉe]rcoles|viernes|domingo|martes|jueves|s[áÁa]bado|lunes|mi[éÉe]r\\.?|mi[éÉe]\\.?|s[áÁa]b\\.?|lun\\.?|mar\\.|jue\\.?|vie\\.?|dom\\.?";

const NUM_1_59: &str = "(?:[0-9]{1,2}|(?:treinta|cuarenta|cincuenta)(?:\\s+y\\s+(?:un[oa]?|dos|tres|cuatro|cinco|seis|siete|ocho|nueve))?|veintid[óÓo]s|veintitr[éÉe]s|veinticuatro|veinticinco|veintis[éÉe]is|veintisiete|veintiocho|veintinueve|veinti[úÚu]n[oa]?|veinte|diecis[éÉe]is|diecisiete|dieciocho|diecinueve|catorce|quince|cuatro|trece|cinco|siete|nueve|once|doce|diez|tres|ocho|seis|un[oa]?|dos)";
const NUM_ANY: &str = "(?:[0-9]+|(?:treinta|cuarenta|cincuenta|sesenta|setenta|ochenta|noventa)(?:\\s+y\\s+(?:un[oa]?|dos|tres|cuatro|cinco|seis|siete|ocho|nueve))?|veintid[óÓo]s|veintitr[éÉe]s|veinticuatro|veinticinco|veintis[éÉe]is|veintisiete|veintiocho|veintinueve|veinti[úÚu]n[oa]?|veinte|diecis[éÉe]is|diecisiete|dieciocho|diecinueve|catorce|quince|cuatro|trece|cinco|siete|nueve|ciento|cien|once|doce|diez|tres|ocho|seis|un[oa]?|dos)";
const HOUR_1_23: &str = "(?:[0-9]{1,2}|veintid[óÓo]s|veintitr[éÉe]s|veinti[úÚu]n[oa]?|veinte|diecis[éÉe]is|diecisiete|dieciocho|diecinueve|catorce|quince|cuatro|trece|cinco|siete|nueve|once|doce|diez|tres|ocho|seis|cero|una|uno|dos)";
const HOUR_1_12: &str =
    "(?:1[0-2]|0?[1-9]|cuatro|cinco|siete|nueve|once|doce|diez|tres|ocho|seis|una|dos)";
const DAY_PART: &str = "1(?:er|ero|ro|[º°o])?|primero|uno|[0-9]{1,2}[º°]?|treinta(?:\\s+y\\s+uno)?|veintid[óÓo]s|veintitr[éÉe]s|veinticuatro|veinticinco|veintis[éÉe]is|veintisiete|veintiocho|veintinueve|veinti[úÚu]n[oa]?|veinte|diecis[éÉe]is|diecisiete|dieciocho|diecinueve|catorce|quince|cuatro|trece|cinco|siete|nueve|once|doce|diez|tres|ocho|seis|dos";

fn es_word_num(w: &str) -> Option<i32> {
    Some(match w {
        "cero" => 0,
        "un" | "una" | "uno" => 1,
        "dos" => 2,
        "tres" => 3,
        "cuatro" => 4,
        "cinco" => 5,
        "seis" => 6,
        "siete" => 7,
        "ocho" => 8,
        "nueve" => 9,
        "diez" => 10,
        "once" => 11,
        "doce" => 12,
        "trece" => 13,
        "catorce" => 14,
        "quince" => 15,
        "dieciséis" | "dieciseis" => 16,
        "diecisiete" => 17,
        "dieciocho" => 18,
        "diecinueve" => 19,
        "veinte" => 20,
        "veintiún" | "veintiun" | "veintiuno" | "veintiuna" => 21,
        "veintidós" | "veintidos" => 22,
        "veintitrés" | "veintitres" => 23,
        "veinticuatro" => 24,
        "veinticinco" => 25,
        "veintiséis" | "veintiseis" => 26,
        "veintisiete" => 27,
        "veintiocho" => 28,
        "veintinueve" => 29,
        "treinta" => 30,
        "cuarenta" => 40,
        "cincuenta" => 50,
        "sesenta" => 60,
        "setenta" => 70,
        "ochenta" => 80,
        "noventa" => 90,
        "cien" | "ciento" => 100,
        _ => return None,
    })
}

fn parse_es_num(s: &str) -> Option<i32> {
    if let Some(n) = crate::number(s) {
        return Some(n);
    }
    let lower = s.to_lowercase();
    let mut it = lower.split_whitespace();
    let first = it.next()?;
    match it.next() {
        None => es_word_num(first),
        Some("y") => {
            let third = it.next()?;
            if it.next().is_some() {
                return None;
            }
            es_word_num(first)?.checked_add(es_word_num(third)?)
        }
        _ => None,
    }
}

fn parse_es_day(s: &str) -> Option<i32> {
    if crate::eq_word(s, "primero") {
        return Some(1);
    }
    let trimmed = if s.as_bytes().first().is_some_and(|b| b.is_ascii_digit()) {
        s.trim_end_matches(|c: char| matches!(c, 'º' | '°' | 'e' | 'r' | 'o' | 'E' | 'R' | 'O'))
    } else {
        s
    };
    let d = parse_es_num(trimmed)?;
    (1..=31).contains(&d).then_some(d)
}

fn parse_es_month(s: &str) -> Option<i32> {
    let lower = s.trim_end_matches('.').to_lowercase();
    Some(match lower.as_str() {
        "enero" | "ene" => 1,
        "febrero" | "feb" => 2,
        "marzo" | "mar" => 3,
        "abril" | "abr" => 4,
        "mayo" | "may" => 5,
        "junio" | "jun" => 6,
        "julio" | "jul" => 7,
        "agosto" | "ago" => 8,
        "septiembre" | "setiembre" | "sept" | "sep" | "set" => 9,
        "octubre" | "oct" => 10,
        "noviembre" | "nov" => 11,
        "diciembre" | "dic" => 12,
        _ => return None,
    })
}

fn parse_es_weekday(s: &str) -> Option<i32> {
    let lower = s.trim_end_matches('.').to_lowercase();
    Some(match lower.as_str() {
        "lunes" | "lun" => 1,
        "martes" | "mar" => 2,
        "miércoles" | "miercoles" | "miér" | "mier" | "mié" | "mie" => 3,
        "jueves" | "jue" => 4,
        "viernes" | "vie" => 5,
        "sábado" | "sabado" | "sáb" | "sab" => 6,
        "domingo" | "dom" => 7,
        _ => return None,
    })
}

fn parse_es_ord(s: &str) -> Option<i32> {
    Some(match s.to_lowercase().as_str() {
        "1er" | "1º" | "1°" | "primer" | "primero" | "primera" => 1,
        "2º" | "2°" | "segundo" | "segunda" => 2,
        "3er" | "3º" | "3°" | "tercer" | "tercero" | "tercera" => 3,
        "4º" | "4°" | "cuarto" | "cuarta" => 4,
        "5º" | "5°" | "quinto" | "quinta" => 5,
        "último" | "ultimo" | "última" | "ultima" => -1,
        _ => return None,
    })
}

fn parse_es_offset(value: i32, unit: &str) -> Option<Component> {
    let lower = unit.to_lowercase();
    if lower.starts_with('d') {
        Some(Component::RelativeDay(value))
    } else if lower.starts_with("sem") {
        Some(Component::Week(value, false))
    } else if lower.starts_with("mes") {
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

fn valid_h_ap(h: i32, ap: Option<bool>) -> bool {
    match ap {
        Some(true) => (1..=23).contains(&h),
        Some(false) => (0..=12).contains(&h),
        None => (0..24).contains(&h),
    }
}

pub fn language() -> Language {
    let alnum_guards = [("guard0", true, G_ALNUM), ("guard1", false, G_ALNUM)];

    Language::new(
        "es",
        r"(?i)(?:[\s,]+|\b(?:a|al|las?|el|del?|en)\b)+",
        vec![
            Pattern::with_builder(
                "es_partOfDay",
                r"(?i)(?P<guard0>)(?P<pod>esta\s+(?:ma[ñÑ]ana|tarde|noche|madrugada)|anteanoche|anoche)(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let pod = c.name("pod")?.as_str().to_lowercase();
                    if pod == "anteanoche" {
                        Some(vec![Component::RelativeDay(-2), Component::Meridiem(true)])
                    } else if pod == "anoche" {
                        Some(vec![Component::RelativeDay(-1), Component::Meridiem(true)])
                    } else if pod.ends_with("tarde") || pod.ends_with("noche") {
                        Some(vec![Component::RelativeDay(0), Component::Meridiem(true)])
                    } else {
                        Some(vec![Component::RelativeDay(0), Component::Meridiem(false)])
                    }
                },
            ),
            Pattern::with_builder(
                "es_relativeDayPhrase",
                r"(?i)(?P<guard0>)(?P<rel>pasado\s+ma[ñÑ]ana|pasadoma[ñÑ]ana|antes\s+de\s+ayer)(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let first = c.name("rel")?.as_str().as_bytes()[0];
                    let offset = if first.eq_ignore_ascii_case(&b'p') {
                        2
                    } else {
                        -2
                    };
                    Some(vec![Component::RelativeDay(offset)])
                },
            ),
            Pattern::new(
                "es_relativeDay",
                r"(?i)(?P<guard0>)(pasado ma[ñÑ]ana|pasado manana|anteayer|ma[ñÑ]ana|manana|antier|ayer|hoy)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("hoy", &[Component::RelativeDay(0)]),
                    ("mañana", &[Component::RelativeDay(1)]),
                    ("manana", &[Component::RelativeDay(1)]),
                    ("pasado mañana", &[Component::RelativeDay(2)]),
                    ("pasado manana", &[Component::RelativeDay(2)]),
                    ("ayer", &[Component::RelativeDay(-1)]),
                    ("anteayer", &[Component::RelativeDay(-2)]),
                    ("antier", &[Component::RelativeDay(-2)]),
                ],
            ),
            Pattern::with_builder(
                "es_nthWeekday",
                &format!(
                    r"(?i)(?P<guard0>)(?:el\s+)?(?P<ord>1er|1[º°]|primer[oa]?|2[º°]|segund[oa]|3er|3[º°]|tercer[oa]?|4[º°]|cuart[oa]|5[º°]|quint[oa]|[úÚu]ltim[oa])\s+(?P<wd>{WD_FULL})\s+(?:de|del\s+mes\s+de)\s+(?P<mo>{MONTH_ALL})(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let ord = parse_es_ord(c.name("ord")?.as_str())?;
                    let wd = parse_es_weekday(c.name("wd")?.as_str())?;
                    let mo = parse_es_month(c.name("mo")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, mo)])
                },
            ),
            Pattern::with_builder(
                "es_nextLastWeekday",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?P<pre_mod>pr[óÓo]xim[oa]|siguiente|pasad[oa]|anterior|[úÚu]ltim[oa]|est[ea])\s+(?P<pre_wd>{WD_NEXTLAST_ALL})|(?P<post_wd>{WD_NEXTLAST_ALL})\s+(?P<post_mod>pr[óÓo]xim[oa]|que\s+viene|siguiente|pasad[oa]|anterior))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let (mod_s, wd_s) = if let Some(m) = c.name("pre_mod") {
                        (m.as_str(), c.name("pre_wd")?.as_str())
                    } else {
                        (c.name("post_mod")?.as_str(), c.name("post_wd")?.as_str())
                    };
                    let lower = mod_s.to_lowercase();
                    let wd = parse_es_weekday(wd_s)?;
                    if lower.starts_with("est") {
                        return Some(vec![Component::Weekday(wd)]);
                    }
                    let offset = if lower.starts_with("pasad")
                        || lower == "anterior"
                        || lower.starts_with("últim")
                        || lower.starts_with("ultim")
                    {
                        -1
                    } else {
                        1
                    };
                    Some(vec![Component::Week(offset, false), Component::Weekday(wd)])
                },
            ),
            Pattern::with_builder(
                "es_weekend",
                r"(?i)(?P<guard0>)(?:(?P<past>pasad[oa]\s+(?:fin\s+de\s+semana|finde)|(?:fin\s+de\s+semana|finde)\s+pasad[oa])|(?P<next>(?:(?:este|pr[óÓo]ximo)\s+)?(?:fin\s+de\s+semana|finde)(?:\s+que\s+viene)?))(?P<guard1>)",
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
                "es_prevAnchor",
                r"(?i)(?P<guard0>)(?P<u>semana|mes|a[ñÑn]o)\s+anterior(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let u = c.name("u")?.as_str().to_lowercase();
                    Some(vec![if u == "semana" {
                        Component::Week(-1, true)
                    } else if u == "mes" {
                        Component::MonthOffset(-1)
                    } else {
                        Component::YearOffset(-1)
                    }])
                },
            ),
            Pattern::new(
                "es_weekAnchor",
                r"(?i)(?P<guard0>)(?:pr[óÓo]xima\s+semana|semana\s+que\s+viene|siguiente\s+semana|semana\s+siguiente|semana\s+pasada|pasada\s+semana|esta\s+semana)(?P<guard1>)",
                &alnum_guards,
                &[],
            ),
            Pattern::new(
                "es_monthAnchor",
                r"(?i)(?P<guard0>)(?:pr[óÓo]ximo\s+mes|mes\s+que\s+viene|siguiente\s+mes|mes\s+siguiente|mes\s+pasado|pasado\s+mes|este\s+mes)(?P<guard1>)",
                &alnum_guards,
                &[],
            ),
            Pattern::new(
                "es_yearAnchor",
                r"(?i)(?P<guard0>)(?:pr[óÓo]ximo\s+a[ñÑn]o|a[ñÑn]o\s+que\s+viene|siguiente\s+a[ñÑn]o|a[ñÑn]o\s+siguiente|a[ñÑn]o\s+pasado|pasado\s+a[ñÑn]o|este\s+a[ñÑn]o)(?P<guard1>)",
                &alnum_guards,
                &[],
            ),
            Pattern::with_builder(
                "es_within",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?:en|dentro\s+de|durante)\s+(?:los\s+(?:pr[óÓo]ximos|siguientes)|las\s+(?:pr[óÓo]ximas|siguientes))\s+(?P<n1>{NUM_ANY})\s+(?P<u1>d[íÍi]as?|semanas?)|en\s+un\s+plazo\s+de\s+(?P<n2>{NUM_ANY})\s+(?P<u2>d[íÍi]as?|semanas?))(?P<guard1>)"
                ),
                &alnum_guards,
                |c, _| {
                    let (n_s, u_s) = if let Some(n1) = c.name("n1") {
                        (n1.as_str(), c.name("u1")?.as_str())
                    } else {
                        (c.name("n2")?.as_str(), c.name("u2")?.as_str())
                    };
                    let mut n = parse_es_num(n_s)?;
                    if u_s.as_bytes()[0].eq_ignore_ascii_case(&b's') {
                        n = n.checked_mul(7)?;
                    }
                    Some(vec![Component::Within(n)])
                },
            ),
            Pattern::with_builder(
                "es_offset",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?:en|dentro\s+de|de\s+aqu[íÍi]\s+a)\s+(?P<fn1>{NUM_ANY})\s+(?P<fu1>d[íÍi]as?|semanas?|mes(?:es)?|a[ñÑn]os?)|(?P<fn2>{NUM_ANY})\s+(?P<fu2>d[íÍi]as?|semanas?|mes(?:es)?|a[ñÑn]os?)\s+(?:desde\s+ahora|despu[éÉe]s|m[áÁa]s\s+tarde)|hace\s+(?P<pn1>{NUM_ANY})\s+(?P<pu1>d[íÍi]as?|semanas?|mes(?:es)?|a[ñÑn]os?)|(?P<pn2>{NUM_ANY})\s+(?P<pu2>d[íÍi]as?|semanas?|mes(?:es)?|a[ñÑn]os?)\s+atr[áÁa]s)(?P<guard1>)"
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
                    let raw = parse_es_num(n_s)?;
                    let val = if neg { raw.checked_neg()? } else { raw };
                    Some(vec![parse_es_offset(val, u_s)?])
                },
            ),
            Pattern::with_builder(
                "es_dayMonth",
                &format!(
                    r"(?i)(?P<guard0>)(?:el\s+)?(?:d[íÍi]a\s+)?(?P<d>{DAY_PART})(?:\s+de\s+|\s+|[-/])(?P<m>{MONTH_ALL})(?P<guard1>)(?:(?:\s+(?:de|del)\s+(?P<y1>[0-9]{{4}}))|(?:\s*,\s*|\s+|[-/])(?P<y2>(?:19|20|21)[0-9]{{2}}))?(?P<guard2>)"
                ),
                &[
                    ("guard0", true, G_ALNUM),
                    ("guard1", false, G_ALNUM),
                    ("guard2", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ0-9:]"),
                ],
                |c, _| {
                    let d = parse_es_day(c.name("d")?.as_str())?;
                    let m = parse_es_month(c.name("m")?.as_str())?;
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(y_m) = c.name("y1").or_else(|| c.name("y2")) {
                        out.push(Component::Year(crate::number(y_m.as_str())?));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "es_monthDay",
                &format!(
                    r"(?i)(?P<guard0>)(?P<m>{MONTH_ALL})\s+(?P<d>[0-9]{{1,2}})(?:[º°])?(?P<guard1>)(?:(?:\s+(?:de|del)\s+|\s*,\s*|\s+)(?P<y>(?:19|20|21)[0-9]{{2}}))?(?P<guard2>)"
                ),
                &[
                    ("guard0", true, G_ALNUM),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9:/\-a-zA-ZáéíóúüñÁÉÍÓÚÜÑ%€$]|\.[0-9])",
                    ),
                    ("guard2", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ0-9:]"),
                ],
                |c, _| {
                    let m = parse_es_month(c.name("m")?.as_str())?;
                    let d = crate::number(c.name("d")?.as_str())?;
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(y_m) = c.name("y") {
                        out.push(Component::Year(crate::number(y_m.as_str())?));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "es_monthYear",
                &format!(
                    r"(?i)(?P<guard0>)(?P<m>{MONTH_ALL})(?:\s+(?:de|del)\s+(?P<y1>[0-9]{{4}})|(?:\s*,\s*|\s+)(?P<y2>(?:19|20|21)[0-9]{{2}}))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, G_ALNUM),
                    ("guard1", false, "[0-9:a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                |c, _| {
                    let m = parse_es_month(c.name("m")?.as_str())?;
                    let y = crate::number(c.name("y1").or_else(|| c.name("y2"))?.as_str())?;
                    Some(vec![Component::Month(m), Component::Year(y)])
                },
            ),
            Pattern::with_builder(
                "es_numericDate",
                r"(?P<guard0>)(?:(?P<iy>[0-9]{4})[-/.](?P<im>[0-9]{1,2})[-/.](?P<id>[0-9]{1,2})|(?P<sd>[0-9]{1,2})/(?P<sm>[0-9]{1,2})/(?P<sy>[0-9]{2,4})|(?P<dd>[0-9]{1,2})-(?P<dm>[0-9]{1,2})-(?P<dy>[0-9]{2,4})|(?P<pd>[0-9]{1,2})\.(?P<pm>[0-9]{1,2})\.(?P<py>[0-9]{2,4})|(?P<yd>[0-9]{1,2})/(?P<ym>0[1-9]|1[0-2]))(?P<guard1>)",
                &[
                    ("guard0", true, r"[0-9./\-a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9:/a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]|\.[0-9]|-[0-9])",
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
                "es_timeAmPm",
                r"(?i)(?P<guard0>)(?P<h>[0-9]{1,2})(?::(?P<m>[0-9]{2}))?\s*(?P<ap>a\.?\s*m\.?|p\.?\s*m\.?)(?P<guard1>)",
                &[
                    ("guard0", true, r"[0-9a-zA-ZáéíóúüñÁÉÍÓÚÜÑ.:/-]"),
                    ("guard1", false, G_ALNUM),
                ],
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = match c.name("m") {
                        Some(v) => Some(crate::number(v.as_str())?),
                        None => None,
                    };
                    let ap = parse_ap(c.name("ap"));
                    if !valid_h_ap(h, ap) {
                        return None;
                    }
                    Some(vec![Component::Time(h, m, ap)])
                },
            ),
            Pattern::with_builder(
                "es_timeHFormat",
                r"(?i)(?P<guard0>)(?:(?P<h1>[0-9]{1,2})h(?P<m1>[0-9]{2})|(?P<h2>[0-9]{1,2}):(?P<m2>[0-9]{2})\s*(?:horas?|hrs?\.?|hs\.?|h))(?P<guard1>)",
                &[
                    ("guard0", true, r"[0-9a-zA-ZáéíóúüñÁÉÍÓÚÜÑ.:/-]"),
                    ("guard1", false, G_ALNUM),
                ],
                |c, _| {
                    let (hs, ms) = if let Some(h1) = c.name("h1") {
                        (h1.as_str(), c.name("m1")?.as_str())
                    } else {
                        (c.name("h2")?.as_str(), c.name("m2")?.as_str())
                    };
                    Some(vec![Component::Time(
                        crate::number(hs)?,
                        Some(crate::number(ms)?),
                        None,
                    )])
                },
            ),
            Pattern::with_builder(
                "es_spokenTime",
                &format!(
                    r"(?i)(?P<guard0>)(?:(?:un\s+)?cuarto\s+para\s+(?:la\s+(?P<cph1>una|1)|las\s+(?P<cph2>{HOUR_1_23}))(?:\s*(?P<cpap>a\.?\s*m\.?|p\.?\s*m\.?))?|(?P<mpm>{NUM_1_59})\s+(?:minutos?\s+)?para\s+(?:la\s+(?P<mph1>una|1)|las\s+(?P<mph2>{HOUR_1_23}))(?:\s*(?P<mpap>a\.?\s*m\.?|p\.?\s*m\.?))?|(?P<tn>(?:(?:a\s+)?las\s+)?12\s+(?:del?\s+mediod[íÍi]a|del\s+d[íÍi]a))|(?P<tnt>(?:(?:a\s+)?las\s+)?12\s+de\s+la\s+(?:noche|madrugada))|(?:a\s+)?(?:la\s+(?P<lh1>una|1)|las\s+(?P<lh2>{HOUR_1_23}))\s+(?:(?P<las_kw>en\s+punto|y\s+media|y\s+cuarto|menos\s+cuarto|horas?|hrs?\.?|hs\.?|h)|(?:y|con)\s+(?P<las_add>{NUM_1_59})|menos\s+(?P<las_sub>{NUM_1_59}))(?:\s*(?P<lap>a\.?\s*m\.?|p\.?\s*m\.?))?|(?P<bh>{HOUR_1_23})\s+(?P<bkw>en\s+punto|y\s+media|y\s+cuarto|menos\s+cuarto)(?:\s*(?P<bap>a\.?\s*m\.?|p\.?\s*m\.?))?|(?:(?:a\s+)?(?:la\s+(?P<mh1>una|1)|las\s+(?P<mh2>{HOUR_1_12}))|(?P<mh3>{HOUR_1_12}))\s+(?:de|por)\s+la\s+(?P<mmer>ma[ñÑ]ana|madrugada|tarde|noche))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, r"[0-9a-zA-ZáéíóúüñÁÉÍÓÚÜÑ.:/-]"),
                    ("guard1", false, G_ALNUM),
                ],
                |c, _| {
                    if c.name("tn").is_some() {
                        return Some(vec![Component::Time(12, Some(0), None)]);
                    }
                    if c.name("tnt").is_some() {
                        return Some(vec![Component::Time(0, Some(0), Some(false))]);
                    }
                    if let Some(hs) = c.name("cph1").or_else(|| c.name("cph2")) {
                        let h = parse_es_num(hs.as_str())?;
                        let ap = parse_ap(c.name("cpap"));
                        if !valid_h_ap(h, ap) {
                            return None;
                        }
                        return Some(vec![Component::Time((h - 1).rem_euclid(24), Some(45), ap)]);
                    }
                    if let Some(m_cap) = c.name("mpm") {
                        let min = parse_es_num(m_cap.as_str())?;
                        if !(1..=59).contains(&min) {
                            return None;
                        }
                        let h = parse_es_num(c.name("mph1").or_else(|| c.name("mph2"))?.as_str())?;
                        let ap = parse_ap(c.name("mpap"));
                        if !valid_h_ap(h, ap) {
                            return None;
                        }
                        return Some(vec![Component::Time(
                            (h - 1).rem_euclid(24),
                            Some(60 - min),
                            ap,
                        )]);
                    }
                    if let Some(hs) = c.name("lh1").or_else(|| c.name("lh2")) {
                        let raw_h = hs.as_str();
                        let h = parse_es_num(raw_h)?;
                        let ap = parse_ap(c.name("lap"));
                        if !valid_h_ap(h, ap) {
                            return None;
                        }
                        if let Some(kw) = c.name("las_kw") {
                            let kw_lower = kw.as_str().to_lowercase();
                            if kw_lower.starts_with('h') {
                                let is_num_24_or_padded = raw_h.bytes().all(|b| b.is_ascii_digit())
                                    && (h >= 13 || raw_h.len() == 2);
                                if kw_lower != "h" && h != 0 && !is_num_24_or_padded {
                                    return None;
                                }
                                return Some(vec![Component::Time(h, Some(0), ap)]);
                            }
                            if kw_lower.starts_with("en") {
                                return Some(vec![Component::Time(h, Some(0), ap)]);
                            }
                            if kw_lower.ends_with("media") {
                                return Some(vec![Component::Time(h, Some(30), ap)]);
                            }
                            if kw_lower.starts_with("y") {
                                return Some(vec![Component::Time(h, Some(15), ap)]);
                            }
                            return Some(vec![Component::Time(
                                (h - 1).rem_euclid(24),
                                Some(45),
                                ap,
                            )]);
                        }
                        if let Some(add_m) = c.name("las_add") {
                            let min = parse_es_num(add_m.as_str())?;
                            if !(1..=59).contains(&min) {
                                return None;
                            }
                            return Some(vec![Component::Time(h, Some(min), ap)]);
                        }
                        let sub_m = parse_es_num(c.name("las_sub")?.as_str())?;
                        if !(1..=59).contains(&sub_m) {
                            return None;
                        }
                        return Some(vec![Component::Time(
                            (h - 1).rem_euclid(24),
                            Some(60 - sub_m),
                            ap,
                        )]);
                    }
                    if let Some(bh) = c.name("bh") {
                        let h = parse_es_num(bh.as_str())?;
                        let ap = parse_ap(c.name("bap"));
                        if !valid_h_ap(h, ap) {
                            return None;
                        }
                        let kw = c.name("bkw")?.as_str().to_lowercase();
                        return Some(vec![if kw.starts_with("en") {
                            Component::Time(h, Some(0), ap)
                        } else if kw.ends_with("media") {
                            Component::Time(h, Some(30), ap)
                        } else if kw.starts_with('y') {
                            Component::Time(h, Some(15), ap)
                        } else {
                            Component::Time((h - 1).rem_euclid(24), Some(45), ap)
                        }]);
                    }
                    let mh = c
                        .name("mh1")
                        .or_else(|| c.name("mh2"))
                        .or_else(|| c.name("mh3"))?;
                    let h = parse_es_num(mh.as_str())?;
                    if !(1..=12).contains(&h) {
                        return None;
                    }
                    let mer = c.name("mmer")?.as_str().to_lowercase();
                    let pm = matches!(mer.as_str(), "tarde" | "noche");
                    Some(vec![Component::Time(h, None, Some(pm))])
                },
            ),
            Pattern::with_builder(
                "es_aLasHour",
                &format!(
                    r"(?i)(?P<guard0>)a\s+(?:la\s+(?P<h1>una|1)|las\s+(?P<h2>{HOUR_1_23}))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, G_ALNUM),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9:a-zA-ZáéíóúüñÁÉÍÓÚÜÑ%]|\.[0-9]|\s*(?:a\.?\s*m\.?|p\.?\s*m\.?)|\s+(?:d[íÍi]as?|semanas?|mes(?:es)?|a[ñÑn]os?|horas?|minutos?|segundos?|personas?|veces|km|kg|euros?|d[óÓo]lares?)\b)",
                    ),
                ],
                |c, _| {
                    let h = parse_es_num(c.name("h1").or_else(|| c.name("h2"))?.as_str())?;
                    (1..=23)
                        .contains(&h)
                        .then(|| vec![Component::Time(h, None, None)])
                },
            ),
            Pattern::new(
                "es_fixedTime",
                r"(?i)(?P<guard0>)(medianoche|mediod[íÍi]a)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("mediodía", &[Component::Time(12, Some(0), None)]),
                    ("mediodia", &[Component::Time(12, Some(0), None)]),
                    ("medianoche", &[Component::Time(0, Some(0), None)]),
                ],
            ),
            Pattern::with_builder(
                "es_meridiem",
                r"(?i)(?P<guard0>)(?:de|por|en)\s+la\s+(?P<m>tarde|noche|ma[ñÑ]ana|madrugada)(?P<guard1>)",
                &alnum_guards,
                |c, _| {
                    let m = c.name("m")?.as_str().to_lowercase();
                    let pm = matches!(m.as_str(), "tarde" | "noche");
                    Some(vec![Component::Meridiem(pm)])
                },
            ),
            Pattern::with_builder(
                "es_elDia",
                r"(?i)(?P<guard0>)el\s+(?:d[íÍi]a\s+)?(?P<d>1[º°]|[0-9]{1,2})(?P<guard1>)",
                &[
                    ("guard0", true, G_ALNUM),
                    (
                        "guard1",
                        false,
                        r"(?:[0-9:/\-a-zA-ZáéíóúüñÁÉÍÓÚÜÑ%€$º°]|\.[0-9])",
                    ),
                ],
                |c, _| Some(vec![Component::Day(parse_es_day(c.name("d")?.as_str())?)]),
            ),
            Pattern::new(
                "es_month",
                r"(?i)(?P<guard0>)(septiembre|setiembre|noviembre|diciembre|febrero|octubre|agosto|enero|marzo|abril|junio|julio|mayo|sept\.?|ene\.|feb\.?|abr\.?|jun\.|jul\.|sep\.|oct\.|nov\.|dic\.)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("enero", &[Component::Month(1)]),
                    ("ene.", &[Component::Month(1)]),
                    ("febrero", &[Component::Month(2)]),
                    ("feb.", &[Component::Month(2)]),
                    ("feb", &[Component::Month(2)]),
                    ("marzo", &[Component::Month(3)]),
                    ("abril", &[Component::Month(4)]),
                    ("abr.", &[Component::Month(4)]),
                    ("abr", &[Component::Month(4)]),
                    ("mayo", &[Component::Month(5)]),
                    ("junio", &[Component::Month(6)]),
                    ("jun.", &[Component::Month(6)]),
                    ("julio", &[Component::Month(7)]),
                    ("jul.", &[Component::Month(7)]),
                    ("agosto", &[Component::Month(8)]),
                    ("septiembre", &[Component::Month(9)]),
                    ("setiembre", &[Component::Month(9)]),
                    ("sept.", &[Component::Month(9)]),
                    ("sept", &[Component::Month(9)]),
                    ("sep.", &[Component::Month(9)]),
                    ("octubre", &[Component::Month(10)]),
                    ("oct.", &[Component::Month(10)]),
                    ("noviembre", &[Component::Month(11)]),
                    ("nov.", &[Component::Month(11)]),
                    ("diciembre", &[Component::Month(12)]),
                    ("dic.", &[Component::Month(12)]),
                ],
            ),
            Pattern::new(
                "es_weekday",
                r"(?i)(?P<guard0>)(mi[éÉe]rcoles|viernes|domingo|martes|jueves|s[áÁa]bado|lunes|mi[éÉe]r\.?|mi[éÉe]\.?|s[áÁa]b\.?|lun\.|jue\.)(?P<guard1>)",
                &alnum_guards,
                &[
                    ("lunes", &[Component::Weekday(1)]),
                    ("lun.", &[Component::Weekday(1)]),
                    ("martes", &[Component::Weekday(2)]),
                    ("miércoles", &[Component::Weekday(3)]),
                    ("miercoles", &[Component::Weekday(3)]),
                    ("miér.", &[Component::Weekday(3)]),
                    ("miér", &[Component::Weekday(3)]),
                    ("mier.", &[Component::Weekday(3)]),
                    ("mié.", &[Component::Weekday(3)]),
                    ("mié", &[Component::Weekday(3)]),
                    ("jueves", &[Component::Weekday(4)]),
                    ("jue.", &[Component::Weekday(4)]),
                    ("viernes", &[Component::Weekday(5)]),
                    ("sábado", &[Component::Weekday(6)]),
                    ("sabado", &[Component::Weekday(6)]),
                    ("sáb.", &[Component::Weekday(6)]),
                    ("sáb", &[Component::Weekday(6)]),
                    ("domingo", &[Component::Weekday(7)]),
                ],
            ),
            Pattern::new("es_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

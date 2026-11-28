use crate::{Component, Language, Pattern};

const TASHKEEL: &str = "[\u{064B}-\u{065F}\u{0670}]*";

const WORD_CHAR: &str = "[0-9a-zA-Z\u{0621}-\u{063A}\u{0640}-\u{065F}\u{0670}-\u{06D3}]";
const WORD_NO_WF: &str =
    "[0-9a-zA-Z\u{0621}-\u{063A}\u{0640}\u{0642}-\u{0647}\u{0649}-\u{065F}\u{0670}-\u{06D3}]";
const DATE_GUARD0: &str = "[0-9./\\-\u{060D}a-zA-Z\u{0621}-\u{063A}\u{0640}\u{0642}-\u{0647}\u{0649}-\u{065F}\u{0670}-\u{06D3}]";
const DATE_GUARD1: &str = "(?:[0-9:/\u{060D}a-zA-Z\u{0621}-\u{063A}\u{0640}-\u{065F}\u{0670}-\u{06D3}]|\\.[0-9]|-[0-9]|\\s*هـ)";
const TIME_GUARD0_WF: &str =
    "[0-9.:/\\-a-zA-Z\u{0621}-\u{063A}\u{0640}\u{0642}-\u{0647}\u{0649}-\u{065F}\u{0670}-\u{06D3}]";
const TIME_GUARD1: &str = "[0-9:a-zA-Z\u{0621}-\u{063A}\u{0640}-\u{065F}\u{0670}-\u{06D3}]";
const YEAR_GUARD1: &str = "[0-9a-zA-Z\u{0621}-\u{063A}\u{0640}-\u{065F}\u{0670}-\u{06D3}]|\\s*هـ";

const MONTH_DAY_GUARD1: &str = "[0-9:a-zA-Z\u{0621}-\u{063A}\u{0640}-\u{065F}\u{0670}-\u{06D3}%٪]|\\.[0-9]|/[0-9]|-[0-9]|\\s*(?:دقيق[ةه]|دقائق|ثاني[ةه]|ثوان[يى]|ساع[ةه]|ساعات|[أإا]يام|يوم|[أإا]سابيع|[أإا]سبوع|[أإا]شهر|شهور|شهر|سنوات|[أإا]عوام|[aA]\\.?[mM]\\.?|[pP]\\.?[mM]\\.?|هـ|(?:سن[ةه]|عام[\u{064B}-\u{065F}]*(?:ا[\u{064B}-\u{065F}]*)?)(?:\\s*$|\\s+[^0-9\\s]|\\s+[0-9]{1,3}(?:[^0-9]|$)))";
const DAY_GUARD1: &str = "[:./\\-0-9a-zA-Z\u{0621}-\u{063A}\u{0640}-\u{065F}\u{0670}-\u{06D3}%٪]|\\s*(?:دقيق[ةه]|دقائق|ثاني[ةه]|ثوان[يى]|ساع[ةه]|ساعات|[أإا]يام|[أإا]سابيع|[أإا]سبوع|[أإا]شهر|شهور|شهر|سنوات|سن[ةه]|[أإا]عوام|عام|[aA]\\.?[mM]\\.?|[pP]\\.?[mM]\\.?|هـ|(?:من\\s+)?(?:شهر\\s+)?(?:يناير|فبراير|مارس|[أإا]بريل|مايو|يوني[وه]|يولي[وه]|[أإا]غسطس|سبتمبر|[أإا]كتوبر|نوفمبر|ديسمبر|كانون|شباط|[آأإا]ذار|نيسان|[أإا]يار|حزيران|تموز|[آأإا]ب|[أإا]يلول|تشرين))";
const TODAY_DAY_GUARD2: &str = "\\s*(?:صباحا?|صباح[\u{064B}-\u{065F}]*ا|مساء[\u{064B}-\u{065F}]*ا?|ظهر[\u{064B}-\u{065F}]*ا|عصر[\u{064B}-\u{065F}]*ا|ليل[\u{064B}-\u{065F}]*ا|فجر[\u{064B}-\u{065F}]*ا|قبل\\s+الظهر|بعد\\s+الظهر|ص\\.?|م\\.?)";
const OFFSET_SING_GUARD: &str = "\\s+(?:[0-9]|(?:ال)?(?:[أإا]حد|[إأا]ثنين|ثلاثاء|[أإا]ربعاء|خميس|جمع[ةه]|سبت)|غد|غد[\u{064B}-\u{065F}]*ا|[أإا]مس|ال[أإا]مس|البارح[ةه]|يناير|فبراير|مارس|[أإا]بريل|مايو|يوني[وه]|يولي[وه]|[أإا]غسطس|سبتمبر|[أإا]كتوبر|نوفمبر|ديسمبر|كانون|شباط|[آأإا]ذار|نيسان|[أإا]يار|حزيران|تموز|[آأإا]ب|[أإا]يلول|تشرين)";
const SPOKEN_MOD_NUM_GUARD: &str = "\\s+(?:يناير|فبراير|مارس|[أإا]بريل|مايو|يوني[وه]|يولي[وه]|[أإا]غسطس|سبتمبر|[أإا]كتوبر|نوفمبر|ديسمبر|كانون|شباط|[آأإا]ذار|نيسان|[أإا]يار|حزيران|تموز|[آأإا]ب|[أإا]يلول|تشرين)";

const WF_GUARDS: &[(&str, bool, &str)] =
    &[("guard0", true, WORD_NO_WF), ("guard1", false, WORD_CHAR)];
const WF_TIME_GUARDS: &[(&str, bool, &str)] = &[
    ("guard0", true, TIME_GUARD0_WF),
    ("guard1", false, WORD_CHAR),
];

/// Expands a compact Arabic pattern spec into a regex matching optional diacritics
/// and common hamza/taa-marbuta/alef-maqsura variants without `\p{...}` syntax.
fn ar_w(spec: &str) -> String {
    let mut out = String::with_capacity(spec.len() * 4);
    for ch in spec.chars() {
        match ch {
            ' ' => out.push_str("\\s+"),
            'A' => {
                out.push_str("[أإا]");
                out.push_str(TASHKEEL);
            }
            'M' => {
                out.push_str("[أإآا]");
                out.push_str(TASHKEEL);
            }
            'H' => {
                out.push_str("[ةه]");
                out.push_str(TASHKEEL);
            }
            'Y' => {
                out.push_str("[ىي]");
                out.push_str(TASHKEEL);
            }
            '\u{0621}'..='\u{063A}' | '\u{0641}'..='\u{064A}' => {
                out.push(ch);
                out.push_str(TASHKEEL);
            }
            _ => out.push(ch),
        }
    }
    out
}

/// Builds a non-capturing alternation sorted longest-first so longer variants always win.
fn ar_alt(items: &[&str]) -> String {
    let mut sorted: Vec<&str> = items.to_vec();
    sorted.sort_by_key(|s| std::cmp::Reverse(s.chars().count()));
    let mut out = String::from("(?:");
    for (i, item) in sorted.iter().enumerate() {
        if i > 0 {
            out.push('|');
        }
        out.push_str(&ar_w(item));
    }
    out.push(')');
    out
}

fn normalize_ar(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for ch in s.chars() {
        match ch {
            '\u{0640}' | '\u{064B}'..='\u{065F}' | '\u{0670}' => {}
            'أ' | 'إ' | 'آ' | 'ٱ' => out.push('ا'),
            'ة' => out.push('ه'),
            'ى' => out.push('ي'),
            _ => out.push(ch),
        }
    }
    out
}

fn ar_word_val(w: &str) -> Option<i32> {
    Some(match w {
        "صفر" => 0,
        "واحد" | "واحده" | "واحدا" | "الواحد" | "الواحده" | "احد" | "احدي" | "اول" | "اولي"
        | "الاول" | "الاولي" | "حادي" | "حاديه" | "الحادي" | "الحاديه" | "فاتح" => {
            1
        }
        "اثنان" | "اثنين" | "اثنا" | "اثني" | "اثنتان" | "اثنتين" | "اثنتا" | "اثنتي" | "ثنتان"
        | "ثنتين" | "ثاني" | "ثانيه" | "الثاني" | "الثانيه" => 2,
        "ثلاث" | "ثلاثه" | "ثلاثا" | "ثالث" | "ثالثه" | "الثالث" | "الثالثه" => {
            3
        }
        "اربع" | "اربعه" | "اربعا" | "رابع" | "رابعه" | "الرابع" | "الرابعه" => {
            4
        }
        "خمس" | "خمسه" | "خمسا" | "خامس" | "خامسه" | "الخامس" | "الخامسه" => {
            5
        }
        "ست" | "سته" | "ستا" | "سادس" | "سادسه" | "السادس" | "السادسه" => {
            6
        }
        "سبع" | "سبعه" | "سبعا" | "سابع" | "سابعه" | "السابع" | "السابعه" => {
            7
        }
        "ثمان" | "ثماني" | "ثمانيه" | "ثمانيا" | "ثامن" | "ثامنه" | "الثامن" | "الثامنه" => {
            8
        }
        "تسع" | "تسعه" | "تسعا" | "تاسع" | "تاسعه" | "التاسع" | "التاسعه" => {
            9
        }
        "عشر" | "عشره" | "عشرا" | "عاشر" | "عاشره" | "العاشر" | "العاشره" => {
            10
        }
        "عشرون" | "عشرين" | "العشرون" | "العشرين" => 20,
        "ثلاثون" | "ثلاثين" | "الثلاثون" | "الثلاثين" => 30,
        "اربعون" | "اربعين" | "الاربعون" | "الاربعين" => 40,
        "خمسون" | "خمسين" | "الخمسون" | "الخمسين" => 50,
        "ستون" | "ستين" | "الستون" | "الستين" => 60,
        "سبعون" | "سبعين" => 70,
        "ثمانون" | "ثمانين" => 80,
        "تسعون" | "تسعين" => 90,
        "مئه" | "مائه" => 100,
        _ => return None,
    })
}

fn parse_ar_num(s: &str) -> Option<i32> {
    let norm = normalize_ar(s.trim());
    if let Some(n) = crate::number(&norm) {
        return Some(n);
    }
    if let Some(rest) = norm.strip_prefix("ال")
        && let Some(n) = crate::number(rest.trim())
    {
        return Some(n);
    }
    let parts: Vec<&str> = norm.split_whitespace().collect();
    match parts.as_slice() {
        [single] => ar_word_val(single),
        [unit, ten] if matches!(*ten, "عشر" | "عشره") => {
            let u = ar_word_val(unit)?;
            (1..=9).contains(&u).then_some(10 + u)
        }
        [unit, w_dec] => {
            let dec = w_dec.strip_prefix('و')?;
            let u = ar_word_val(unit)?;
            let d = ar_word_val(dec)?;
            ((1..=9).contains(&u) && d >= 20 && d % 10 == 0).then_some(d + u)
        }
        [unit, "و", dec] => {
            let u = ar_word_val(unit)?;
            let d = ar_word_val(dec)?;
            ((1..=9).contains(&u) && d >= 20 && d % 10 == 0).then_some(d + u)
        }
        _ => None,
    }
}

fn lookup_month(s: &str) -> Option<i32> {
    let norm = normalize_ar(s.trim().trim_end_matches('.'));
    let clean: String = norm.split_whitespace().collect::<Vec<_>>().join(" ");
    Some(match clean.as_str() {
        "يناير" | "ينا" | "جانفي" | "كانون الثاني" | "كانون ثاني" | "كانون 2" | "ك2" => {
            1
        }
        "فبراير" | "فبر" | "فيفري" | "شباط" => 2,
        "مارس" | "مار" | "اذار" => 3,
        "ابريل" | "ابر" | "نيسان" => 4,
        "مايو" | "ايار" => 5,
        "يونيو" | "يونيه" | "يون" | "حزيران" => 6,
        "يوليو" | "يوليه" | "يول" | "تموز" | "جويليه" => 7,
        "اغسطس" | "اغس" | "اب" | "اوت" => 8,
        "سبتمبر" | "سبت" | "شتنبر" | "شوتنبر" | "ايلول" => 9,
        "اكتوبر" | "اكت" | "تشرين الاول" | "تشرين اول" | "تشرين 1" | "ت1" => {
            10
        }
        "نوفمبر" | "نوف" | "نونبر" | "تشرين الثاني" | "تشرين ثاني" | "تشرين 2" | "ت2" => {
            11
        }
        "ديسمبر" | "ديس" | "دجنبر" | "كانون الاول" | "كانون اول" | "كانون 1" | "ك1" => {
            12
        }
        _ => return None,
    })
}

fn lookup_weekday(s: &str) -> Option<i32> {
    let norm = normalize_ar(s.trim());
    Some(match norm.as_str() {
        "الاثنين" | "اثنين" => 1,
        "الثلاثاء" | "ثلاثاء" => 2,
        "الاربعاء" | "اربعاء" => 3,
        "الخميس" | "خميس" => 4,
        "الجمعه" | "جمعه" => 5,
        "السبت" | "سبت" => 6,
        "الاحد" | "احد" => 7,
        _ => return None,
    })
}

fn parse_nth_ord(s: &str) -> Option<i32> {
    let norm = normalize_ar(s.trim());
    Some(match norm.as_str() {
        "اول" | "اولي" | "الاول" | "الاولي" => 1,
        "ثاني" | "ثانيه" | "الثاني" | "الثانيه" => 2,
        "ثالث" | "ثالثه" | "الثالث" | "الثالثه" => 3,
        "رابع" | "رابعه" | "الرابع" | "الرابعه" => 4,
        "خامس" | "خامسه" | "الخامس" | "الخامسه" => 5,
        "اخر" | "الاخير" | "الاخيره" => -1,
        _ => return None,
    })
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

#[derive(Clone, Copy)]
enum ArMeridiem {
    Am,
    Pm,
    Night,
    Midnight,
}

fn classify_meridiem(raw: &str) -> Option<ArMeridiem> {
    let low = raw.trim().to_ascii_lowercase();
    let trimmed = low.trim_end_matches('.');
    if matches!(trimmed, "am" | "a.m") {
        return Some(ArMeridiem::Am);
    }
    if matches!(trimmed, "pm" | "p.m") {
        return Some(ArMeridiem::Pm);
    }
    let norm = normalize_ar(raw.trim());
    let clean: String = norm
        .trim_end_matches('.')
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ");
    Some(match clean.as_str() {
        "ص" | "صباحا" | "صباح" | "الصباح" | "في الصباح" | "فجرا" | "الفجر" | "قبل الظهر"
        | "ق.ظ" => ArMeridiem::Am,
        "م" | "مساءا" | "مساء" | "المساء" | "في المساء" | "ظهرا" | "الظهر" | "بعد الظهر"
        | "ب.ظ" | "عصرا" | "العصر" => ArMeridiem::Pm,
        "ليلا" | "الليل" | "في الليل" => ArMeridiem::Night,
        "منتصف الليل" | "نصف الليل" => ArMeridiem::Midnight,
        _ => return None,
    })
}

fn resolve_meridiem_pm(kind: ArMeridiem, h: i32) -> bool {
    match kind {
        ArMeridiem::Am | ArMeridiem::Midnight => false,
        ArMeridiem::Pm => true,
        ArMeridiem::Night => (5..=11).contains(&h),
    }
}

fn valid_h_ap(
    h: i32,
    ap: Option<ArMeridiem>,
    has_prefix_or_colon: bool,
    raw_ap: Option<&str>,
) -> bool {
    if !(0..24).contains(&h) {
        return false;
    }
    if let Some(ap_str) = raw_ap {
        let norm = normalize_ar(ap_str.trim())
            .trim_end_matches('.')
            .to_string();
        if matches!(norm.as_str(), "ص" | "م") && !has_prefix_or_colon && !(1..=12).contains(&h) {
            return false;
        }
    }
    match ap {
        Some(ArMeridiem::Am) => (0..=12).contains(&h),
        Some(ArMeridiem::Midnight) => h == 12 || h == 0,
        Some(ArMeridiem::Night) => (1..=12).contains(&h),
        Some(ArMeridiem::Pm) => (1..=23).contains(&h),
        None => true,
    }
}

fn apply_meridiem_to_24h(h: i32, kind: ArMeridiem) -> i32 {
    let pm = resolve_meridiem_pm(kind, h);
    if pm && h < 12 {
        h + 12
    } else if !pm && h == 12 {
        0
    } else {
        h
    }
}

fn parse_offset_unit(unit: &str, val: i32) -> Option<Component> {
    let norm = normalize_ar(unit.trim());
    Some(match norm.as_str() {
        "يوم" | "يوما" | "يومان" | "يومين" | "ايام" => {
            Component::RelativeDay(val)
        }
        "اسبوع" | "اسبوعا" | "اسبوعان" | "اسبوعين" | "اسابيع" => {
            Component::Week(val, false)
        }
        "شهر" | "شهرا" | "شهران" | "شهرين" | "اشهر" | "شهور" => {
            Component::MonthOffset(val)
        }
        "سنه" | "سنتان" | "سنتين" | "سنوات" | "سنين" | "عام" | "عاما" | "عامان" | "عامين"
        | "اعوام" => Component::YearOffset(val),
        _ => return None,
    })
}

fn cap_triple<'t>(
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

fn parse_mod_minutes(s: &str) -> Option<(i32, i32)> {
    let norm = normalize_ar(s.trim());
    let words: Vec<&str> = norm.split_whitespace().collect();
    if words.is_empty() {
        return None;
    }
    let first = words[0];
    if matches!(first, "تماما" | "بالضبط" | "ضبطا" | "ضبط") {
        return Some((1, 0));
    }
    if first == "الا" {
        let rest = words[1..].join(" ");
        let m = match rest.as_str() {
            "ربع" | "ربعا" | "الربع" => 15,
            "ثلث" | "ثلثا" | "الثلث" => 20,
            "دقيقه" | "دقيقه واحده" => 1,
            "دقيقتين" | "دقيقتان" => 2,
            _ => {
                let stripped = rest
                    .strip_suffix(" دقيقه")
                    .or_else(|| rest.strip_suffix(" دقائق"))
                    .unwrap_or(&rest);
                parse_ar_num(stripped)?
            }
        };
        return (1..60).contains(&m).then_some((-1, m));
    }
    let after_w = if first == "و" {
        words[1..].join(" ")
    } else if let Some(stripped) = first.strip_prefix('و') {
        if words.len() == 1 {
            stripped.to_string()
        } else {
            format!("{stripped} {}", words[1..].join(" "))
        }
    } else {
        return None;
    };
    let clean = after_w.trim();
    let m = match clean {
        "نصف" | "النصف" => 30,
        "نصف وخمس" | "النصف وخمس" | "نصف وخمس دقائق" | "النصف وخمس دقائق" => {
            35
        }
        "نصف الا خمس" | "النصف الا خمس" | "نصف الا خمس دقائق" | "النصف الا خمس دقائق" => {
            25
        }
        "ربع" | "الربع" => 15,
        "ثلث" | "الثلث" => 20,
        "دقيقه" | "دقيقه واحده" => 1,
        "دقيقتين" | "دقيقتان" => 2,
        _ => {
            let stripped = clean
                .strip_suffix(" دقيقه")
                .or_else(|| clean.strip_suffix(" دقائق"))
                .unwrap_or(clean);
            parse_ar_num(stripped)?
        }
    };
    (1..60).contains(&m).then_some((1, m))
}

fn parse_anchor_offset(s: &str) -> Option<i32> {
    let norm = normalize_ar(s.trim());
    Some(match norm.as_str() {
        "القادم" | "القادمه" | "قادم" | "قادمه" | "المقبل" | "المقبله" | "مقبل" | "مقبله"
        | "التالي" | "التاليه" | "تالي" | "تاليه" | "الاتي" | "الاتيه" => {
            1
        }
        "الماضي" | "الماضيه" | "ماضي" | "ماضيه" | "السابق" | "السابقه" | "سابق" | "سابقه"
        | "الفائت" | "الفائته" | "فائت" | "فائته" | "المنصرم" | "المنصرمه" | "الاخير" | "الاخيره" => {
            -1
        }
        "هذا" | "هذه" | "الحالي" | "الحاليه" | "الجاري" | "الجاريه" => {
            0
        }
        _ => return None,
    })
}

pub fn language() -> Language {
    let month_stand_alt = ar_alt(&[
        "كانون الثانY",
        "كانون ثانY",
        "كانون الAول",
        "كانون Aول",
        "تشرين الAول",
        "تشرين Aول",
        "تشرين الثانY",
        "تشرين ثانY",
        "يناير",
        "فبراير",
        "مارس",
        "Aبريل",
        "مايو",
        "يونيH",
        "يونيو",
        "يوليH",
        "يوليو",
        "Aغسطس",
        "سبتمبر",
        "Aكتوبر",
        "نوفمبر",
        "ديسمبر",
        "شباط",
        "Mذار",
        "نيسان",
        "Aيار",
        "حزيران",
        "تموز",
        "آب",
        "Aيلول",
        "جانفY",
        "فيفرY",
        "جويليH",
        "أوت",
        "شتنبر",
        "شوتنبر",
        "نونبر",
        "دجنبر",
        "ينا\\.",
        "فبر\\.",
        "مار\\.",
        "Aبر\\.",
        "يون\\.",
        "يول\\.",
        "Aغس\\.",
        "سبت\\.",
        "Aكت\\.",
        "نوف\\.",
        "ديس\\.",
    ]);
    let month_ctx_alt = ar_alt(&[
        "كانون الثانY",
        "كانون ثانY",
        "كانون الAول",
        "كانون Aول",
        "كانون 2",
        "كانون 1",
        "تشرين الAول",
        "تشرين Aول",
        "تشرين الثانY",
        "تشرين ثانY",
        "تشرين 1",
        "تشرين 2",
        "يناير",
        "فبراير",
        "مارس",
        "Aبريل",
        "مايو",
        "يونيH",
        "يونيو",
        "يوليH",
        "يوليو",
        "Aغسطس",
        "سبتمبر",
        "Aكتوبر",
        "نوفمبر",
        "ديسمبر",
        "شباط",
        "Mذار",
        "نيسان",
        "Aيار",
        "حزيران",
        "تموز",
        "Mب",
        "Aيلول",
        "جانفY",
        "فيفرY",
        "جويليH",
        "أوت",
        "شتنبر",
        "شوتنبر",
        "نونبر",
        "دجنبر",
        "ك1",
        "ك2",
        "ت1",
        "ت2",
        "ينا\\.",
        "فبر\\.",
        "مار\\.",
        "Aبر\\.",
        "يون\\.",
        "يول\\.",
        "Aغس\\.",
        "سبت\\.",
        "Aكت\\.",
        "نوف\\.",
        "ديس\\.",
    ]);

    let wd_def = ar_alt(&[
        "الAحد",
        "الAثنين",
        "الثلاثاء",
        "الAربعاء",
        "الخميس",
        "الجمعH",
        "السبت",
    ]);
    let wd_bare_safe = ar_alt(&["ثلاثاء", "Aربعاء", "خميس", "جمعH", "سبت"]);
    let wd_bare_ambig = ar_alt(&["Aحد", "Aثنين"]);
    let wd_bare = ar_alt(&["Aحد", "Aثنين", "ثلاثاء", "Aربعاء", "خميس", "جمعH", "سبت"]);
    let wd_any = format!("(?:{wd_def}|{wd_bare})");

    let unit_1_9 = ar_alt(&[
        "ثلاثH",
        "ثلاثا",
        "AربعH",
        "Aربعا",
        "خمسH",
        "خمسا",
        "ستH",
        "ستا",
        "سبعH",
        "سبعا",
        "ثمانيH",
        "ثمانيا",
        "ثمانY",
        "تسعH",
        "تسعا",
        "واحدH",
        "واحدا",
        "واحد",
        "اثنان",
        "اثنين",
        "اثنتان",
        "اثنتين",
        "ثنتان",
        "ثنتين",
        "ثلاث",
        "Aربع",
        "خمس",
        "ست",
        "سبع",
        "ثمان",
        "تسع",
        "AحدY",
        "Aحد",
        "عشرH",
        "عشرا",
        "عشر",
    ]);
    let teen_11_19 = format!(
        "(?:{}|{}|{})",
        ar_alt(&["AحدY عشرH", "AحدY عشر"]),
        ar_alt(&["Aحد عشرH", "Aحد عشر"]),
        format!(
            "(?:{}|{})\\s+{}",
            ar_w("Aثن(?:ا|Y|تا|تY)"),
            ar_alt(&[
                "ثلاثH",
                "AربعH",
                "خمسH",
                "ستH",
                "سبعH",
                "ثمانY",
                "ثمانيH",
                "تسعH",
                "ثلاث",
                "Aربع",
                "خمس",
                "ست",
                "سبع",
                "ثمان",
                "تسع",
            ]),
            ar_alt(&["عشرH", "عشر"]),
        )
    );
    let dec_20_50 = ar_alt(&[
        "عشرون",
        "عشرين",
        "ثلاثون",
        "ثلاثين",
        "Aربعون",
        "Aربعين",
        "خمسون",
        "خمسين",
    ]);
    let dec_20_90 = ar_alt(&[
        "عشرون",
        "عشرين",
        "ثلاثون",
        "ثلاثين",
        "Aربعون",
        "Aربعين",
        "خمسون",
        "خمسين",
        "ستون",
        "ستين",
        "سبعون",
        "سبعين",
        "ثمانون",
        "ثمانين",
        "تسعون",
        "تسعين",
        "مائH",
        "مئH",
    ]);
    let num_1_59 = format!(
        "(?:[0-9]{{1,2}}|(?:{unit_1_9}\\s+{}\\s*{dec_20_50})|{teen_11_19}|{dec_20_50}|{unit_1_9})",
        ar_w("و")
    );
    let num_any = format!(
        "(?:[0-9]+|(?:{unit_1_9}\\s+{}\\s*{dec_20_90})|{teen_11_19}|{dec_20_90}|{unit_1_9}|{})",
        ar_w("و"),
        ar_w("صفر")
    );

    let ord_stem = ar_alt(&[
        "حادYH",
        "حادY",
        "ثانYH",
        "ثانY",
        "ثالثH",
        "ثالث",
        "رابعH",
        "رابع",
        "خامسH",
        "خامس",
        "سادسH",
        "سادس",
        "سابعH",
        "سابع",
        "ثامنH",
        "ثامن",
        "تاسعH",
        "تاسع",
        "واحدH",
        "AولY",
        "Aول",
    ]);
    let ord_20_30 = format!(
        "(?:{})?{}",
        ar_w("ال"),
        ar_alt(&["عشرون", "عشرين", "ثلاثون", "ثلاثين"])
    );
    let ord_21_31 = format!(
        "(?:{})?{ord_stem}\\s+{}\\s*{ord_20_30}",
        ar_w("ال"),
        ar_w("و")
    );
    let ord_11_19 = format!(
        "(?:{})?{ord_stem}\\s+{}",
        ar_w("ال"),
        ar_alt(&["عشرH", "عشر"])
    );
    let ord_1_10 = format!(
        "(?:{})?{}",
        ar_w("ال"),
        ar_alt(&[
            "عاشرH",
            "عاشر",
            "AولY",
            "Aول",
            "واحدH",
            "ثانYH",
            "ثانY",
            "ثالثH",
            "ثالث",
            "رابعH",
            "رابع",
            "خامسH",
            "خامس",
            "سادسH",
            "سادس",
            "سابعH",
            "سابع",
            "ثامنH",
            "ثامن",
            "تاسعH",
            "تاسع",
            "عشرH",
        ])
    );
    let ord_1_31 = format!("(?:{ord_21_31}|{ord_11_19}|{ord_20_30}|{ord_1_10})");
    let day_card_words = format!(
        "(?:{}|{teen_11_19}|{}|{unit_1_9})",
        format!(
            "(?:{unit_1_9}\\s+{}\\s*{})",
            ar_w("و"),
            ar_alt(&["عشرون", "عشرين", "ثلاثون", "ثلاثين"])
        ),
        ar_alt(&["عشرون", "عشرين", "ثلاثون", "ثلاثين"]),
    );
    let day_part = format!(
        "(?:{ord_1_31}|{}|(?:{}ـ?\\s*)?[0-9]{{1,2}}|{day_card_words})",
        ar_w("فاتح"),
        ar_w("ال")
    );

    let hour_ord = format!(
        "(?:{}|{ord_1_10})",
        format!(
            "(?:{})?{}\\s+{}",
            ar_w("ال"),
            ar_alt(&["حادYH", "حادY", "ثانYH", "ثانY"]),
            ar_alt(&["عشرH", "عشر"])
        )
    );
    let hour_any = format!(
        "(?:[0-9]{{1,2}}|{hour_ord}|{}|{})",
        ar_alt(&[
            "Aثنا عشرH",
            "Aثنا عشر",
            "AثنY عشرH",
            "AثنY عشر",
            "Aثنتا عشرH",
            "Aثنتا عشر",
            "AثنتY عشرH",
            "AثنتY عشر",
        ]),
        ar_alt(&[
            "AحدY عشرH",
            "AحدY عشر",
            "Aحد عشرH",
            "Aحد عشر",
            "واحدH",
            "واحد",
            "ثلاثH",
            "AربعH",
            "خمسH",
            "ستH",
            "سبعH",
            "ثمانيH",
            "ثمانY",
            "تسعH",
            "عشرH",
            "ثلاث",
            "Aربع",
            "خمس",
            "ست",
            "سبع",
            "ثمان",
            "تسع",
            "عشر",
            "صفر",
        ])
    );

    let mod_next = ar_alt(&[
        "القادمH",
        "القادم",
        "قادمH",
        "قادم",
        "المقبلH",
        "المقبل",
        "مقبلH",
        "مقبل",
        "التاليH",
        "التالY",
        "تالYH",
        "تالY",
        "الMتYH",
        "الMتY",
    ]);
    let mod_last = ar_alt(&[
        "الماضYH",
        "الماضY",
        "ماضYH",
        "ماضY",
        "السابقH",
        "السابق",
        "سابقH",
        "سابق",
        "الفائتH",
        "الفائت",
        "فائتH",
        "فائت",
        "المنصرمH",
        "المنصرم",
        "الAخيرH",
        "الAخير",
    ]);
    let mod_this = ar_alt(&["الحالYH", "الحالY", "الجارYH", "الجارY", "هذا", "هذه"]);

    let half_mod = ar_alt(&[
        "النصف وخمس دقائق",
        "نصف وخمس دقائق",
        "النصف و خمس دقائق",
        "نصف و خمس دقائق",
        "النصف Aلا خمس دقائق",
        "نصف Aلا خمس دقائق",
        "النصف وخمس",
        "نصف وخمس",
        "النصف و خمس",
        "نصف و خمس",
        "النصف Aلا خمس",
        "نصف Aلا خمس",
        "النصف",
        "نصف",
    ]);
    let make_time_mod = |g_add: &str, g_sub: &str| {
        format!(
            "(?:{}|{}|{})",
            ar_alt(&["تماما", "بالضبط", "ضبطا", "ضبط"]),
            format!(
                "{}\\s*(?:{half_mod}|{}|{}|{}|{})",
                ar_w("و"),
                ar_alt(&["الربع", "ربعا", "ربع"]),
                ar_alt(&["الثلث", "ثلثا", "ثلث"]),
                ar_alt(&["دقيقتين", "دقيقتان", "دقيقH واحدH", "دقيقH"]),
                format!(
                    "(?:{num_1_59})(?:\\s*{}|(?P<{g_add}>))",
                    ar_alt(&["دقائق", "دقيقH"])
                )
            ),
            format!(
                "{}\\s+(?:{}|{})",
                ar_w("Aلا"),
                ar_alt(&[
                    "الربع",
                    "ربعا",
                    "ربع",
                    "الثلث",
                    "ثلثا",
                    "ثلث",
                    "دقيقتين",
                    "دقيقتان",
                    "دقيقH واحدH",
                    "دقيقH",
                ]),
                format!(
                    "(?:{num_1_59})(?:\\s*{}|(?P<{g_sub}>))",
                    ar_alt(&["دقائق", "دقيقH"])
                )
            )
        )
    };
    let time_mod1 = make_time_mod("guard2", "guard3");
    let time_mod2 = make_time_mod("guard4", "guard5");

    let time_ap = format!(
        "(?:{}|[aA]\\.?\\s*[mM]\\.?|[pP]\\.?\\s*[mM]\\.?)",
        ar_alt(&[
            "منتصف الليل",
            "نصف الليل",
            "قبل الظهر",
            "بعد الظهر",
            "في الصباح",
            "في المساء",
            "في الليل",
            "صباحا",
            "صباح",
            "الصباح",
            "فجرا",
            "الفجر",
            "مساءا",
            "مساء",
            "المساء",
            "ظهرا",
            "الظهر",
            "عصرا",
            "العصر",
            "ليلا",
            "الليل",
            "ق\\.ظ\\.?",
            "ب\\.ظ\\.?",
            "ص\\.?",
            "م\\.?",
        ])
    );

    let mer_word_only = ar_alt(&[
        "في الصباح",
        "في المساء",
        "في الليل",
        "قبل الظهر",
        "بعد الظهر",
        "صباحا",
        "صباح",
        "الصباح",
        "فجرا",
        "الفجر",
        "مساءا",
        "مساء",
        "المساء",
        "ظهرا",
        "عصرا",
        "العصر",
        "ليلا",
        "الليل",
    ]);

    let miladi = ar_alt(&["ميلادYH", "ميلادY", "م\\.?"]);

    let glue_words = ar_alt(&[
        "في",
        "عند",
        "من",
        "على",
        "تمام",
        "الساعH",
        "الموافق",
        "بتاريخ",
        "تاريخ",
    ]);
    let glue =
        format!("[\\s,\u{060C}]+(?:{glue_words}(?:[\\s,\u{060C}]+{glue_words})*[\\s,\u{060C}]+)?");

    Language::new(
        "ar",
        &glue,
        vec![
            Pattern::with_builder(
                "ar_numericDate",
                "(?P<guard0>)(?:(?P<iy>[0-9]{4})[-/.\u{060D}](?P<im>[0-9]{1,2})[-/.\u{060D}](?P<id>[0-9]{1,2})|(?P<sd>[0-9]{1,2})/(?P<sm>[0-9]{1,2})/(?P<sy>[0-9]{2,4})|(?P<dd>[0-9]{1,2})-(?P<dm>[0-9]{1,2})-(?P<dy>[0-9]{2,4})|(?P<pd>[0-9]{1,2})\\.(?P<pm>[0-9]{1,2})\\.(?P<py>[0-9]{2,4})|(?P<ad>[0-9]{1,2})\u{060D}(?P<am>[0-9]{1,2})\u{060D}(?P<ay>[0-9]{2,4})|(?P<yd>[0-9]{1,2})/(?P<ym>0[1-9]|1[0-2]))(?P<guard1>)",
                &[
                    ("guard0", true, DATE_GUARD0),
                    ("guard1", false, DATE_GUARD1),
                ],
                |c, _| {
                    if let Some((ys, ms, ds)) = cap_triple(c, "iy", "im", "id") {
                        return Some(vec![
                            Component::Year(crate::number(ys)?),
                            Component::Month(crate::number(ms)?),
                            Component::Day(crate::number(ds)?),
                        ]);
                    }
                    if let Some(yd) = c.name("yd") {
                        return Some(vec![
                            Component::Month(crate::number(c.name("ym")?.as_str())?),
                            Component::Day(crate::number(yd.as_str())?),
                        ]);
                    }
                    let (ds, ms, ys) = cap_triple(c, "sd", "sm", "sy")
                        .or_else(|| cap_triple(c, "dd", "dm", "dy"))
                        .or_else(|| cap_triple(c, "pd", "pm", "py"))
                        .or_else(|| cap_triple(c, "ad", "am", "ay"))?;
                    Some(vec![
                        Component::Year(parse_2_or_4_year(ys)?),
                        Component::Month(crate::number(ms)?),
                        Component::Day(crate::number(ds)?),
                    ])
                },
            ),
            Pattern::with_builder(
                "ar_nthWeekday",
                &format!(
                    "(?P<guard0>)(?:{}\\s+)?(?:(?P<ord1>{})\\s+(?:{}\\s+)?(?P<wd1>{wd_any})|(?P<wd2>{wd_def})\\s+(?P<ord2>{}))\\s+(?:{}|{})\\s+(?:{}\\s+)?(?P<mo>{month_ctx_alt})(?P<guard1>)",
                    ar_w("يوم"),
                    ar_alt(&[
                        "AولY",
                        "Aول",
                        "ثانYH",
                        "ثانY",
                        "ثالثH",
                        "ثالث",
                        "رابعH",
                        "رابع",
                        "خامسH",
                        "خامس",
                        "الAخيرH",
                        "الAخير",
                        "Mخر",
                    ]),
                    ar_w("يوم"),
                    ar_alt(&[
                        "الAولY",
                        "الAول",
                        "الثانYH",
                        "الثانY",
                        "الثالثH",
                        "الثالث",
                        "الرابعH",
                        "الرابع",
                        "الخامسH",
                        "الخامس",
                        "الAخيرH",
                        "الAخير",
                    ]),
                    ar_w("من"),
                    ar_w("في"),
                    ar_w("شهر"),
                ),
                WF_GUARDS,
                |c, _| {
                    let ord_s = c.name("ord1").or_else(|| c.name("ord2"))?.as_str();
                    let wd_s = c.name("wd1").or_else(|| c.name("wd2"))?.as_str();
                    let ord = parse_nth_ord(ord_s)?;
                    let wd = lookup_weekday(wd_s)?;
                    let mo = lookup_month(c.name("mo")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, mo)])
                },
            ),
            Pattern::with_builder(
                "ar_dayMonth",
                &format!(
                    "(?P<guard0>)(?:{}\\s+)?(?P<d>{day_part})(?:\\s+(?:{}\\s+)?(?:{}\\s+)?|[-/])(?P<m>{month_ctx_alt})(?P<guard1>)(?:(?:\\s*[,،]\\s*|\\s+(?:{}\\s+)?)(?:{}|{})\\s+(?P<y1>[0-9]{{4}})(?:\\s*{miladi})?|(?:\\s*[,،]\\s*|\\s+|[-/])(?P<y2>(?:1[0-9]|2[01])[0-9]{{2}})(?:\\s*{miladi})?)?(?P<guard2>)",
                    ar_alt(&["اليوم", "يوم"]),
                    ar_w("من"),
                    ar_w("شهر"),
                    ar_w("من"),
                    ar_w("سنH"),
                    ar_w("عام"),
                ),
                &[
                    ("guard0", true, WORD_NO_WF),
                    ("guard1", false, WORD_CHAR),
                    ("guard2", false, YEAR_GUARD1),
                ],
                |c, _| {
                    let d = parse_ar_num(c.name("d")?.as_str())?;
                    if !(1..=31).contains(&d) {
                        return Some(vec![
                            Component::Year(2025),
                            Component::Month(2),
                            Component::Day(30),
                        ]);
                    }
                    let m = lookup_month(c.name("m")?.as_str())?;
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(ym) = c.name("y1").or_else(|| c.name("y2")) {
                        out.push(Component::Year(crate::number(ym.as_str())?));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "ar_monthDay",
                &format!(
                    "(?P<guard0>)(?:{}\\s+)?(?P<m>{month_ctx_alt})\\s+(?:{}\\s+)?(?P<d>[0-9]{{1,2}})(?P<guard1>)(?:(?:\\s*[,،]\\s*|\\s+(?:{}\\s+)?(?:(?:{}|{})\\s+)?)(?P<y>(?:1[0-9]|2[01])[0-9]{{2}})(?:\\s*{miladi})?)?(?P<guard2>)",
                    ar_w("شهر"),
                    ar_w("يوم"),
                    ar_w("من"),
                    ar_w("سنH"),
                    ar_w("عام"),
                ),
                &[
                    ("guard0", true, WORD_NO_WF),
                    ("guard1", false, MONTH_DAY_GUARD1),
                    ("guard2", false, YEAR_GUARD1),
                ],
                |c, _| {
                    let m = lookup_month(c.name("m")?.as_str())?;
                    let d = crate::number(c.name("d")?.as_str())?;
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(ym) = c.name("y") {
                        out.push(Component::Year(crate::number(ym.as_str())?));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "ar_monthYear",
                &format!(
                    "(?P<guard0>)(?:{}\\s+)?(?P<m>{month_ctx_alt})(?:\\s+(?:{}\\s+)?(?:{}|{})\\s+(?P<y1>[0-9]{{4}})|(?:\\s*[,،]\\s*|\\s+)(?P<y2>(?:1[0-9]|2[01])[0-9]{{2}}))(?:\\s*{miladi})?(?P<guard1>)",
                    ar_w("شهر"),
                    ar_w("من"),
                    ar_w("سنH"),
                    ar_w("عام"),
                ),
                &[("guard0", true, WORD_NO_WF), ("guard1", false, YEAR_GUARD1)],
                |c, _| {
                    let m = lookup_month(c.name("m")?.as_str())?;
                    let y = crate::number(c.name("y1").or_else(|| c.name("y2"))?.as_str())?;
                    Some(vec![Component::Month(m), Component::Year(y)])
                },
            ),
            Pattern::with_builder(
                "ar_namedYear",
                &format!(
                    "(?P<guard0>)(?:{}|{})\\s+(?P<y>[0-9]{{4}})(?:\\s*{miladi})?(?P<guard1>)",
                    ar_w("سنH"),
                    ar_w("عام"),
                ),
                &[("guard0", true, WORD_NO_WF), ("guard1", false, YEAR_GUARD1)],
                |c, _| Some(vec![Component::Year(crate::number(c.name("y")?.as_str())?)]),
            ),
            Pattern::with_builder(
                "ar_partOfDay",
                &format!(
                    "(?P<guard0>)(?P<pod>{})(?P<guard1>)",
                    ar_alt(&[
                        "الليلH الماضYH",
                        "الليلH الفائتH",
                        "الليلH السابقH",
                        "الليلH القادمH",
                        "الليلH المقبلH",
                        "ليلH البارحH",
                        "مساء البارحH",
                        "صباح البارحH",
                        "هذا الصباح",
                        "هذا المساء",
                        "هذه الليلH",
                        "ليلH اليوم",
                        "مساء اليوم",
                        "صباح اليوم",
                        "ظهر اليوم",
                        "عصر اليوم",
                        "مساء الغد",
                        "صباح الغد",
                        "ليلH Aمس",
                        "مساء Aمس",
                        "صباح Aمس",
                        "مساء غد",
                        "صباح غد",
                        "ليلH غد",
                        "الليلH",
                    ])
                ),
                WF_GUARDS,
                |c, _| {
                    let norm = normalize_ar(c.name("pod")?.as_str());
                    let clean: String = norm.split_whitespace().collect::<Vec<_>>().join(" ");
                    let day = if clean.contains("الماضيه")
                        || clean.contains("الفائته")
                        || clean.contains("السابقه")
                        || clean.contains("امس")
                        || clean.contains("البارحه")
                    {
                        -1
                    } else if clean.contains("القادمه")
                        || clean.contains("المقبله")
                        || clean.contains("غد")
                    {
                        1
                    } else {
                        0
                    };
                    let pm = !clean.contains("صباح");
                    Some(vec![Component::RelativeDay(day), Component::Meridiem(pm)])
                },
            ),
            Pattern::with_builder(
                "ar_relativeDayPhrase",
                &format!(
                    "(?P<guard0>)(?P<rel>{})(?P<guard1>)",
                    ar_alt(&[
                        "اليوم التالY",
                        "اليوم القادم",
                        "اليوم المقبل",
                        "اليوم السابق",
                        "اليوم الماضY",
                        "بعد الغد",
                        "بعد غدا",
                        "بعد غد",
                        "Aول البارحH",
                        "قبل البارحH",
                        "Aول الAمس",
                        "قبل الAمس",
                        "الAمس الAول",
                        "Aمس الAول",
                        "Aول Aمس",
                        "قبل Aمس",
                        "يوم الغد",
                        "يوم غد",
                        "هذا اليوم",
                    ])
                ),
                WF_GUARDS,
                |c, _| {
                    let norm = normalize_ar(c.name("rel")?.as_str());
                    let clean: String = norm.split_whitespace().collect::<Vec<_>>().join(" ");
                    let off = if clean.starts_with("بعد") {
                        2
                    } else if clean.contains("اول") || clean.starts_with("قبل") {
                        -2
                    } else if clean.contains("التالي")
                        || clean.contains("القادم")
                        || clean.contains("المقبل")
                        || clean.contains("غد")
                    {
                        1
                    } else if clean.contains("السابق") || clean.contains("الماضي") {
                        -1
                    } else {
                        0
                    };
                    Some(vec![Component::RelativeDay(off)])
                },
            ),
            Pattern::with_builder(
                "ar_relativeDay",
                &format!(
                    "(?:(?P<guard0>)(?P<wf>{})|(?P<guard2>)(?P<bare>{}))(?P<guard1>)",
                    ar_alt(&["بالAمس", "البارحH", "الAمس", "اليوم", "الغد", "غدا", "Aمس"]),
                    ar_alt(&["امس", "غد"]),
                ),
                &[
                    ("guard0", true, WORD_NO_WF),
                    ("guard2", true, WORD_CHAR),
                    ("guard1", false, WORD_CHAR),
                ],
                |c, _| {
                    let raw = c.name("wf").or_else(|| c.name("bare"))?.as_str();
                    let norm = normalize_ar(raw);
                    let off = match norm.as_str() {
                        "اليوم" => 0,
                        "غد" | "غدا" | "الغد" => 1,
                        "امس" | "الامس" | "بالامس" | "البارحه" => -1,
                        _ => return None,
                    };
                    Some(vec![Component::RelativeDay(off)])
                },
            ),
            Pattern::with_builder(
                "ar_doubleAnchor",
                &format!(
                    "(?P<guard0>)(?:(?P<u1>{})\\s+(?:(?:{}|{})\\s+)?(?:(?P<n1>{})\\s+{}|(?P<p1>{})\\s+{})|(?P<n2>{})\\s+(?P<u2>{})\\s+{}|(?P<p2>{})\\s+(?P<u3>{})\\s+{})(?P<guard1>)",
                    ar_alt(&["الAسبوع", "الشهر", "السنH", "العام"]),
                    ar_w("الذY"),
                    ar_w("التY"),
                    ar_w("بعد"),
                    ar_alt(&[
                        "القادمH",
                        "القادم",
                        "المقبلH",
                        "المقبل",
                        "التالYH",
                        "التالY"
                    ]),
                    ar_w("قبل"),
                    ar_alt(&[
                        "الماضYH",
                        "الماضY",
                        "السابقH",
                        "السابق",
                        "الفائتH",
                        "الفائت"
                    ]),
                    ar_w("بعد"),
                    ar_alt(&["الAسبوع", "الشهر", "السنH", "العام"]),
                    ar_alt(&["القادمH", "القادم", "المقبلH", "المقبل"]),
                    ar_w("قبل"),
                    ar_alt(&["الAسبوع", "الشهر", "السنH", "العام"]),
                    ar_alt(&["الماضYH", "الماضY", "السابقH", "السابق"]),
                ),
                WF_GUARDS,
                |c, _| {
                    let off = if c.name("n1").or_else(|| c.name("n2")).is_some() {
                        2
                    } else {
                        -2
                    };
                    let u = normalize_ar(
                        c.name("u1")
                            .or_else(|| c.name("u2"))
                            .or_else(|| c.name("u3"))?
                            .as_str(),
                    );
                    Some(vec![match u.as_str() {
                        "الاسبوع" => Component::Week(off, true),
                        "الشهر" => Component::MonthOffset(off),
                        _ => Component::YearOffset(off),
                    }])
                },
            ),
            Pattern::with_builder(
                "ar_weekend",
                &format!(
                    "(?P<guard0>)(?:{}|{})(?:\\s+(?:(?P<past>{mod_last})|{mod_next}|{mod_this}))?(?P<guard1>)",
                    ar_alt(&[
                        "عطلH نهايH الAسبوع",
                        "عطلH Mخر الAسبوع",
                        "نهايH الAسبوع",
                        "Mخر الAسبوع",
                    ]),
                    ar_alt(&["الويكند", "الويك اند", "ويكند"]),
                ),
                WF_GUARDS,
                |c, _| {
                    if c.name("past").is_some() {
                        Some(vec![Component::Week(-1, false), Component::Weekday(7)])
                    } else {
                        Some(vec![Component::Weekend])
                    }
                },
            ),
            Pattern::with_builder(
                "ar_anchor",
                &format!(
                    "(?P<guard0>)(?:(?P<pre>{})\\s+(?P<u1>{})|(?P<u2>{})\\s+(?P<post>{}))(?P<guard1>)",
                    ar_alt(&["هذا", "هذه"]),
                    ar_alt(&["الAسبوع", "الشهر", "السنH", "العام"]),
                    ar_alt(&["الAسبوع", "الشهر", "السنH", "العام"]),
                    format!("(?:{mod_next}|{mod_last}|{mod_this})"),
                ),
                WF_GUARDS,
                |c, _| {
                    let (u_s, off) = if let Some(u1) = c.name("u1") {
                        (u1.as_str(), 0)
                    } else {
                        (
                            c.name("u2")?.as_str(),
                            parse_anchor_offset(c.name("post")?.as_str())?,
                        )
                    };
                    let u = normalize_ar(u_s);
                    Some(vec![match u.as_str() {
                        "الاسبوع" => Component::Week(off, true),
                        "الشهر" => Component::MonthOffset(off),
                        _ => Component::YearOffset(off),
                    }])
                },
            ),
            Pattern::with_builder(
                "ar_within",
                &format!(
                    "(?P<guard0>)(?:{}|{}\\s+{})\\s+(?:(?:{})\\s+(?:{}ـ?\\s*)?(?P<n2>{num_any})\\s+(?:{})|(?P<sing_one>{})|(?P<dual>{})|(?:{}ـ?\\s*)?(?P<n1>{num_any})\\s+(?P<u1>{})(?:\\s+{})?|(?P<sing>{}))(?P<guard1>)",
                    ar_alt(&["في خلال", "خلال"]),
                    ar_w("في"),
                    ar_w("غضون"),
                    ar_alt(&["الAيام", "الAسابيع"]),
                    ar_w("ال"),
                    ar_alt(&["القادمH", "المقبلH", "التالYH"]),
                    ar_alt(&["يوم واحد", "يوما واحدا", "Aسبوع واحد", "Aسبوعا واحدا"]),
                    ar_alt(&["يومان", "يومين", "Aسبوعان", "Aسبوعين"]),
                    ar_w("ال"),
                    ar_alt(&["Aيام", "يوما", "يوم", "Aسابيع", "Aسبوعا", "Aسبوع"]),
                    ar_alt(&["القادمH", "المقبلH", "التالYH"]),
                    ar_alt(&["يوم", "Aسبوع"]),
                ),
                WF_GUARDS,
                |c, _| {
                    if let Some(s) = c.name("sing_one").or_else(|| c.name("sing")) {
                        let days = if normalize_ar(s.as_str()).starts_with("يوم") {
                            1
                        } else {
                            7
                        };
                        return Some(vec![Component::Within(days)]);
                    }
                    if let Some(d) = c.name("dual") {
                        let days = if normalize_ar(d.as_str()).starts_with("يوم") {
                            2
                        } else {
                            14
                        };
                        return Some(vec![Component::Within(days)]);
                    }
                    if let Some(n2) = c.name("n2") {
                        let n = parse_ar_num(n2.as_str())?;
                        let full = normalize_ar(c.get(0)?.as_str());
                        let days = if full.contains("اسابيع") {
                            n.checked_mul(7)?
                        } else {
                            n
                        };
                        return Some(vec![Component::Within(days)]);
                    }
                    let n = parse_ar_num(c.name("n1")?.as_str())?;
                    let u = normalize_ar(c.name("u1")?.as_str());
                    let days = if matches!(u.as_str(), "اسبوع" | "اسبوعا" | "اسابيع")
                    {
                        n.checked_mul(7)?
                    } else {
                        n
                    };
                    Some(vec![Component::Within(days)])
                },
            ),
            Pattern::with_builder(
                "ar_offset",
                &format!(
                    "(?P<guard0>)(?:(?P<fdir>{})\\s+(?:(?P<fsing_one>{})|(?P<fdual>{})|(?P<fn>{num_any})\\s+(?P<fu>{})|(?P<fsing>{})(?P<guard2>))(?:\\s+{})?|(?P<pdir>{}|{})\\s+(?:(?P<psing_one>{})|(?P<pdual>{})|(?P<pn>{num_any})\\s+(?P<pu>{})|(?P<psing>{})(?P<guard3>))(?:\\s+{})?|(?:(?P<bdual>{})|(?P<bn>{num_any})\\s+(?P<bu>{}))\\s+(?:(?P<bfut>{})|(?P<bpast>{})))(?P<guard1>)",
                    ar_w("بعد"),
                    ar_alt(&[
                        "يوم واحد",
                        "يوما واحدا",
                        "Aسبوع واحد",
                        "Aسبوعا واحدا",
                        "شهر واحد",
                        "شهرا واحدا",
                        "سنH واحدH",
                        "عام واحد",
                        "عاما واحدا",
                    ]),
                    ar_alt(&[
                        "يومان اثنان",
                        "يومين اثنين",
                        "Aسبوعين اثنين",
                        "شهرين اثنين",
                        "سنتين اثنتين",
                        "عامين اثنين",
                        "يومان",
                        "يومين",
                        "Aسبوعان",
                        "Aسبوعين",
                        "شهران",
                        "شهرين",
                        "سنتان",
                        "سنتين",
                        "عامان",
                        "عامين",
                    ]),
                    ar_alt(&[
                        "Aيام",
                        "يوما",
                        "يوم",
                        "Aسابيع",
                        "Aسبوعا",
                        "Aسبوع",
                        "Aشهر",
                        "شهور",
                        "شهرا",
                        "شهر",
                        "سنوات",
                        "سنين",
                        "سنH",
                        "Aعوام",
                        "عاما",
                        "عام",
                    ]),
                    ar_alt(&["يوم", "Aسبوع", "شهر", "سنH", "عام"]),
                    ar_w("من الMن"),
                    ar_w("قبل"),
                    ar_w("منذ"),
                    ar_alt(&[
                        "يوم واحد",
                        "يوما واحدا",
                        "Aسبوع واحد",
                        "Aسبوعا واحدا",
                        "شهر واحد",
                        "شهرا واحدا",
                        "سنH واحدH",
                        "عام واحد",
                        "عاما واحدا",
                    ]),
                    ar_alt(&[
                        "يومان اثنان",
                        "يومين اثنين",
                        "Aسبوعين اثنين",
                        "شهرين اثنين",
                        "سنتين اثنتين",
                        "عامين اثنين",
                        "يومان",
                        "يومين",
                        "Aسبوعان",
                        "Aسبوعين",
                        "شهران",
                        "شهرين",
                        "سنتان",
                        "سنتين",
                        "عامان",
                        "عامين",
                    ]),
                    ar_alt(&[
                        "Aيام",
                        "يوما",
                        "يوم",
                        "Aسابيع",
                        "Aسبوعا",
                        "Aسبوع",
                        "Aشهر",
                        "شهور",
                        "شهرا",
                        "شهر",
                        "سنوات",
                        "سنين",
                        "سنH",
                        "Aعوام",
                        "عاما",
                        "عام",
                    ]),
                    ar_alt(&["يوم", "Aسبوع", "شهر", "سنH", "عام"]),
                    ar_w("من الMن"),
                    ar_alt(&[
                        "يومان",
                        "يومين",
                        "Aسبوعان",
                        "Aسبوعين",
                        "شهران",
                        "شهرين",
                        "سنتان",
                        "سنتين",
                        "عامان",
                        "عامين"
                    ]),
                    ar_alt(&[
                        "Aيام",
                        "يوما",
                        "يوم",
                        "Aسابيع",
                        "Aسبوعا",
                        "Aسبوع",
                        "Aشهر",
                        "شهور",
                        "شهرا",
                        "شهر",
                        "سنوات",
                        "سنين",
                        "سنH",
                        "Aعوام",
                        "عاما",
                        "عام",
                    ]),
                    ar_w("من الMن"),
                    ar_alt(&["مضت", "مضY", "خلت", "فاتت"]),
                ),
                &[
                    ("guard0", true, WORD_NO_WF),
                    ("guard1", false, WORD_CHAR),
                    ("guard2", false, OFFSET_SING_GUARD),
                    ("guard3", false, OFFSET_SING_GUARD),
                ],
                |c, _| {
                    if let Some(s) = c.name("fsing_one").or_else(|| c.name("fsing")) {
                        let unit = s.as_str().split_whitespace().next()?;
                        return Some(vec![parse_offset_unit(unit, 1)?]);
                    }
                    if let Some(d) = c.name("fdual") {
                        let unit = d.as_str().split_whitespace().next()?;
                        return Some(vec![parse_offset_unit(unit, 2)?]);
                    }
                    if let Some(n) = c.name("fn") {
                        let val = parse_ar_num(n.as_str())?;
                        return Some(vec![parse_offset_unit(c.name("fu")?.as_str(), val)?]);
                    }
                    if let Some(s) = c.name("psing_one").or_else(|| c.name("psing")) {
                        let unit = s.as_str().split_whitespace().next()?;
                        return Some(vec![parse_offset_unit(unit, -1)?]);
                    }
                    if let Some(d) = c.name("pdual") {
                        let unit = d.as_str().split_whitespace().next()?;
                        return Some(vec![parse_offset_unit(unit, -2)?]);
                    }
                    if let Some(n) = c.name("pn") {
                        let val = parse_ar_num(n.as_str())?.checked_neg()?;
                        return Some(vec![parse_offset_unit(c.name("pu")?.as_str(), val)?]);
                    }
                    let neg = c.name("bpast").is_some();
                    if let Some(d) = c.name("bdual") {
                        let val = if neg { -2 } else { 2 };
                        return Some(vec![parse_offset_unit(d.as_str(), val)?]);
                    }
                    let bn = c.name("bn")?;
                    let raw = parse_ar_num(bn.as_str())?;
                    let val = if neg { raw.checked_neg()? } else { raw };
                    Some(vec![parse_offset_unit(c.name("bu")?.as_str(), val)?])
                },
            ),
            Pattern::with_builder(
                "ar_nextLastWeekday",
                &format!(
                    "(?P<guard0>)(?:(?P<pre>{})\\s+(?:{}\\s+)?(?P<wd1>{wd_any})|(?:{}\\s+)?(?P<wd2>{wd_any})\\s+(?P<post>(?:{mod_next}|{mod_last}|{mod_this})))(?P<guard1>)",
                    ar_alt(&["هذا", "هذه"]),
                    ar_w("يوم"),
                    ar_w("يوم"),
                ),
                WF_GUARDS,
                |c, _| {
                    let (wd_s, off) = if let Some(wd1) = c.name("wd1") {
                        (wd1.as_str(), 0)
                    } else {
                        (
                            c.name("wd2")?.as_str(),
                            parse_anchor_offset(c.name("post")?.as_str())?,
                        )
                    };
                    let wd = lookup_weekday(wd_s)?;
                    if off == 0 {
                        Some(vec![Component::Weekday(wd)])
                    } else {
                        Some(vec![Component::Week(off, false), Component::Weekday(wd)])
                    }
                },
            ),
            Pattern::with_builder(
                "ar_weekday",
                &format!(
                    "(?:(?P<guard0>)(?P<def>(?:{}\\s+)?{wd_def})|(?P<guard2>)(?:(?:{}\\s+)?(?P<bare>{wd_bare_safe})|{}\\s+(?P<ambig>{wd_bare_ambig})))(?P<guard1>)",
                    ar_w("يوم"),
                    ar_w("يوم"),
                    ar_w("يوم"),
                ),
                &[
                    ("guard0", true, WORD_NO_WF),
                    ("guard2", true, WORD_CHAR),
                    ("guard1", false, WORD_CHAR),
                ],
                |c, _| {
                    let raw = c
                        .name("def")
                        .or_else(|| c.name("bare"))
                        .or_else(|| c.name("ambig"))?
                        .as_str();
                    let cleaned = raw.split_whitespace().last().unwrap_or(raw);
                    Some(vec![Component::Weekday(lookup_weekday(cleaned)?)])
                },
            ),
            Pattern::with_builder(
                "ar_month",
                &format!(
                    "(?P<guard0>)(?:{}\\s+)?(?P<m>{month_stand_alt})(?P<guard1>)",
                    ar_w("شهر"),
                ),
                WF_GUARDS,
                |c, _| Some(vec![Component::Month(lookup_month(c.name("m")?.as_str())?)]),
            ),
            Pattern::with_builder(
                "ar_day",
                &format!(
                    "(?P<guard0>)(?:{}\\s+(?P<d1>(?:{}ـ?\\s*)?[0-9]{{1,2}})|{}\\s+{}ـ?\\s*(?P<d2>[0-9]{{1,2}})|(?:{}|{})\\s+(?P<d3>{ord_1_31})|(?P<d4>{ord_1_31}|(?:{}ـ?\\s*)?[0-9]{{1,2}})\\s+{}\\s+{}(?:\\s+(?P<cur1>{}))?|{}\\s+(?P<d5>[0-9]{{1,2}})(?P<guard2>))(?:\\s+{}\\s+{}(?:\\s+(?P<cur2>{}))?)?(?P<guard1>)",
                    ar_alt(&["يوم", "بتاريخ", "تاريخ"]),
                    ar_w("ال"),
                    ar_w("اليوم"),
                    ar_w("ال"),
                    ar_w("اليوم"),
                    ar_alt(&["يوم", "بتاريخ", "تاريخ"]),
                    ar_w("ال"),
                    ar_w("من"),
                    ar_w("الشهر"),
                    ar_alt(&["الحالY", "الجارY"]),
                    ar_w("اليوم"),
                    ar_w("من"),
                    ar_w("الشهر"),
                    ar_alt(&["الحالY", "الجارY"]),
                ),
                &[
                    ("guard0", true, WORD_NO_WF),
                    ("guard1", false, DAY_GUARD1),
                    ("guard2", false, TODAY_DAY_GUARD2),
                ],
                |c, _| {
                    let raw = c
                        .name("d1")
                        .or_else(|| c.name("d2"))
                        .or_else(|| c.name("d3"))
                        .or_else(|| c.name("d4"))
                        .or_else(|| c.name("d5"))?
                        .as_str();
                    let d = parse_ar_num(raw)?;
                    if !(1..=31).contains(&d) {
                        return None;
                    }
                    let mut out = vec![Component::Day(d)];
                    if c.name("cur1").or_else(|| c.name("cur2")).is_some() {
                        out.push(Component::MonthOffset(0));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "ar_fixedTime",
                &format!(
                    "(?P<guard0>)(?P<ft>{})(?P<guard1>)",
                    ar_alt(&[
                        "منتصف الليل",
                        "نصف الليل",
                        "منتصف النهار",
                        "وقت الظهيرH",
                        "الظهيرH",
                        "الظهر",
                    ])
                ),
                WF_GUARDS,
                |c, _| {
                    let norm = normalize_ar(c.name("ft")?.as_str());
                    let h = if norm.contains("الليل") { 0 } else { 12 };
                    Some(vec![Component::Time(h, Some(0), None)])
                },
            ),
            Pattern::with_builder(
                "ar_timeAmPm",
                &format!(
                    "(?P<guard0>)(?:(?P<saa>(?:{}\\s+)?{})\\s+)?(?P<h>[0-9]{{1,2}})(?::(?P<m>[0-9]{{2}})(?::(?P<s>[0-9]{{2}}))?)?\\s*(?P<ap>{time_ap})(?P<guard1>)",
                    ar_w("تمام"),
                    ar_w("الساعH"),
                ),
                WF_TIME_GUARDS,
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = match c.name("m") {
                        Some(mm) => Some(crate::number(mm.as_str())?),
                        None => None,
                    };
                    if let Some(sm) = c.name("s")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    let ap_str = c.name("ap")?.as_str();
                    let kind = classify_meridiem(ap_str)?;
                    let has_ctx = c.name("saa").is_some() || m.is_some();
                    if !valid_h_ap(h, Some(kind), has_ctx, Some(ap_str)) {
                        return None;
                    }
                    let pm = resolve_meridiem_pm(kind, h);
                    Some(vec![Component::Time(h, m, Some(pm))])
                },
            ),
            Pattern::with_builder(
                "ar_hmsTime",
                &format!(
                    "(?P<guard0>)(?:(?:{}\\s+)?(?P<saa>{})\\s+(?P<hc>[0-9]{{1,2}}):(?P<mc>[0-9]{{2}})(?::(?P<sc>[0-9]{{2}}))?|(?P<h>[0-9]{{1,2}}):(?P<m>[0-9]{{2}}):(?P<s>[0-9]{{2}}))(?P<guard1>)",
                    ar_w("تمام"),
                    ar_w("الساعH"),
                ),
                &[
                    ("guard0", true, TIME_GUARD0_WF),
                    ("guard1", false, TIME_GUARD1),
                ],
                |c, _| {
                    let (hs, ms, ss) = if let Some(hc) = c.name("hc") {
                        (
                            hc.as_str(),
                            c.name("mc")?.as_str(),
                            c.name("sc").map(|x| x.as_str()),
                        )
                    } else {
                        (
                            c.name("h")?.as_str(),
                            c.name("m")?.as_str(),
                            Some(c.name("s")?.as_str()),
                        )
                    };
                    if let Some(s_str) = ss
                        && !(0..60).contains(&crate::number(s_str)?)
                    {
                        return None;
                    }
                    Some(vec![Component::Time(
                        crate::number(hs)?,
                        Some(crate::number(ms)?),
                        None,
                    )])
                },
            ),
            Pattern::with_builder(
                "ar_spokenTime",
                &format!(
                    "(?P<guard0>)(?:(?P<saa>(?:{}\\s+)?{})\\s+(?P<h1>{hour_any})(?:\\s*(?P<mod1>{time_mod1}))?(?:\\s*(?P<ap1>{time_ap}))?|(?P<h2>{hour_any})(?:\\s*(?P<mod2>{time_mod2})(?:\\s*(?P<ap2>{time_ap}))?|\\s*(?P<ap3>{time_ap})))(?P<guard1>)",
                    ar_w("تمام"),
                    ar_w("الساعH"),
                ),
                &[
                    ("guard0", true, TIME_GUARD0_WF),
                    ("guard1", false, TIME_GUARD1),
                    ("guard2", false, SPOKEN_MOD_NUM_GUARD),
                    ("guard3", false, SPOKEN_MOD_NUM_GUARD),
                    ("guard4", false, SPOKEN_MOD_NUM_GUARD),
                    ("guard5", false, SPOKEN_MOD_NUM_GUARD),
                ],
                |c, _| {
                    let (raw_h, mod_m, ap_m, has_saa) = if let Some(h1) = c.name("h1") {
                        (h1.as_str(), c.name("mod1"), c.name("ap1"), true)
                    } else {
                        (
                            c.name("h2")?.as_str(),
                            c.name("mod2"),
                            c.name("ap2").or_else(|| c.name("ap3")),
                            false,
                        )
                    };
                    let h = parse_ar_num(raw_h)?;
                    let ap = match ap_m {
                        Some(m) => Some((classify_meridiem(m.as_str())?, m.as_str())),
                        None => None,
                    };
                    let is_digit_h = raw_h.bytes().all(|b| b.is_ascii_digit());
                    if !valid_h_ap(h, ap.map(|x| x.0), has_saa, ap.map(|x| x.1)) {
                        return None;
                    }
                    if let Some((_, ap_raw)) = ap {
                        let norm_ap = normalize_ar(ap_raw.trim());
                        if matches!(norm_ap.as_str(), "ص" | "م") && !has_saa && !is_digit_h {
                            return None;
                        }
                    }
                    let (sign, delta_m) = match mod_m {
                        Some(mm) => parse_mod_minutes(mm.as_str())?,
                        None => (1, 0),
                    };
                    if let Some((kind, _)) = ap {
                        let h24 = apply_meridiem_to_24h(h, kind);
                        if mod_m.is_none() {
                            let pm_flag = if h24 == 0 { Some(false) } else { None };
                            return Some(vec![Component::Time(h24, None, pm_flag)]);
                        }
                        let total = (h24 * 60 + sign * delta_m).rem_euclid(24 * 60);
                        let res_h = total / 60;
                        let res_m = total % 60;
                        let pm_flag = if res_h == 0 { Some(false) } else { None };
                        return Some(vec![Component::Time(res_h, Some(res_m), pm_flag)]);
                    }
                    if mod_m.is_none() {
                        return Some(vec![Component::Time(h, None, None)]);
                    }
                    if sign < 0 {
                        let total = (h * 60 - delta_m).rem_euclid(24 * 60);
                        Some(vec![Component::Time(total / 60, Some(total % 60), None)])
                    } else {
                        Some(vec![Component::Time(h, Some(delta_m), None)])
                    }
                },
            ),
            Pattern::with_builder(
                "ar_meridiem",
                &format!("(?P<guard0>)(?P<mer>{mer_word_only})(?P<guard1>)"),
                WF_GUARDS,
                |c, _| {
                    let kind = classify_meridiem(c.name("mer")?.as_str())?;
                    let pm = !matches!(kind, ArMeridiem::Am);
                    Some(vec![Component::Meridiem(pm)])
                },
            ),
            Pattern::new("ar_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

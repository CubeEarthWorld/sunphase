use sunphase::{NaiveDate, NaiveDateTime, Options, Parser, parse_with};

fn ref_dt() -> NaiveDateTime {
    NaiveDate::from_ymd_opt(2025, 2, 8)
        .unwrap()
        .and_hms_opt(11, 5, 0)
        .unwrap()
}

fn dt(y: i32, m: u32, d: u32, h: u32, min: u32) -> NaiveDateTime {
    NaiveDate::from_ymd_opt(y, m, d)
        .unwrap()
        .and_hms_opt(h, min, 0)
        .unwrap()
}

fn es_opts() -> Options<'static> {
    let mut o = Options::new(ref_dt());
    o.languages = &["es"];
    o
}

fn assert_es_one(input: &str, expected_slice: &str, expected_dt: NaiveDateTime) {
    let matches = parse_with(input, &es_opts()).unwrap();
    assert_eq!(
        matches.len(),
        1,
        "expected 1 match for {input:?}, got {matches:?}"
    );
    let m = &matches[0];
    assert_eq!(
        &input[m.start..m.end],
        expected_slice,
        "span mismatch for {input:?}"
    );
    assert_eq!(m.date, expected_dt, "date mismatch for {input:?}");
}

fn assert_es_none(input: &str) {
    let matches = parse_with(input, &es_opts()).unwrap();
    assert!(
        matches.is_empty(),
        "expected no matches for {input:?}, got {matches:?}"
    );
}

#[test]
fn es_relative_days_and_parts_of_day() {
    assert_es_one("hoy", "hoy", dt(2025, 2, 8, 0, 0));
    assert_es_one("mañana", "mañana", dt(2025, 2, 9, 0, 0));
    assert_es_one("manana", "manana", dt(2025, 2, 9, 0, 0));
    assert_es_one("pasado mañana", "pasado mañana", dt(2025, 2, 10, 0, 0));
    assert_es_one("pasado  mañana", "pasado  mañana", dt(2025, 2, 10, 0, 0));
    assert_es_one("pasadomañana", "pasadomañana", dt(2025, 2, 10, 0, 0));
    assert_es_one("ayer", "ayer", dt(2025, 2, 7, 0, 0));
    assert_es_one("anteayer", "anteayer", dt(2025, 2, 6, 0, 0));
    assert_es_one("antier", "antier", dt(2025, 2, 6, 0, 0));
    assert_es_one("antes de ayer", "antes de ayer", dt(2025, 2, 6, 0, 0));

    assert_es_one("esta mañana", "esta mañana", dt(2025, 2, 8, 0, 0));
    assert_es_one(
        "esta mañana a las 9",
        "esta mañana a las 9",
        dt(2025, 2, 8, 9, 0),
    );
    assert_es_one(
        "esta tarde a las 5",
        "esta tarde a las 5",
        dt(2025, 2, 8, 17, 0),
    );
    assert_es_one(
        "esta madrugada a las 3",
        "esta madrugada a las 3",
        dt(2025, 2, 8, 3, 0),
    );
    assert_es_one(
        "esta noche a las 9",
        "esta noche a las 9",
        dt(2025, 2, 8, 21, 0),
    );
    assert_es_one("anoche a las 10", "anoche a las 10", dt(2025, 2, 7, 22, 0));
    assert_es_one(
        "anteanoche a las 23:00",
        "anteanoche a las 23:00",
        dt(2025, 2, 6, 23, 0),
    );
    assert_es_one(
        "mañana por la mañana a las 8",
        "mañana por la mañana a las 8",
        dt(2025, 2, 9, 8, 0),
    );
    assert_es_one(
        "hoy por la tarde a las 5",
        "hoy por la tarde a las 5",
        dt(2025, 2, 8, 17, 0),
    );
}

#[test]
fn es_uppercase_unicode_no_default_features() {
    assert_es_one("MAÑANA", "MAÑANA", dt(2025, 2, 9, 0, 0));
    assert_es_one("SÁBADO", "SÁBADO", dt(2025, 2, 15, 0, 0));
    assert_es_one("MIÉRCOLES", "MIÉRCOLES", dt(2025, 2, 12, 0, 0));
    assert_es_one("PRÓXIMO LUNES", "PRÓXIMO LUNES", dt(2025, 2, 10, 0, 0));
    assert_es_one("EL DÍA 20", "EL DÍA 20", dt(2025, 2, 20, 0, 0));
    assert_es_one("HACE 3 DÍAS", "HACE 3 DÍAS", dt(2025, 2, 5, 0, 0));
}

#[test]
fn es_anchors_and_weekend() {
    assert_es_one("este año", "este año", dt(2025, 2, 1, 0, 0));
    assert_es_one("próximo año", "próximo año", dt(2026, 2, 1, 0, 0));
    assert_es_one("año que viene", "año que viene", dt(2026, 2, 1, 0, 0));
    assert_es_one("año pasado", "año pasado", dt(2024, 2, 1, 0, 0));
    assert_es_one("año anterior", "año anterior", dt(2024, 2, 1, 0, 0));
    assert_es_one(
        "enero del año pasado",
        "enero del año pasado",
        dt(2024, 1, 1, 0, 0),
    );
    assert_es_one(
        "marzo del próximo año",
        "marzo del próximo año",
        dt(2026, 3, 1, 0, 0),
    );

    assert_es_one("fin de semana", "fin de semana", dt(2025, 2, 9, 0, 0));
    assert_es_one(
        "este fin de semana a las 16:00",
        "este fin de semana a las 16:00",
        dt(2025, 2, 9, 16, 0),
    );
    assert_es_one("este finde", "este finde", dt(2025, 2, 9, 0, 0));
    assert_es_one(
        "fin de semana pasado",
        "fin de semana pasado",
        dt(2025, 2, 2, 0, 0),
    );

    let mut range_opts = es_opts();
    range_opts.range = true;
    let m_week = Parser::default()
        .parse_ranges("la semana que viene", &range_opts)
        .unwrap();
    assert_eq!(m_week.len(), 1);
    assert_eq!(
        &"la semana que viene"[m_week[0].start..m_week[0].end],
        "semana que viene"
    );
    assert_eq!(m_week[0].date, dt(2025, 2, 9, 0, 0));
    assert_eq!(m_week[0].range_days, Some(7));

    range_opts.week_start = 1;
    let m_week_mon = Parser::default()
        .parse_ranges("la semana anterior", &range_opts)
        .unwrap();
    assert_eq!(m_week_mon[0].date, dt(2025, 1, 27, 0, 0));
    assert_eq!(m_week_mon[0].range_days, Some(7));

    let m_month = Parser::default()
        .parse_ranges("el mes anterior", &range_opts)
        .unwrap();
    assert_eq!(m_month[0].date, dt(2025, 1, 1, 0, 0));
    assert_eq!(m_month[0].range_days, Some(31));

    let m_next_month = Parser::default()
        .parse_ranges("el siguiente mes", &range_opts)
        .unwrap();
    assert_eq!(m_next_month[0].date, dt(2025, 3, 1, 0, 0));
    assert_eq!(m_next_month[0].range_days, Some(31));
}

#[test]
fn es_weekdays_and_months() {
    assert_es_one("el lunes pasado", "lunes pasado", dt(2025, 2, 3, 0, 0));
    assert_es_one("el viernes pasado", "viernes pasado", dt(2025, 2, 7, 0, 0));
    assert_es_one(
        "el martes que viene",
        "martes que viene",
        dt(2025, 2, 11, 0, 0),
    );
    assert_es_one(
        "jueves siguiente",
        "jueves siguiente",
        dt(2025, 2, 13, 0, 0),
    );
    assert_es_one("este miércoles", "este miércoles", dt(2025, 2, 12, 0, 0));
    assert_es_one("último lunes", "último lunes", dt(2025, 2, 3, 0, 0));
    assert_es_one("próximo mar.", "próximo mar.", dt(2025, 2, 11, 0, 0));
    assert_es_one("vie. pasado", "vie. pasado", dt(2025, 2, 7, 0, 0));
    assert_es_one("lun.", "lun.", dt(2025, 2, 10, 0, 0));
    assert_es_one("mié.", "mié.", dt(2025, 2, 12, 0, 0));
    assert_es_one("sáb.", "sáb.", dt(2025, 2, 15, 0, 0));
    assert_es_one(
        "domingo de la semana que viene",
        "domingo de la semana que viene",
        dt(2025, 2, 9, 0, 0),
    );

    assert_es_one("setiembre", "setiembre", dt(2025, 9, 1, 0, 0));
    assert_es_one("feb.", "feb.", dt(2025, 2, 1, 0, 0));
    assert_es_one("sept.", "sept.", dt(2025, 9, 1, 0, 0));
    assert_es_one("marzo de 2026", "marzo de 2026", dt(2026, 3, 1, 0, 0));
    assert_es_one("ene. 2026", "ene. 2026", dt(2026, 1, 1, 0, 0));
}

#[test]
fn es_dates_numeric_and_nth() {
    assert_es_one("1º de mayo", "1º de mayo", dt(2025, 5, 1, 0, 0));
    assert_es_one("1° de enero", "1° de enero", dt(2026, 1, 1, 0, 0));
    assert_es_one(
        "el primero de marzo",
        "el primero de marzo",
        dt(2025, 3, 1, 0, 0),
    );
    assert_es_one("cinco de mayo", "cinco de mayo", dt(2025, 5, 5, 0, 0));
    assert_es_one(
        "veintiuno de marzo",
        "veintiuno de marzo",
        dt(2025, 3, 21, 0, 0),
    );
    assert_es_one(
        "14 de marzo del 2025",
        "14 de marzo del 2025",
        dt(2025, 3, 14, 0, 0),
    );
    assert_es_one("14 mar 2025", "14 mar 2025", dt(2025, 3, 14, 0, 0));
    assert_es_one("14-mar-2025", "14-mar-2025", dt(2025, 3, 14, 0, 0));
    assert_es_one("marzo 14", "marzo 14", dt(2025, 3, 14, 0, 0));
    assert_es_one("marzo 14, 2025", "marzo 14, 2025", dt(2025, 3, 14, 0, 0));
    assert_es_one("marzo 14:30", "marzo 14:30", dt(2025, 3, 1, 14, 30));
    assert_es_one("el 1º", "el 1º", dt(2025, 3, 1, 0, 0));
    assert_es_one("el 1°", "el 1°", dt(2025, 3, 1, 0, 0));

    assert_es_one("14/03/2025", "14/03/2025", dt(2025, 3, 14, 0, 0));
    assert_es_one("14/03/26", "14/03/26", dt(2026, 3, 14, 0, 0));
    assert_es_one("14-03-2025", "14-03-2025", dt(2025, 3, 14, 0, 0));
    assert_es_one("14.03.2025", "14.03.2025", dt(2025, 3, 14, 0, 0));
    assert_es_one("2025-03-14", "2025-03-14", dt(2025, 3, 14, 0, 0));
    assert_es_one("2025/03/14", "2025/03/14", dt(2025, 3, 14, 0, 0));
    assert_es_one("14/03", "14/03", dt(2025, 3, 14, 0, 0));
    assert_es_one("05/01", "05/01", dt(2026, 1, 5, 0, 0));
    assert_es_one(
        "La cita es el 14/03/2025.",
        "14/03/2025",
        dt(2025, 3, 14, 0, 0),
    );
    assert_es_one(
        "el 14/03/2025 a las 15:30",
        "14/03/2025 a las 15:30",
        dt(2025, 3, 14, 15, 30),
    );

    assert_es_one(
        "primer lunes de marzo",
        "primer lunes de marzo",
        dt(2025, 3, 3, 0, 0),
    );
    assert_es_one(
        "3er miércoles de sept.",
        "3er miércoles de sept.",
        dt(2025, 9, 17, 0, 0),
    );
}

#[test]
fn es_offsets_and_within() {
    assert_es_one("en 3 días", "en 3 días", dt(2025, 2, 11, 0, 0));
    assert_es_one(
        "dentro de 3 días",
        "dentro de 3 días",
        dt(2025, 2, 11, 0, 0),
    );
    assert_es_one(
        "dentro de una semana",
        "dentro de una semana",
        dt(2025, 2, 15, 0, 0),
    );
    assert_es_one("en 1 mes", "en 1 mes", dt(2025, 3, 1, 0, 0));
    assert_es_one("en un año", "en un año", dt(2026, 2, 1, 0, 0));
    assert_es_one(
        "de aquí a 5 días",
        "de aquí a 5 días",
        dt(2025, 2, 13, 0, 0),
    );
    assert_es_one(
        "4 días más tarde",
        "4 días más tarde",
        dt(2025, 2, 12, 0, 0),
    );
    assert_es_one("5 días después", "5 días después", dt(2025, 2, 13, 0, 0));
    assert_es_one("hace un mes", "hace un mes", dt(2025, 1, 1, 0, 0));
    assert_es_one("hace dos años", "hace dos años", dt(2023, 2, 1, 0, 0));
    assert_es_one("2 meses atrás", "2 meses atrás", dt(2024, 12, 1, 0, 0));
    assert_es_one("1 año atrás", "1 año atrás", dt(2024, 2, 1, 0, 0));
    assert_es_one(
        "hace quince días",
        "hace quince días",
        dt(2025, 1, 24, 0, 0),
    );
    assert_es_one(
        "dentro de veintiún días",
        "dentro de veintiún días",
        dt(2025, 3, 1, 0, 0),
    );
    assert_es_one(
        "hace treinta y un días",
        "hace treinta y un días",
        dt(2025, 1, 8, 0, 0),
    );

    let mut range_opts = es_opts();
    range_opts.range = true;
    let w1 = Parser::default()
        .parse_ranges("en los próximos 3 días", &range_opts)
        .unwrap();
    assert_eq!(w1.len(), 1);
    assert_eq!(w1[0].date, dt(2025, 2, 8, 0, 0));
    assert_eq!(w1[0].range_days, Some(4));

    let w2 = Parser::default()
        .parse_ranges("en un plazo de 7 días", &range_opts)
        .unwrap();
    assert_eq!(w2[0].range_days, Some(8));

    let w3 = Parser::default()
        .parse_ranges("dentro de las próximas 2 semanas", &range_opts)
        .unwrap();
    assert_eq!(w3[0].range_days, Some(15));
}

#[test]
fn es_time_expressions() {
    assert_es_one("15h30", "15h30", dt(2025, 2, 8, 15, 30));
    assert_es_one("09h05", "09h05", dt(2025, 2, 9, 9, 5));
    assert_es_one("14:30 horas", "14:30 horas", dt(2025, 2, 8, 14, 30));
    assert_es_one("15:30 h", "15:30 h", dt(2025, 2, 8, 15, 30));

    assert_es_one("3pm", "3pm", dt(2025, 2, 8, 15, 0));
    assert_es_one("3:30 p.m.", "3:30 p.m.", dt(2025, 2, 8, 15, 30));
    assert_es_one("09:15 a. m.", "09:15 a. m.", dt(2025, 2, 9, 9, 15));
    assert_es_one("12:00 a.m.", "12:00 a.m.", dt(2025, 2, 9, 0, 0));
    assert_es_one("12:00 p.m.", "12:00 p.m.", dt(2025, 2, 8, 12, 0));

    assert_es_one("mediodía", "mediodía", dt(2025, 2, 8, 12, 0));
    assert_es_one("medianoche", "medianoche", dt(2025, 2, 9, 0, 0));
    assert_es_one(
        "mañana al mediodía",
        "mañana al mediodía",
        dt(2025, 2, 9, 12, 0),
    );
    assert_es_one(
        "a las 12 del mediodía",
        "a las 12 del mediodía",
        dt(2025, 2, 8, 12, 0),
    );
    assert_es_one(
        "a las 12 de la noche",
        "a las 12 de la noche",
        dt(2025, 2, 9, 0, 0),
    );

    assert_es_one("a las 3", "a las 3", dt(2025, 2, 9, 3, 0));
    assert_es_one("a la una", "a la una", dt(2025, 2, 9, 1, 0));
    assert_es_one("a las 15", "a las 15", dt(2025, 2, 8, 15, 0));
    assert_es_one("a las 15 horas", "a las 15 horas", dt(2025, 2, 8, 15, 0));
    assert_es_one("a las 09 horas", "a las 09 horas", dt(2025, 2, 9, 9, 0));
    assert_es_one("3 en punto", "3 en punto", dt(2025, 2, 9, 3, 0));
    assert_es_one("las 3 y media", "las 3 y media", dt(2025, 2, 9, 3, 30));
    assert_es_one(
        "a la una y media de la tarde",
        "a la una y media de la tarde",
        dt(2025, 2, 8, 13, 30),
    );
    assert_es_one(
        "a las 4 y cuarto",
        "a las 4 y cuarto",
        dt(2025, 2, 9, 4, 15),
    );
    assert_es_one(
        "las 4 menos cuarto",
        "las 4 menos cuarto",
        dt(2025, 2, 9, 3, 45),
    );
    assert_es_one(
        "a la una menos cuarto de la tarde",
        "a la una menos cuarto de la tarde",
        dt(2025, 2, 8, 12, 45),
    );
    assert_es_one(
        "un cuarto para las cuatro",
        "un cuarto para las cuatro",
        dt(2025, 2, 9, 3, 45),
    );
    assert_es_one(
        "diez para la una de la tarde",
        "diez para la una de la tarde",
        dt(2025, 2, 8, 12, 50),
    );
    assert_es_one(
        "a las 8 y veinte",
        "a las 8 y veinte",
        dt(2025, 2, 9, 8, 20),
    );
    assert_es_one("las 10 con 30", "las 10 con 30", dt(2025, 2, 9, 10, 30));
    assert_es_one(
        "las 5 menos diez",
        "las 5 menos diez",
        dt(2025, 2, 9, 4, 50),
    );
    assert_es_one("3 de la tarde", "3 de la tarde", dt(2025, 2, 8, 15, 0));
    assert_es_one("9 de la mañana", "9 de la mañana", dt(2025, 2, 9, 9, 0));
    assert_es_one(
        "3 de la madrugada",
        "3 de la madrugada",
        dt(2025, 2, 9, 3, 0),
    );
    assert_es_one("3 y media pm", "3 y media pm", dt(2025, 2, 8, 15, 30));
}

#[test]
fn es_utf8_spans_composition_and_offset() {
    let s1 = "Reunión mañana a las 3 de la tarde";
    assert_es_one(s1, "mañana a las 3 de la tarde", dt(2025, 2, 9, 15, 0));

    let s2 = "Café el próximo lunes a las 9 y media";
    assert_es_one(s2, "próximo lunes a las 9 y media", dt(2025, 2, 10, 9, 30));

    let mut opts = es_opts();
    opts.offset_minutes = -180;
    let matches = parse_with("mañana a las 15:00", &opts).unwrap();
    assert_eq!(matches[0].date, dt(2025, 2, 9, 12, 0));
}

#[test]
fn es_negative_and_boundary_guards() {
    for input in [
        "HoyX",
        "MañanaA",
        "lunesB",
        "eneroC",
        "pasado mañanaZ",
        "de la tardeX",
        "hotel 20",
        "tienen 3 días",
        "deshace 3 días",
        "en 3 diarios",
        "Voy al mar.",
        "C'est la vie.",
        "el DOM",
        "soy el primero en llegar",
        "tengo 3 gatos",
        "las 3 casas",
        "a las dos semanas",
        "a las 2 horas",
        "dura 3 horas",
        "entre 3 y 20 días",
        "24/7",
        "1/2",
        "v1.2.2025",
        "10.12.20.1",
        "el 20%",
        "el 200",
        "el 20°C",
        "de la tarde",
        "por la mañana",
        "31/02/2025",
        "15 am",
    ] {
        assert_es_none(input);
    }

    assert_es_one("Voy al mar a las 10:00", "10:00", dt(2025, 2, 9, 10, 0));
    assert_es_one(
        "14 de marzo 1500 personas",
        "14 de marzo",
        dt(2025, 3, 14, 0, 0),
    );
    assert_es_one("3:30 amigos", "3:30", dt(2025, 2, 9, 3, 30));
}

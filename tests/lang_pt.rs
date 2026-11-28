use sunphase::{Error, Match, NaiveDate, NaiveDateTime, Options, Parser, parse_with};

fn ref_dt() -> NaiveDateTime {
    NaiveDate::from_ymd_opt(2025, 2, 8)
        .unwrap()
        .and_hms_opt(11, 5, 0)
        .unwrap()
}

fn opts() -> Options<'static> {
    Options {
        languages: &["pt"],
        ..Options::new(ref_dt())
    }
}

fn parse_one(parser: &Parser, text: &str, options: &Options<'_>) -> Match {
    let results = parser.parse(text, options).unwrap();
    assert_eq!(
        results.len(),
        1,
        "expected 1 match for {text:?}, got {results:?}"
    );
    let m = results.into_iter().next().unwrap();
    assert!(
        text.is_char_boundary(m.start) && text.is_char_boundary(m.end),
        "non-char-boundary span in {text:?}: {}..{}",
        m.start,
        m.end
    );
    m
}

fn assert_date(parser: &Parser, text: &str, expected: &str) {
    let m = parse_one(parser, text, &opts());
    assert_eq!(m.date.to_string(), expected, "for {text:?}");
}

fn assert_exact(parser: &Parser, text: &str, expected: &str) {
    let m = parse_one(parser, text, &opts());
    assert_eq!(&text[m.start..m.end], text, "partial span for {text:?}");
    assert_eq!(m.date.to_string(), expected, "for {text:?}");
}

fn assert_empty(parser: &Parser, text: &str) {
    let results = parser.parse(text, &opts()).unwrap();
    assert!(
        results.is_empty(),
        "expected no match for {text:?}, got {results:?}"
    );
}

#[test]
fn relative_days_and_tonight() {
    let p = Parser::default();
    for (text, expected) in [
        ("hoje", "2025-02-08 00:00:00"),
        ("Hoje", "2025-02-08 00:00:00"),
        ("HOJE", "2025-02-08 00:00:00"),
        ("amanhã", "2025-02-09 00:00:00"),
        ("amanha", "2025-02-09 00:00:00"),
        ("Amanhã", "2025-02-09 00:00:00"),
        ("depois de amanhã", "2025-02-10 00:00:00"),
        ("depois de amanha", "2025-02-10 00:00:00"),
        ("ontem", "2025-02-07 00:00:00"),
        ("Ontem", "2025-02-07 00:00:00"),
        ("anteontem", "2025-02-06 00:00:00"),
        ("ante-ontem", "2025-02-06 00:00:00"),
        ("ante ontem", "2025-02-06 00:00:00"),
        ("antes de ontem", "2025-02-06 00:00:00"),
        ("trás-anteontem", "2025-02-05 00:00:00"),
        ("tras-anteontem", "2025-02-05 00:00:00"),
        ("trásanteontem", "2025-02-05 00:00:00"),
        ("trasanteontem", "2025-02-05 00:00:00"),
        ("trás anteontem", "2025-02-05 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    for (text, expected) in [
        ("hoje à noite", "2025-02-08 12:00:00"),
        ("hoje a noite", "2025-02-08 12:00:00"),
        ("hoje à tarde", "2025-02-08 12:00:00"),
        ("hoje de manhã", "2025-02-08 00:00:00"),
        ("amanhã pela manhã", "2025-02-09 00:00:00"),
        ("amanhã à noite", "2025-02-09 12:00:00"),
        ("depois de amanhã à tarde", "2025-02-10 12:00:00"),
        ("ontem de madrugada", "2025-02-07 00:00:00"),
        ("antes de ontem à noite", "2025-02-06 12:00:00"),
        ("esta noite", "2025-02-08 12:00:00"),
        ("nesta tarde", "2025-02-08 12:00:00"),
        ("esta manhã", "2025-02-08 00:00:00"),
        ("essa madrugada", "2025-02-08 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    let sentence = "reunião marcada para amanhã";
    let m = parse_one(&p, sentence, &opts());
    assert_eq!(&sentence[m.start..m.end], "amanhã");
    assert_eq!(m.date.to_string(), "2025-02-09 00:00:00");
}

#[test]
fn weekdays_full_short_abbreviations_and_relative() {
    let p = Parser::default();
    for (text, expected) in [
        ("segunda-feira", "2025-02-10 00:00:00"),
        ("segunda feira", "2025-02-10 00:00:00"),
        ("segundas-feiras", "2025-02-10 00:00:00"),
        ("segunda", "2025-02-10 00:00:00"),
        ("2ª-feira", "2025-02-10 00:00:00"),
        ("2a feira", "2025-02-10 00:00:00"),
        ("seg.", "2025-02-10 00:00:00"),
        ("seg", "2025-02-10 00:00:00"),
        ("terça-feira", "2025-02-11 00:00:00"),
        ("terca-feira", "2025-02-11 00:00:00"),
        ("terças-feiras", "2025-02-11 00:00:00"),
        ("terça", "2025-02-11 00:00:00"),
        ("terca", "2025-02-11 00:00:00"),
        ("3ª-feira", "2025-02-11 00:00:00"),
        ("ter.", "2025-02-11 00:00:00"),
        ("ter", "2025-02-11 00:00:00"),
        ("quarta-feira", "2025-02-12 00:00:00"),
        ("quartas-feiras", "2025-02-12 00:00:00"),
        ("quarta", "2025-02-12 00:00:00"),
        ("4ª-feira", "2025-02-12 00:00:00"),
        ("qua.", "2025-02-12 00:00:00"),
        ("qua", "2025-02-12 00:00:00"),
        ("quinta-feira", "2025-02-13 00:00:00"),
        ("quintas-feiras", "2025-02-13 00:00:00"),
        ("quinta", "2025-02-13 00:00:00"),
        ("5ª-feira", "2025-02-13 00:00:00"),
        ("qui.", "2025-02-13 00:00:00"),
        ("qui", "2025-02-13 00:00:00"),
        ("sexta-feira", "2025-02-14 00:00:00"),
        ("sextas-feiras", "2025-02-14 00:00:00"),
        ("sexta", "2025-02-14 00:00:00"),
        ("6ª-feira", "2025-02-14 00:00:00"),
        ("sex.", "2025-02-14 00:00:00"),
        ("sex", "2025-02-14 00:00:00"),
        ("sábado", "2025-02-15 00:00:00"),
        ("sabado", "2025-02-15 00:00:00"),
        ("sáb.", "2025-02-15 00:00:00"),
        ("sáb", "2025-02-15 00:00:00"),
        ("sab.", "2025-02-15 00:00:00"),
        ("sab", "2025-02-15 00:00:00"),
        ("domingo", "2025-02-09 00:00:00"),
        ("dom.", "2025-02-09 00:00:00"),
        ("dom", "2025-02-09 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    for (text, expected) in [
        ("próxima segunda-feira", "2025-02-10 00:00:00"),
        ("proxima segunda", "2025-02-10 00:00:00"),
        ("segunda-feira que vem", "2025-02-10 00:00:00"),
        ("seguinte segunda-feira", "2025-02-10 00:00:00"),
        ("próxima terça-feira", "2025-02-11 00:00:00"),
        ("sexta-feira seguinte", "2025-02-14 00:00:00"),
        ("próximo sábado", "2025-02-15 00:00:00"),
        ("proximo sabado", "2025-02-15 00:00:00"),
        ("sábado que vem", "2025-02-15 00:00:00"),
        ("próximo domingo", "2025-02-09 00:00:00"),
        ("proximo domingo", "2025-02-09 00:00:00"),
        ("segunda-feira passada", "2025-02-03 00:00:00"),
        ("segunda passada", "2025-02-03 00:00:00"),
        ("segunda-feira anterior", "2025-02-03 00:00:00"),
        ("última segunda-feira", "2025-02-03 00:00:00"),
        ("ultima segunda", "2025-02-03 00:00:00"),
        ("sexta passada", "2025-02-07 00:00:00"),
        ("anterior sexta-feira", "2025-02-07 00:00:00"),
        ("última sexta", "2025-02-07 00:00:00"),
        ("sábado passado", "2025-02-01 00:00:00"),
        ("sabado passado", "2025-02-01 00:00:00"),
        ("domingo passado", "2025-02-02 00:00:00"),
        ("último domingo", "2025-02-02 00:00:00"),
        ("ultimo domingo", "2025-02-02 00:00:00"),
        ("quarta-feira da próxima semana", "2025-02-12 00:00:00"),
        ("segunda-feira da semana que vem", "2025-02-10 00:00:00"),
        ("quinta-feira da semana anterior", "2025-01-30 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    let mut mon_start = opts();
    mon_start.week_start = 1;
    for text in ["este domingo", "neste domingo", "domingo desta semana"] {
        assert_eq!(
            parse_one(&p, text, &mon_start).date.to_string(),
            "2025-02-09 00:00:00",
            "{text}"
        );
    }

    let mon_ref = NaiveDate::from_ymd_opt(2025, 2, 10)
        .unwrap()
        .and_hms_opt(11, 5, 0)
        .unwrap();
    for week_start in [1, 7] {
        let mut o = opts();
        o.reference = mon_ref;
        o.week_start = week_start;
        for text in [
            "esta quarta-feira",
            "esta quarta",
            "nessa quarta",
            "quarta-feira da semana atual",
        ] {
            assert_eq!(
                parse_one(&p, text, &o).date.to_string(),
                "2025-02-12 00:00:00",
                "{text}, week_start={week_start}"
            );
        }
    }
}

#[test]
fn calendar_anchors_and_week_start() {
    let p = Parser::default();

    for (week_start, this_w, next_w, last_w, prev2_w) in [
        (
            7,
            "2025-02-02 00:00:00",
            "2025-02-09 00:00:00",
            "2025-01-26 00:00:00",
            "2025-01-19 00:00:00",
        ),
        (
            1,
            "2025-02-03 00:00:00",
            "2025-02-10 00:00:00",
            "2025-01-27 00:00:00",
            "2025-01-20 00:00:00",
        ),
    ] {
        let mut o = opts();
        o.week_start = week_start;
        for text in [
            "esta semana",
            "nesta semana",
            "essa semana",
            "semana atual",
            "semana corrente",
        ] {
            let m = parse_one(&p, text, &o);
            assert_eq!(
                m.date.to_string(),
                this_w,
                "{text}, week_start={week_start}"
            );
            assert_eq!(m.range_type, Some("week"));
        }
        for text in [
            "próxima semana",
            "proxima semana",
            "semana que vem",
            "semana seguinte",
            "seguinte semana",
        ] {
            let m = parse_one(&p, text, &o);
            assert_eq!(
                m.date.to_string(),
                next_w,
                "{text}, week_start={week_start}"
            );
            assert_eq!(m.range_type, Some("week"));
        }
        for text in [
            "semana passada",
            "última semana",
            "ultima semana",
            "semana anterior",
        ] {
            let m = parse_one(&p, text, &o);
            assert_eq!(
                m.date.to_string(),
                last_w,
                "{text}, week_start={week_start}"
            );
            assert_eq!(m.range_type, Some("week"));
        }
        let m = parse_one(&p, "semana retrasada", &o);
        assert_eq!(m.date.to_string(), prev2_w, "week_start={week_start}");
        assert_eq!(m.range_type, Some("week"));
    }

    for (text, expected) in [
        ("este mês", "2025-02-01 00:00:00"),
        ("este mes", "2025-02-01 00:00:00"),
        ("nesse mês", "2025-02-01 00:00:00"),
        ("mês atual", "2025-02-01 00:00:00"),
        ("mês corrente", "2025-02-01 00:00:00"),
        ("próximo mês", "2025-03-01 00:00:00"),
        ("proximo mes", "2025-03-01 00:00:00"),
        ("mês que vem", "2025-03-01 00:00:00"),
        ("mes que vem", "2025-03-01 00:00:00"),
        ("mês seguinte", "2025-03-01 00:00:00"),
        ("mês passado", "2025-01-01 00:00:00"),
        ("mes passado", "2025-01-01 00:00:00"),
        ("último mês", "2025-01-01 00:00:00"),
        ("ultimo mes", "2025-01-01 00:00:00"),
        ("mês anterior", "2025-01-01 00:00:00"),
        ("mês retrasado", "2024-12-01 00:00:00"),
        ("mes retrasado", "2024-12-01 00:00:00"),
    ] {
        let m = parse_one(&p, text, &opts());
        assert_eq!(&text[m.start..m.end], text, "for {text:?}");
        assert_eq!(m.date.to_string(), expected, "for {text:?}");
        assert_eq!(m.range_type, Some("month"), "for {text:?}");
    }

    for (text, expected) in [
        ("este ano", "2025-02-01 00:00:00"),
        ("nesse ano", "2025-02-01 00:00:00"),
        ("ano atual", "2025-02-01 00:00:00"),
        ("ano corrente", "2025-02-01 00:00:00"),
        ("próximo ano", "2026-02-01 00:00:00"),
        ("proximo ano", "2026-02-01 00:00:00"),
        ("ano que vem", "2026-02-01 00:00:00"),
        ("ano seguinte", "2026-02-01 00:00:00"),
        ("ano passado", "2024-02-01 00:00:00"),
        ("último ano", "2024-02-01 00:00:00"),
        ("ultimo ano", "2024-02-01 00:00:00"),
        ("ano anterior", "2024-02-01 00:00:00"),
        ("ano retrasado", "2023-02-01 00:00:00"),
        ("em 2026", "2026-02-01 00:00:00"),
        ("no ano de 2026", "2026-02-01 00:00:00"),
        ("ano de 2026", "2026-02-01 00:00:00"),
        ("ano 2026", "2026-02-01 00:00:00"),
        ("o ano de 2024", "2024-02-01 00:00:00"),
    ] {
        let m = parse_one(&p, text, &opts());
        assert_eq!(&text[m.start..m.end], text, "for {text:?}");
        assert_eq!(m.date.to_string(), expected, "for {text:?}");
        assert_eq!(m.range_type, None, "for {text:?}");
    }

    for (text, expected) in [
        ("fim de semana", "2025-02-09 00:00:00"),
        ("fim-de-semana", "2025-02-09 00:00:00"),
        ("final de semana", "2025-02-09 00:00:00"),
        ("este fim de semana", "2025-02-09 00:00:00"),
        ("neste fim de semana", "2025-02-09 00:00:00"),
        ("próximo fim de semana", "2025-02-09 00:00:00"),
        ("fim de semana que vem", "2025-02-09 00:00:00"),
        ("próximo final de semana", "2025-02-09 00:00:00"),
        ("fim de semana passado", "2025-02-02 00:00:00"),
        ("último fim de semana", "2025-02-02 00:00:00"),
        ("passado fim de semana", "2025-02-02 00:00:00"),
        ("final de semana passado", "2025-02-02 00:00:00"),
        ("fim de semana retrasado", "2025-01-26 00:00:00"),
        ("final de semana retrasado", "2025-01-26 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }
}

#[test]
fn months_full_abbreviated_and_with_year() {
    let p = Parser::default();
    for (text, expected) in [
        ("janeiro", "2026-01-01 00:00:00"),
        ("jan.", "2026-01-01 00:00:00"),
        ("jan", "2026-01-01 00:00:00"),
        ("fevereiro", "2025-02-01 00:00:00"),
        ("fev", "2025-02-01 00:00:00"),
        ("fev.", "2025-02-01 00:00:00"),
        ("março", "2025-03-01 00:00:00"),
        ("marco", "2025-03-01 00:00:00"),
        ("mar.", "2025-03-01 00:00:00"),
        ("mar", "2025-03-01 00:00:00"),
        ("abril", "2025-04-01 00:00:00"),
        ("abr", "2025-04-01 00:00:00"),
        ("abr.", "2025-04-01 00:00:00"),
        ("maio", "2025-05-01 00:00:00"),
        ("mai.", "2025-05-01 00:00:00"),
        ("mai", "2025-05-01 00:00:00"),
        ("junho", "2025-06-01 00:00:00"),
        ("jun.", "2025-06-01 00:00:00"),
        ("jun", "2025-06-01 00:00:00"),
        ("julho", "2025-07-01 00:00:00"),
        ("jul.", "2025-07-01 00:00:00"),
        ("jul", "2025-07-01 00:00:00"),
        ("agosto", "2025-08-01 00:00:00"),
        ("ago.", "2025-08-01 00:00:00"),
        ("ago", "2025-08-01 00:00:00"),
        ("setembro", "2025-09-01 00:00:00"),
        ("set.", "2025-09-01 00:00:00"),
        ("set", "2025-09-01 00:00:00"),
        ("outubro", "2025-10-01 00:00:00"),
        ("out.", "2025-10-01 00:00:00"),
        ("out", "2025-10-01 00:00:00"),
        ("novembro", "2025-11-01 00:00:00"),
        ("nov.", "2025-11-01 00:00:00"),
        ("nov", "2025-11-01 00:00:00"),
        ("dezembro", "2025-12-01 00:00:00"),
        ("dez.", "2025-12-01 00:00:00"),
        ("dez", "2025-12-01 00:00:00"),
        ("próximo março", "2025-03-01 00:00:00"),
        ("março que vem", "2025-03-01 00:00:00"),
        ("próximo janeiro", "2026-01-01 00:00:00"),
        ("janeiro que vem", "2026-01-01 00:00:00"),
        ("próximo fevereiro", "2026-02-01 00:00:00"),
        ("janeiro passado", "2025-01-01 00:00:00"),
        ("último janeiro", "2025-01-01 00:00:00"),
        ("março passado", "2024-03-01 00:00:00"),
        ("último março", "2024-03-01 00:00:00"),
        ("fevereiro passado", "2024-02-01 00:00:00"),
        ("dezembro passado", "2024-12-01 00:00:00"),
    ] {
        let m = parse_one(&p, text, &opts());
        assert_eq!(&text[m.start..m.end], text, "for {text:?}");
        assert_eq!(m.date.to_string(), expected, "for {text:?}");
        assert_eq!(m.range_type, Some("month"), "for {text:?}");
    }

    for (text, expected) in [
        ("janeiro de 2025", "2025-01-01 00:00:00"),
        ("fevereiro de 2026", "2026-02-01 00:00:00"),
        ("dezembro de 2025", "2025-12-01 00:00:00"),
        ("março 2026", "2026-03-01 00:00:00"),
        ("março, 2026", "2026-03-01 00:00:00"),
        ("mar/2026", "2026-03-01 00:00:00"),
        ("mar de 2025", "2025-03-01 00:00:00"),
        ("mai de 2025", "2025-05-01 00:00:00"),
    ] {
        let m = parse_one(&p, text, &opts());
        assert_eq!(&text[m.start..m.end], text, "for {text:?}");
        assert_eq!(m.date.to_string(), expected, "for {text:?}");
        assert_eq!(m.range_type, None, "for {text:?}");
    }
}

#[test]
fn calendar_dates_ordinals_numeric_and_nth_weekdays() {
    let p = Parser::default();
    for (text, expected) in [
        ("15 de jan", "2026-01-15 00:00:00"),
        ("15 de fev", "2025-02-15 00:00:00"),
        ("15 de mar", "2025-03-15 00:00:00"),
        ("15 de abr", "2025-04-15 00:00:00"),
        ("15 de mai", "2025-05-15 00:00:00"),
        ("15 de jun", "2025-06-15 00:00:00"),
        ("15 de jul", "2025-07-15 00:00:00"),
        ("15 de ago", "2025-08-15 00:00:00"),
        ("15 de set", "2025-09-15 00:00:00"),
        ("15 de out", "2025-10-15 00:00:00"),
        ("15 de nov", "2025-11-15 00:00:00"),
        ("15 de dez", "2025-12-15 00:00:00"),
        ("15 de março", "2025-03-15 00:00:00"),
        ("15 de marco", "2025-03-15 00:00:00"),
        ("o dia 15 de março", "2025-03-15 00:00:00"),
        ("dia 15 de março", "2025-03-15 00:00:00"),
        ("quinze de março", "2025-03-15 00:00:00"),
        ("primeiro de maio", "2025-05-01 00:00:00"),
        ("vinte e cinco de dezembro", "2025-12-25 00:00:00"),
        ("15 de março de 2026", "2026-03-15 00:00:00"),
        ("15 de março, 2026", "2026-03-15 00:00:00"),
        ("15 março 2026", "2026-03-15 00:00:00"),
        ("15-mar", "2025-03-15 00:00:00"),
        ("15/mar", "2025-03-15 00:00:00"),
        ("15 mar.", "2025-03-15 00:00:00"),
        ("15 mai.", "2025-05-15 00:00:00"),
        ("15-mar-2026", "2026-03-15 00:00:00"),
        ("15/mar/2026", "2026-03-15 00:00:00"),
        ("15 de set de 2025", "2025-09-15 00:00:00"),
        ("15 de março próximo", "2025-03-15 00:00:00"),
        ("15 de janeiro próximo", "2026-01-15 00:00:00"),
        ("8 de fevereiro próximo", "2026-02-08 00:00:00"),
        ("15 de janeiro passado", "2025-01-15 00:00:00"),
        ("15 de março passado", "2024-03-15 00:00:00"),
        ("março 15", "2025-03-15 00:00:00"),
        ("março 15 de 2026", "2026-03-15 00:00:00"),
        ("março 15, 2026", "2026-03-15 00:00:00"),
        ("fevereiro 29", "2028-02-29 00:00:00"),
        ("jan. 20 2026", "2026-01-20 00:00:00"),
        ("5 de janeiro", "2026-01-05 00:00:00"),
        ("7 de fevereiro", "2026-02-07 00:00:00"),
        ("8 de fevereiro", "2025-02-08 00:00:00"),
        ("1 de maio", "2025-05-01 00:00:00"),
        ("1º de maio", "2025-05-01 00:00:00"),
        ("29 de fevereiro", "2028-02-29 00:00:00"),
        ("29 de fevereiro de 2024", "2024-02-29 00:00:00"),
        ("08/02/2025", "2025-02-08 00:00:00"),
        ("20/03/2025", "2025-03-20 00:00:00"),
        ("20/03/25", "2025-03-20 00:00:00"),
        ("20/03/99", "1999-03-20 00:00:00"),
        ("20-03-2025", "2025-03-20 00:00:00"),
        ("20-03-25", "2025-03-20 00:00:00"),
        ("20.03.2025", "2025-03-20 00:00:00"),
        ("20.03.25", "2025-03-20 00:00:00"),
        ("20/03", "2025-03-20 00:00:00"),
        ("05/01", "2026-01-05 00:00:00"),
        ("25/12/2025", "2025-12-25 00:00:00"),
        ("29/02/2024", "2024-02-29 00:00:00"),
        ("2025-03-20", "2025-03-20 00:00:00"),
        ("2025/03/20", "2025-03-20 00:00:00"),
        ("2025.03.20", "2025-03-20 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    for (text, expected) in [
        ("dia 10", "2025-02-10 00:00:00"),
        ("o dia 10", "2025-02-10 00:00:00"),
        ("dia vinte e cinco", "2025-02-25 00:00:00"),
        ("dia primeiro", "2025-03-01 00:00:00"),
        ("dia 1º", "2025-03-01 00:00:00"),
        ("1º", "2025-03-01 00:00:00"),
        ("1ª", "2025-03-01 00:00:00"),
        ("1°", "2025-03-01 00:00:00"),
        ("dia 8", "2025-03-08 00:00:00"),
        ("dia 5", "2025-03-05 00:00:00"),
        ("dia 31", "2025-03-31 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    let mut apr30 = opts();
    apr30.reference = NaiveDate::from_ymd_opt(2025, 4, 30)
        .unwrap()
        .and_hms_opt(0, 0, 0)
        .unwrap();
    assert_eq!(
        parse_one(&p, "dia 31", &apr30).date.to_string(),
        "2025-05-31 00:00:00"
    );

    for (text, expected) in [
        ("primeira segunda-feira de março", "2025-03-03 00:00:00"),
        ("1ª segunda-feira de março", "2025-03-03 00:00:00"),
        (
            "primeira segunda-feira do mês de março",
            "2025-03-03 00:00:00",
        ),
        ("segunda segunda-feira de março", "2025-03-10 00:00:00"),
        ("terceira segunda-feira de março", "2025-03-17 00:00:00"),
        ("a terceira segunda-feira de março", "2025-03-17 00:00:00"),
        ("terceira 2ª-feira de março", "2025-03-17 00:00:00"),
        ("quarta segunda-feira de março", "2025-03-24 00:00:00"),
        ("quinta segunda-feira de março", "2025-03-31 00:00:00"),
        ("última sexta-feira em março", "2025-03-28 00:00:00"),
        ("última segunda-feira de fevereiro", "2025-02-24 00:00:00"),
        ("ultima segunda-feira de fevereiro", "2025-02-24 00:00:00"),
        ("o primeiro domingo de março", "2025-03-02 00:00:00"),
        ("3º domingo de março", "2025-03-16 00:00:00"),
        ("terceiro sábado de fevereiro", "2025-02-15 00:00:00"),
        ("último domingo de fevereiro", "2025-02-23 00:00:00"),
        ("segundo sábado de fevereiro", "2026-02-14 00:00:00"),
        ("primeira segunda-feira de fevereiro", "2026-02-02 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }
}

#[test]
fn offsets_ahead_ago_and_within_days() {
    let p = Parser::default();
    for (text, expected) in [
        ("daqui a 1 dia", "2025-02-09 00:00:00"),
        ("daqui a dois dias", "2025-02-10 00:00:00"),
        ("daqui a 3 dias", "2025-02-11 00:00:00"),
        ("daqui a vinte e cinco dias", "2025-03-05 00:00:00"),
        ("daqui a 1 semana", "2025-02-15 00:00:00"),
        ("daqui a uma semana", "2025-02-15 00:00:00"),
        ("daqui a 2 semanas", "2025-02-22 00:00:00"),
        ("daqui a 1 mês", "2025-03-01 00:00:00"),
        ("daqui a 1 mes", "2025-03-01 00:00:00"),
        ("daqui a 2 meses", "2025-04-01 00:00:00"),
        ("daqui a três meses", "2025-05-01 00:00:00"),
        ("daqui a 1 ano", "2026-02-01 00:00:00"),
        ("daqui a um ano", "2026-02-01 00:00:00"),
        ("daqui a 2 anos", "2027-02-01 00:00:00"),
        ("em 1 mês", "2025-03-01 00:00:00"),
        ("em 1 ano", "2026-02-01 00:00:00"),
        ("dentro de 4 dias", "2025-02-12 00:00:00"),
        ("de hoje a 5 dias", "2025-02-13 00:00:00"),
        ("3 dias depois", "2025-02-11 00:00:00"),
        ("2 semanas mais tarde", "2025-02-22 00:00:00"),
        ("1 mês a partir de agora", "2025-03-01 00:00:00"),
        ("2 anos à frente", "2027-02-01 00:00:00"),
        ("5 dias adiante", "2025-02-13 00:00:00"),
        ("há 1 dia", "2025-02-07 00:00:00"),
        ("ha 1 dia", "2025-02-07 00:00:00"),
        ("há dois dias", "2025-02-06 00:00:00"),
        ("1 dia atrás", "2025-02-07 00:00:00"),
        ("1 dia atras", "2025-02-07 00:00:00"),
        ("há 3 dias", "2025-02-05 00:00:00"),
        ("faz 3 dias", "2025-02-05 00:00:00"),
        ("há 2 dias atrás", "2025-02-06 00:00:00"),
        ("3 dias atrás", "2025-02-05 00:00:00"),
        ("3 dias antes", "2025-02-05 00:00:00"),
        ("há 1 semana", "2025-02-01 00:00:00"),
        ("1 semana atrás", "2025-02-01 00:00:00"),
        ("há 2 semanas", "2025-01-25 00:00:00"),
        ("fazem 2 semanas", "2025-01-25 00:00:00"),
        ("2 semanas atrás", "2025-01-25 00:00:00"),
        ("duas semanas atrás", "2025-01-25 00:00:00"),
        ("2 semanas mais cedo", "2025-01-25 00:00:00"),
        ("há 1 mês", "2025-01-01 00:00:00"),
        ("ha 1 mes", "2025-01-01 00:00:00"),
        ("1 mês atrás", "2025-01-01 00:00:00"),
        ("1 mes atras", "2025-01-01 00:00:00"),
        ("há 2 meses", "2024-12-01 00:00:00"),
        ("2 meses atrás", "2024-12-01 00:00:00"),
        ("há 1 ano", "2024-02-01 00:00:00"),
        ("1 ano atrás", "2024-02-01 00:00:00"),
        ("há 2 anos", "2023-02-01 00:00:00"),
        ("2 anos atrás", "2023-02-01 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    for text in [
        "em 0 dias",
        "em 1 dia",
        "em 3 dias",
        "em 2 semanas",
        "em até 0 dias",
        "em até 1 dia",
        "em até 3 dias",
        "em ate 3 dias",
        "dentro de até 3 dias",
        "no prazo de 5 dias",
        "em um prazo de 2 dias",
        "nos próximos 3 dias",
        "nos próximos dois dias",
        "durante os próximos 5 dias",
        "nas próximas 2 semanas",
        "em até 1 semana",
    ] {
        assert_exact(&p, text, "2025-02-08 00:00:00");
    }

    let mut range_opts = opts();
    range_opts.range = true;
    for text in ["em 1 dia", "em até 1 dia"] {
        let one_day = p.parse(text, &range_opts).unwrap();
        assert_eq!(one_day.len(), 2, "{text}");
        assert_eq!(one_day[0].date.to_string(), "2025-02-08 00:00:00");
        assert_eq!(one_day[1].date.to_string(), "2025-02-09 00:00:00");
    }

    for text in ["em 3 dias", "nos próximos 3 dias"] {
        let three_days = p.parse(text, &range_opts).unwrap();
        assert_eq!(three_days.len(), 4, "{text}");
        assert_eq!(three_days[0].date.to_string(), "2025-02-08 00:00:00");
        assert_eq!(three_days[3].date.to_string(), "2025-02-11 00:00:00");
    }

    let two_weeks = p.parse("em 2 semanas", &range_opts).unwrap();
    assert_eq!(two_weeks.len(), 15);
    assert_eq!(two_weeks[14].date.to_string(), "2025-02-22 00:00:00");

    let one_week = p.parse("em até 1 semana", &range_opts).unwrap();
    assert_eq!(one_week.len(), 8);
    assert_eq!(one_week[7].date.to_string(), "2025-02-15 00:00:00");
}

#[test]
fn time_expressions_24h_12h_meridiems_and_fractions() {
    let p = Parser::default();
    for (text, expected) in [
        ("14:30", "2025-02-08 14:30:00"),
        ("09:15", "2025-02-09 09:15:00"),
        ("11:05", "2025-02-09 11:05:00"),
        ("11:06", "2025-02-08 11:06:00"),
        ("00:00", "2025-02-09 00:00:00"),
        ("23:59", "2025-02-08 23:59:00"),
        ("14:30:45", "2025-02-08 14:30:00"),
        ("09:05:10", "2025-02-09 09:05:00"),
        ("meio-dia", "2025-02-08 12:00:00"),
        ("meio dia", "2025-02-08 12:00:00"),
        ("meia-noite", "2025-02-09 00:00:00"),
        ("meia noite", "2025-02-09 00:00:00"),
        ("meio-dia em ponto", "2025-02-08 12:00:00"),
        ("meio-dia e meia", "2025-02-08 12:30:00"),
        ("meio-dia e um quarto", "2025-02-08 12:15:00"),
        ("meio-dia e 20", "2025-02-08 12:20:00"),
        ("meia-noite e meia", "2025-02-09 00:30:00"),
        ("meia-noite e dez", "2025-02-09 00:10:00"),
        ("12 da noite", "2025-02-09 00:00:00"),
        ("12:15 da madrugada", "2025-02-09 00:15:00"),
        ("12 da tarde", "2025-02-08 12:00:00"),
        ("12 do meio-dia", "2025-02-08 12:00:00"),
        ("14h", "2025-02-08 14:00:00"),
        ("14 hrs", "2025-02-08 14:00:00"),
        ("14 hs", "2025-02-08 14:00:00"),
        ("14 horas", "2025-02-08 14:00:00"),
        ("14h30", "2025-02-08 14:30:00"),
        ("14h30min", "2025-02-08 14:30:00"),
        ("14h30m", "2025-02-08 14:30:00"),
        ("14 h 30", "2025-02-08 14:30:00"),
        ("14:30 horas", "2025-02-08 14:30:00"),
        ("15H05", "2025-02-08 15:05:00"),
        ("9h", "2025-02-09 09:00:00"),
        ("9h15", "2025-02-09 09:15:00"),
        ("0h", "2025-02-09 00:00:00"),
        ("3pm", "2025-02-08 15:00:00"),
        ("3:30 p.m.", "2025-02-08 15:30:00"),
        ("3:15:30 pm", "2025-02-08 15:15:00"),
        ("9am", "2025-02-09 09:00:00"),
        ("9 a.m.", "2025-02-09 09:00:00"),
        ("9h am", "2025-02-09 09:00:00"),
        ("9h30 am", "2025-02-09 09:30:00"),
        ("12pm", "2025-02-08 12:00:00"),
        ("12am", "2025-02-09 00:00:00"),
        ("9h da manhã", "2025-02-09 09:00:00"),
        ("9 da manhã", "2025-02-09 09:00:00"),
        ("9 da manha", "2025-02-09 09:00:00"),
        ("nove da manhã", "2025-02-09 09:00:00"),
        ("11h30 da manhã", "2025-02-08 11:30:00"),
        ("02h15 da madrugada", "2025-02-09 02:15:00"),
        ("3h da tarde", "2025-02-08 15:00:00"),
        ("3 da tarde", "2025-02-08 15:00:00"),
        ("duas da tarde", "2025-02-08 14:00:00"),
        ("3h30 da tarde", "2025-02-08 15:30:00"),
        ("3h30min da tarde", "2025-02-08 15:30:00"),
        ("3:30 da tarde", "2025-02-08 15:30:00"),
        ("8h da noite", "2025-02-08 20:00:00"),
        ("8 da noite", "2025-02-08 20:00:00"),
        ("9:15 da noite", "2025-02-08 21:15:00"),
        ("14h e meia", "2025-02-08 14:30:00"),
        ("14 horas e meia", "2025-02-08 14:30:00"),
        ("14h e 45", "2025-02-08 14:45:00"),
        ("3 e meia da tarde", "2025-02-08 15:30:00"),
        ("três e meia da tarde", "2025-02-08 15:30:00"),
        ("3h e meia da tarde", "2025-02-08 15:30:00"),
        ("9 e meia da manhã", "2025-02-09 09:30:00"),
        ("14h e quinze", "2025-02-08 14:15:00"),
        ("14 horas e quinze", "2025-02-08 14:15:00"),
        ("3 e quinze da tarde", "2025-02-08 15:15:00"),
        ("3 e um quarto da tarde", "2025-02-08 15:15:00"),
        ("3h e quinze da tarde", "2025-02-08 15:15:00"),
        ("9 e quinze da manhã", "2025-02-09 09:15:00"),
        ("quinze para as 4", "2025-02-09 03:45:00"),
        ("quinze para as 4 da tarde", "2025-02-08 15:45:00"),
        ("um quarto para as 4 da tarde", "2025-02-08 15:45:00"),
        ("dez para o meio-dia", "2025-02-08 11:50:00"),
        ("vinte para a meia-noite", "2025-02-08 23:40:00"),
        ("cinco pras 3 da tarde", "2025-02-08 14:55:00"),
        ("dez minutos para as 10h", "2025-02-09 09:50:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    for (text, expected) in [
        ("às 15h", "2025-02-08 15:00:00"),
        ("as 15h", "2025-02-08 15:00:00"),
        ("às 15 horas", "2025-02-08 15:00:00"),
        ("às duas horas", "2025-02-09 02:00:00"),
        ("à 1 hora", "2025-02-09 01:00:00"),
        ("às 15", "2025-02-08 15:00:00"),
        ("às vinte", "2025-02-08 20:00:00"),
        ("à uma", "2025-02-09 01:00:00"),
        ("às 3 e meia", "2025-02-09 03:30:00"),
        ("às 14 e 20", "2025-02-08 14:20:00"),
        ("às 14 e meia", "2025-02-08 14:30:00"),
        ("às 14 e quinze", "2025-02-08 14:15:00"),
        ("às 15h em ponto", "2025-02-08 15:00:00"),
        ("às 12h30 da noite", "2025-02-09 00:30:00"),
        ("9 horas da manhã", "2025-02-09 09:00:00"),
        ("3 horas da tarde", "2025-02-08 15:00:00"),
        ("8 horas da noite", "2025-02-08 20:00:00"),
    ] {
        assert_date(&p, text, expected);
    }
}

#[test]
fn utf8_byte_spans_and_normalized_digits() {
    let p = Parser::default();
    let prose = "📅 Reunião amanhã às 14h30 em São Paulo 🚀";
    let m = parse_one(&p, prose, &opts());
    assert_eq!(&prose[m.start..m.end], "amanhã às 14h30");
    assert_eq!(m.date.to_string(), "2025-02-09 14:30:00");

    let mut range_opts = opts();
    range_opts.range = true;

    let fullwidth = "😀 １５ de março 🚀 ２０/０３/２０２５ 🎉";
    let mut results = p.parse(fullwidth, &range_opts).unwrap();
    results.sort_by_key(|r| r.start);
    assert_eq!(results.len(), 2);
    for r in &results {
        assert!(fullwidth.is_char_boundary(r.start) && fullwidth.is_char_boundary(r.end));
    }
    assert_eq!(
        &fullwidth[results[0].start..results[0].end],
        "１５ de março"
    );
    assert_eq!(results[0].date.to_string(), "2025-03-15 00:00:00");
    assert_eq!(
        &fullwidth[results[1].start..results[1].end],
        "２０/０３/２０２５"
    );
    assert_eq!(results[1].date.to_string(), "2025-03-20 00:00:00");

    let arabic_digits = "😀 ١٥ de março às ٩h 🎉";
    let m = parse_one(&p, arabic_digits, &opts());
    assert_eq!(&arabic_digits[m.start..m.end], "١٥ de março às ٩h");
    assert_eq!(m.date.to_string(), "2025-03-15 09:00:00");
}

#[test]
fn composition_date_relative_anchor_weekday_and_time() {
    let p = Parser::default();
    for (text, expected) in [
        ("hoje às 15h", "2025-02-08 15:00:00"),
        ("hoje as 15h", "2025-02-08 15:00:00"),
        ("amanhã às 9h30", "2025-02-09 09:30:00"),
        ("amanha as 9h30", "2025-02-09 09:30:00"),
        ("amanhã por volta das 14h", "2025-02-09 14:00:00"),
        ("amanhã de manhã às 8h", "2025-02-09 08:00:00"),
        ("amanhã à tarde às 3h", "2025-02-09 15:00:00"),
        ("amanhã às 3 da tarde", "2025-02-09 15:00:00"),
        ("amanhã ao meio-dia", "2025-02-09 12:00:00"),
        ("amanhã à meia-noite", "2025-02-09 00:00:00"),
        ("depois de amanhã 18:45", "2025-02-10 18:45:00"),
        ("ontem às 20h", "2025-02-07 20:00:00"),
        ("ontem à noite às 10h", "2025-02-07 22:00:00"),
        ("anteontem às 8h da manhã", "2025-02-06 08:00:00"),
        ("hoje de madrugada às 2h", "2025-02-08 02:00:00"),
        ("hoje às 9 da noite", "2025-02-08 21:00:00"),
        ("esta noite às 9h", "2025-02-08 21:00:00"),
        ("15 de março às 14h30", "2025-03-15 14:30:00"),
        ("15 de março de 2026 às 9h da manhã", "2026-03-15 09:00:00"),
        ("20/03/2025 às 16:45", "2025-03-20 16:45:00"),
        ("dia 10 às 8h", "2025-02-10 08:00:00"),
        (
            "terceira segunda-feira de março às 15:00",
            "2025-03-17 15:00:00",
        ),
        ("sexta-feira às 19h", "2025-02-14 19:00:00"),
        ("próxima segunda às 10h", "2025-02-10 10:00:00"),
        ("segunda passada às 10h", "2025-02-03 10:00:00"),
        ("fim de semana às 16h", "2025-02-09 16:00:00"),
        ("próxima semana quarta-feira às 14h", "2025-02-12 14:00:00"),
        (
            "segunda-feira da próxima semana às 14h",
            "2025-02-10 14:00:00",
        ),
        ("próximo mês segunda-feira", "2025-03-03 00:00:00"),
        ("segunda-feira de fevereiro", "2025-02-03 00:00:00"),
        (
            "segunda-feira 10 de fevereiro às 15h",
            "2025-02-10 15:00:00",
        ),
        (
            "segunda-feira, 10 de fevereiro, às 15h",
            "2025-02-10 15:00:00",
        ),
        ("terça-feira 11 de fevereiro", "2025-02-11 00:00:00"),
    ] {
        assert_exact(&p, text, expected);
    }

    let wed_ref = NaiveDate::from_ymd_opt(2025, 2, 12)
        .unwrap()
        .and_hms_opt(11, 5, 0)
        .unwrap();
    for week_start in [1, 7] {
        let mut o = opts();
        o.reference = wed_ref;
        o.week_start = week_start;
        for text in [
            "semana passada segunda-feira",
            "segunda-feira da semana passada",
        ] {
            assert_eq!(
                parse_one(&p, text, &o).date.to_string(),
                "2025-02-03 00:00:00",
                "{text}, week_start={week_start}"
            );
        }
    }
    for (week_start, expected) in [(1, "2025-02-09 00:00:00"), (7, "2025-02-02 00:00:00")] {
        let mut o = opts();
        o.reference = wed_ref;
        o.week_start = week_start;
        for text in ["semana passada domingo", "domingo da semana passada"] {
            assert_eq!(
                parse_one(&p, text, &o).date.to_string(),
                expected,
                "{text}, week_start={week_start}"
            );
        }
    }
}

#[test]
fn range_mode_parse_ranges_offsets_and_errors() {
    let p = Parser::default();
    let mut o = opts();
    o.range = true;

    let sun_week = p.parse("próxima semana", &o).unwrap();
    assert_eq!(sun_week.len(), 7);
    assert_eq!(sun_week[0].date.to_string(), "2025-02-09 00:00:00");
    assert_eq!(sun_week[6].date.to_string(), "2025-02-15 00:00:00");

    o.week_start = 1;
    let mon_week = p.parse("próxima semana", &o).unwrap();
    assert_eq!(mon_week.len(), 7);
    assert_eq!(mon_week[0].date.to_string(), "2025-02-10 00:00:00");
    assert_eq!(mon_week[6].date.to_string(), "2025-02-16 00:00:00");

    o.week_start = 7;
    assert_eq!(p.parse("este mês", &o).unwrap().len(), 28);
    assert_eq!(p.parse("próximo mês", &o).unwrap().len(), 31);
    assert_eq!(p.parse("abril", &o).unwrap().len(), 30);

    let ranges_week = p.parse_ranges("próxima semana", &o).unwrap();
    assert_eq!(ranges_week.len(), 1);
    assert_eq!(ranges_week[0].range_days, Some(7));
    assert_eq!(ranges_week[0].range_type, Some("week"));

    let ranges_month = p.parse_ranges("próximo mês", &o).unwrap();
    assert_eq!(ranges_month.len(), 1);
    assert_eq!(ranges_month[0].range_days, Some(31));
    assert_eq!(ranges_month[0].range_type, Some("month"));

    for text in ["em 5 dias", "em até 5 dias", "nos próximos 5 dias"] {
        let ranges_within = p.parse_ranges(text, &o).unwrap();
        assert_eq!(ranges_within.len(), 1, "{text}");
        assert_eq!(ranges_within[0].date.to_string(), "2025-02-08 00:00:00");
        assert_eq!(ranges_within[0].range_days, Some(6));
    }

    let multi = "O evento começa em 10 de março às 9h e termina em 15 de março às 18h";
    let mut matches = p.parse(multi, &o).unwrap();
    matches.sort_by_key(|m| m.start);
    assert_eq!(matches.len(), 2);
    assert_eq!(matches[0].date.to_string(), "2025-03-10 09:00:00");
    assert_eq!(matches[1].date.to_string(), "2025-03-15 18:00:00");

    let mut brt = opts();
    brt.offset_minutes = -180;
    assert_eq!(
        parse_with("15 de março às 14:00", &brt).unwrap()[0]
            .date
            .to_string(),
        "2025-03-15 11:00:00"
    );

    let mut dup = opts();
    dup.languages = &["pt", "pt"];
    assert_eq!(
        p.parse("amanhã às 14h", &dup).unwrap(),
        p.parse("amanhã às 14h", &opts()).unwrap()
    );

    assert_eq!(p.parse("em 999999 dias", &o), Err(Error::RangeTooLarge));
    assert_eq!(p.parse("em até 999999 dias", &o), Err(Error::RangeTooLarge));
    o.week_start = 2;
    assert_eq!(p.parse("hoje", &o), Err(Error::InvalidWeekStart));
}

#[test]
fn negative_guards_invalid_dates_and_glue_boundaries() {
    let p = Parser::default();

    for text in [
        "",
        "3pmPST",
        "15hABC",
        "10ha",
        "100 habitantes",
        "10h de viagem",
        "2h de duração",
        "2 horas e meia",
        "3 horas",
        "1º lugar",
        "1º andar",
        "1º grau",
        "em 2025 pessoas",
        "15 de marçoA",
        "hojeA",
        "apontem",
        "melodia",
        "agostinho",
        "maravilha",
        "sexteto",
        "bissexto",
        "domínio",
        "seguro",
        "termo",
        "quadro",
        "quilo",
        "saber",
        "janela",
        "abrir",
        "mais",
        "junto",
        "julgar",
        "agonia",
        "seta",
        "outro",
        "novela",
        "dezena",
        "30 de fevereiro",
        "31 de abril",
        "31 de junho",
        "31 de setembro",
        "31 de novembro",
        "29 de fevereiro de 2025",
        "0 de março",
        "32 de março",
        "março 32",
        "março 0",
        "30/02/2025",
        "31/04/2025",
        "29/02/2025",
        "15/13/2025",
        "00/03/2025",
        "25:00",
        "24:00",
        "12:60",
        "25h",
        "24h",
        "14h60",
        "quinta segunda-feira de fevereiro",
        "segunda-feira 11 de fevereiro",
        "daqui a 999999999999999999999 dias",
        "999999999999999999999 dias atrás",
        "14:999999999999999999999",
        "da manhã",
        "da tarde",
        "da noite",
        "am",
        "pm",
        "Eu gosto de música pela tarde tranquila.",
    ] {
        assert_empty(&p, text);
    }

    let mut range_opts = opts();
    range_opts.range = true;

    let sep_time = "amanhã reunião às 15h";
    let mut r1 = p.parse(sep_time, &range_opts).unwrap();
    r1.sort_by_key(|m| m.start);
    assert_eq!(r1.len(), 2);
    assert!(
        r1.iter()
            .all(|m| !sep_time[m.start..m.end].contains("reunião"))
    );
    assert_eq!(r1[0].date.to_string(), "2025-02-09 00:00:00");
    assert_eq!(r1[1].date.to_string(), "2025-02-08 15:00:00");

    let sep_dates = "10 de março viagem 20 de março";
    let mut r2 = p.parse(sep_dates, &range_opts).unwrap();
    r2.sort_by_key(|m| m.start);
    assert_eq!(r2.len(), 2);
    assert!(
        r2.iter()
            .all(|m| !sep_dates[m.start..m.end].contains("viagem"))
    );
    assert_eq!(r2[0].date.to_string(), "2025-03-10 00:00:00");
    assert_eq!(r2[1].date.to_string(), "2025-03-20 00:00:00");
}

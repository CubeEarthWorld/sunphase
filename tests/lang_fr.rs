use sunphase::{Error, NaiveDate, Options, Parser};

fn opts() -> Options<'static> {
    Options::new(
        NaiveDate::from_ymd_opt(2025, 2, 8)
            .unwrap()
            .and_hms_opt(11, 5, 0)
            .unwrap(),
    )
}

fn fr_opts() -> Options<'static> {
    Options {
        languages: &["fr"],
        ..opts()
    }
}

fn assert_fr(cases: &[(&str, &str)]) {
    let p = Parser::default();
    let o = fr_opts();
    for &(text, expected) in cases {
        let res = p.parse(text, &o).unwrap();
        assert_eq!(res.len(), 1, "expected 1 match for {text:?}, got {res:?}");
        assert_eq!(res[0].date.to_string(), expected, "{text}");
    }
}

#[test]
fn relative_days() {
    assert_fr(&[
        ("aujourd'hui", "2025-02-08 00:00:00"),
        ("aujourd’hui", "2025-02-08 00:00:00"),
        ("Aujourd'hui", "2025-02-08 00:00:00"),
        ("aujourdhui", "2025-02-08 00:00:00"),
        ("auj.", "2025-02-08 00:00:00"),
        ("demain", "2025-02-09 00:00:00"),
        ("Demain", "2025-02-09 00:00:00"),
        ("hier", "2025-02-07 00:00:00"),
        ("après-demain", "2025-02-10 00:00:00"),
        ("apres-demain", "2025-02-10 00:00:00"),
        ("après demain", "2025-02-10 00:00:00"),
        ("apres demain", "2025-02-10 00:00:00"),
        ("apresdemain", "2025-02-10 00:00:00"),
        ("avant-hier", "2025-02-06 00:00:00"),
        ("avant hier", "2025-02-06 00:00:00"),
        ("avanthier", "2025-02-06 00:00:00"),
        ("après-après-demain", "2025-02-11 00:00:00"),
        ("apres apres demain", "2025-02-11 00:00:00"),
        ("avant-avant-hier", "2025-02-05 00:00:00"),
        ("avant avant hier", "2025-02-05 00:00:00"),
        ("ce soir à 9h", "2025-02-08 21:00:00"),
        ("ce soir à 20h", "2025-02-08 20:00:00"),
        ("ce matin à 8h", "2025-02-08 08:00:00"),
        ("cet après-midi à 3h", "2025-02-08 15:00:00"),
        ("cet aprèm à 4h", "2025-02-08 16:00:00"),
        ("cette soirée à 9h", "2025-02-08 21:00:00"),
        ("cette nuit à 2h", "2025-02-08 02:00:00"),
        ("cette matinée à 10h", "2025-02-08 10:00:00"),
        ("demain matin à 8h", "2025-02-09 08:00:00"),
        ("demain matinée à 9h", "2025-02-09 09:00:00"),
        ("demain soir à 8h", "2025-02-09 20:00:00"),
        ("hier soir à 9h", "2025-02-07 21:00:00"),
        ("hier soirée à 8h", "2025-02-07 20:00:00"),
        ("demain après-midi à 3h", "2025-02-09 15:00:00"),
        ("demain apres-midi à 15h", "2025-02-09 15:00:00"),
        ("demain aprèm à 4h", "2025-02-09 16:00:00"),
        ("demain aprem à 16h", "2025-02-09 16:00:00"),
        ("après-demain matin à 10h", "2025-02-10 10:00:00"),
        ("avant-hier soir à 7h", "2025-02-06 19:00:00"),
        ("demain nuit à 2h", "2025-02-09 02:00:00"),
        ("ce midi", "2025-02-08 12:00:00"),
        ("ce midi et demi", "2025-02-08 12:30:00"),
        ("ce midi et quart", "2025-02-08 12:15:00"),
        ("ce midi moins le quart", "2025-02-08 11:45:00"),
        ("ce midi moins quart", "2025-02-08 11:45:00"),
        ("ce midi pile", "2025-02-08 12:00:00"),
        ("ce midi précis", "2025-02-08 12:00:00"),
        ("ce midi juste", "2025-02-08 12:00:00"),
    ]);

    let p = Parser::default();
    let o = fr_opts();
    let tonight = p.parse("ce soir", &o).unwrap();
    assert_eq!(tonight.len(), 1);
    assert_eq!(
        tonight[0].date.date(),
        NaiveDate::from_ymd_opt(2025, 2, 8).unwrap()
    );
}

#[test]
fn weekdays_and_relative_weekdays() {
    assert_fr(&[
        ("lundi", "2025-02-10 00:00:00"),
        ("mardi", "2025-02-11 00:00:00"),
        ("mercredi", "2025-02-12 00:00:00"),
        ("jeudi", "2025-02-13 00:00:00"),
        ("vendredi", "2025-02-14 00:00:00"),
        ("samedi", "2025-02-15 00:00:00"),
        ("dimanche", "2025-02-09 00:00:00"),
        ("Lundi", "2025-02-10 00:00:00"),
        ("SAMEDI", "2025-02-15 00:00:00"),
        ("Dimanche", "2025-02-09 00:00:00"),
        ("lun.", "2025-02-10 00:00:00"),
        ("mar.", "2025-02-11 00:00:00"),
        ("mer.", "2025-02-12 00:00:00"),
        ("merc", "2025-02-12 00:00:00"),
        ("merc.", "2025-02-12 00:00:00"),
        ("mercr", "2025-02-12 00:00:00"),
        ("mercr.", "2025-02-12 00:00:00"),
        ("jeu.", "2025-02-13 00:00:00"),
        ("jeud", "2025-02-13 00:00:00"),
        ("jeud.", "2025-02-13 00:00:00"),
        ("ven.", "2025-02-14 00:00:00"),
        ("vend", "2025-02-14 00:00:00"),
        ("vend.", "2025-02-14 00:00:00"),
        ("sam.", "2025-02-15 00:00:00"),
        ("dim.", "2025-02-09 00:00:00"),
        ("lundi prochain", "2025-02-10 00:00:00"),
        ("lundi qui vient", "2025-02-10 00:00:00"),
        ("lundi suivant", "2025-02-10 00:00:00"),
        ("prochain lundi", "2025-02-10 00:00:00"),
        ("dimanche prochain", "2025-02-09 00:00:00"),
        ("samedi prochain", "2025-02-15 00:00:00"),
        ("vendredi dernier", "2025-02-07 00:00:00"),
        ("vendredi passé", "2025-02-07 00:00:00"),
        ("vendredi précédent", "2025-02-07 00:00:00"),
        ("dernier vendredi", "2025-02-07 00:00:00"),
        ("lundi dernier", "2025-02-03 00:00:00"),
        ("samedi dernier", "2025-02-01 00:00:00"),
        ("dimanche dernier", "2025-02-02 00:00:00"),
        ("lun prochain", "2025-02-10 00:00:00"),
        ("ven dernier", "2025-02-07 00:00:00"),
        ("merc. prochain", "2025-02-12 00:00:00"),
        ("jeud dernier", "2025-02-06 00:00:00"),
        ("lundi de la semaine prochaine", "2025-02-10 00:00:00"),
        ("vendredi semaine suivante", "2025-02-14 00:00:00"),
        ("lundi de la semaine qui vient", "2025-02-10 00:00:00"),
    ]);

    let p = Parser::default();
    let mut wed = fr_opts();
    wed.reference = "2025-02-12T11:05:00".parse().unwrap();
    for (text, expected) in [
        ("ce jeudi", "2025-02-13 00:00:00"),
        ("ce vendredi", "2025-02-14 00:00:00"),
        ("ce samedi", "2025-02-15 00:00:00"),
        ("vendredi de cette semaine", "2025-02-14 00:00:00"),
        ("lundi de la semaine passée", "2025-02-03 00:00:00"),
        ("mercredi de la semaine précédente", "2025-02-05 00:00:00"),
        ("vendredi de la semaine courante", "2025-02-14 00:00:00"),
        ("vendredi semaine en cours", "2025-02-14 00:00:00"),
    ] {
        assert_eq!(
            p.parse(text, &wed).unwrap()[0].date.to_string(),
            expected,
            "{text}"
        );
    }

    let mut mon_week = fr_opts();
    mon_week.week_start = 1;
    assert_eq!(
        p.parse("ce dimanche", &mon_week).unwrap()[0]
            .date
            .to_string(),
        "2025-02-09 00:00:00"
    );
}

#[test]
fn calendar_anchors() {
    assert_fr(&[
        ("cette semaine", "2025-02-02 00:00:00"),
        ("semaine en cours", "2025-02-02 00:00:00"),
        ("semaine courante", "2025-02-02 00:00:00"),
        ("la semaine prochaine", "2025-02-09 00:00:00"),
        ("la prochaine semaine", "2025-02-09 00:00:00"),
        ("semaine prochaine", "2025-02-09 00:00:00"),
        ("semaine suivante", "2025-02-09 00:00:00"),
        ("semaine qui vient", "2025-02-09 00:00:00"),
        ("la semaine dernière", "2025-01-26 00:00:00"),
        ("la dernière semaine", "2025-01-26 00:00:00"),
        ("la semaine derniere", "2025-01-26 00:00:00"),
        ("semaine dernière", "2025-01-26 00:00:00"),
        ("semaine passée", "2025-01-26 00:00:00"),
        ("semaine précédente", "2025-01-26 00:00:00"),
        ("ce mois", "2025-02-01 00:00:00"),
        ("ce mois-ci", "2025-02-01 00:00:00"),
        ("mois en cours", "2025-02-01 00:00:00"),
        ("mois courant", "2025-02-01 00:00:00"),
        ("le mois prochain", "2025-03-01 00:00:00"),
        ("le prochain mois", "2025-03-01 00:00:00"),
        ("mois prochain", "2025-03-01 00:00:00"),
        ("mois suivant", "2025-03-01 00:00:00"),
        ("mois qui vient", "2025-03-01 00:00:00"),
        ("le mois dernier", "2025-01-01 00:00:00"),
        ("le dernier mois", "2025-01-01 00:00:00"),
        ("mois dernier", "2025-01-01 00:00:00"),
        ("mois passé", "2025-01-01 00:00:00"),
        ("mois précédent", "2025-01-01 00:00:00"),
        ("cette année", "2025-02-01 00:00:00"),
        ("cette année-ci", "2025-02-01 00:00:00"),
        ("cette annee", "2025-02-01 00:00:00"),
        ("cet an", "2025-02-01 00:00:00"),
        ("cet an-ci", "2025-02-01 00:00:00"),
        ("l'année en cours", "2025-02-01 00:00:00"),
        ("l'année courante", "2025-02-01 00:00:00"),
        ("l'année prochaine", "2026-02-01 00:00:00"),
        ("la prochaine année", "2026-02-01 00:00:00"),
        ("l'année suivante", "2026-02-01 00:00:00"),
        ("l'année qui vient", "2026-02-01 00:00:00"),
        ("l'annee prochaine", "2026-02-01 00:00:00"),
        ("l'an prochain", "2026-02-01 00:00:00"),
        ("le prochain an", "2026-02-01 00:00:00"),
        ("l'an suivant", "2026-02-01 00:00:00"),
        ("l'année dernière", "2024-02-01 00:00:00"),
        ("l'année passée", "2024-02-01 00:00:00"),
        ("l'année précédente", "2024-02-01 00:00:00"),
        ("l'annee derniere", "2024-02-01 00:00:00"),
        ("l'an dernier", "2024-02-01 00:00:00"),
        ("l'an passé", "2024-02-01 00:00:00"),
        ("l'an précédent", "2024-02-01 00:00:00"),
        ("week-end", "2025-02-09 00:00:00"),
        ("ce week-end", "2025-02-09 00:00:00"),
        ("weekend", "2025-02-09 00:00:00"),
        ("ce weekend", "2025-02-09 00:00:00"),
        ("fin de semaine", "2025-02-09 00:00:00"),
        ("la fin de semaine", "2025-02-09 00:00:00"),
        ("prochain week-end", "2025-02-09 00:00:00"),
        ("week-end qui vient", "2025-02-09 00:00:00"),
        ("week-end suivant", "2025-02-09 00:00:00"),
        ("le week-end dernier", "2025-02-02 00:00:00"),
        ("week-end passé", "2025-02-02 00:00:00"),
        ("dernier week-end", "2025-02-02 00:00:00"),
        ("la fin de semaine dernière", "2025-02-02 00:00:00"),
        ("mars prochain", "2025-03-01 00:00:00"),
        ("janvier prochain", "2026-01-01 00:00:00"),
        ("février prochain", "2026-02-01 00:00:00"),
        ("prochain avril", "2025-04-01 00:00:00"),
        ("avril qui vient", "2025-04-01 00:00:00"),
        ("janvier dernier", "2025-01-01 00:00:00"),
        ("février dernier", "2024-02-01 00:00:00"),
        ("décembre dernier", "2024-12-01 00:00:00"),
        ("dernier octobre", "2024-10-01 00:00:00"),
        ("novembre passé", "2024-11-01 00:00:00"),
        ("août précédent", "2024-08-01 00:00:00"),
    ]);

    let p = Parser::default();
    let o = fr_opts();
    assert_eq!(
        p.parse("cette semaine", &o).unwrap()[0].range_type,
        Some("week")
    );
    assert_eq!(
        p.parse("ce mois-ci", &o).unwrap()[0].range_type,
        Some("month")
    );
}

#[test]
fn months() {
    assert_fr(&[
        ("janvier", "2026-01-01 00:00:00"),
        ("février", "2025-02-01 00:00:00"),
        ("fevrier", "2025-02-01 00:00:00"),
        ("mars", "2025-03-01 00:00:00"),
        ("avril", "2025-04-01 00:00:00"),
        ("mai", "2025-05-01 00:00:00"),
        ("juin", "2025-06-01 00:00:00"),
        ("juillet", "2025-07-01 00:00:00"),
        ("août", "2025-08-01 00:00:00"),
        ("aout", "2025-08-01 00:00:00"),
        ("septembre", "2025-09-01 00:00:00"),
        ("octobre", "2025-10-01 00:00:00"),
        ("novembre", "2025-11-01 00:00:00"),
        ("décembre", "2025-12-01 00:00:00"),
        ("decembre", "2025-12-01 00:00:00"),
        ("Décembre", "2025-12-01 00:00:00"),
        ("janv", "2026-01-01 00:00:00"),
        ("janv.", "2026-01-01 00:00:00"),
        ("jan.", "2026-01-01 00:00:00"),
        ("févr", "2025-02-01 00:00:00"),
        ("févr.", "2025-02-01 00:00:00"),
        ("fevr", "2025-02-01 00:00:00"),
        ("fév", "2025-02-01 00:00:00"),
        ("fév.", "2025-02-01 00:00:00"),
        ("fev", "2025-02-01 00:00:00"),
        ("fev.", "2025-02-01 00:00:00"),
        ("avr", "2025-04-01 00:00:00"),
        ("avr.", "2025-04-01 00:00:00"),
        ("juil", "2025-07-01 00:00:00"),
        ("juil.", "2025-07-01 00:00:00"),
        ("juill", "2025-07-01 00:00:00"),
        ("juill.", "2025-07-01 00:00:00"),
        ("sept", "2025-09-01 00:00:00"),
        ("sept.", "2025-09-01 00:00:00"),
        ("sep", "2025-09-01 00:00:00"),
        ("sep.", "2025-09-01 00:00:00"),
        ("oct", "2025-10-01 00:00:00"),
        ("oct.", "2025-10-01 00:00:00"),
        ("nov", "2025-11-01 00:00:00"),
        ("nov.", "2025-11-01 00:00:00"),
        ("déc", "2025-12-01 00:00:00"),
        ("déc.", "2025-12-01 00:00:00"),
        ("dec", "2025-12-01 00:00:00"),
        ("janvier 2025", "2025-01-01 00:00:00"),
        ("février 2026", "2026-02-01 00:00:00"),
        ("août 2025", "2025-08-01 00:00:00"),
        ("mars de 2026", "2026-03-01 00:00:00"),
        ("mars en 2026", "2026-03-01 00:00:00"),
        ("mars, 2026", "2026-03-01 00:00:00"),
        ("en 2026", "2026-02-01 00:00:00"),
        ("l'an 2026", "2026-02-01 00:00:00"),
        ("l'année 2026", "2026-02-01 00:00:00"),
        ("année 2026", "2026-02-01 00:00:00"),
        ("rendez-vous en mars", "2025-03-01 00:00:00"),
    ]);

    let p = Parser::default();
    let o = fr_opts();
    assert_eq!(p.parse("mars", &o).unwrap()[0].range_type, Some("month"));
}

#[test]
fn calendar_dates_and_ordinals() {
    assert_fr(&[
        ("14 juillet 2025", "2025-07-14 00:00:00"),
        ("14 juillet, 2025", "2025-07-14 00:00:00"),
        ("14-juillet-2025", "2025-07-14 00:00:00"),
        ("14/juillet/2025", "2025-07-14 00:00:00"),
        ("14 du mois de juillet", "2025-07-14 00:00:00"),
        ("14 du mois d'août", "2025-08-14 00:00:00"),
        ("14 juillet", "2025-07-14 00:00:00"),
        ("15 janvier", "2026-01-15 00:00:00"),
        ("8 février", "2025-02-08 00:00:00"),
        ("7 février", "2026-02-07 00:00:00"),
        ("29 février", "2028-02-29 00:00:00"),
        ("29 février 2024", "2024-02-29 00:00:00"),
        ("le 15 mars", "2025-03-15 00:00:00"),
        ("le 8 août 2025", "2025-08-08 00:00:00"),
        ("le 25 décembre", "2025-12-25 00:00:00"),
        ("1er janvier 2026", "2026-01-01 00:00:00"),
        ("1er février", "2026-02-01 00:00:00"),
        ("1er mars", "2025-03-01 00:00:00"),
        ("1er mai", "2025-05-01 00:00:00"),
        ("1ère mai", "2025-05-01 00:00:00"),
        ("1re mai", "2025-05-01 00:00:00"),
        ("15e mars", "2025-03-15 00:00:00"),
        ("15ème mars", "2025-03-15 00:00:00"),
        ("15ième mars", "2025-03-15 00:00:00"),
        ("1er août", "2025-08-01 00:00:00"),
        ("1er decembre", "2025-12-01 00:00:00"),
        ("quatorze juillet 2025", "2025-07-14 00:00:00"),
        ("vingt-cinq décembre", "2025-12-25 00:00:00"),
        ("trente et un mars", "2025-03-31 00:00:00"),
        ("premier avril", "2025-04-01 00:00:00"),
        ("14 juillet prochain", "2025-07-14 00:00:00"),
        ("15 janvier prochain", "2026-01-15 00:00:00"),
        ("8 février prochain", "2026-02-08 00:00:00"),
        ("15 janvier dernier", "2025-01-15 00:00:00"),
        ("14 juillet dernier", "2024-07-14 00:00:00"),
        ("8 février dernier", "2024-02-08 00:00:00"),
        ("juillet 14", "2025-07-14 00:00:00"),
        ("mars 15, 2025", "2025-03-15 00:00:00"),
        ("février 1er", "2026-02-01 00:00:00"),
        ("avril-10-2025", "2025-04-10 00:00:00"),
        ("mars 10 heures", "2025-03-01 10:00:00"),
        ("mars 10 minutes", "2025-03-01 00:00:00"),
        ("mai 5 euros", "2025-05-01 00:00:00"),
        ("15 janv 2026", "2026-01-15 00:00:00"),
        ("15 févr", "2025-02-15 00:00:00"),
        ("15 fevr", "2025-02-15 00:00:00"),
        ("15 avr", "2025-04-15 00:00:00"),
        ("15 juil", "2025-07-15 00:00:00"),
        ("15 sept", "2025-09-15 00:00:00"),
        ("15 oct", "2025-10-15 00:00:00"),
        ("15 nov", "2025-11-15 00:00:00"),
        ("15 déc", "2025-12-15 00:00:00"),
        ("15 dec", "2025-12-15 00:00:00"),
        ("le 10", "2025-02-10 00:00:00"),
        ("le jour 10", "2025-02-10 00:00:00"),
        ("le 8", "2025-03-08 00:00:00"),
        ("le 5", "2025-03-05 00:00:00"),
        ("le 31", "2025-03-31 00:00:00"),
        ("le 1er", "2025-03-01 00:00:00"),
        ("le premier", "2025-03-01 00:00:00"),
        ("1er", "2025-03-01 00:00:00"),
        ("1ère", "2025-03-01 00:00:00"),
        ("le 15e", "2025-02-15 00:00:00"),
        ("le 15ème", "2025-02-15 00:00:00"),
        ("le 15ième", "2025-02-15 00:00:00"),
        ("15ème", "2025-02-15 00:00:00"),
        ("20e", "2025-02-20 00:00:00"),
        ("2ème", "2025-03-02 00:00:00"),
        ("14/07/2025", "2025-07-14 00:00:00"),
        ("03/04/2025", "2025-04-03 00:00:00"),
        ("5/3/2025", "2025-03-05 00:00:00"),
        ("14/07/25", "2025-07-14 00:00:00"),
        ("14/07/99", "1999-07-14 00:00:00"),
        ("14/07", "2025-07-14 00:00:00"),
        ("15/01", "2026-01-15 00:00:00"),
        ("03/04", "2025-04-03 00:00:00"),
        ("03.04.2025", "2025-04-03 00:00:00"),
        ("14.07.2025", "2025-07-14 00:00:00"),
        ("03.04.25", "2025-04-03 00:00:00"),
        ("03-04-2025", "2025-04-03 00:00:00"),
        ("03-04-25", "2025-04-03 00:00:00"),
        ("25-12-2025", "2025-12-25 00:00:00"),
        ("2025-07-14", "2025-07-14 00:00:00"),
        ("2025/07/14", "2025-07-14 00:00:00"),
        ("2025.07.14", "2025-07-14 00:00:00"),
        ("le premier lundi de mars", "2025-03-03 00:00:00"),
        ("premier lundi de mars", "2025-03-03 00:00:00"),
        ("le 1er lundi de mars", "2025-03-03 00:00:00"),
        ("le deuxième mardi de mars", "2025-03-11 00:00:00"),
        ("le deuxieme mardi de mars", "2025-03-11 00:00:00"),
        ("le 2e mardi de mars", "2025-03-11 00:00:00"),
        ("le second mardi de mars", "2025-03-11 00:00:00"),
        ("le troisième lundi de mars", "2025-03-17 00:00:00"),
        ("le troisieme lundi de mars", "2025-03-17 00:00:00"),
        ("le 3ème lundi de mars", "2025-03-17 00:00:00"),
        ("le quatrième vendredi de mars", "2025-03-28 00:00:00"),
        ("le quatrieme vendredi de mars", "2025-03-28 00:00:00"),
        ("le 4e vendredi de mars", "2025-03-28 00:00:00"),
        ("le cinquième lundi de mars", "2025-03-31 00:00:00"),
        ("le cinquieme lundi de mars", "2025-03-31 00:00:00"),
        ("le 5ème lundi de mars", "2025-03-31 00:00:00"),
        ("le dernier lundi de février", "2025-02-24 00:00:00"),
        ("le dernier lundi de fevrier", "2025-02-24 00:00:00"),
        ("le dernier lundi en février", "2025-02-24 00:00:00"),
        ("le dernier dimanche de mars", "2025-03-30 00:00:00"),
        ("le premier lundi d'avril", "2025-04-07 00:00:00"),
        ("le premier lundi du mois d'avril", "2025-04-07 00:00:00"),
        ("le troisième lundi du mois de mars", "2025-03-17 00:00:00"),
        ("le dernier vendredi d'août", "2025-08-29 00:00:00"),
        ("le deuxième mercredi d'octobre", "2025-10-08 00:00:00"),
        ("le troisième lundi de janvier", "2026-01-19 00:00:00"),
        ("le 3e lundi de janv.", "2026-01-19 00:00:00"),
    ]);

    let p = Parser::default();
    let mut apr30 = fr_opts();
    apr30.reference = "2025-04-30T00:00:00".parse().unwrap();
    assert_eq!(
        p.parse("le 31", &apr30).unwrap()[0].date.to_string(),
        "2025-05-31 00:00:00"
    );
}

#[test]
fn offsets() {
    assert_fr(&[
        ("dans 0 jour", "2025-02-08 00:00:00"),
        ("dans 1 jour", "2025-02-09 00:00:00"),
        ("dans 3 jours", "2025-02-11 00:00:00"),
        ("dans 2 journées", "2025-02-10 00:00:00"),
        ("dans cinq jours", "2025-02-13 00:00:00"),
        ("dans vingt-deux jours", "2025-03-02 00:00:00"),
        ("dans septante jours", "2025-04-19 00:00:00"),
        ("dans soixante-dix jours", "2025-04-19 00:00:00"),
        ("dans quatre-vingts jours", "2025-04-29 00:00:00"),
        ("dans cent jours", "2025-05-19 00:00:00"),
        ("dans 1 semaine", "2025-02-15 00:00:00"),
        ("dans une semaine", "2025-02-15 00:00:00"),
        ("dans 2 semaines", "2025-02-22 00:00:00"),
        ("dans 1 mois", "2025-03-01 00:00:00"),
        ("dans 3 mois", "2025-05-01 00:00:00"),
        ("dans 12 mois", "2026-02-01 00:00:00"),
        ("dans 1 an", "2026-02-01 00:00:00"),
        ("dans 2 ans", "2027-02-01 00:00:00"),
        ("dans 2 années", "2027-02-01 00:00:00"),
        ("dans 2 annees", "2027-02-01 00:00:00"),
        ("d'ici 2 mois", "2025-04-01 00:00:00"),
        ("d'ici à 3 mois", "2025-05-01 00:00:00"),
        ("d'ici 1 an", "2026-02-01 00:00:00"),
        ("d'ici 2 ans", "2027-02-01 00:00:00"),
        ("il y a 1 jour", "2025-02-07 00:00:00"),
        ("il y a 3 jours", "2025-02-05 00:00:00"),
        ("il y a 1 semaine", "2025-02-01 00:00:00"),
        ("il y a 2 semaines", "2025-01-25 00:00:00"),
        ("il y a trois semaines", "2025-01-18 00:00:00"),
        ("il y a 1 mois", "2025-01-01 00:00:00"),
        ("il y a 2 mois", "2024-12-01 00:00:00"),
        ("il y a 1 an", "2024-02-01 00:00:00"),
        ("il y a un an", "2024-02-01 00:00:00"),
        ("il y a 3 ans", "2022-02-01 00:00:00"),
        ("il y a 2 années", "2023-02-01 00:00:00"),
        ("3 jours plus tard", "2025-02-11 00:00:00"),
        ("2 journées plus tard", "2025-02-10 00:00:00"),
        ("2 semaines plus tard", "2025-02-22 00:00:00"),
        ("2 semaines après", "2025-02-22 00:00:00"),
        ("1 mois plus tard", "2025-03-01 00:00:00"),
        ("2 ans plus tard", "2027-02-01 00:00:00"),
        ("2 années plus tard", "2027-02-01 00:00:00"),
        ("3 jours plus tôt", "2025-02-05 00:00:00"),
        ("2 semaines auparavant", "2025-01-25 00:00:00"),
        ("1 mois avant", "2025-01-01 00:00:00"),
        ("2 ans en arrière", "2023-02-01 00:00:00"),
        ("d'ici 1 jour", "2025-02-08 00:00:00"),
        ("d'ici 3 jours", "2025-02-08 00:00:00"),
        ("d'ici à 5 jours", "2025-02-08 00:00:00"),
        ("d'ici trois jours", "2025-02-08 00:00:00"),
        ("d'ici 2 journées", "2025-02-08 00:00:00"),
        ("d'ici 2 semaines", "2025-02-08 00:00:00"),
        ("d'ici deux semaines", "2025-02-08 00:00:00"),
        ("sous 3 jours", "2025-02-08 00:00:00"),
        ("sous 1 semaine", "2025-02-08 00:00:00"),
        ("dans un délai de 4 jours", "2025-02-08 00:00:00"),
        ("en l'espace de 3 jours", "2025-02-08 00:00:00"),
        ("en moins de 2 jours", "2025-02-08 00:00:00"),
        ("dans les 5 prochains jours", "2025-02-08 00:00:00"),
        ("pendant les 3 prochains jours", "2025-02-08 00:00:00"),
        ("durant les 4 jours suivants", "2025-02-08 00:00:00"),
        ("au cours des 2 prochaines semaines", "2025-02-08 00:00:00"),
        ("dans les prochains 5 jours", "2025-02-08 00:00:00"),
        ("sur les 3 jours à venir", "2025-02-08 00:00:00"),
    ]);

    let p = Parser::default();
    let o = fr_opts();
    for (expr, expected_days) in [
        ("d'ici 1 jour", 2),
        ("d'ici 3 jours", 4),
        ("d'ici à 5 jours", 6),
        ("d'ici trois jours", 4),
        ("d'ici 2 journées", 3),
        ("d'ici 2 semaines", 15),
        ("d'ici deux semaines", 15),
        ("sous 3 jours", 4),
        ("sous 1 semaine", 8),
        ("dans un délai de 4 jours", 5),
        ("en l'espace de 3 jours", 4),
        ("en moins de 2 jours", 3),
        ("dans les 5 prochains jours", 6),
        ("au cours des 2 prochaines semaines", 15),
        ("dans les prochains 5 jours", 6),
        ("sur les 3 jours à venir", 4),
    ] {
        assert_eq!(
            p.parse(expr, &o).unwrap()[0].range_days,
            Some(expected_days),
            "{expr}"
        );
    }
}

#[test]
fn time_expressions() {
    assert_fr(&[
        ("15h", "2025-02-08 15:00:00"),
        ("15 h", "2025-02-08 15:00:00"),
        ("9h", "2025-02-09 09:00:00"),
        ("11h05", "2025-02-09 11:05:00"),
        ("11h06", "2025-02-08 11:06:00"),
        ("14h30", "2025-02-08 14:30:00"),
        ("14 h 30", "2025-02-08 14:30:00"),
        ("14H30", "2025-02-08 14:30:00"),
        ("14:30h", "2025-02-08 14:30:00"),
        ("14:30 heures", "2025-02-08 14:30:00"),
        ("14:30 hrs.", "2025-02-08 14:30:00"),
        ("14:30:45 heures", "2025-02-08 14:30:00"),
        ("8h05", "2025-02-09 08:05:00"),
        ("08h15", "2025-02-09 08:15:00"),
        ("0h", "2025-02-09 00:00:00"),
        ("0h30", "2025-02-09 00:30:00"),
        ("00h30", "2025-02-09 00:30:00"),
        ("23h59", "2025-02-08 23:59:00"),
        ("15:30", "2025-02-08 15:30:00"),
        ("14:30:45", "2025-02-08 14:30:00"),
        ("09:15:59", "2025-02-09 09:15:00"),
        ("09:15", "2025-02-09 09:15:00"),
        ("11:05", "2025-02-09 11:05:00"),
        ("11:06", "2025-02-08 11:06:00"),
        ("3pm", "2025-02-08 15:00:00"),
        ("3 pm", "2025-02-08 15:00:00"),
        ("3 p.m.", "2025-02-08 15:00:00"),
        ("9am", "2025-02-09 09:00:00"),
        ("9 a.m.", "2025-02-09 09:00:00"),
        ("3:30pm", "2025-02-08 15:30:00"),
        ("3:30:15 pm", "2025-02-08 15:30:00"),
        ("12:00 am", "2025-02-09 00:00:00"),
        ("12:00 pm", "2025-02-08 12:00:00"),
        ("15:30 pm", "2025-02-08 15:30:00"),
        ("1 heure", "2025-02-09 01:00:00"),
        ("15 heures", "2025-02-08 15:00:00"),
        ("à 1 heure", "2025-02-09 01:00:00"),
        ("à 15 heures", "2025-02-08 15:00:00"),
        ("vers 15 heures", "2025-02-08 15:00:00"),
        ("pour 9 heures", "2025-02-09 09:00:00"),
        ("à trois heures", "2025-02-09 03:00:00"),
        ("à vingt-deux heures", "2025-02-08 22:00:00"),
        ("15 heures pile", "2025-02-08 15:00:00"),
        ("14 heures précises", "2025-02-08 14:00:00"),
        ("14 heures juste", "2025-02-08 14:00:00"),
        ("14h pile", "2025-02-08 14:00:00"),
        ("14 heures 30", "2025-02-08 14:30:00"),
        ("quatorze heures trente", "2025-02-08 14:30:00"),
        ("huit heures vingt-cinq", "2025-02-09 08:25:00"),
        ("zéro heure trente", "2025-02-09 00:30:00"),
        ("vingt-trois heures cinquante", "2025-02-08 23:50:00"),
        ("8 heures 05", "2025-02-09 08:05:00"),
        ("1 heure 30", "2025-02-09 01:30:00"),
        ("14 heures et demie", "2025-02-08 14:30:00"),
        ("14h et demie", "2025-02-08 14:30:00"),
        ("8 heures et demie", "2025-02-09 08:30:00"),
        ("1 heure et demie", "2025-02-09 01:30:00"),
        ("14 heures et quart", "2025-02-08 14:15:00"),
        ("9 heures et quart", "2025-02-09 09:15:00"),
        ("15 heures moins le quart", "2025-02-08 14:45:00"),
        ("15h moins le quart", "2025-02-08 14:45:00"),
        ("15h moins quart", "2025-02-08 14:45:00"),
        ("15h moins 10", "2025-02-08 14:50:00"),
        ("quinze heures moins dix", "2025-02-08 14:50:00"),
        ("dix heures moins cinq minutes", "2025-02-09 09:55:00"),
        ("10 heures moins le quart", "2025-02-09 09:45:00"),
        ("1 heure moins le quart", "2025-02-09 00:45:00"),
        ("midi", "2025-02-08 12:00:00"),
        ("à midi", "2025-02-08 12:00:00"),
        ("midi et demi", "2025-02-08 12:30:00"),
        ("midi et quart", "2025-02-08 12:15:00"),
        ("midi moins le quart", "2025-02-08 11:45:00"),
        ("midi moins quart", "2025-02-08 11:45:00"),
        ("midi moins 10", "2025-02-08 11:50:00"),
        ("midi moins dix minutes", "2025-02-08 11:50:00"),
        ("midi 15", "2025-02-08 12:15:00"),
        ("midi vingt minutes", "2025-02-08 12:20:00"),
        ("midi pile", "2025-02-08 12:00:00"),
        ("midi précis", "2025-02-08 12:00:00"),
        ("midi juste", "2025-02-08 12:00:00"),
        ("minuit", "2025-02-09 00:00:00"),
        ("minuit et demi", "2025-02-09 00:30:00"),
        ("minuit moins le quart", "2025-02-08 23:45:00"),
        ("minuit moins 5 minutes", "2025-02-08 23:55:00"),
        ("minuit 10", "2025-02-09 00:10:00"),
        ("minuit pile", "2025-02-09 00:00:00"),
        ("8h du matin", "2025-02-09 08:00:00"),
        ("8 heures de la matinée", "2025-02-09 08:00:00"),
        ("9h dans la matinée", "2025-02-09 09:00:00"),
        ("8h au matin", "2025-02-09 08:00:00"),
        ("11h30 du matin", "2025-02-08 11:30:00"),
        ("11h00 du matin", "2025-02-09 11:00:00"),
        ("12h du matin", "2025-02-09 00:00:00"),
        ("12h de l'après-midi", "2025-02-08 12:00:00"),
        ("3h de l'après-midi", "2025-02-08 15:00:00"),
        ("3h de l'apres-midi", "2025-02-08 15:00:00"),
        ("3 heures de l'aprèm", "2025-02-08 15:00:00"),
        ("3 heures de l'aprem", "2025-02-08 15:00:00"),
        ("2 heures de la nuit", "2025-02-09 02:00:00"),
        ("3 heures p.m.", "2025-02-08 15:00:00"),
        ("9 heures a.m.", "2025-02-09 09:00:00"),
        ("8h du soir", "2025-02-08 20:00:00"),
        ("8h au soir", "2025-02-08 20:00:00"),
        ("9h dans la soirée", "2025-02-08 21:00:00"),
        ("11h du soir", "2025-02-08 23:00:00"),
        ("3 heures et demie de l'après-midi", "2025-02-08 15:30:00"),
        (
            "trois heures et demie de l'après-midi",
            "2025-02-08 15:30:00",
        ),
        ("3 heures et quart de l'après-midi", "2025-02-08 15:15:00"),
        (
            "4 heures moins le quart de l'après-midi",
            "2025-02-08 15:45:00",
        ),
        ("9 heures moins le quart du soir", "2025-02-08 20:45:00"),
        ("8 heures et demie du matin", "2025-02-09 08:30:00"),
    ]);
}

#[test]
fn native_digits_and_utf8_spans() {
    let p = Parser::default();
    let o = fr_opts();

    for (input, expected_date, expected_span) in [
        (
            "Rendez-vous après-demain à 14h30 à Paris",
            "2025-02-10 14:30:00",
            "après-demain à 14h30",
        ),
        (
            "Réunion : 14 juillet 2025 à 15h30 à Lyon",
            "2025-07-14 15:30:00",
            "14 juillet 2025 à 15h30",
        ),
        (
            "😀 ١٤ juillet ٢٠٢٥ à ١٥h٣٠ !",
            "2025-07-14 15:30:00",
            "١٤ juillet ٢٠٢٥ à ١٥h٣٠",
        ),
        ("Café dans ３ jours", "2025-02-11 00:00:00", "dans ３ jours"),
        ("Départ १५ août २०२५", "2025-08-15 00:00:00", "१५ août २०२५"),
        (
            "Concert ۱۶ octobre ۲۰۲۵ à ۱۸h",
            "2025-10-16 18:00:00",
            "۱۶ octobre ۲۰۲۵ à ۱۸h",
        ),
        (
            "Soirée ۱۶ octobre ۲۰۲۵ à ۱۸h",
            "2025-10-16 18:00:00",
            "۱۶ octobre ۲۰۲۵ à ۱۸h",
        ),
        (
            "Dans la soirée du ۱۶ octobre ۲۰۲۵ à ۶h",
            "2025-10-16 18:00:00",
            "Dans la soirée du ۱۶ octobre ۲۰۲۵ à ۶h",
        ),
        (
            "Concert : ۱۶ octobre ۲۰۲۵ à ۶h du soir",
            "2025-10-16 18:00:00",
            "۱۶ octobre ۲۰۲۵ à ۶h du soir",
        ),
    ] {
        let res = p.parse(input, &o).unwrap();
        assert_eq!(res.len(), 1, "{input}");
        assert!(input.is_char_boundary(res[0].start) && input.is_char_boundary(res[0].end));
        assert_eq!(res[0].date.to_string(), expected_date, "{input}");
        assert_eq!(&input[res[0].start..res[0].end], expected_span, "{input}");
    }

    let mut range_o = fr_opts();
    range_o.range = true;
    let multi = "😀 ９😀 dans ３ jours ; café dans １２ jours ; fin";
    let mut results = p.parse(multi, &range_o).unwrap();
    results.sort_by_key(|m| m.start);
    let spans: Vec<_> = results
        .iter()
        .map(|m| {
            assert!(multi.is_char_boundary(m.start) && multi.is_char_boundary(m.end));
            (m.date.to_string(), &multi[m.start..m.end])
        })
        .collect();
    assert_eq!(
        spans,
        vec![
            ("2025-02-11 00:00:00".to_string(), "dans ３ jours"),
            ("2025-02-20 00:00:00".to_string(), "dans １２ jours"),
        ]
    );

    let dedup_o = Options {
        languages: &["fr", "fr", "universal", "universal"],
        ..range_o.clone()
    };
    assert_eq!(
        p.parse(multi, &dedup_o).unwrap(),
        p.parse(multi, &range_o).unwrap()
    );
}

#[test]
fn composition() {
    assert_fr(&[
        ("14 juillet 2025 à 15h30", "2025-07-14 15:30:00"),
        ("14 juillet 2025 15:30", "2025-07-14 15:30:00"),
        ("14 juillet, 15h30", "2025-07-14 15:30:00"),
        ("14/07/2025 à 18h", "2025-07-14 18:00:00"),
        ("1er mars à 9 heures du matin", "2025-03-01 09:00:00"),
        (
            "le 10 mars à 3 heures de l'après-midi",
            "2025-03-10 15:00:00",
        ),
        ("le 10 à 14h30", "2025-02-10 14:30:00"),
        ("aujourd'hui à 18h", "2025-02-08 18:00:00"),
        ("demain à 9h", "2025-02-09 09:00:00"),
        ("demain vers 15h", "2025-02-09 15:00:00"),
        ("demain 14h30", "2025-02-09 14:30:00"),
        ("demain l'aprèm à 4h", "2025-02-09 16:00:00"),
        ("après-demain à midi", "2025-02-10 12:00:00"),
        ("demain à minuit", "2025-02-09 00:00:00"),
        ("demain à minuit moins le quart", "2025-02-09 23:45:00"),
        ("hier à 16h15", "2025-02-07 16:15:00"),
        ("avant-hier à 8h", "2025-02-06 08:00:00"),
        ("demain soir à 8h30", "2025-02-09 20:30:00"),
        ("demain matin à 7h30", "2025-02-09 07:30:00"),
        ("lundi à 9h", "2025-02-10 09:00:00"),
        ("lundi pour 10h", "2025-02-10 10:00:00"),
        ("vendredi prochain à 17h30", "2025-02-14 17:30:00"),
        ("lundi dernier à 10h", "2025-02-03 10:00:00"),
        ("samedi à 10h", "2025-02-15 10:00:00"),
        ("la semaine prochaine lundi", "2025-02-10 00:00:00"),
        ("la semaine prochaine mercredi à 14h", "2025-02-12 14:00:00"),
        ("le mois prochain lundi", "2025-03-03 00:00:00"),
        ("lundi de février", "2025-02-03 00:00:00"),
        ("lundi 10 février", "2025-02-10 00:00:00"),
        ("lundi 10 février à 15h", "2025-02-10 15:00:00"),
        ("lundi 10 février 2025 à 9h30", "2025-02-10 09:30:00"),
        ("lundi 14 juillet 2025 à 20h", "2025-07-14 20:00:00"),
        ("le troisième lundi de mars à 15h", "2025-03-17 15:00:00"),
        ("le dernier lundi de février à 9h30", "2025-02-24 09:30:00"),
        ("ce week-end à 16h", "2025-02-09 16:00:00"),
    ]);

    let p = Parser::default();
    let mut o = fr_opts();
    o.week_start = 1;
    assert_eq!(
        p.parse("la semaine prochaine mercredi à 14h", &o).unwrap()[0]
            .date
            .to_string(),
        "2025-02-12 14:00:00"
    );
}

#[test]
fn ranges_and_week_start() {
    let p = Parser::default();
    let mut o = fr_opts();
    o.range = true;

    let text = "Réunion demain à 10h et livraison vendredi prochain à 15h30.";
    let mut multi = p.parse(text, &o).unwrap();
    multi.sort_by_key(|m| m.start);
    assert_eq!(multi.len(), 2);
    assert_eq!(multi[0].date.to_string(), "2025-02-09 10:00:00");
    assert_eq!(multi[1].date.to_string(), "2025-02-14 15:30:00");

    for (expr, expected_len, expected_first, expected_last) in [
        (
            "cette semaine",
            7,
            "2025-02-02 00:00:00",
            "2025-02-08 00:00:00",
        ),
        (
            "la semaine prochaine",
            7,
            "2025-02-09 00:00:00",
            "2025-02-15 00:00:00",
        ),
        (
            "ce mois-ci",
            28,
            "2025-02-01 00:00:00",
            "2025-02-28 00:00:00",
        ),
        ("février", 28, "2025-02-01 00:00:00", "2025-02-28 00:00:00"),
        ("mars", 31, "2025-03-01 00:00:00", "2025-03-31 00:00:00"),
        (
            "d'ici 1 jour",
            2,
            "2025-02-08 00:00:00",
            "2025-02-09 00:00:00",
        ),
        (
            "d'ici 3 jours",
            4,
            "2025-02-08 00:00:00",
            "2025-02-11 00:00:00",
        ),
        (
            "d'ici 2 semaines",
            15,
            "2025-02-08 00:00:00",
            "2025-02-22 00:00:00",
        ),
        (
            "sous 1 semaine",
            8,
            "2025-02-08 00:00:00",
            "2025-02-15 00:00:00",
        ),
    ] {
        let expanded = p.parse(expr, &o).unwrap();
        assert_eq!(expanded.len(), expected_len, "{expr}");
        assert_eq!(expanded[0].date.to_string(), expected_first, "{expr}");
        assert_eq!(
            expanded.last().unwrap().date.to_string(),
            expected_last,
            "{expr}"
        );

        let compact = p.parse_ranges(expr, &o).unwrap();
        assert_eq!(compact.len(), 1, "{expr}");
        assert_eq!(compact[0].date.to_string(), expected_first, "{expr}");
        assert_eq!(compact[0].range_days, Some(expected_len as i32), "{expr}");
    }

    let mut mon_start = o.clone();
    mon_start.week_start = 1;
    for (expr, expected_start) in [
        ("cette semaine", "2025-02-03 00:00:00"),
        ("la semaine prochaine", "2025-02-10 00:00:00"),
        ("la semaine dernière", "2025-01-27 00:00:00"),
    ] {
        let expanded = p.parse(expr, &mon_start).unwrap();
        assert_eq!(expanded.len(), 7, "{expr}");
        assert_eq!(expanded[0].date.to_string(), expected_start, "{expr}");
        assert_eq!(
            p.parse_ranges(expr, &mon_start).unwrap()[0].range_days,
            Some(7)
        );
    }

    let mut wed_o = fr_opts();
    wed_o.reference = "2025-02-12T11:05:00".parse().unwrap();
    for week_start in [1, 7] {
        wed_o.week_start = week_start;
        assert_eq!(
            p.parse("la semaine dernière lundi", &wed_o).unwrap()[0]
                .date
                .to_string(),
            "2025-02-03 00:00:00",
            "week_start={week_start}"
        );
    }
    for (week_start, expected_last_sun, expected_this_sun) in [
        (1, "2025-02-09 00:00:00", "2025-02-16 00:00:00"),
        (7, "2025-02-02 00:00:00", "2025-02-09 00:00:00"),
    ] {
        wed_o.week_start = week_start;
        assert_eq!(
            p.parse("la semaine dernière dimanche", &wed_o).unwrap()[0]
                .date
                .to_string(),
            expected_last_sun
        );
        assert_eq!(
            p.parse("cette semaine dimanche", &wed_o).unwrap()[0]
                .date
                .to_string(),
            expected_this_sun
        );
    }

    let mut tz = fr_opts();
    tz.offset_minutes = 60;
    assert_eq!(
        p.parse("demain à 23h30", &tz).unwrap()[0].date.to_string(),
        "2025-02-10 00:30:00"
    );
    tz.range = true;
    assert_eq!(
        p.parse_ranges("ce mois-ci", &tz).unwrap()[0].date,
        p.parse("ce mois-ci", &tz).unwrap()[0].date
    );
}

#[test]
fn negative_and_boundary_cases() {
    let p = Parser::default();
    let o = fr_opts();

    for empty_input in [
        "",
        "Bonjour tout le monde",
        "Un chat noir dort sur le canapé",
        "je vais à la mer",
        "un jeu vidéo",
        "1 heure de trajet",
        "2 heures de vol",
        "3h de vol",
        "2h de trajet",
        "4h de route",
        "8h de sommeil",
        "10h par jour",
        "2h plus tard",
        "3h d'affilée",
        "2h minimum",
        "à 2 heures de route",
        "à 3 heures de vol",
        "à 2 heures d'intervalle",
        "pour 5 heures de route",
        "le 10 euros",
        "le 3ème étage",
        "le 1er arrondissement",
        "le 20e siècle",
        "le 2ème chapitre",
        "le 5ème km",
        "le 2ème tour",
        "en 2025 euros",
        "en 2025 km",
        "en 2025 heures",
        "1.2.3.4",
        "13am",
        "3:60 pm",
        "maisons",
        "marseille",
        "marsupial",
        "marche",
        "diminuer",
        "lunettes",
        "jeunesse",
        "vendre",
        "samovar",
        "octogone",
        "novice",
        "décider",
        "lundiA",
        "lundiÉ",
        "xlundi",
        "demainABC",
        "15hPST",
        "15h30É",
        "1erJour",
        "12 maiA",
        "12 maiÉ",
        "30 février 2025",
        "29 février 2025",
        "31 avril 2025",
        "31 juin 2025",
        "31 septembre 2025",
        "31 novembre 2025",
        "32 janvier 2025",
        "0 mars 2025",
        "janvier 32 2025",
        "32/01/2025",
        "00/03/2025",
        "32-01-2025",
        "00-03-2025",
        "32.01.2025",
        "30/02/2025",
        "29/02/2025",
        "31/04/2025",
        "15/13/2025",
        "00/05/2025",
        "31.02.2025",
        "31-04-2025",
        "24h00",
        "25h00",
        "24h",
        "25h",
        "12h60",
        "14h99",
        "25 heures",
        "12 heures 60",
        "25:00",
        "12:60",
        "mardi 10 février",
        "mercredi 14 juillet 2025",
        "le cinquième lundi de février",
        "du matin",
        "de l'après-midi",
        "du soir",
        "dans 999999999999999999999 jours",
    ] {
        assert!(
            p.parse(empty_input, &o).unwrap().is_empty(),
            "expected no match for {empty_input:?}"
        );
    }

    let mut range_o = fr_opts();
    range_o.range = true;
    assert_eq!(
        p.parse("d'ici 999999 jours", &range_o),
        Err(Error::RangeTooLarge)
    );
    assert_eq!(
        p.parse_ranges("d'ici 999999 jours", &range_o),
        Err(Error::RangeTooLarge)
    );

    let mut bad_ws = fr_opts();
    bad_ws.week_start = 2;
    assert_eq!(p.parse("", &bad_ws), Err(Error::InvalidWeekStart));

    for (text, expected_count) in [
        ("demain réunion 15h", 2),
        ("lundi prochain conférence à 14h", 2),
        ("14 juillet voiture 15h", 2),
    ] {
        let mut res = p.parse(text, &range_o).unwrap();
        res.sort_by_key(|m| m.start);
        assert_eq!(res.len(), expected_count, "{text}");
        for m in &res {
            let span = &text[m.start..m.end];
            assert!(
                !span.contains("réunion")
                    && !span.contains("conférence")
                    && !span.contains("voiture"),
                "glue swallowed non-date word in {text:?}: {span:?}"
            );
        }
    }
}

use sunphase::{Error, Match, NaiveDate, Options, Parser};

fn options() -> Options<'static> {
    let mut o = Options::new(
        NaiveDate::from_ymd_opt(2025, 2, 8)
            .unwrap()
            .and_hms_opt(11, 5, 0)
            .unwrap(),
    );
    o.languages = &["id"];
    o
}

fn parse_one(p: &Parser, input: &str, o: &Options<'_>) -> Match {
    let results = p.parse(input, o).unwrap();
    assert_eq!(
        results.len(),
        1,
        "expected 1 match for {input:?}, got {results:?}"
    );
    let m = results.into_iter().next().unwrap();
    assert_eq!(
        &input[m.start..m.end],
        input,
        "expected full span match for {input:?}"
    );
    m
}

fn assert_cases(p: &Parser, o: &Options<'_>, cases: &[(&str, &str)]) {
    for &(input, expected) in cases {
        let m = parse_one(p, input, o);
        assert_eq!(m.date.to_string(), expected, "input={input:?}");
    }
}

#[test]
fn relative_days() {
    let p = Parser::default();
    let o = options();
    assert_cases(
        &p,
        &o,
        &[
            ("hari ini", "2025-02-08 00:00:00"),
            ("Hari Ini", "2025-02-08 00:00:00"),
            ("HARI INI", "2025-02-08 00:00:00"),
            ("besok", "2025-02-09 00:00:00"),
            ("BESOK", "2025-02-09 00:00:00"),
            ("esok", "2025-02-09 00:00:00"),
            ("hari esok", "2025-02-09 00:00:00"),
            ("esok hari", "2025-02-09 00:00:00"),
            ("lusa", "2025-02-10 00:00:00"),
            ("besok lusa", "2025-02-10 00:00:00"),
            ("esok lusa", "2025-02-10 00:00:00"),
            ("kemarin", "2025-02-07 00:00:00"),
            ("kemaren", "2025-02-07 00:00:00"),
            ("kelmarin", "2025-02-07 00:00:00"),
            ("hari kemarin", "2025-02-07 00:00:00"),
            ("hari kemaren", "2025-02-07 00:00:00"),
            ("kemarin lusa", "2025-02-06 00:00:00"),
            ("kemaren lusa", "2025-02-06 00:00:00"),
            ("kelmarin lusa", "2025-02-06 00:00:00"),
            ("kemarin dulu", "2025-02-06 00:00:00"),
            ("kemaren dulu", "2025-02-06 00:00:00"),
            ("pagi ini", "2025-02-08 00:00:00"),
            ("subuh ini", "2025-02-08 00:00:00"),
            ("dini hari ini", "2025-02-08 00:00:00"),
            ("tadi pagi", "2025-02-08 00:00:00"),
            ("siang ini", "2025-02-08 12:00:00"),
            ("sore ini", "2025-02-08 12:00:00"),
            ("petang ini", "2025-02-08 12:00:00"),
            ("malam ini", "2025-02-08 12:00:00"),
            ("malem ini", "2025-02-08 12:00:00"),
            ("tadi siang", "2025-02-08 12:00:00"),
            ("tadi sore", "2025-02-08 12:00:00"),
            ("tadi petang", "2025-02-08 12:00:00"),
            ("nanti malam", "2025-02-08 12:00:00"),
            ("malam nanti", "2025-02-08 12:00:00"),
            ("nanti sore", "2025-02-08 12:00:00"),
            ("sore nanti", "2025-02-08 12:00:00"),
            ("nanti siang", "2025-02-08 12:00:00"),
            ("siang nanti", "2025-02-08 12:00:00"),
            ("semalam", "2025-02-07 12:00:00"),
            ("tadi malam", "2025-02-07 12:00:00"),
            ("tadi malem", "2025-02-07 12:00:00"),
            ("kemarin malam", "2025-02-07 12:00:00"),
            ("kemaren malem", "2025-02-07 12:00:00"),
            ("malam ini jam 8", "2025-02-08 20:00:00"),
            ("malam ini pukul 21.30", "2025-02-08 21:30:00"),
            ("tadi pagi pukul 6.30", "2025-02-08 06:30:00"),
            ("semalam pukul 22.00", "2025-02-07 22:00:00"),
            ("tadi malam jam 9", "2025-02-07 21:00:00"),
            ("nanti malam jam 8", "2025-02-08 20:00:00"),
            ("malam nanti jam 8", "2025-02-08 20:00:00"),
            ("sore nanti jam 5", "2025-02-08 17:00:00"),
        ],
    );
}

#[test]
fn weekdays_and_next_last_this() {
    let p = Parser::default();
    let o = options();
    assert_cases(
        &p,
        &o,
        &[
            ("Senin", "2025-02-10 00:00:00"),
            ("senen", "2025-02-10 00:00:00"),
            ("hari Senin", "2025-02-10 00:00:00"),
            ("hari Sen", "2025-02-10 00:00:00"),
            ("Sen", "2025-02-10 00:00:00"),
            ("sen.", "2025-02-10 00:00:00"),
            ("SENIN", "2025-02-10 00:00:00"),
            ("Selasa", "2025-02-11 00:00:00"),
            ("hari Selasa", "2025-02-11 00:00:00"),
            ("Sel", "2025-02-11 00:00:00"),
            ("sel.", "2025-02-11 00:00:00"),
            ("Rabu", "2025-02-12 00:00:00"),
            ("hari Rabu", "2025-02-12 00:00:00"),
            ("Rab", "2025-02-12 00:00:00"),
            ("rab.", "2025-02-12 00:00:00"),
            ("RAB", "2025-02-12 00:00:00"),
            ("Kamis", "2025-02-13 00:00:00"),
            ("hari Kamis", "2025-02-13 00:00:00"),
            ("Kam", "2025-02-13 00:00:00"),
            ("kam.", "2025-02-13 00:00:00"),
            ("Jumat", "2025-02-14 00:00:00"),
            ("Jum'at", "2025-02-14 00:00:00"),
            ("Jum’at", "2025-02-14 00:00:00"),
            ("hari Jumat", "2025-02-14 00:00:00"),
            ("hari Jum.", "2025-02-14 00:00:00"),
            ("Jum", "2025-02-14 00:00:00"),
            ("jum.", "2025-02-14 00:00:00"),
            ("Sabtu", "2025-02-15 00:00:00"),
            ("hari Sabtu", "2025-02-15 00:00:00"),
            ("Sab", "2025-02-15 00:00:00"),
            ("sab.", "2025-02-15 00:00:00"),
            ("Minggu", "2025-02-09 00:00:00"),
            ("Ahad", "2025-02-09 00:00:00"),
            ("hari Minggu", "2025-02-09 00:00:00"),
            ("hari Ahad", "2025-02-09 00:00:00"),
            ("hari mgg", "2025-02-09 00:00:00"),
            ("Min", "2025-02-09 00:00:00"),
            ("min.", "2025-02-09 00:00:00"),
            ("ming", "2025-02-09 00:00:00"),
            ("ming.", "2025-02-09 00:00:00"),
            ("mgg", "2025-02-09 00:00:00"),
            ("mgg.", "2025-02-09 00:00:00"),
            ("Senin depan", "2025-02-10 00:00:00"),
            ("Senin yang akan datang", "2025-02-10 00:00:00"),
            ("Jumat mendatang", "2025-02-14 00:00:00"),
            ("Kamis berikutnya", "2025-02-13 00:00:00"),
            ("Selasa selanjutnya", "2025-02-11 00:00:00"),
            ("Rabu depan", "2025-02-12 00:00:00"),
            ("Sabtu depan", "2025-02-15 00:00:00"),
            ("hari Minggu depan", "2025-02-09 00:00:00"),
            ("Senin lalu", "2025-02-03 00:00:00"),
            ("Rabu lalu", "2025-02-05 00:00:00"),
            ("Sabtu lalu", "2025-02-01 00:00:00"),
            ("hari Minggu lalu", "2025-02-02 00:00:00"),
            ("hari Minggu yang lalu", "2025-02-02 00:00:00"),
            ("Rabu kemarin", "2025-02-05 00:00:00"),
            ("Jumat kemaren", "2025-02-07 00:00:00"),
            ("Selasa yang silam", "2025-02-04 00:00:00"),
            ("Senin silam", "2025-02-03 00:00:00"),
            ("Kamis sebelumnya", "2025-02-06 00:00:00"),
            ("Senin ini", "2025-02-10 00:00:00"),
            ("Rabu ini", "2025-02-12 00:00:00"),
            ("Senin nanti", "2025-02-10 00:00:00"),
            ("Senin besok", "2025-02-10 00:00:00"),
            ("hari Minggu ini", "2025-02-09 00:00:00"),
        ],
    );
}

#[test]
fn calendar_anchors_and_weekend() {
    let p = Parser::default();
    let mut o = options();

    for (input, expected) in [
        ("minggu ini", "2025-02-02 00:00:00"),
        ("minggu sekarang", "2025-02-02 00:00:00"),
        ("pekan ini", "2025-02-02 00:00:00"),
        ("minggu depan", "2025-02-09 00:00:00"),
        ("minggu yang akan datang", "2025-02-09 00:00:00"),
        ("pekan depan", "2025-02-09 00:00:00"),
        ("pekan mendatang", "2025-02-09 00:00:00"),
        ("minggu lalu", "2025-01-26 00:00:00"),
        ("pekan lalu", "2025-01-26 00:00:00"),
        ("minggu yang lalu", "2025-01-26 00:00:00"),
        ("pekan yang lalu", "2025-01-26 00:00:00"),
        ("minggu kemarin", "2025-01-26 00:00:00"),
        ("pekan sebelumnya", "2025-01-26 00:00:00"),
    ] {
        let m = parse_one(&p, input, &o);
        assert_eq!(m.date.to_string(), expected, "week_start=7 input={input:?}");
        assert_eq!(m.range_type, Some("week"), "input={input:?}");
    }

    o.week_start = 1;
    assert_cases(
        &p,
        &o,
        &[
            ("minggu ini", "2025-02-03 00:00:00"),
            ("pekan ini", "2025-02-03 00:00:00"),
            ("minggu depan", "2025-02-10 00:00:00"),
            ("pekan depan", "2025-02-10 00:00:00"),
            ("minggu lalu", "2025-01-27 00:00:00"),
            ("pekan lalu", "2025-01-27 00:00:00"),
        ],
    );

    o.week_start = 7;
    for (input, expected) in [
        ("bulan ini", "2025-02-01 00:00:00"),
        ("bulan sekarang", "2025-02-01 00:00:00"),
        ("bulan depan", "2025-03-01 00:00:00"),
        ("bulan berikutnya", "2025-03-01 00:00:00"),
        ("bulan nanti", "2025-03-01 00:00:00"),
        ("bulan lalu", "2025-01-01 00:00:00"),
        ("bulan yang lalu", "2025-01-01 00:00:00"),
        ("bulan kemaren", "2025-01-01 00:00:00"),
        ("bulan yang silam", "2025-01-01 00:00:00"),
    ] {
        let m = parse_one(&p, input, &o);
        assert_eq!(m.date.to_string(), expected, "input={input:?}");
        assert_eq!(m.range_type, Some("month"), "input={input:?}");
    }

    assert_cases(
        &p,
        &o,
        &[
            ("tahun ini", "2025-02-01 00:00:00"),
            ("tahun sekarang", "2025-02-01 00:00:00"),
            ("tahun depan", "2026-02-01 00:00:00"),
            ("tahun selanjutnya", "2026-02-01 00:00:00"),
            ("tahun lalu", "2024-02-01 00:00:00"),
            ("tahun yang lalu", "2024-02-01 00:00:00"),
            ("tahun silam", "2024-02-01 00:00:00"),
            ("akhir pekan", "2025-02-09 00:00:00"),
            ("akhir minggu", "2025-02-09 00:00:00"),
            ("akhir pekan ini", "2025-02-09 00:00:00"),
            ("akhir pekan depan", "2025-02-09 00:00:00"),
            ("akhir pekan mendatang", "2025-02-09 00:00:00"),
            ("akhir pekan yang akan datang", "2025-02-09 00:00:00"),
            ("akhir pekan nanti", "2025-02-09 00:00:00"),
            ("akhir minggu berikutnya", "2025-02-09 00:00:00"),
            ("akhir minggu selanjutnya", "2025-02-09 00:00:00"),
            ("akhir pekan lalu", "2025-02-02 00:00:00"),
            ("akhir minggu lalu", "2025-02-02 00:00:00"),
            ("akhir pekan yang lalu", "2025-02-02 00:00:00"),
            ("akhir pekan kemarin", "2025-02-02 00:00:00"),
            ("akhir pekan kemaren", "2025-02-02 00:00:00"),
            ("akhir pekan silam", "2025-02-02 00:00:00"),
            ("akhir pekan yang silam", "2025-02-02 00:00:00"),
            ("akhir pekan sebelumnya", "2025-02-02 00:00:00"),
        ],
    );

    o.reference = "2025-02-12T11:05:00".parse().unwrap();
    assert_eq!(
        parse_one(&p, "akhir pekan", &o).date.to_string(),
        "2025-02-16 00:00:00"
    );
}

#[test]
fn all_twelve_months_and_abbreviations() {
    let p = Parser::default();
    let o = options();

    for (input, expected) in [
        ("Januari", "2026-01-01 00:00:00"),
        ("Djanuari", "2026-01-01 00:00:00"),
        ("Jan", "2026-01-01 00:00:00"),
        ("jan.", "2026-01-01 00:00:00"),
        ("Februari", "2025-02-01 00:00:00"),
        ("Pebruari", "2025-02-01 00:00:00"),
        ("Feb", "2025-02-01 00:00:00"),
        ("feb.", "2025-02-01 00:00:00"),
        ("Peb", "2025-02-01 00:00:00"),
        ("peb.", "2025-02-01 00:00:00"),
        ("Maret", "2025-03-01 00:00:00"),
        ("bulan Maret", "2025-03-01 00:00:00"),
        ("Mar", "2025-03-01 00:00:00"),
        ("mar.", "2025-03-01 00:00:00"),
        ("MARET", "2025-03-01 00:00:00"),
        ("April", "2025-04-01 00:00:00"),
        ("Apr", "2025-04-01 00:00:00"),
        ("apr.", "2025-04-01 00:00:00"),
        ("Mei", "2025-05-01 00:00:00"),
        ("Juni", "2025-06-01 00:00:00"),
        ("Djuni", "2025-06-01 00:00:00"),
        ("Jun", "2025-06-01 00:00:00"),
        ("jun.", "2025-06-01 00:00:00"),
        ("Juli", "2025-07-01 00:00:00"),
        ("Djuli", "2025-07-01 00:00:00"),
        ("Jul", "2025-07-01 00:00:00"),
        ("jul.", "2025-07-01 00:00:00"),
        ("Agustus", "2025-08-01 00:00:00"),
        ("Agu", "2025-08-01 00:00:00"),
        ("agu.", "2025-08-01 00:00:00"),
        ("Agt", "2025-08-01 00:00:00"),
        ("agt.", "2025-08-01 00:00:00"),
        ("Agst", "2025-08-01 00:00:00"),
        ("agst.", "2025-08-01 00:00:00"),
        ("Ags", "2025-08-01 00:00:00"),
        ("ags.", "2025-08-01 00:00:00"),
        ("September", "2025-09-01 00:00:00"),
        ("Sep", "2025-09-01 00:00:00"),
        ("sep.", "2025-09-01 00:00:00"),
        ("Sept", "2025-09-01 00:00:00"),
        ("sept.", "2025-09-01 00:00:00"),
        ("Oktober", "2025-10-01 00:00:00"),
        ("Okt", "2025-10-01 00:00:00"),
        ("okt.", "2025-10-01 00:00:00"),
        ("November", "2025-11-01 00:00:00"),
        ("Nopember", "2025-11-01 00:00:00"),
        ("Nov", "2025-11-01 00:00:00"),
        ("nov.", "2025-11-01 00:00:00"),
        ("Nop", "2025-11-01 00:00:00"),
        ("nop.", "2025-11-01 00:00:00"),
        ("Desember", "2025-12-01 00:00:00"),
        ("Des", "2025-12-01 00:00:00"),
        ("des.", "2025-12-01 00:00:00"),
        ("DESEMBER", "2025-12-01 00:00:00"),
    ] {
        let m = parse_one(&p, input, &o);
        assert_eq!(m.date.to_string(), expected, "input={input:?}");
        assert_eq!(m.range_type, Some("month"), "input={input:?}");
    }

    for (input, expected) in [
        ("Januari 2025", "2025-01-01 00:00:00"),
        ("Maret 2026", "2026-03-01 00:00:00"),
        ("bulan Maret tahun 2025", "2025-03-01 00:00:00"),
        ("Maret, 2025", "2025-03-01 00:00:00"),
        ("Maret-2025", "2025-03-01 00:00:00"),
        ("Maret/2025", "2025-03-01 00:00:00"),
        ("tahun 2026", "2026-02-01 00:00:00"),
        ("thn 2026", "2026-02-01 00:00:00"),
        ("thn. 2026", "2026-02-01 00:00:00"),
        ("tahun 2024", "2024-02-01 00:00:00"),
    ] {
        let m = parse_one(&p, input, &o);
        assert_eq!(m.date.to_string(), expected, "input={input:?}");
        assert_eq!(m.range_type, None, "input={input:?}");
    }
}

#[test]
fn calendar_dates_numeric_ordinals_and_nth_weekday() {
    let p = Parser::default();
    let mut o = options();
    assert_cases(
        &p,
        &o,
        &[
            ("15 Maret", "2025-03-15 00:00:00"),
            ("15 Maret 2025", "2025-03-15 00:00:00"),
            ("tanggal 15 Maret 2025", "2025-03-15 00:00:00"),
            ("tgl. 15 Maret 2025", "2025-03-15 00:00:00"),
            ("tgl 20 Mei", "2025-05-20 00:00:00"),
            ("15 bulan Maret tahun 2025", "2025-03-15 00:00:00"),
            ("15-Maret-2025", "2025-03-15 00:00:00"),
            ("15/Maret/2025", "2025-03-15 00:00:00"),
            ("15 Maret, 2025", "2025-03-15 00:00:00"),
            ("dua puluh lima Desember 2025", "2025-12-25 00:00:00"),
            ("tujuh belas Agustus 1945", "1945-08-17 00:00:00"),
            ("tiga puluh satu Maret", "2025-03-31 00:00:00"),
            ("Maret 15", "2025-03-15 00:00:00"),
            ("Maret 15, 2025", "2025-03-15 00:00:00"),
            ("bulan Maret tanggal 15", "2025-03-15 00:00:00"),
            ("bulan Maret tgl. 20 tahun 2025", "2025-03-20 00:00:00"),
            ("Agustus 17 1945", "1945-08-17 00:00:00"),
            ("Februari 29", "2028-02-29 00:00:00"),
            ("8 Februari", "2025-02-08 00:00:00"),
            ("5 Februari", "2026-02-05 00:00:00"),
            ("10 Januari", "2026-01-10 00:00:00"),
            ("17 Agustus 1945", "1945-08-17 00:00:00"),
            ("25 Des 2025", "2025-12-25 00:00:00"),
            ("1 Agu 2025", "2025-08-01 00:00:00"),
            ("29 Februari", "2028-02-29 00:00:00"),
            ("tanggal 10", "2025-02-10 00:00:00"),
            ("tanggal 8", "2025-03-08 00:00:00"),
            ("tanggal 5", "2025-03-05 00:00:00"),
            ("tanggal 31", "2025-03-31 00:00:00"),
            ("tgl 20", "2025-02-20 00:00:00"),
            ("tgl. dua puluh", "2025-02-20 00:00:00"),
            ("15/03/2025", "2025-03-15 00:00:00"),
            ("05/03/2025", "2025-03-05 00:00:00"),
            ("29/02/2024", "2024-02-29 00:00:00"),
            ("17-08-2025", "2025-08-17 00:00:00"),
            ("17.08.2025", "2025-08-17 00:00:00"),
            ("2025-03-15", "2025-03-15 00:00:00"),
            ("2025/03/15", "2025-03-15 00:00:00"),
            ("2025.03.15", "2025-03-15 00:00:00"),
            ("15/03/25", "2025-03-15 00:00:00"),
            ("05.03.25", "2025-03-05 00:00:00"),
            ("17-08-95", "1995-08-17 00:00:00"),
            ("25/12/99", "1999-12-25 00:00:00"),
            ("01/01/70", "1970-01-01 00:00:00"),
            ("15/03", "2025-03-15 00:00:00"),
            ("10/01", "2026-01-10 00:00:00"),
            ("29/02", "2028-02-29 00:00:00"),
            ("Senin pertama bulan Maret", "2025-03-03 00:00:00"),
            ("Senin kesatu bulan Maret", "2025-03-03 00:00:00"),
            ("Senin kedua bulan Maret", "2025-03-10 00:00:00"),
            ("Senin ketiga bulan Maret", "2025-03-17 00:00:00"),
            ("Senin keempat bulan Maret", "2025-03-24 00:00:00"),
            ("Senin kelima bulan Maret", "2025-03-31 00:00:00"),
            ("Senin terakhir bulan Februari", "2025-02-24 00:00:00"),
            ("Senin penghabisan bulan Februari", "2025-02-24 00:00:00"),
            ("Senin pertama bulan Februari", "2026-02-02 00:00:00"),
            ("Rabu ke-2 bulan Maret", "2025-03-12 00:00:00"),
            ("Jumat ke2 bulan Maret", "2025-03-14 00:00:00"),
            ("Sabtu ke 4 bulan Maret", "2025-03-22 00:00:00"),
            ("hari Senin ketiga di bulan Maret", "2025-03-17 00:00:00"),
            ("Senin kedua pada Maret", "2025-03-10 00:00:00"),
            ("Rabu terakhir dalam Februari", "2025-02-26 00:00:00"),
            ("Kamis pertama Maret", "2025-03-06 00:00:00"),
            (
                "Senin ketiga bulan Maret pukul 15.00",
                "2025-03-17 15:00:00",
            ),
        ],
    );

    o.reference = "2025-04-30T00:00:00".parse().unwrap();
    assert_eq!(
        parse_one(&p, "tanggal 31", &o).date.to_string(),
        "2025-05-31 00:00:00"
    );
}

#[test]
fn offsets_and_within_days() {
    let p = Parser::default();
    let mut o = options();
    assert_cases(
        &p,
        &o,
        &[
            ("1 hari lagi", "2025-02-09 00:00:00"),
            ("sehari lagi", "2025-02-09 00:00:00"),
            ("3 hari lagi", "2025-02-11 00:00:00"),
            ("lima belas hari lagi", "2025-02-23 00:00:00"),
            ("dua puluh tiga hari lagi", "2025-03-03 00:00:00"),
            ("seratus hari lagi", "2025-05-19 00:00:00"),
            ("1 minggu lagi", "2025-02-15 00:00:00"),
            ("seminggu lagi", "2025-02-15 00:00:00"),
            ("sepekan lagi", "2025-02-15 00:00:00"),
            ("2 minggu lagi", "2025-02-22 00:00:00"),
            ("2 pekan lagi", "2025-02-22 00:00:00"),
            ("1 bulan lagi", "2025-03-01 00:00:00"),
            ("sebulan lagi", "2025-03-01 00:00:00"),
            ("2 bulan lagi", "2025-04-01 00:00:00"),
            ("14 bulan lagi", "2026-04-01 00:00:00"),
            ("1 tahun lagi", "2026-02-01 00:00:00"),
            ("setahun lagi", "2026-02-01 00:00:00"),
            ("3 tahun lagi", "2028-02-01 00:00:00"),
            ("5 hari dari sekarang", "2025-02-13 00:00:00"),
            ("dalam 3 hari lagi", "2025-02-11 00:00:00"),
            ("dalam 2 bulan", "2025-04-01 00:00:00"),
            ("dalam setahun", "2026-02-01 00:00:00"),
            ("dalam 2 tahun ke depan", "2027-02-01 00:00:00"),
            ("2 bulan kedepan", "2025-04-01 00:00:00"),
            ("3 hari mendatang", "2025-02-11 00:00:00"),
            ("2 minggu berikutnya", "2025-02-22 00:00:00"),
            ("4 hari selanjutnya", "2025-02-12 00:00:00"),
            ("5 hari kemudian", "2025-02-13 00:00:00"),
            ("3 hari setelahnya", "2025-02-11 00:00:00"),
            ("1 hari yang lalu", "2025-02-07 00:00:00"),
            ("sehari yang lalu", "2025-02-07 00:00:00"),
            ("3 hari yang lalu", "2025-02-05 00:00:00"),
            ("3 hari lalu", "2025-02-05 00:00:00"),
            ("3 hari silam", "2025-02-05 00:00:00"),
            ("1 minggu yang lalu", "2025-02-01 00:00:00"),
            ("seminggu yang lalu", "2025-02-01 00:00:00"),
            ("sepekan lalu", "2025-02-01 00:00:00"),
            ("2 minggu yang lalu", "2025-01-25 00:00:00"),
            ("2 pekan yang lalu", "2025-01-25 00:00:00"),
            ("2 minggu yang silam", "2025-01-25 00:00:00"),
            ("tiga minggu yang lalu", "2025-01-18 00:00:00"),
            ("1 bulan yang lalu", "2025-01-01 00:00:00"),
            ("sebulan yang lalu", "2025-01-01 00:00:00"),
            ("2 bulan yang lalu", "2024-12-01 00:00:00"),
            ("dua bulan lalu", "2024-12-01 00:00:00"),
            ("4 bulan sebelumnya", "2024-10-01 00:00:00"),
            ("1 tahun yang lalu", "2024-02-01 00:00:00"),
            ("setahun yang lalu", "2024-02-01 00:00:00"),
            ("1 tahun silam", "2024-02-01 00:00:00"),
            ("5 tahun yang lalu", "2020-02-01 00:00:00"),
        ],
    );

    for (input, expected_days) in [
        ("dalam 1 hari", 2),
        ("dalam sehari", 2),
        ("dalam tiga hari", 4),
        ("dalam 5 hari", 6),
        ("dalam kurun waktu 3 hari", 4),
        ("dalam jangka waktu 4 hari", 5),
        ("dalam waktu 5 hari", 6),
        ("dalam 3 hari ke depan", 4),
        ("dalam 3 hari kedepan", 4),
        ("dalam 3 hari terdekat", 4),
        ("selama 3 hari ke depan", 4),
        ("3 hari ke depan", 4),
        ("sehari ke depan", 2),
        ("dalam seminggu", 8),
        ("dalam sepekan", 8),
        ("dalam 2 minggu", 15),
        ("dalam 1 pekan", 8),
        ("2 minggu kedepan", 15),
        ("dalam dua puluh lima hari", 26),
        ("dalam seratus hari", 101),
    ] {
        let m = parse_one(&p, input, &o);
        assert_eq!(m.date.to_string(), "2025-02-08 00:00:00", "input={input:?}");
        assert_eq!(m.range_days, Some(expected_days), "input={input:?}");
    }

    o.range = true;
    let expanded = p.parse("dalam 3 hari", &o).unwrap();
    assert_eq!(expanded.len(), 4);
    assert_eq!(expanded[0].date.to_string(), "2025-02-08 00:00:00");
    assert_eq!(expanded[3].date.to_string(), "2025-02-11 00:00:00");

    let compact = p.parse_ranges("dalam 3 hari", &o).unwrap();
    assert_eq!(compact.len(), 1);
    assert_eq!(compact[0].date.to_string(), "2025-02-08 00:00:00");
    assert_eq!(compact[0].range_days, Some(4));

    let zero_days = p.parse("dalam 0 hari", &o).unwrap();
    assert_eq!(zero_days.len(), 1);
    assert_eq!(zero_days[0].date.to_string(), "2025-02-08 00:00:00");
}

#[test]
fn time_expressions() {
    let p = Parser::default();
    let o = options();
    assert_cases(
        &p,
        &o,
        &[
            ("jam 14.30", "2025-02-08 14:30:00"),
            ("pukul 14.30", "2025-02-08 14:30:00"),
            ("JAM 15.00", "2025-02-08 15:00:00"),
            ("pkl 16.45", "2025-02-08 16:45:00"),
            ("pk 14.00", "2025-02-08 14:00:00"),
            ("pk. 09.30", "2025-02-09 09:30:00"),
            ("jam 08.15", "2025-02-09 08:15:00"),
            ("pukul 8.00", "2025-02-09 08:00:00"),
            ("pukul 11.05", "2025-02-09 11:05:00"),
            ("pukul 11.06", "2025-02-08 11:06:00"),
            ("jam 00.00", "2025-02-09 00:00:00"),
            ("15:00", "2025-02-08 15:00:00"),
            ("09:30", "2025-02-09 09:30:00"),
            ("jam 14:30", "2025-02-08 14:30:00"),
            ("pukul 23:59", "2025-02-08 23:59:00"),
            ("14:30:45", "2025-02-08 14:30:00"),
            ("jam 14.30:45", "2025-02-08 14:30:00"),
            ("pukul 09:15:30 pagi", "2025-02-09 09:15:00"),
            ("14.00 wib", "2025-02-08 14:00:00"),
            ("14.00 tepat wib", "2025-02-08 14:00:00"),
            ("08.30 wita", "2025-02-09 08:30:00"),
            ("16.00 wit", "2025-02-08 16:00:00"),
            ("08.30 pagi", "2025-02-09 08:30:00"),
            ("14.30 wib siang", "2025-02-08 14:30:00"),
            ("14.00 sore", "2025-02-08 14:00:00"),
            ("14.00 tepat sore", "2025-02-08 14:00:00"),
            ("jam 15", "2025-02-08 15:00:00"),
            ("jam 15 tepat", "2025-02-08 15:00:00"),
            ("pukul 8", "2025-02-09 08:00:00"),
            ("jam lima", "2025-02-09 05:00:00"),
            ("pukul dua puluh satu", "2025-02-08 21:00:00"),
            ("jam nol", "2025-02-09 00:00:00"),
            ("jam kosong", "2025-02-09 00:00:00"),
            ("pukul tujuh pagi", "2025-02-09 07:00:00"),
            ("lima sore", "2025-02-08 17:00:00"),
            ("dua belas malam", "2025-02-09 00:00:00"),
            ("3 pm", "2025-02-08 15:00:00"),
            ("3am", "2025-02-09 03:00:00"),
            ("11:30 a.m.", "2025-02-08 11:30:00"),
            ("jam 4.15 p.m.", "2025-02-08 16:15:00"),
            ("pukul 12 am", "2025-02-09 00:00:00"),
            ("pukul 12 pm", "2025-02-08 12:00:00"),
            ("15:30 pm", "2025-02-08 15:30:00"),
            ("jam 7 pagi", "2025-02-09 07:00:00"),
            ("7 pagi", "2025-02-09 07:00:00"),
            ("pukul 11.30 pagi", "2025-02-08 11:30:00"),
            ("jam 11 siang", "2025-02-09 11:00:00"),
            ("11 siang", "2025-02-09 11:00:00"),
            ("jam 11.10 siang", "2025-02-08 11:10:00"),
            ("jam 1 siang", "2025-02-08 13:00:00"),
            ("2 siang", "2025-02-08 14:00:00"),
            ("pukul 12 siang", "2025-02-08 12:00:00"),
            ("jam 3 sore", "2025-02-08 15:00:00"),
            ("pukul 3 tepat sore", "2025-02-08 15:00:00"),
            ("3 tepat sore", "2025-02-08 15:00:00"),
            ("PUKUL 3 SORE", "2025-02-08 15:00:00"),
            ("5 sore", "2025-02-08 17:00:00"),
            ("pukul 5.30 sore", "2025-02-08 17:30:00"),
            ("jam 6 petang", "2025-02-08 18:00:00"),
            ("jam 8 malam", "2025-02-08 20:00:00"),
            ("jam 9 malem", "2025-02-08 21:00:00"),
            ("9 malam", "2025-02-08 21:00:00"),
            ("pukul 9.15 malam", "2025-02-08 21:15:00"),
            ("jam 12 malam", "2025-02-09 00:00:00"),
            ("jam 2 dini hari", "2025-02-09 02:00:00"),
            ("pukul 5 subuh", "2025-02-09 05:00:00"),
            ("pagi jam 8", "2025-02-09 08:00:00"),
            ("sore pukul 4.30", "2025-02-08 16:30:00"),
            ("malam jam 9", "2025-02-08 21:00:00"),
            ("subuh pukul 5", "2025-02-09 05:00:00"),
            ("dini hari jam 2", "2025-02-09 02:00:00"),
            ("petang jam 6", "2025-02-08 18:00:00"),
            ("siang sekitar jam 2", "2025-02-08 14:00:00"),
            ("pagi kira-kira pukul 9", "2025-02-09 09:00:00"),
            ("malam ini pada jam 8", "2025-02-08 20:00:00"),
            ("tadi pagi pukul tujuh", "2025-02-08 07:00:00"),
            ("nanti sore jam setengah 5", "2025-02-08 16:30:00"),
            ("kemarin malam stgh. 9", "2025-02-07 20:30:00"),
            ("sore jam 4 tepat wib", "2025-02-08 16:00:00"),
            ("pagi pk. 7", "2025-02-09 07:00:00"),
            ("siang jam 11 pagi", "2025-02-09 11:00:00"),
            ("jam 8 malam ini", "2025-02-08 20:00:00"),
            ("pukul 9.30 tadi malam", "2025-02-07 21:30:00"),
            ("7 pagi ini", "2025-02-08 07:00:00"),
            ("jam 4 sore nanti", "2025-02-08 16:00:00"),
            ("jam 8 pada malam ini", "2025-02-08 20:00:00"),
            ("jam 10 di pagi ini", "2025-02-08 10:00:00"),
            ("jam 8 pm malam ini", "2025-02-08 20:00:00"),
            ("pukul 14.30 wib sore nanti", "2025-02-08 14:30:00"),
            ("tengah hari", "2025-02-08 12:00:00"),
            ("siang hari", "2025-02-08 12:00:00"),
            ("12 tengah hari", "2025-02-08 12:00:00"),
            ("pukul 12.00 tengah hari", "2025-02-08 12:00:00"),
            ("siang", "2025-02-08 12:00:00"),
            ("tengah malam", "2025-02-09 00:00:00"),
            ("12 tengah malam", "2025-02-09 00:00:00"),
            ("jam 12.00 tengah malam", "2025-02-09 00:00:00"),
            ("setengah 3", "2025-02-09 02:30:00"),
            ("stgh 3", "2025-02-09 02:30:00"),
            ("stgh. 4 sore", "2025-02-08 15:30:00"),
            ("setengah tiga", "2025-02-09 02:30:00"),
            ("setengah dua belas", "2025-02-08 11:30:00"),
            ("setengah 3 wib", "2025-02-09 02:30:00"),
            ("setengah 5 petang", "2025-02-08 16:30:00"),
            ("setengah 2 dini hari", "2025-02-09 01:30:00"),
            ("jam setengah 3", "2025-02-09 02:30:00"),
            ("pukul setengah 3", "2025-02-09 02:30:00"),
            ("setengah 3 sore", "2025-02-08 14:30:00"),
            ("SETENGAH 3 SORE", "2025-02-08 14:30:00"),
            ("jam setengah 3 siang", "2025-02-08 14:30:00"),
            ("setengah 8 malam", "2025-02-08 19:30:00"),
            ("setengah 9 pagi", "2025-02-09 08:30:00"),
            ("setengah 12", "2025-02-08 11:30:00"),
            ("setengah 1 siang", "2025-02-08 12:30:00"),
            ("jam 3 lewat seperempat", "2025-02-09 03:15:00"),
            ("jam 3 lewat 10", "2025-02-09 03:10:00"),
            ("pukul 14 lebih 20", "2025-02-08 14:20:00"),
            ("jam 3 lewat 1/4", "2025-02-09 03:15:00"),
            ("pukul 3 kurang 1/4", "2025-02-09 02:45:00"),
            ("jam 3 lewat setengah", "2025-02-09 03:30:00"),
            ("pukul 3 lebih 1/2 sore", "2025-02-08 15:30:00"),
            ("jam 3 kurang setengah", "2025-02-09 02:30:00"),
            ("3 lewat 10 menit", "2025-02-09 03:10:00"),
            (
                "pukul lima lebih lima belas menit sore",
                "2025-02-08 17:15:00",
            ),
            ("jam 8 kurang 20 menit malam", "2025-02-08 19:40:00"),
            ("jam 10 lewat seperempat wib pagi", "2025-02-09 10:15:00"),
            ("jam 12 kurang 15 menit malam", "2025-02-08 23:45:00"),
            ("pukul 3 lebih seperempat sore", "2025-02-08 15:15:00"),
            ("jam 3 kurang seperempat", "2025-02-09 02:45:00"),
            ("pukul 3 kurang seperempat sore", "2025-02-08 14:45:00"),
            ("jam 12 kurang seperempat", "2025-02-08 11:45:00"),
        ],
    );
}

#[test]
fn unicode_spans_and_normalized_digits() {
    let p = Parser::default();
    let mut o = options();
    o.range = true;

    let prose = "📅 Rapat — besok jam 14.30 dan “bulan depan” di ruang 🎉";
    let mut results = p.parse_ranges(prose, &o).unwrap();
    results.sort_by_key(|m| m.start);
    assert_eq!(results.len(), 2);
    for m in &results {
        assert!(prose.is_char_boundary(m.start) && prose.is_char_boundary(m.end));
    }
    assert_eq!(&prose[results[0].start..results[0].end], "besok jam 14.30");
    assert_eq!(results[0].date.to_string(), "2025-02-09 14:30:00");
    assert_eq!(&prose[results[1].start..results[1].end], "bulan depan");
    assert_eq!(results[1].date.to_string(), "2025-03-01 00:00:00");

    let normalized_prose = "😀 １５ Maret ２０２５ — besok jam １４.３０；akhir";
    let mut norm_results = p.parse(normalized_prose, &o).unwrap();
    norm_results.sort_by_key(|m| m.start);
    assert_eq!(norm_results.len(), 2);
    for m in &norm_results {
        assert!(
            normalized_prose.is_char_boundary(m.start) && normalized_prose.is_char_boundary(m.end)
        );
    }
    assert_eq!(
        &normalized_prose[norm_results[0].start..norm_results[0].end],
        "１５ Maret ２０２５"
    );
    assert_eq!(norm_results[0].date.to_string(), "2025-03-15 00:00:00");
    assert_eq!(
        &normalized_prose[norm_results[1].start..norm_results[1].end],
        "besok jam １４.３０"
    );
    assert_eq!(norm_results[1].date.to_string(), "2025-02-09 14:30:00");

    let arabic_digits = "📅 ١٥/٠٣/٢٠٢٥";
    let arabic_matches = p.parse(arabic_digits, &o).unwrap();
    assert_eq!(arabic_matches.len(), 1);
    let m = &arabic_matches[0];
    assert!(arabic_digits.is_char_boundary(m.start) && arabic_digits.is_char_boundary(m.end));
    assert_eq!(&arabic_digits[m.start..m.end], "١٥/٠٣/٢٠٢٥");
    assert_eq!(m.date.to_string(), "2025-03-15 00:00:00");
}

#[test]
fn composition_date_time_weekday_anchor() {
    let p = Parser::default();
    let o = options();
    assert_cases(
        &p,
        &o,
        &[
            ("hari ini pukul 18.00", "2025-02-08 18:00:00"),
            ("besok jam 15.00", "2025-02-09 15:00:00"),
            ("besok @ jam 10", "2025-02-09 10:00:00"),
            ("besok sekitar jam 10", "2025-02-09 10:00:00"),
            ("besok kira-kira pukul 9 pagi", "2025-02-09 09:00:00"),
            ("besok pukul 09:30", "2025-02-09 09:30:00"),
            ("lusa jam setengah 4 sore", "2025-02-10 15:30:00"),
            ("kemarin jam 8 malam", "2025-02-07 20:00:00"),
            ("kemarin lusa jam 7 pagi", "2025-02-06 07:00:00"),
            ("besok pagi jam 8", "2025-02-09 08:00:00"),
            ("besok dini hari jam 2", "2025-02-09 02:00:00"),
            ("besok subuh jam 5", "2025-02-09 05:00:00"),
            ("besok sore jam 5", "2025-02-09 17:00:00"),
            ("besok petang jam 6", "2025-02-09 18:00:00"),
            ("besok malam jam 9", "2025-02-09 21:00:00"),
            ("besok malem jam 8", "2025-02-09 20:00:00"),
            ("besok tengah hari", "2025-02-09 12:00:00"),
            ("hari ini tengah malam", "2025-02-08 00:00:00"),
            ("besok tengah malam", "2025-02-09 00:00:00"),
            ("15 Maret jam 14.30", "2025-03-15 14:30:00"),
            ("15 Maret di pukul 14.00", "2025-03-15 14:00:00"),
            ("15 Maret @ pukul 14.30", "2025-03-15 14:30:00"),
            ("15 Maret sekitar pukul 14.30", "2025-03-15 14:30:00"),
            ("15 Maret 2025 pukul 09.00", "2025-03-15 09:00:00"),
            ("15 Maret 2025, jam 16.00", "2025-03-15 16:00:00"),
            ("15 Maret pada pukul 10 pagi", "2025-03-15 10:00:00"),
            ("17/08/2025 jam 10 pagi", "2025-08-17 10:00:00"),
            ("15 Maret tahun depan pukul 11.30", "2026-03-15 11:30:00"),
            ("tahun 2026 bulan Maret", "2026-03-01 00:00:00"),
            ("Senin jam 9 pagi", "2025-02-10 09:00:00"),
            ("Senin di jam 9 pagi", "2025-02-10 09:00:00"),
            ("hari Jumat pukul 14.00", "2025-02-14 14:00:00"),
            ("Sabtu jam 7 malam", "2025-02-15 19:00:00"),
            ("minggu depan Senin jam 9 pagi", "2025-02-10 09:00:00"),
            ("pekan depan Jumat pukul 14.30", "2025-02-14 14:30:00"),
            ("pekan lalu Rabu jam 16.00", "2025-01-29 16:00:00"),
            ("bulan depan Senin", "2025-03-03 00:00:00"),
            ("Senin bulan Februari", "2025-02-03 00:00:00"),
            ("Senin, 10 Februari 2025 pukul 09.00", "2025-02-10 09:00:00"),
            ("Senin, tanggal 10 Februari 2025", "2025-02-10 00:00:00"),
            ("Senin tgl. 10 Februari", "2025-02-10 00:00:00"),
            ("Sabtu 15 Maret 2025 jam 8 malam", "2025-03-15 20:00:00"),
        ],
    );

    for bad in ["Senin, 11 Februari 2025", "Jumat, 10 Februari 2025"] {
        assert!(p.parse(bad, &o).unwrap().is_empty(), "input={bad:?}");
    }
}

#[test]
fn range_mode_week_start_and_timezone_offset() {
    let p = Parser::default();
    let mut o = options();
    o.range = true;

    let text = "Acara dimulai besok jam 10 pagi dan berakhir 15 Maret pukul 16.00.";
    let mut doc_matches = p.parse(text, &o).unwrap();
    doc_matches.sort_by_key(|m| m.start);
    assert_eq!(doc_matches.len(), 2);
    assert_eq!(
        &text[doc_matches[0].start..doc_matches[0].end],
        "besok jam 10 pagi"
    );
    assert_eq!(doc_matches[0].date.to_string(), "2025-02-09 10:00:00");
    assert_eq!(
        &text[doc_matches[1].start..doc_matches[1].end],
        "15 Maret pukul 16.00"
    );
    assert_eq!(doc_matches[1].date.to_string(), "2025-03-15 16:00:00");

    let feb = p.parse("bulan ini", &o).unwrap();
    assert_eq!(feb.len(), 28);
    assert_eq!(feb[0].date.to_string(), "2025-02-01 00:00:00");
    assert_eq!(feb[27].date.to_string(), "2025-02-28 00:00:00");

    let feb_compact = p.parse_ranges("bulan ini", &o).unwrap();
    assert_eq!(feb_compact.len(), 1);
    assert_eq!(feb_compact[0].range_days, Some(28));

    let mar = p.parse("bulan depan", &o).unwrap();
    assert_eq!(mar.len(), 31);
    assert_eq!(
        p.parse_ranges("bulan depan", &o).unwrap()[0].range_days,
        Some(31)
    );

    let week_sun = p.parse("minggu depan", &o).unwrap();
    assert_eq!(week_sun.len(), 7);
    assert_eq!(week_sun[0].date.to_string(), "2025-02-09 00:00:00");
    assert_eq!(
        p.parse_ranges("minggu depan", &o).unwrap()[0].range_days,
        Some(7)
    );

    o.week_start = 1;
    let week_mon = p.parse("minggu depan", &o).unwrap();
    assert_eq!(week_mon.len(), 7);
    assert_eq!(week_mon[0].date.to_string(), "2025-02-10 00:00:00");

    o.reference = "2025-02-12T11:05:00".parse().unwrap();
    for week_start in [1, 7] {
        o.week_start = week_start;
        assert_eq!(
            p.parse("pekan lalu Senin", &o).unwrap()[0].date.to_string(),
            "2025-02-03 00:00:00",
            "week_start={week_start}"
        );
    }
    o.week_start = 1;
    assert_eq!(
        p.parse("pekan lalu Minggu", &o).unwrap()[0]
            .date
            .to_string(),
        "2025-02-09 00:00:00"
    );
    o.week_start = 7;
    assert_eq!(
        p.parse("pekan lalu Minggu", &o).unwrap()[0]
            .date
            .to_string(),
        "2025-02-02 00:00:00"
    );

    o = options();
    o.offset_minutes = 420;
    assert_eq!(
        parse_one(&p, "besok jam 10 pagi", &o).date.to_string(),
        "2025-02-09 17:00:00"
    );
    o.range = true;
    for offset in [-90, 420] {
        o.offset_minutes = offset;
        assert_eq!(
            p.parse_ranges("minggu depan", &o).unwrap()[0].date,
            p.parse("minggu depan", &o).unwrap()[0].date
        );
    }
}

#[test]
fn negative_boundary_and_error_cases() {
    let p = Parser::default();
    let mut o = options();

    for invalid in [
        "",
        "besokX",
        "Xbesok",
        "besoknya",
        "harian",
        "mingguan",
        "bulanan",
        "tahunan",
        "hari iniABC",
        "SeninX",
        "15 MaretA",
        "DesemberX",
        "setengah 3ABC",
        "setengah 3 kg",
        "setengah 5 juta",
        "setengah 2 menit",
        "setengah 4 kali",
        "pukul 14.30ABC",
        "jam 8.15XYZ",
        "jam 8 menit",
        "jam 8 mnt",
        "jam 8 detik",
        "pukul 10 dtk",
        "14.30",
        "3 hari lagiABC",
        "dalam 5 hariABC",
        "Saya minum air di kamar sambil membaca kamus",
        "Hujan di desa membuat mereka senang dan sabar",
        "Jumlah dokter di pasar melebihi target",
        "Lagu itu selesai pada acara makan bersama",
        "31 Februari",
        "31 Februari 2025",
        "30 Februari 2025",
        "29 Februari 2025",
        "31 April 2025",
        "31 Juni",
        "31 September",
        "31 November",
        "0 Maret",
        "32 Januari",
        "32/01/2025",
        "00/01/2025",
        "30/02/2025",
        "31/04/2025",
        "15/13/2025",
        "00/03/2025",
        "10/13",
        "15/00",
        "2025-02-30",
        "2025-04-31",
        "pukul 25.00",
        "jam 24.00",
        "jam 12.60",
        "jam 12:60",
        "jam 14.30:60",
        "25:00",
        "12:60",
        "setengah 0",
        "setengah 13",
        "setengah 25",
        "tanggal 0",
        "tanggal 32",
        "Senin kelima bulan Februari",
        "Senin, 11 Februari 2025",
        "pagi",
        "sore",
        "malam",
        "malem",
        "petang",
        "subuh",
        "dini hari",
        "ini",
        "depan",
        "lalu",
        "tanggal",
        "jam",
        "pukul",
        "akhir",
        "999999999999999999999 hari lagi",
        "pukul 999999999999999999999.00",
        "tanggal 999999999999999999999",
    ] {
        assert!(
            p.parse(invalid, &o).unwrap().is_empty(),
            "expected empty for {invalid:?}"
        );
    }

    o.range = true;
    for (text, expected_spans) in [
        ("besok dan jam 10", ["besok", "jam 10"]),
        ("15 Maret sampai 20 Maret", ["15 Maret", "20 Maret"]),
        ("besok atau lusa", ["besok", "lusa"]),
    ] {
        let mut results = p.parse(text, &o).unwrap();
        results.sort_by_key(|m| m.start);
        assert_eq!(results.len(), 2, "input={text:?}");
        let spans: Vec<_> = results.iter().map(|m| &text[m.start..m.end]).collect();
        assert_eq!(spans, expected_spans, "input={text:?}");
    }

    for (text, expected_span) in [
        ("Maret 10 hari", "Maret"),
        ("Mei 5 orang", "Mei"),
        ("Juni 20 persen", "Juni"),
        ("April 15%", "April"),
        ("Juli 100$", "Juli"),
    ] {
        let results = p.parse_ranges(text, &o).unwrap();
        assert_eq!(results.len(), 1, "input={text:?}");
        assert_eq!(
            &text[results[0].start..results[0].end],
            expected_span,
            "input={text:?}"
        );
    }

    assert_eq!(p.parse("dalam 999999 hari", &o), Err(Error::RangeTooLarge));
    assert_eq!(
        p.parse_ranges("dalam 36600 hari", &o),
        Err(Error::RangeTooLarge)
    );

    o.week_start = 2;
    assert_eq!(p.parse("", &o), Err(Error::InvalidWeekStart));
}

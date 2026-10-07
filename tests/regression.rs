use sunphase::{DateTime, Options, Parser};
#[path = "data/legacy_cases.rs"]
mod data;
#[test]
fn legacy_cases() {
    let parser = Parser::default();
    for &(input, reference, languages, range, week_start, offset_minutes, expected) in data::CASES {
        let options = Options {
            reference: DateTime::parse(reference).unwrap(),
            languages,
            range,
            week_start,
            offset_minutes,
        };
        let results = parser.parse(input, &options).unwrap();
        let compact = parser.parse_ranges(input, &options).unwrap();
        let expanded: Vec<_> = compact
            .into_iter()
            .flat_map(|m| {
                let range = options.range && m.range_days.is_some();
                let days = if range { m.range_days.unwrap() } else { 1 };
                (0..days).map(move |day| sunphase::Match {
                    date: DateTime::from_timestamp_micros(
                        m.date.timestamp_micros() + i64::from(day) * 86_400_000_000,
                    )
                    .unwrap(),
                    range_type: if range { None } else { m.range_type },
                    range_days: if range { None } else { m.range_days },
                    ..m.clone()
                })
            })
            .collect();
        assert_eq!(expanded, results, "compact {input:?} {languages:?}");
        let actual: Vec<_> = results
            .iter()
            .map(|m| {
                (
                    input[..m.start].encode_utf16().count(),
                    input[m.start..m.end]
                        .chars()
                        .map(|ch| {
                            if ('０'..='９').contains(&ch) {
                                char::from_u32(ch as u32 - 0xfee0).unwrap()
                            } else {
                                ch
                            }
                        })
                        .collect::<String>(),
                    m.date,
                    m.range_type,
                    m.range_days,
                )
            })
            .collect();
        let expected: Vec<_> = expected
            .iter()
            .map(|&(i, t, d, r, n)| (i, t.to_string(), DateTime::parse(d).unwrap(), r, n))
            .collect();
        assert_eq!(actual, expected, "{input:?} {languages:?}");
    }
}

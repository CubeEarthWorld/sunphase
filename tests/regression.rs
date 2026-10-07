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

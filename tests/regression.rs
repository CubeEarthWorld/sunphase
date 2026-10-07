use serde_json::Value;
use sunphase::{NaiveDateTime, Options, Parser};
fn dt(s: &str) -> NaiveDateTime {
    NaiveDateTime::parse_from_str(s.trim_end_matches('Z'), "%Y-%m-%dT%H:%M:%S%.f").unwrap()
}
#[test]
fn legacy_cases() {
    let cases: Value = serde_json::from_str(include_str!("legacy_cases.json")).unwrap();
    let parser = Parser::default();
    let mut errors = Vec::new();
    for c in cases.as_array().unwrap() {
        let input = c["input"].as_str().unwrap();
        let languages: Vec<&str> = c["languages"]
            .as_array()
            .map(|ls| ls.iter().map(|s| s.as_str().unwrap()).collect())
            .unwrap_or_else(|| vec!["en", "ja", "zh"]);
        let o = Options {
            reference: dt(c["reference"].as_str().unwrap()),
            languages: &languages,
            range: c["range"].as_bool().unwrap(),
            week_start: c["week_start"].as_u64().unwrap() as u8,
            offset_minutes: c["timezone"]
                .as_str()
                .and_then(|s| s.parse().ok())
                .unwrap_or(0),
        };
        let results = parser.parse(input, &o).unwrap();
        let actual:Vec<Value>=results.iter().map(|m|serde_json::json!({
            "index":input[..m.start].encode_utf16().count(),
            "text":input[m.start..m.end].chars().map(|ch|if ('０'..='９').contains(&ch){char::from_u32(ch as u32-0xfee0).unwrap()}else{ch}).collect::<String>(),
            "date":m.date.format("%Y-%m-%dT%H:%M:%S%.3f").to_string(),
            "range_type":m.range_type,"range_days":m.range_days,
        })).collect();
        let mut expected = c["results"].clone();
        for m in expected.as_array_mut().unwrap() {
            m["date"] = serde_json::json!(m["date"].as_str().unwrap().trim_end_matches('Z'));
        }
        if serde_json::json!(actual) != expected {
            errors.push(format!(
                "{input:?} {languages:?}\nexpected {}\nactual {}",
                expected,
                serde_json::json!(actual)
            ));
        }
    }
    assert!(
        errors.is_empty(),
        "{} mismatches:\n{}",
        errors.len(),
        errors.join("\n")
    );
}

use crate::{Component, Language, Pattern};
pub fn language() -> Language {
    Language::new(
        "ko",
        "(?i)^(?:[\\s,]|에)+$",
        vec![
            Pattern::new(
                "ko_relativeDay",
                "(그끄제|오늘|금일|내일|명일|모레|어제|그제)",
                &[],
                &[
                    ("오늘", &[Component::RelativeDay(0)]),
                    ("금일", &[Component::RelativeDay(0)]),
                    ("내일", &[Component::RelativeDay(1)]),
                    ("명일", &[Component::RelativeDay(1)]),
                    ("모레", &[Component::RelativeDay(2)]),
                    ("어제", &[Component::RelativeDay(-1)]),
                    ("그제", &[Component::RelativeDay(-2)]),
                    ("그끄제", &[Component::RelativeDay(-3)]),
                ],
            ),
            Pattern::new(
                "ko_meridiem",
                "(오전|오후)",
                &[],
                &[
                    ("오전", &[Component::Meridiem(false)]),
                    ("오후", &[Component::Meridiem(true)]),
                ],
            ),
            Pattern::new(
                "ko_weekend",
                "(주말)",
                &[],
                &[("주말", &[Component::Weekend])],
            ),
            Pattern::new(
                "ko_weekAnchor",
                "(다다음|다음|이번|저번|지난)\\s*주(?P<guard0>)",
                &[("guard0", false, "말")],
                &[],
            ),
            Pattern::new(
                "ko_nextLastWeekday",
                "(다음|지난|저번)\\s*([월화수목금토일])요일",
                &[],
                &[],
            ),
            Pattern::new(
                "ko_monthAnchor",
                "(다음|이번|지난|저번)\\s*(?:달|월)(?P<guard0>)",
                &[("guard0", false, "[요0-9]")],
                &[],
            ),
            Pattern::new(
                "ko_yearAnchor",
                "(내후년|내년|올해|작년)",
                &[],
                &[
                    ("내년", &[Component::YearOffset(1)]),
                    ("올해", &[Component::YearOffset(0)]),
                    ("작년", &[Component::YearOffset(-1)]),
                    ("내후년", &[Component::YearOffset(2)]),
                ],
            ),
            Pattern::new(
                "ko_offset",
                "([0-9零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+)\\s*(일|주|개월|달|년)\\s*(후|뒤|전)",
                &[],
                &[],
            ),
            Pattern::new("ko_weekday", "([월화수목금토일])요일", &[], &[]),
            Pattern::new("ko_year", "([0-9]{4})년", &[], &[]),
            Pattern::new(
                "ko_month",
                "([0-9零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+)월",
                &[],
                &[],
            ),
            Pattern::new(
                "ko_day",
                "([0-9零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+)일(?P<guard0>)",
                &[("guard0", false, "요일")],
                &[],
            ),
            Pattern::new(
                "ko_time",
                "([0-9零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+)시(?:\\s*([0-9零一二三四五六七八九十]+|[영일이삼사오육칠팔구십]+)분)?",
                &[],
                &[],
            ),
            Pattern::new("ko_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

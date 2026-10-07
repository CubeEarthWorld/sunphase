use crate::{Component, Language, Pattern};
pub fn language() -> Language {
    Language::new(
        "zh",
        "(?i)^(?:[\\s、,]|的)+$",
        vec![
            Pattern::new(
                "zh_relativeDay",
                "(大后天|大前天|今天|今日|明天|后天|昨天|前天)",
                &[],
                &[
                    ("今天", &[Component::RelativeDay(0)]),
                    ("今日", &[Component::RelativeDay(0)]),
                    ("明天", &[Component::RelativeDay(1)]),
                    ("后天", &[Component::RelativeDay(2)]),
                    ("大后天", &[Component::RelativeDay(3)]),
                    ("昨天", &[Component::RelativeDay(-1)]),
                    ("前天", &[Component::RelativeDay(-2)]),
                    ("大前天", &[Component::RelativeDay(-3)]),
                ],
            ),
            Pattern::new(
                "zh_yearAnchor",
                "(后年|明年|今年|去年|前年)",
                &[],
                &[
                    ("后年", &[Component::YearOffset(2)]),
                    ("明年", &[Component::YearOffset(1)]),
                    ("今年", &[Component::YearOffset(0)]),
                    ("去年", &[Component::YearOffset(-1)]),
                    ("前年", &[Component::YearOffset(-2)]),
                ],
            ),
            Pattern::new(
                "zh_meridiem",
                "(上午|早上|凌晨|中午|下午|晚上|夜里)",
                &[],
                &[
                    ("上午", &[Component::Meridiem(false)]),
                    ("早上", &[Component::Meridiem(false)]),
                    ("凌晨", &[Component::Meridiem(false)]),
                    ("中午", &[Component::Meridiem(false)]),
                    ("下午", &[Component::Meridiem(true)]),
                    ("晚上", &[Component::Meridiem(true)]),
                    ("夜里", &[Component::Meridiem(true)]),
                ],
            ),
            Pattern::new(
                "zh_weekend",
                "(周末)",
                &[],
                &[("周末", &[Component::Weekend])],
            ),
            Pattern::new(
                "zh_weekday",
                "(下下|下|这|本|上)?(?:个)?(?:星期|礼拜|周)([一二三四五六日天])",
                &[],
                &[],
            ),
            Pattern::new(
                "zh_weekAnchor",
                "(下下|下|这|本|上)(?:个)?(?:星期|礼拜|周)(?P<guard0>)",
                &[("guard0", false, "[一二三四五六日天]")],
                &[],
            ),
            Pattern::new("zh_monthAnchor", "(下下|下|这|本|上)个月", &[], &[]),
            Pattern::new(
                "zh_offset",
                "([0-9〇零一二三四五六七八九十百千]+)(天|(?:个)?(?:星期|礼拜|周)|个月|年)(后|前)",
                &[],
                &[],
            ),
            Pattern::new("zh_year", "([0-9]{4})年", &[], &[]),
            Pattern::new(
                "zh_month",
                "([0-9〇零一二三四五六七八九十百千]+)月",
                &[],
                &[],
            ),
            Pattern::new(
                "zh_day",
                "([0-9〇零一二三四五六七八九十百千]+)[号日]",
                &[],
                &[],
            ),
            Pattern::new(
                "zh_time",
                "([0-9〇零一二三四五六七八九十百千]+)[点时](?:\\s*([0-9〇零一二三四五六七八九十百千]+)分)?",
                &[],
                &[],
            ),
            Pattern::new("zh_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

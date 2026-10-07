use crate::{Component, Language, Pattern};
pub fn language() -> Language {
    Language::new(
        "hi",
        "(?i)^(?:[\\s,]|को|के|की)+$",
        vec![
            Pattern::new(
                "hi_relativeDay",
                "(?P<guard0>)(परसों|नरसों|आज|कल)(?P<guard1>)",
                &[("guard0", true, "[ऀ-ॿ]"), ("guard1", false, "[ऀ-ॿ]")],
                &[
                    ("आज", &[Component::RelativeDay(0)]),
                    ("कल", &[Component::RelativeDay(1)]),
                    ("परसों", &[Component::RelativeDay(2)]),
                    ("नरसों", &[Component::RelativeDay(3)]),
                ],
            ),
            Pattern::new(
                "hi_meridiem",
                "(?P<guard0>)(दोपहर|सुबह|शाम|रात)(?P<guard1>)",
                &[("guard0", true, "[ऀ-ॿ]"), ("guard1", false, "[ऀ-ॿ]")],
                &[
                    ("सुबह", &[Component::Meridiem(false)]),
                    ("दोपहर", &[Component::Meridiem(true)]),
                    ("शाम", &[Component::Meridiem(true)]),
                    ("रात", &[Component::Meridiem(true)]),
                ],
            ),
            Pattern::new(
                "hi_weekAnchor",
                "(अगले|पिछले|इस)\\s+(?:सप्ताह|हफ़्ते|हफ्ते|हफ्ता)",
                &[],
                &[],
            ),
            Pattern::new(
                "hi_monthAnchor",
                "(अगले|पिछले|इस)\\s+(?:महीने|महीना)",
                &[],
                &[],
            ),
            Pattern::new("hi_yearAnchor", "(अगले|पिछले|इस)\\s+(?:साल|वर्ष)", &[], &[]),
            Pattern::new(
                "hi_nextLastWeekday",
                "(अगले|पिछले)\\s+(शुक्रवार|मंगलवार|गुरुवार|सोमवार|बुधवार|शनिवार|रविवार)",
                &[],
                &[],
            ),
            Pattern::new(
                "hi_weekday",
                "(?P<guard0>)(शुक्रवार|मंगलवार|गुरुवार|सोमवार|बुधवार|शनिवार|रविवार)(?P<guard1>)",
                &[("guard0", true, "[ऀ-ॿ]"), ("guard1", false, "[ऀ-ॿ]")],
                &[
                    ("सोमवार", &[Component::Weekday(1)]),
                    ("मंगलवार", &[Component::Weekday(2)]),
                    ("बुधवार", &[Component::Weekday(3)]),
                    ("गुरुवार", &[Component::Weekday(4)]),
                    ("शुक्रवार", &[Component::Weekday(5)]),
                    ("शनिवार", &[Component::Weekday(6)]),
                    ("रविवार", &[Component::Weekday(7)]),
                ],
            ),
            Pattern::new(
                "hi_offset",
                "([0-9]+)\\s*(दिन|(?:सप्ताह|हफ़्ते|हफ्ते|हफ्ता)|महीने|साल)\\s*(बाद|पहले)",
                &[],
                &[],
            ),
            Pattern::new(
                "hi_dayMonth",
                "([0-9]{1,2})\\s+(अक्टूबर|फ़रवरी|अप्रैल|सितंबर|दिसंबर|जनवरी|फरवरी|मार्च|जुलाई|अगस्त|नवंबर|जून|मई)(?P<guard0>)(?:\\s+([0-9]{4}))?",
                &[("guard0", false, "[ऀ-ॿ]")],
                &[],
            ),
            Pattern::new(
                "hi_month",
                "(?P<guard0>)(अक्टूबर|फ़रवरी|अप्रैल|सितंबर|दिसंबर|जनवरी|फरवरी|मार्च|जुलाई|अगस्त|नवंबर|जून|मई)(?P<guard1>)",
                &[("guard0", true, "[ऀ-ॿ]"), ("guard1", false, "[ऀ-ॿ]")],
                &[
                    ("जनवरी", &[Component::Month(1)]),
                    ("फरवरी", &[Component::Month(2)]),
                    ("फ़रवरी", &[Component::Month(2)]),
                    ("मार्च", &[Component::Month(3)]),
                    ("अप्रैल", &[Component::Month(4)]),
                    ("मई", &[Component::Month(5)]),
                    ("जून", &[Component::Month(6)]),
                    ("जुलाई", &[Component::Month(7)]),
                    ("अगस्त", &[Component::Month(8)]),
                    ("सितंबर", &[Component::Month(9)]),
                    ("अक्टूबर", &[Component::Month(10)]),
                    ("नवंबर", &[Component::Month(11)]),
                    ("दिसंबर", &[Component::Month(12)]),
                ],
            ),
            Pattern::new("hi_day", "([0-9]{1,2})\\s*तारीख", &[], &[]),
            Pattern::new("hi_baje", "([0-9]{1,2})\\s*बजे", &[], &[]),
            Pattern::new("hi_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

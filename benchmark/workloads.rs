pub const SHORT: &[&str] = &[
    "tomorrow at 3pm",
    "next month on the 21st at 2pm",
    "March 7 10:10",
    "来月21日12時31分",
    "来週火曜14時14分",
    "明日午後３時３０分",
    "下个月21号下午3点",
    "明天上午九点",
    "2025-03-07T10:10:00Z",
    "no date in this sentence",
    "",
];
pub const RANGE: &[&str] = &["next week", "march", "来月", "3日以内", "下个月"];
pub const LONG: &str = "tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. tomorrow at 3pm; 来月21日12時31分; 下个月21号下午3点; no date here. ";
pub const NO_MATCH: &str = "nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. nothing to schedule here. ";
pub const LANGUAGES: &[&[&str]] = &[
    &[
        "tomorrow at 3pm",
        "next month on the 21st at 2pm",
        "last Friday",
    ],
    &["来月21日12時31分", "来週火曜14時14分", "明日午後３時３０分"],
    &["下个月21号下午3点", "明天上午九点", "三天后"],
    &[
        "mañana a las 3pm",
        "el próximo mes",
        "el tercer lunes de marzo",
    ],
    &["कल", "अगले सोमवार", "3 दिन बाद"],
    &["내일", "다음 달 21일", "오후 3시"],
    &["завтра", "в следующем месяце", "через 3 дня"],
];

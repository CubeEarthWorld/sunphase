use crate::{Language, Pattern};
pub fn language() -> Language {
    Language::new(
        "universal",
        "(?i)^[\\s,]+$",
        vec![
            Pattern::new(
                "universal_iso",
                "[0-9]{4}-[0-9]{2}-[0-9]{2}[T\\s][0-9]{2}:[0-9]{2}:[0-9]{2}(?:\\.[0-9]+)?(?:Z|[+\\-][0-9]{2}:?[0-9]{2})?",
                &[],
                &[],
            ),
            Pattern::new(
                "universal_rfc",
                "[A-Za-z0-9_]{3}\\s+[A-Za-z0-9_]{3}\\s+[0-9]{1,2}\\s+[0-9]{4}\\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\\s+GMT[+\\-][0-9]{4}(?:\\s*\\(.*\\))?",
                &[],
                &[],
            ),
            Pattern::new(
                "universal_date",
                "([0-9]{4})[-/]([0-9]{1,2})[-/]([0-9]{1,2})",
                &[],
                &[],
            ),
            Pattern::new("universal_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

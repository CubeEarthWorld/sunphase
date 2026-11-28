use crate::Language;
pub fn language() -> Language {
    Language::new("te", r"\s+", vec![])
}

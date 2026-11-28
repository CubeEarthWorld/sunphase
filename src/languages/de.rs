use crate::Language;
pub fn language() -> Language {
    Language::new("de", r"\s+", vec![])
}

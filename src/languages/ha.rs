use crate::Language;
pub fn language() -> Language {
    Language::new("ha", r"\s+", vec![])
}

use crate::Language;
pub fn language() -> Language {
    Language::new("ur", r"\s+", vec![])
}

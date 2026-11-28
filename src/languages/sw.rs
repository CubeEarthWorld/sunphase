use crate::Language;
pub fn language() -> Language {
    Language::new("sw", r"\s+", vec![])
}

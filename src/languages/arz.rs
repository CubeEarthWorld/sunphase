use crate::Language;
pub fn language() -> Language {
    Language::new("arz", r"\s+", vec![])
}

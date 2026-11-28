use crate::Language;
pub fn language() -> Language {
    Language::new("vi", r"\s+", vec![])
}

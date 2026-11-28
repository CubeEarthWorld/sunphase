use crate::Language;
pub fn language() -> Language {
    Language::new("mr", r"\s+", vec![])
}

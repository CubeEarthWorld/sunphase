use crate::Language;
pub fn language() -> Language {
    Language::new("pcm", r"\s+", vec![])
}

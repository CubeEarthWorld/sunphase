use crate::{Component, Language, Pattern};
pub fn language() -> Language {
    Language::new(
        "es",
        "(?i)^(?:[\\s,]|a|las|la|el|de|del|en)+$",
        vec![
            Pattern::new(
                "es_relativeDay",
                "(?i)(?P<guard0>)(pasado mañana|pasado manana|anteayer|mañana|manana|antier|ayer|hoy)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[
                    ("hoy", &[Component::RelativeDay(0)]),
                    ("mañana", &[Component::RelativeDay(1)]),
                    ("manana", &[Component::RelativeDay(1)]),
                    ("pasado mañana", &[Component::RelativeDay(2)]),
                    ("pasado manana", &[Component::RelativeDay(2)]),
                    ("ayer", &[Component::RelativeDay(-1)]),
                    ("anteayer", &[Component::RelativeDay(-2)]),
                    ("antier", &[Component::RelativeDay(-2)]),
                ],
            ),
            Pattern::new(
                "es_estaNoche",
                "(?i)(?P<guard0>)esta\\s+noche(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[],
            ),
            Pattern::new(
                "es_meridiem",
                "(?i)(?P<guard0>)de\\s+la\\s+(tarde|noche|mañana|manana)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[],
            ),
            Pattern::new(
                "es_fixedTime",
                "(?i)(?P<guard0>)(medianoche|mediodía|mediodia)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[
                    ("mediodía", &[Component::Time(12, Some(0), None)]),
                    ("mediodia", &[Component::Time(12, Some(0), None)]),
                    ("medianoche", &[Component::Time(0, Some(0), None)]),
                ],
            ),
            Pattern::new(
                "es_nthWeekday",
                "(?i)(?P<guard0>)el\\s+(primer|primero|segundo|tercer|tercero|cuarto|quinto|[úu]ltimo)\\s+(lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo)\\s+de\\s+(septiembre|setiembre|noviembre|diciembre|febrero|octubre|agosto|enero|marzo|abril|junio|julio|mayo)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[],
            ),
            Pattern::new(
                "es_nextLastWeekday",
                "(?i)(?P<guard0>)(pr[óo]xim[oa]|pasad[oa])\\s+(lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[],
            ),
            Pattern::new(
                "es_weekAnchor",
                "(?i)(?P<guard0>)(?:pr[óo]xima\\s+semana|semana\\s+pasada|esta\\s+semana)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[],
            ),
            Pattern::new(
                "es_monthAnchor",
                "(?i)(?P<guard0>)(?:pr[óo]ximo\\s+mes|mes\\s+que\\s+viene|mes\\s+pasado|este\\s+mes)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[],
            ),
            Pattern::new(
                "es_yearAnchor",
                "(?i)(?P<guard0>)(?:pr[óo]ximo\\s+a[ñn]o|a[ñn]o\\s+pasado)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[],
            ),
            Pattern::new(
                "es_ago",
                "(?i)hace\\s+([0-9]+)\\s+(d[ií]as?|semanas?|meses|años?)",
                &[],
                &[],
            ),
            Pattern::new(
                "es_atras",
                "(?i)([0-9]+)\\s+(d[ií]as?|semanas?)\\s+atr[aá]s",
                &[],
                &[],
            ),
            Pattern::new(
                "es_en",
                "(?i)en\\s+([0-9]+)\\s+(d[ií]as?|semanas?|meses)",
                &[],
                &[],
            ),
            Pattern::new(
                "es_desdeAhora",
                "(?i)([0-9]+)\\s+(d[ií]as?|semanas?)\\s+desde\\s+ahora",
                &[],
                &[],
            ),
            Pattern::new(
                "es_dayMonth",
                "(?i)(?:el\\s+)?(?:d[ií]a\\s+)?([0-9]{1,2})\\s+de\\s+(septiembre|setiembre|noviembre|diciembre|febrero|octubre|agosto|enero|marzo|abril|junio|julio|mayo)(?P<guard0>)(?:\\s+de\\s+([0-9]{4}))?",
                &[("guard0", false, "[a-záéíóúñ]")],
                &[],
            ),
            Pattern::new(
                "es_month",
                "(?i)(?P<guard0>)(septiembre|setiembre|noviembre|diciembre|febrero|octubre|agosto|enero|marzo|abril|junio|julio|mayo)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[
                    ("enero", &[Component::Month(1)]),
                    ("febrero", &[Component::Month(2)]),
                    ("marzo", &[Component::Month(3)]),
                    ("abril", &[Component::Month(4)]),
                    ("mayo", &[Component::Month(5)]),
                    ("junio", &[Component::Month(6)]),
                    ("julio", &[Component::Month(7)]),
                    ("agosto", &[Component::Month(8)]),
                    ("septiembre", &[Component::Month(9)]),
                    ("setiembre", &[Component::Month(9)]),
                    ("octubre", &[Component::Month(10)]),
                    ("noviembre", &[Component::Month(11)]),
                    ("diciembre", &[Component::Month(12)]),
                ],
            ),
            Pattern::new(
                "es_weekday",
                "(?i)(?P<guard0>)(miércoles|miercoles|viernes|domingo|martes|jueves|sábado|sabado|lunes)(?P<guard1>)",
                &[
                    ("guard0", true, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                    ("guard1", false, "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]"),
                ],
                &[
                    ("lunes", &[Component::Weekday(1)]),
                    ("martes", &[Component::Weekday(2)]),
                    ("miércoles", &[Component::Weekday(3)]),
                    ("miercoles", &[Component::Weekday(3)]),
                    ("jueves", &[Component::Weekday(4)]),
                    ("viernes", &[Component::Weekday(5)]),
                    ("sábado", &[Component::Weekday(6)]),
                    ("sabado", &[Component::Weekday(6)]),
                    ("domingo", &[Component::Weekday(7)]),
                ],
            ),
            Pattern::new(
                "es_elDia",
                "(?i)el\\s+(?:d[ií]a\\s+)?([0-9]{1,2})(?P<guard0>)",
                &[("guard0", false, "[[0-9]:]")],
                &[],
            ),
            Pattern::new("es_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
        ],
    )
}

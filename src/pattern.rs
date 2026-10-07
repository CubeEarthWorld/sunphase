//! Small ordered Thompson NFA. Each instruction is visited at most once per
//! input character: repetition cannot cause exponential backtracking.
use std::{fmt, rc::Rc};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PatternError(pub &'static str);
impl fmt::Display for PatternError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.0)
    }
}
impl std::error::Error for PatternError {}
#[derive(Clone)]
enum Class {
    Ranges(Vec<(char, char)>, bool),
    Space,
    Digit,
    Word,
    Any,
}
impl Class {
    fn accepts(&self, c: char, fold: bool) -> bool {
        match self {
            Self::Space => c.is_whitespace(),
            Self::Digit => c.is_ascii_digit(),
            Self::Word => c.is_alphanumeric() || c == '_',
            Self::Any => c != '\n',
            Self::Ranges(r, neg) => {
                let inside = |c| r.iter().any(|&(a, b)| a <= c && c <= b);
                let found = inside(c)
                    || fold && (c.to_lowercase().any(inside) || c.to_uppercase().any(inside));
                found != *neg
            }
        }
    }
}
enum Ast {
    Empty,
    Char(Class),
    Start,
    End,
    Seq(Vec<Ast>),
    Alt(Vec<Ast>),
    Group(usize, Box<Ast>),
    Repeat(Box<Ast>, usize, Option<usize>, bool),
}
enum Inst {
    Char(Class, usize),
    Split(usize, usize),
    Save(usize, usize),
    Start(usize),
    End(usize),
    Match,
}
struct Reader {
    chars: Vec<char>,
    at: usize,
    names: Vec<Option<String>>,
    fold: bool,
    depth: usize,
}
impl Reader {
    fn take(&mut self) -> Option<char> {
        let c = self.chars.get(self.at).copied();
        self.at += usize::from(c.is_some());
        c
    }
    fn peek(&self) -> Option<char> {
        self.chars.get(self.at).copied()
    }
    fn alt(&mut self) -> Result<Ast, PatternError> {
        let mut alternatives = vec![self.seq()?];
        while self.peek() == Some('|') {
            self.take();
            alternatives.push(self.seq()?);
        }
        Ok(if alternatives.len() == 1 {
            alternatives.pop().unwrap()
        } else {
            Ast::Alt(alternatives)
        })
    }
    fn seq(&mut self) -> Result<Ast, PatternError> {
        let mut parts = vec![];
        while !matches!(self.peek(), None | Some(')' | '|')) {
            let mut a = self.atom()?;
            let repeat = match self.peek() {
                Some('?') => {
                    self.take();
                    Some((0, Some(1)))
                }
                Some('*') => {
                    self.take();
                    Some((0, None))
                }
                Some('+') => {
                    self.take();
                    Some((1, None))
                }
                Some('{') => {
                    self.take();
                    let min = self.number()?;
                    let max = if self.peek() == Some(',') {
                        self.take();
                        if self.peek() == Some('}') {
                            None
                        } else {
                            Some(self.number()?)
                        }
                    } else {
                        Some(min)
                    };
                    if self.take() != Some('}')
                        || min > 1000
                        || max.is_some_and(|m| m < min || m > 1000)
                    {
                        return Err(PatternError("invalid or excessive repetition"));
                    }
                    Some((min, max))
                }
                _ => None,
            };
            if let Some((min, max)) = repeat {
                let greedy = self.peek() != Some('?');
                if !greedy {
                    self.take();
                }
                a = Ast::Repeat(Box::new(a), min, max, greedy);
            }
            parts.push(a);
        }
        Ok(Ast::Seq(parts))
    }
    fn number(&mut self) -> Result<usize, PatternError> {
        let mut n = 0usize;
        let start = self.at;
        while self.peek().is_some_and(|c| c.is_ascii_digit()) {
            n = n
                .checked_mul(10)
                .and_then(|v| v.checked_add(self.take().unwrap() as usize - '0' as usize))
                .ok_or(PatternError("repetition overflow"))?;
        }
        if self.at == start {
            Err(PatternError("expected repetition count"))
        } else {
            Ok(n)
        }
    }
    fn escaped(&mut self) -> Result<Class, PatternError> {
        Ok(match self.take().ok_or(PatternError("trailing escape"))? {
            's' => Class::Space,
            'd' => Class::Digit,
            'w' => Class::Word,
            'n' => Class::Ranges(vec![('\n', '\n')], false),
            'r' => Class::Ranges(vec![('\r', '\r')], false),
            't' => Class::Ranges(vec![('\t', '\t')], false),
            c if !c.is_alphanumeric() => Class::Ranges(vec![(c, c)], false),
            _ => return Err(PatternError("unsupported escape; use explicit characters")),
        })
    }
    fn atom(&mut self) -> Result<Ast, PatternError> {
        Ok(match self.take().ok_or(PatternError("expected pattern"))? {
            '^' => Ast::Start,
            '$' => Ast::End,
            '.' => Ast::Char(Class::Any),
            '\\' => Ast::Char(self.escaped()?),
            '[' => {
                let neg = self.peek() == Some('^');
                if neg {
                    self.take();
                }
                let mut ranges = vec![];
                while self.peek() != Some(']') {
                    let c = self
                        .take()
                        .ok_or(PatternError("unclosed character class"))?;
                    let a = if c == '\\' {
                        match self.escaped()? {
                            Class::Ranges(r, false) => r[0].0,
                            Class::Space => {
                                ranges.extend([
                                    ('\t', '\r'),
                                    (' ', ' '),
                                    ('\u{85}', '\u{85}'),
                                    ('\u{a0}', '\u{a0}'),
                                    ('\u{1680}', '\u{1680}'),
                                    ('\u{2000}', '\u{200a}'),
                                    ('\u{2028}', '\u{2029}'),
                                    ('\u{202f}', '\u{202f}'),
                                    ('\u{205f}', '\u{205f}'),
                                    ('\u{3000}', '\u{3000}'),
                                ]);
                                continue;
                            }
                            Class::Digit => {
                                ranges.push(('0', '9'));
                                continue;
                            }
                            _ => return Err(PatternError("unsupported class escape")),
                        }
                    } else {
                        c
                    };
                    let b = if self.peek() == Some('-') && self.chars.get(self.at + 1) != Some(&']')
                    {
                        self.take();
                        let b = self.take().ok_or(PatternError("unclosed range"))?;
                        if b == '\\' {
                            match self.escaped()? {
                                Class::Ranges(r, false) => r[0].0,
                                _ => return Err(PatternError("invalid range")),
                            }
                        } else {
                            b
                        }
                    } else {
                        a
                    };
                    if a > b {
                        return Err(PatternError("reversed character range"));
                    }
                    ranges.push((a, b));
                }
                self.take();
                if ranges.is_empty() {
                    return Err(PatternError("empty class"));
                }
                Ast::Char(Class::Ranges(ranges, neg))
            }
            '(' => {
                self.depth += 1;
                if self.depth > 64 {
                    return Err(PatternError("pattern nesting exceeds 64"));
                }
                let mut name = None;
                let mut capture = true;
                if self.peek() == Some('?') {
                    self.take();
                    match self.take() {
                        Some(':') => capture = false,
                        Some('i') if self.take() == Some(')') => {
                            if self.at != 4 {
                                return Err(PatternError(
                                    "(?i) is supported only at pattern start",
                                ));
                            }
                            self.fold = true;
                            self.depth -= 1;
                            return Ok(Ast::Empty);
                        }
                        Some('P') if self.take() == Some('<') => {
                            let mut n = String::new();
                            while self.peek() != Some('>') {
                                n.push(self.take().ok_or(PatternError("unclosed group name"))?);
                            }
                            self.take();
                            if n.is_empty() || self.names.iter().any(|v| v.as_ref() == Some(&n)) {
                                return Err(PatternError("invalid or duplicate capture name"));
                            }
                            name = Some(n);
                        }
                        _ => {
                            return Err(PatternError("unsupported group; use captures or (?:...)"));
                        }
                    }
                }
                let group = self.names.len();
                if capture {
                    self.names.push(name);
                }
                let a = self.alt()?;
                if self.take() != Some(')') {
                    return Err(PatternError("unclosed group"));
                }
                self.depth -= 1;
                if capture {
                    Ast::Group(group, Box::new(a))
                } else {
                    a
                }
            }
            '*' | '+' | '?' | '{' | '}' | ')' => {
                return Err(PatternError("unexpected metacharacter"));
            }
            c => Ast::Char(Class::Ranges(vec![(c, c)], false)),
        })
    }
}
fn size(a: &Ast) -> Option<usize> {
    let n = match a {
        Ast::Empty => 0,
        Ast::Char(_) | Ast::Start | Ast::End => 1,
        Ast::Group(_, a) => size(a)?.checked_add(2)?,
        Ast::Seq(xs) => xs.iter().try_fold(0usize, |n, a| n.checked_add(size(a)?))?,
        Ast::Alt(xs) => xs
            .iter()
            .try_fold(xs.len() - 1, |n, a| n.checked_add(size(a)?))?,
        Ast::Repeat(a, min, max, _) => {
            let count = max.unwrap_or(min + 1);
            size(a)?.checked_mul(count)?.checked_add(count - min)?
        }
    };
    (n <= 65536).then_some(n)
}
fn emit(code: &mut Vec<Inst>, a: &Ast, next: usize) -> usize {
    match a {
        Ast::Empty => next,
        Ast::Char(c) => {
            let p = code.len();
            code.push(Inst::Char(c.clone(), next));
            p
        }
        Ast::Start => {
            let p = code.len();
            code.push(Inst::Start(next));
            p
        }
        Ast::End => {
            let p = code.len();
            code.push(Inst::End(next));
            p
        }
        Ast::Seq(parts) => parts.iter().rev().fold(next, |n, a| emit(code, a, n)),
        Ast::Alt(parts) => {
            let mut n = emit(code, parts.last().unwrap(), next);
            for a in parts[..parts.len() - 1].iter().rev() {
                let first = emit(code, a, next);
                let p = code.len();
                code.push(Inst::Split(first, n));
                n = p;
            }
            n
        }
        Ast::Group(i, a) => {
            let end = code.len();
            code.push(Inst::Save(i * 2 + 1, next));
            let body = emit(code, a, end);
            let start = code.len();
            code.push(Inst::Save(i * 2, body));
            start
        }
        Ast::Repeat(a, min, max, greedy) => {
            let mut n = next;
            if let Some(max) = max {
                for _ in *min..*max {
                    let body = emit(code, a, n);
                    let p = code.len();
                    code.push(if *greedy {
                        Inst::Split(body, n)
                    } else {
                        Inst::Split(n, body)
                    });
                    n = p;
                }
            } else {
                let p = code.len();
                code.push(Inst::Match);
                let body = emit(code, a, p);
                code[p] = if *greedy {
                    Inst::Split(body, next)
                } else {
                    Inst::Split(next, body)
                };
                n = p;
            }
            for _ in 0..*min {
                n = emit(code, a, n);
            }
            n
        }
    }
}
pub(crate) struct Regex {
    code: Vec<Inst>,
    start: usize,
    names: Vec<Option<String>>,
    fold: bool,
    first: Vec<usize>,
    nullable: bool,
    ascii_start: u128,
}
#[derive(Clone)]
struct Thread {
    pc: usize,
    slots: Rc<Vec<usize>>,
}
pub struct Captures<'a> {
    text: &'a str,
    names: &'a [Option<String>],
    slots: Vec<usize>,
}
pub struct Capture<'a> {
    text: &'a str,
    start: usize,
    end: usize,
}
impl<'a> Capture<'a> {
    pub fn is_empty(&self) -> bool {
        self.start == self.end
    }
    pub fn as_str(&self) -> &'a str {
        &self.text[self.start..self.end]
    }
    pub fn start(&self) -> usize {
        self.start
    }
    pub fn end(&self) -> usize {
        self.end
    }
}
impl<'a> Captures<'a> {
    pub fn get(&self, i: usize) -> Option<Capture<'a>> {
        let start = *self.slots.get(i * 2)?;
        let end = *self.slots.get(i * 2 + 1)?;
        (start != usize::MAX && end != usize::MAX).then_some(Capture {
            text: self.text,
            start,
            end,
        })
    }
    pub fn name(&self, name: &str) -> Option<Capture<'a>> {
        self.get(self.names.iter().position(|n| n.as_deref() == Some(name))?)
    }
}
impl Regex {
    pub fn new(s: &str) -> Result<Self, PatternError> {
        if s.len() > 65536 {
            return Err(PatternError("pattern exceeds 64 KiB"));
        }
        let mut r = Reader {
            chars: s.chars().collect(),
            at: 0,
            names: vec![None],
            fold: false,
            depth: 0,
        };
        let a = r.alt()?;
        if r.at != r.chars.len() {
            return Err(PatternError("unmatched closing group"));
        }
        size(&a).ok_or(PatternError("compiled pattern exceeds 65536 instructions"))?;
        let mut code = vec![Inst::Match];
        let start = emit(&mut code, &Ast::Group(0, Box::new(a)), 0);
        if code.len() > 65536 {
            return Err(PatternError("compiled pattern exceeds 65536 instructions"));
        }
        let mut first = vec![];
        let mut seen = vec![false; code.len()];
        let mut pending = vec![start];
        let mut nullable = false;
        while let Some(p) = pending.pop() {
            if seen[p] {
                continue;
            }
            seen[p] = true;
            match code[p] {
                Inst::Char(..) => first.push(p),
                Inst::Split(a, b) => pending.extend([a, b]),
                Inst::Save(_, n) | Inst::Start(n) | Inst::End(n) => pending.push(n),
                Inst::Match => nullable = true,
            }
        }
        let ascii_start = (0u8..128)
            .filter(|&c| {
                nullable
                    || first.iter().any(|&p| match &code[p] {
                        Inst::Char(class, _) => class.accepts(char::from(c), r.fold),
                        _ => false,
                    })
            })
            .fold(0u128, |mask, c| mask | (1u128 << c));
        Ok(Self {
            code,
            start,
            names: r.names,
            fold: r.fold,
            first,
            nullable,
            ascii_start,
        })
    }
    pub fn capture_names(&self) -> impl Iterator<Item = Option<&str>> {
        self.names.iter().map(|n| n.as_deref())
    }
    fn add(
        &self,
        list: &mut Vec<Thread>,
        mut t: Thread,
        at: usize,
        len: usize,
        seen: &mut [bool],
        pending: &mut Vec<Thread>,
    ) {
        loop {
            if !seen[t.pc] {
                seen[t.pc] = true;
                match self.code[t.pc] {
                    Inst::Split(a, b) => {
                        pending.push(Thread {
                            pc: b,
                            slots: t.slots.clone(),
                        });
                        t.pc = a;
                        continue;
                    }
                    Inst::Save(i, n) => {
                        Rc::make_mut(&mut t.slots)[i] = at;
                        t.pc = n;
                        continue;
                    }
                    Inst::Start(n) if at == 0 => {
                        t.pc = n;
                        continue;
                    }
                    Inst::End(n) if at == len => {
                        t.pc = n;
                        continue;
                    }
                    Inst::Char(..) | Inst::Match => list.push(t),
                    _ => {}
                }
            }
            match pending.pop() {
                Some(next) => t = next,
                None => break,
            }
        }
    }
    pub fn captures_at<'a>(&'a self, text: &'a str, at: usize) -> Option<Captures<'a>> {
        if at > text.len() || !text.is_char_boundary(at) {
            return None;
        }
        let mut current = Vec::with_capacity(self.code.len());
        let mut next = Vec::with_capacity(self.code.len());
        let mut seen = vec![false; self.code.len()];
        let mut pending = Vec::new();
        let blank = Rc::new(vec![usize::MAX; self.names.len() * 2]);
        let mut found = None;
        for (pos, ch) in text[at..]
            .char_indices()
            .map(|(p, c)| (p + at, Some(c)))
            .chain(std::iter::once((text.len(), None)))
        {
            if found.is_none()
                && (self.nullable
                    || ch.is_some_and(|c| {
                        if c.is_ascii() {
                            self.ascii_start & (1u128 << c as u8) != 0
                        } else {
                            self.first.iter().any(|&p| match &self.code[p] {
                                Inst::Char(class, _) => class.accepts(c, self.fold),
                                _ => false,
                            })
                        }
                    }))
            {
                self.add(
                    &mut current,
                    Thread {
                        pc: self.start,
                        slots: blank.clone(),
                    },
                    pos,
                    text.len(),
                    &mut seen,
                    &mut pending,
                );
            }
            if current.is_empty() {
                if found.is_some() {
                    break;
                }
                continue;
            }
            seen.fill(false);
            for t in current.drain(..) {
                match &self.code[t.pc] {
                    Inst::Match => {
                        found = Some(t.slots);
                        break;
                    }
                    Inst::Char(class, n) if ch.is_some_and(|c| class.accepts(c, self.fold)) => self
                        .add(
                            &mut next,
                            Thread {
                                pc: *n,
                                slots: t.slots,
                            },
                            pos + ch.unwrap().len_utf8(),
                            text.len(),
                            &mut seen,
                            &mut pending,
                        ),
                    _ => {}
                }
            }
            std::mem::swap(&mut current, &mut next);
            if found.is_some() && current.is_empty() {
                break;
            }
        }
        found.map(|slots| Captures {
            text,
            names: &self.names,
            slots: Rc::unwrap_or_clone(slots),
        })
    }
    pub fn is_match(&self, text: &str) -> bool {
        self.captures_at(text, 0).is_some()
    }
}

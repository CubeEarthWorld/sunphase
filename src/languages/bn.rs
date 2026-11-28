use std::borrow::Cow;

use crate::{Component, Language, Pattern};

// Bengali letters, vowel signs, and combining marks (`U+0980..=U+09E3`, `U+09F0..=U+09F1`, `U+09FC`),
// excluding Bengali digits (`০-৯` U+09E6..=U+09EF, normalized to ASCII 0-9),
// currency/fraction symbols (`U+09F2..=U+09FB`, e.g. `৳`), abbreviation sign (`U+09FD`),
// and danda punctuation (`।` U+0964, `॥` U+0965).
const NON_DIGIT_WORD_CHAR: &str = "[a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]";
const WORD_CHAR: &str = "[0-9a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]";
const COLON_WORD_CHAR: &str = "[0-9:a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]";

const BN_GUARDS: &[(&str, bool, &str)] = &[
    ("guard0", true, WORD_CHAR),
    ("guard1", false, NON_DIGIT_WORD_CHAR),
];
const WORD_GUARDS: &[(&str, bool, &str)] =
    &[("guard0", true, WORD_CHAR), ("guard1", false, WORD_CHAR)];
const DATE_GUARDS: &[(&str, bool, &str)] = &[
    (
        "guard0",
        true,
        "[0-9./\\-a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]",
    ),
    (
        "guard1",
        false,
        "(?:[0-9:/a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]|\\.[0-9]|-[0-9])",
    ),
];

const WEEKDAYS: &[(&str, &[Component])] = &[
    ("সোমবারের", &[Component::Weekday(1)]),
    ("সোমবারে", &[Component::Weekday(1)]),
    ("সোমবার", &[Component::Weekday(1)]),
    ("সোম.", &[Component::Weekday(1)]),
    ("মঙ্গলবারের", &[Component::Weekday(2)]),
    ("মঙ্গলবারে", &[Component::Weekday(2)]),
    ("মঙ্গলবার", &[Component::Weekday(2)]),
    ("মঙ্গল.", &[Component::Weekday(2)]),
    ("বুধবারের", &[Component::Weekday(3)]),
    ("বুধবারে", &[Component::Weekday(3)]),
    ("বুধবার", &[Component::Weekday(3)]),
    ("বুধ.", &[Component::Weekday(3)]),
    ("বৃহস্পতিবারের", &[Component::Weekday(4)]),
    ("বৃহস্পতিবারে", &[Component::Weekday(4)]),
    ("বৃহস্পতিবার", &[Component::Weekday(4)]),
    ("বৃহঃবারের", &[Component::Weekday(4)]),
    ("বৃহঃবারে", &[Component::Weekday(4)]),
    ("বৃহঃবার", &[Component::Weekday(4)]),
    ("বৃহঃ.", &[Component::Weekday(4)]),
    ("বৃহঃ", &[Component::Weekday(4)]),
    ("বৃহ.", &[Component::Weekday(4)]),
    ("গুরুবারের", &[Component::Weekday(4)]),
    ("গুরুবারে", &[Component::Weekday(4)]),
    ("গুরুবার", &[Component::Weekday(4)]),
    ("শুক্রবারের", &[Component::Weekday(5)]),
    ("শুক্রবারে", &[Component::Weekday(5)]),
    ("শুক্রবার", &[Component::Weekday(5)]),
    ("শুক্র.", &[Component::Weekday(5)]),
    ("শনিবারের", &[Component::Weekday(6)]),
    ("শনিবারে", &[Component::Weekday(6)]),
    ("শনিবার", &[Component::Weekday(6)]),
    ("শনি.", &[Component::Weekday(6)]),
    ("রবিবারের", &[Component::Weekday(7)]),
    ("রবিবারে", &[Component::Weekday(7)]),
    ("রবিবার", &[Component::Weekday(7)]),
    ("রবি.", &[Component::Weekday(7)]),
    ("রোববারের", &[Component::Weekday(7)]),
    ("রোববারে", &[Component::Weekday(7)]),
    ("রোববার", &[Component::Weekday(7)]),
];

const MONTHS: &[(&str, &[Component])] = &[
    ("জানুয়ারির", &[Component::Month(1)]),
    ("জানুয়ারিতে", &[Component::Month(1)]),
    ("জানুয়ারি", &[Component::Month(1)]),
    ("জানুয়ারীর", &[Component::Month(1)]),
    ("জানুয়ারীতে", &[Component::Month(1)]),
    ("জানুয়ারী", &[Component::Month(1)]),
    ("জানুয\u{09BC}ারির", &[Component::Month(1)]),
    ("জানুয\u{09BC}ারিতে", &[Component::Month(1)]),
    ("জানুয\u{09BC}ারি", &[Component::Month(1)]),
    ("জানুয\u{09BC}ারীর", &[Component::Month(1)]),
    ("জানুয\u{09BC}ারীতে", &[Component::Month(1)]),
    ("জানুয\u{09BC}ারী", &[Component::Month(1)]),
    ("জানু.", &[Component::Month(1)]),
    ("জানু", &[Component::Month(1)]),
    ("ফেব্রুয়ারির", &[Component::Month(2)]),
    ("ফেব্রুয়ারিতে", &[Component::Month(2)]),
    ("ফেব্রুয়ারি", &[Component::Month(2)]),
    ("ফেব্রুয়ারীর", &[Component::Month(2)]),
    ("ফেব্রুয়ারীতে", &[Component::Month(2)]),
    ("ফেব্রুয়ারী", &[Component::Month(2)]),
    ("ফেব্রুয\u{09BC}ারির", &[Component::Month(2)]),
    ("ফেব্রুয\u{09BC}ারিতে", &[Component::Month(2)]),
    ("ফেব্রুয\u{09BC}ারি", &[Component::Month(2)]),
    ("ফেব্রুয\u{09BC}ারীর", &[Component::Month(2)]),
    ("ফেব্রুয\u{09BC}ারীতে", &[Component::Month(2)]),
    ("ফেব্রুয\u{09BC}ারী", &[Component::Month(2)]),
    ("ফেব্রু.", &[Component::Month(2)]),
    ("ফেব্রু", &[Component::Month(2)]),
    ("ফেব.", &[Component::Month(2)]),
    ("ফেব", &[Component::Month(2)]),
    ("মার্চের", &[Component::Month(3)]),
    ("মার্চে", &[Component::Month(3)]),
    ("মার্চ", &[Component::Month(3)]),
    ("মার.", &[Component::Month(3)]),
    ("অ্যাপ্রিলের", &[Component::Month(4)]),
    ("অ্যাপ্রিলে", &[Component::Month(4)]),
    ("অ্যাপ্রিল", &[Component::Month(4)]),
    ("এপ্রিলের", &[Component::Month(4)]),
    ("এপ্রিলে", &[Component::Month(4)]),
    ("এপ্রিল", &[Component::Month(4)]),
    ("এপ্রি.", &[Component::Month(4)]),
    ("এপ্রি", &[Component::Month(4)]),
    ("এপ্র.", &[Component::Month(4)]),
    ("মে", &[Component::Month(5)]),
    ("জুনের", &[Component::Month(6)]),
    ("জুনে", &[Component::Month(6)]),
    ("জুন", &[Component::Month(6)]),
    ("জুলাইয়ের", &[Component::Month(7)]),
    ("জুলাইয়ে", &[Component::Month(7)]),
    ("জুলাইয\u{09BC}ের", &[Component::Month(7)]),
    ("জুলাইয\u{09BC}ে", &[Component::Month(7)]),
    ("জুলাইতে", &[Component::Month(7)]),
    ("জুলাইর", &[Component::Month(7)]),
    ("জুলাই", &[Component::Month(7)]),
    ("জুল.", &[Component::Month(7)]),
    ("জুল", &[Component::Month(7)]),
    ("আগস্টের", &[Component::Month(8)]),
    ("আগস্টে", &[Component::Month(8)]),
    ("আগস্ট", &[Component::Month(8)]),
    ("অগাস্টের", &[Component::Month(8)]),
    ("অগাস্টে", &[Component::Month(8)]),
    ("অগাস্ট", &[Component::Month(8)]),
    ("আগষ্টের", &[Component::Month(8)]),
    ("আগষ্টে", &[Component::Month(8)]),
    ("আগষ্ট", &[Component::Month(8)]),
    ("অগস্টের", &[Component::Month(8)]),
    ("অগস্টে", &[Component::Month(8)]),
    ("অগস্ট", &[Component::Month(8)]),
    ("অগষ্টের", &[Component::Month(8)]),
    ("অগষ্টে", &[Component::Month(8)]),
    ("অগষ্ট", &[Component::Month(8)]),
    ("আগ.", &[Component::Month(8)]),
    ("অগ.", &[Component::Month(8)]),
    ("সেপ্টেম্বরের", &[Component::Month(9)]),
    ("সেপ্টেম্বরে", &[Component::Month(9)]),
    ("সেপ্টেম্বর", &[Component::Month(9)]),
    ("সেপ্টেম্বার", &[Component::Month(9)]),
    ("সেপটেম্বরের", &[Component::Month(9)]),
    ("সেপটেম্বরে", &[Component::Month(9)]),
    ("সেপটেম্বর", &[Component::Month(9)]),
    ("সেপ্টে.", &[Component::Month(9)]),
    ("সেপ্টে", &[Component::Month(9)]),
    ("সেপ্ট.", &[Component::Month(9)]),
    ("সেপ্ট", &[Component::Month(9)]),
    ("সেপ.", &[Component::Month(9)]),
    ("সেপ", &[Component::Month(9)]),
    ("অক্টোবরের", &[Component::Month(10)]),
    ("অক্টোবরে", &[Component::Month(10)]),
    ("অক্টোবর", &[Component::Month(10)]),
    ("অক্টোবার", &[Component::Month(10)]),
    ("অকটোবরের", &[Component::Month(10)]),
    ("অকটোবরে", &[Component::Month(10)]),
    ("অকটোবর", &[Component::Month(10)]),
    ("অক্টো.", &[Component::Month(10)]),
    ("অক্টো", &[Component::Month(10)]),
    ("অক্ট.", &[Component::Month(10)]),
    ("অক্ট", &[Component::Month(10)]),
    ("নভেম্বরের", &[Component::Month(11)]),
    ("নভেম্বরে", &[Component::Month(11)]),
    ("নভেম্বর", &[Component::Month(11)]),
    ("নভেম্বার", &[Component::Month(11)]),
    ("নভে.", &[Component::Month(11)]),
    ("নভে", &[Component::Month(11)]),
    ("নভ.", &[Component::Month(11)]),
    ("নভ", &[Component::Month(11)]),
    ("ডিসেম্বরের", &[Component::Month(12)]),
    ("ডিসেম্বরে", &[Component::Month(12)]),
    ("ডিসেম্বর", &[Component::Month(12)]),
    ("ডিসেম্বার", &[Component::Month(12)]),
    ("ডিসে.", &[Component::Month(12)]),
    ("ডিসে", &[Component::Month(12)]),
    ("ডিস.", &[Component::Month(12)]),
    ("ডিস", &[Component::Month(12)]),
];

const WEEKDAY_ALT: &str = "বৃহস্পতিবারের|বৃহস্পতিবারে|বৃহস্পতিবার|বৃহস্পতি\\s+বারের|বৃহস্পতি\\s+বারে|বৃহস্পতি\\s+বার|বৃহঃবারের|বৃহঃবারে|বৃহঃবার|বৃহঃ\\.?|বৃহ\\.|মঙ্গলবারের|মঙ্গলবারে|মঙ্গলবার|মঙ্গল\\.|শুক্রবারের|শুক্রবারে|শুক্রবার|শুক্র\\.|সোমবারের|সোমবারে|সোমবার|সোম\\.|বুধবারের|বুধবারে|বুধবার|বুধ\\.|গুরুবারের|গুরুবারে|গুরুবার|শনিবারের|শনিবারে|শনিবার|শনি\\.|রবিবারের|রবিবারে|রবিবার|রোববারের|রোববারে|রোববার|রবি\\.";

const MONTH_ALT: &str = "জানু(?:য়|য\u{09BC})ারির|জানু(?:য়|য\u{09BC})ারিতে|জানু(?:য়|য\u{09BC})ারি|জানু(?:য়|য\u{09BC})ারীর|জানু(?:য়|য\u{09BC})ারীতে|জানু(?:য়|য\u{09BC})ারী|জানু\\.?|ফেব্রু(?:য়|য\u{09BC})ারির|ফেব্রু(?:য়|য\u{09BC})ারিতে|ফেব্রু(?:য়|য\u{09BC})ারি|ফেব্রু(?:য়|য\u{09BC})ারীর|ফেব্রু(?:য়|য\u{09BC})ারীতে|ফেব্রু(?:য়|য\u{09BC})ারী|ফেব্রু\\.?|ফেব\\.?|অ্যাপ্রিলের|অ্যাপ্রিলে|অ্যাপ্রিল|এপ্রিলের|এপ্রিলে|এপ্রিল|এপ্রি\\.?|এপ্র\\.|সেপ্টেম্বরের|সেপ্টেম্বরে|সেপ্টেম্বর|সেপ্টেম্বার|সেপটেম্বরের|সেপটেম্বরে|সেপটেম্বর|সেপ্টে\\.?|সেপ্ট\\.?|সেপ\\.?|অক্টোবরের|অক্টোবরে|অক্টোবর|অক্টোবার|অকটোবরের|অকটোবরে|অকটোবর|অক্টো\\.?|অক্ট\\.?|নভেম্বরের|নভেম্বরে|নভেম্বর|নভেম্বার|নভে\\.?|নভ\\.?|ডিসেম্বরের|ডিসেম্বরে|ডিসেম্বর|ডিসেম্বার|ডিসে\\.?|ডিস\\.?|জুলাই(?:য়ে|য\u{09BC}ে)র|জুলাই(?:য়ে|য\u{09BC}ে)|জুলাইতে|জুলাইর|জুলাই|জুল\\.?|আগস্টের|আগস্টে|আগস্ট|অগাস্টের|অগাস্টে|অগাস্ট|আগষ্টের|আগষ্টে|আগষ্ট|অগস্টের|অগস্টে|অগস্ট|অগষ্টের|অগষ্টে|অগষ্ট|আগ\\.|অগ\\.|মার্চের|মার্চে|মার্চ|মার\\.|জুনের|জুনে|জুন|মে";

// Calendar date ordinals (তারিখবাচক শব্দ 1..=31).
const ORD_DAY_ALT: &str = "একত্রিশে|ঊনত্রিশে|উনত্রিশে|আঠারোই|আঠারই|পনেরোই|পনেরই|সতেরোই|সতেরই|চব্বিশে|ছাব্বিশে|তিরিশে|এগারোই|এগারই|তেরোই|তেরই|চৌদ্দই|ষোলোই|ষোলই|কু(?:ড়|ড\u{09BC})িই|একুশে|বাইশে|তেইশে|পঁচিশে|সাতাশে|আটাশে|পহেলা|প(?:য়|য\u{09BC})লা|দোসরা|দুসরা|তেসরা|তিসরা|চৌঠা|চউঠা|বারোই|বারই|পাঁচই|ত্রিশে|বিশে|উনিশে|ছ(?:য়|য\u{09BC})ই|সাতই|আটই|ন(?:য়|য\u{09BC})ই|দশই";

// Bengali cardinal number words 1..=31 (longest alternatives first).
const WORD_NUM_1_31: &str = "একত্রিশ|ঊনত্রিশ|উনত্রিশ|পনেরো|সতেরো|আঠারো|চব্বিশ|ছাব্বিশ|তিরিশ|এগারো|পনের|সতের|আঠার|একুশ|বাইশ|তেইশ|পঁচিশ|সাতাশ|আটাশ|কু(?:ড়|ড\u{09BC})ি|এগার|বারো|তেরো|চৌদ্দ|ষোলো|উনিশ|ত্রিশ|প্রথম|দ্বিতী(?:য়|য\u{09BC})|তৃতী(?:য়|য\u{09BC})|চতুর্থ|পঞ্চম|ষষ্ঠ|সপ্তম|অষ্টম|নবম|দশম|পাঁচ|ছ(?:য়|য\u{09BC})|সাত|আট|ন(?:য়|য\u{09BC})|দশ|বার|তের|ষোল|বিশ|দুই|তিন|চার|এক";

// Bengali cardinal number words 1..=59 (longest alternatives first).
const WORD_NUM_1_59: &str = "পঁ(?:য়|য\u{09BC})তাল্লিশ|ঊনচল্লিশ|উনচল্লিশ|একচল্লিশ|বি(?:য়|য\u{09BC})াল্লিশ|তেতাল্লিশ|চু(?:য়|য\u{09BC})াল্লিশ|ছেচল্লিশ|সাতচল্লিশ|আটচল্লিশ|ঊনপঞ্চাশ|উনপঞ্চাশ|পঁ(?:য়|য\u{09BC})ত্রিশ|সাঁইত্রিশ|সাইত্রিশ|ছাপ্পান্ন|একত্রিশ|ঊনত্রিশ|উনত্রিশ|বত্রিশ|তেত্রিশ|চৌত্রিশ|ছত্রিশ|আটত্রিশ|চল্লিশ|পঞ্চাশ|একান্ন|বাহান্ন|তিপ্পান্ন|চু(?:য়|য\u{09BC})ান্ন|পঞ্চান্ন|সাতান্ন|আটান্ন|ঊনষাট|উনষাট|পনেরো|সতেরো|আঠারো|চব্বিশ|ছাব্বিশ|তিরিশ|এগারো|পনের|সতের|আঠার|একুশ|বাইশ|তেইশ|পঁচিশ|সাতাশ|আটাশ|কু(?:ড়|ড\u{09BC})ি|এগার|বারো|তেরো|চৌদ্দ|ষোলো|উনিশ|ত্রিশ|পাঁচ|ছ(?:য়|য\u{09BC})|সাত|আট|ন(?:য়|য\u{09BC})|দশ|বার|তের|ষোল|বিশ|দুই|তিন|চার|এক|ছ['’]|ন['’]";

// Bengali cardinal number words for offsets/within (1..=100, longest first).
const WORD_NUM_ANY: &str = "পঁ(?:য়|য\u{09BC})তাল্লিশ|ঊনচল্লিশ|উনচল্লিশ|একচল্লিশ|বি(?:য়|য\u{09BC})াল্লিশ|তেতাল্লিশ|চু(?:য়|য\u{09BC})াল্লিশ|ছেচল্লিশ|সাতচল্লিশ|আটচল্লিশ|ঊনপঞ্চাশ|উনপঞ্চাশ|পঁ(?:য়|য\u{09BC})ত্রিশ|সাঁইত্রিশ|সাইত্রিশ|ছাপ্পান্ন|একত্রিশ|ঊনত্রিশ|উনত্রিশ|বত্রিশ|তেত্রিশ|চৌত্রিশ|ছত্রিশ|আটত্রিশ|চল্লিশ|পঞ্চাশ|একান্ন|বাহান্ন|তিপ্পান্ন|চু(?:য়|য\u{09BC})ান্ন|পঞ্চান্ন|সাতান্ন|আটান্ন|ঊনষাট|উনষাট|পনেরো|সতেরো|আঠারো|চব্বিশ|ছাব্বিশ|তিরিশ|এগারো|একশো|একশ|পনের|সতের|আঠার|একুশ|বাইশ|তেইশ|পঁচিশ|সাতাশ|আটাশ|সত্তর|নব্বই|কু(?:ড়|ড\u{09BC})ি|এগার|বারো|তেরো|চৌদ্দ|ষোলো|উনিশ|ত্রিশ|আশি|পাঁচ|ছ(?:য়|য\u{09BC})|সাত|আট|ন(?:য়|য\u{09BC})|দশ|বার|তের|ষোল|বিশ|ষাট|দুই|তিন|চার|এক|দু['’]?|ছ['’]|ন['’]";

const HOUR_WORD_NO_EKTA: &str = "এগারো|এগার|বারো|বার|তেরো|তের|চৌদ্দ|পনেরো|পনের|ষোলো|ষোল|সতেরো|সতের|আঠারো|আঠার|উনিশ|বিশ|একুশ|বাইশ|তেইশ|দুটো|তিনটে|চারটে|দুই|দু['’]?|তিন|চার|পাঁচ|ছ(?:য়|য\u{09BC})|ছ['’]?|সাত|আট|ন(?:য়|য\u{09BC})|ন['’]?|দশ";
const HOUR_ALT: &str = "(?:[0-9]{1,2}|এগারো|এগার|বারো|বার|তেরো|তের|চৌদ্দ|পনেরো|পনের|ষোলো|ষোল|সতেরো|সতের|আঠারো|আঠার|উনিশ|বিশ|একুশ|বাইশ|তেইশ|একটা|দুটো|তিনটে|চারটে|দুই|দু['’]?|তিন|চার|পাঁচ|ছ(?:য়|য\u{09BC})|ছ['’]?|সাত|আট|ন(?:য়|য\u{09BC})|ন['’]?|দশ|এক)";
const HOUR_ALT_NO_EKTA: &str = "(?:[0-9]{1,2}|এগারো|এগার|বারো|বার|তেরো|তের|চৌদ্দ|পনেরো|পনের|ষোলো|ষোল|সতেরো|সতের|আঠারো|আঠার|উনিশ|বিশ|একুশ|বাইশ|তেইশ|দুটো|তিনটে|চারটে|দুই|দু['’]?|তিন|চার|পাঁচ|ছ(?:য়|য\u{09BC})|ছ['’]?|সাত|আট|ন(?:য়|য\u{09BC})|ন['’]?|দশ)";

const TIME_SUFFIX: &str = "(?:টা(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|টে(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|টো(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|বাজে)";
const BN_DAY_GUARD1: &str = "(?:[:0-9a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}%$৳]|\\.[0-9]|/[0-9]|-[0-9]|\\s*(?:জানু|ফেব|মার্চ|মার\\.|এপ্রি|অ্যাপ্রিল|মে(?:[\\s,.]|$)|জুন|জুল|আগ|অগ|সেপ্ট|সেপ|অক্টো|অক্ট|নভে|নভ|ডিসে|ডিস|টা|টে|টো|বাজে|দিন|সপ্তাহ|হপ্তা|মাস|বছর|বৎসর|সাল))";
const TIME_MIN_GUARD1: &str = "(?:[0-9:a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]|\\s*(?:তারিখ(?:ের|ে)?|দিন(?:ের|ে)?|সপ্তাহ(?:ের|ে)?|হপ্তা(?:(?:য়|য\u{09BC})|র)?|মাস(?:ের|ে)?|বছর(?:ের|ে)?|বৎসর(?:ের|ে)?|সাল(?:ের|ে)?|ঘণ্টা|ঘন্টা|সেকেন্ড|টাকা|জন|বার|টি|টা|জানু(?:য়|য\u{09BC})ারি|ফেব্রু(?:য়|য\u{09BC})ারি|মার্চ|এপ্রিল|অ্যাপ্রিল|মে|জুন|জুলাই|আগস্ট|অগাস্ট|আগষ্ট|অগস্ট|অগষ্ট|সেপ্টেম্বর|অক্টোবর|নভেম্বর|ডিসেম্বর))";
const BN_HOUR_GUARD1: &str = "(?:[0-9a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]|\\s*(?:বেজে\\s*)?(?:[0-9]+|পঁ(?:য়|য\u{09BC})তাল্লিশ|ঊনচল্লিশ|উনচল্লিশ|একচল্লিশ|বি(?:য়|য\u{09BC})াল্লিশ|তেতাল্লিশ|চু(?:য়|য\u{09BC})াল্লিশ|ছেচল্লিশ|সাতচল্লিশ|আটচল্লিশ|ঊনপঞ্চাশ|উনপঞ্চাশ|পঁ(?:য়|য\u{09BC})ত্রিশ|সাঁইত্রিশ|সাইত্রিশ|ছাপ্পান্ন|একত্রিশ|ঊনত্রিশ|উনত্রিশ|বত্রিশ|তেত্রিশ|চৌত্রিশ|ছত্রিশ|আটত্রিশ|চল্লিশ|পঞ্চাশ|একান্ন|বাহান্ন|তিপ্পান্ন|চু(?:য়|য\u{09BC})ান্ন|পঞ্চান্ন|সাতান্ন|আটান্ন|ঊনষাট|উনষাট|পনেরো|সতেরো|আঠারো|চব্বিশ|ছাব্বিশ|তিরিশ|এগারো|একশো|একশ|পনের|সতের|আঠার|একুশ|বাইশ|তেইশ|পঁচিশ|সাতাশ|আটাশ|সত্তর|নব্বই|কু(?:ড়|ড\u{09BC})ি|এগার|বারো|তেরো|চৌদ্দ|ষোলো|উনিশ|ত্রিশ|আশি|পাঁচ|ছ(?:য়|য\u{09BC})|সাত|আট|ন(?:য়|য\u{09BC})|দশ|বার|তের|ষোল|বিশ|ষাট|দুই|তিন|চার|এক|ছ['’]|ন['’])\\s*মিনিট)";

fn norm_nukta(s: &str) -> Cow<'_, str> {
    if !s.contains('\u{09BC}') {
        return Cow::Borrowed(s);
    }
    Cow::Owned(
        s.replace("য\u{09BC}", "য়")
            .replace("ড\u{09BC}", "ড়")
            .replace("ঢ\u{09BC}", "ঢ়"),
    )
}

fn lookup_weekday(s: &str) -> Option<i32> {
    let norm = norm_nukta(s);
    let compact: String;
    let key = if norm.contains(char::is_whitespace) {
        compact = norm.split_whitespace().collect();
        compact.as_str()
    } else {
        norm.as_ref()
    };
    if let Some((_, cs)) = WEEKDAYS.iter().find(|(w, _)| crate::eq_word(key, w)) {
        return match cs.first()? {
            Component::Weekday(n) => Some(*n),
            _ => None,
        };
    }
    match key {
        "বৃহস্পতিবারের" | "বৃহস্পতিবারে" | "বৃহস্পতিবার" => {
            Some(4)
        }
        _ => None,
    }
}

fn lookup_month(s: &str) -> Option<i32> {
    let norm = norm_nukta(s);
    MONTHS
        .iter()
        .find(|(w, _)| crate::eq_word(norm.as_ref(), w))
        .and_then(|(_, cs)| match cs.first()? {
            Component::Month(n) => Some(*n),
            _ => None,
        })
}

fn bn_number(s: &str) -> Option<i32> {
    let norm = norm_nukta(s.trim());
    let cleaned = norm.trim_matches(|c| matches!(c, '\'' | '’'));
    if let Some(n) = crate::number(cleaned) {
        return Some(n);
    }
    if cleaned.as_bytes().first().is_some_and(u8::is_ascii_digit) {
        for suffix in ["লা", "রা", "ঠা", "ই", "শে", "এ", "তম", "ম", "য়", "র্থ", "ষ্ঠ"]
        {
            if let Some(stem) = cleaned.strip_suffix(suffix) {
                let stem = stem.trim().trim_end_matches('-').trim();
                return crate::number(stem);
            }
        }
    }
    let stem = cleaned.strip_suffix("তম").unwrap_or(cleaned);
    Some(match stem {
        "শূন্য" | "শুন্য" => 0,
        "এক" | "পহেলা" | "পয়লা" | "প্রথম" | "একটা" | "একটায়" | "একটার" => {
            1
        }
        "দুই" | "দু" | "দোসরা" | "দুসরা" | "দ্বিতীয়" | "দুটো" | "দুটোয়" | "দুটোর" => {
            2
        }
        "তিন" | "তেসরা" | "তিসরা" | "তৃতীয়" | "তিনটে" | "তিনটেয়" | "তিনটের" => {
            3
        }
        "চার" | "চৌঠা" | "চউঠা" | "চতুর্থ" | "চারটে" | "চারটেয়" | "চারটের" => {
            4
        }
        "পাঁচ" | "পাঁচই" | "পঞ্চম" => 5,
        "ছয়" | "ছ" | "ছয়ই" | "ছই" | "ষষ্ঠ" => 6,
        "সাত" | "সাতই" | "সপ্তম" => 7,
        "আট" | "আটই" | "অষ্টম" => 8,
        "নয়" | "ন" | "নয়ই" | "নই" | "নবম" => 9,
        "দশ" | "দশই" | "দশম" => 10,
        "এগারো" | "এগার" | "এগারোই" | "এগারই" | "একাদশ" => {
            11
        }
        "বারো" | "বার" | "বারোই" | "বারই" | "দ্বাদশ" => {
            12
        }
        "তেরো" | "তের" | "তেরোই" | "তেরই" | "ত্রয়োদশ" => {
            13
        }
        "চৌদ্দ" | "চৌদ্দই" | "চতুর্দশ" => 14,
        "পনেরো" | "পনের" | "পনেরোই" | "পনেরই" | "পঞ্চদশ" => {
            15
        }
        "ষোলো" | "ষোল" | "ষোলোই" | "ষোলই" | "ষোড়শ" => 16,
        "সতেরো" | "সতের" | "সতেরোই" | "সতেরই" | "সপ্তদশ" => {
            17
        }
        "আঠারো" | "আঠার" | "আঠারোই" | "আঠারই" | "অষ্টাদশ" => {
            18
        }
        "উনিশ" | "উনিশে" => 19,
        "বিশ" | "বিশে" | "কুড়ি" | "কুড়িই" => 20,
        "একুশ" | "একুশে" => 21,
        "বাইশ" | "বাইশে" => 22,
        "তেইশ" | "তেইশে" => 23,
        "চব্বিশ" | "চব্বিশে" => 24,
        "পঁচিশ" | "পঁচিশে" => 25,
        "ছাব্বিশ" | "ছাব্বিশে" => 26,
        "সাতাশ" | "সাতাশে" => 27,
        "আটাশ" | "আটাশে" => 28,
        "ঊনত্রিশ" | "উনত্রিশ" | "ঊনত্রিশে" | "উনত্রিশে" => {
            29
        }
        "ত্রিশ" | "তিরিশ" | "ত্রিশে" | "তিরিশে" => 30,
        "একত্রিশ" | "একত্রিশে" => 31,
        "বত্রিশ" => 32,
        "তেত্রিশ" => 33,
        "চৌত্রিশ" => 34,
        "পঁয়ত্রিশ" => 35,
        "ছত্রিশ" => 36,
        "সাঁইত্রিশ" | "সাইত্রিশ" => 37,
        "আটত্রিশ" => 38,
        "ঊনচল্লিশ" | "উনচল্লিশ" => 39,
        "চল্লিশ" => 40,
        "একচল্লিশ" => 41,
        "বিয়াল্লিশ" => 42,
        "তেতাল্লিশ" => 43,
        "চুয়াল্লিশ" => 44,
        "পঁয়তাল্লিশ" => 45,
        "ছেচল্লিশ" => 46,
        "সাতচল্লিশ" => 47,
        "আটচল্লিশ" => 48,
        "ঊনপঞ্চাশ" | "উনপঞ্চাশ" => 49,
        "পঞ্চাশ" => 50,
        "একান্ন" => 51,
        "বাহান্ন" => 52,
        "তিপ্পান্ন" => 53,
        "চুয়ান্ন" => 54,
        "পঞ্চান্ন" => 55,
        "ছাপ্পান্ন" => 56,
        "সাতান্ন" => 57,
        "আটান্ন" => 58,
        "ঊনষাট" | "উনষাট" => 59,
        "ষাট" => 60,
        "সত্তর" => 70,
        "আশি" => 80,
        "নব্বই" => 90,
        "একশ" | "একশো" => 100,
        _ => return None,
    })
}

fn parse_bn_hour_word(s: &str) -> Option<i32> {
    let norm = norm_nukta(s.trim());
    let mut base = norm.as_ref();
    if let Some(prefix) = base.strip_suffix("বাজে") {
        base = prefix.trim();
    }
    for sfx in ["টায়", "টার", "টা", "টেয়", "টের", "টে", "টোয়", "টোর", "টো"]
    {
        if let Some(prefix) = base.strip_suffix(sfx) {
            base = prefix.trim();
            break;
        }
    }
    bn_number(base)
}

fn parse_2_or_4_year(s: &str) -> Option<i32> {
    if s.len() != 2 && s.len() != 4 {
        return None;
    }
    let y = crate::number(s)?;
    Some(if s.len() == 2 {
        if y >= 70 { 1900 + y } else { 2000 + y }
    } else {
        y
    })
}

fn triple_group<'t>(
    c: &crate::Captures<'t>,
    a: &str,
    b: &str,
    d: &str,
) -> Option<(&'t str, &'t str, &'t str)> {
    Some((
        c.name(a)?.as_str(),
        c.name(b)?.as_str(),
        c.name(d)?.as_str(),
    ))
}

pub fn language() -> Language {
    Language::new(
        "bn",
        "(?:\\s+(?:তারিখ(?:ের|ে)?|রোজ|বেলা(?:য়|য\u{09BC})?|সময়(?:ে)?|সময\u{09BC}(?:ে)?)\\s+|[\\s,]+)+",
        vec![
            Pattern::with_builder(
                "bn_numericDate",
                "(?P<guard0>)(?:(?P<y1>[0-9]{4})-(?P<m1>[0-9]{1,2})-(?P<d1>[0-9]{1,2})|(?P<y2>[0-9]{4})/(?P<m2>[0-9]{1,2})/(?P<d2>[0-9]{1,2})|(?P<y3>[0-9]{4})\\.(?P<m3>[0-9]{1,2})\\.(?P<d3>[0-9]{1,2})|(?P<d4>[0-9]{1,2})/(?P<m4>[0-9]{1,2})/(?P<y4>[0-9]{4}|[0-9]{2})|(?P<d5>[0-9]{1,2})-(?P<m5>[0-9]{1,2})-(?P<y5>[0-9]{4}|[0-9]{2})|(?P<d6>[0-9]{1,2})\\.(?P<m6>[0-9]{1,2})\\.(?P<y6>[0-9]{4}|[0-9]{2})|(?P<sd>[0-9]{1,2})/(?P<sm>0[1-9]|1[0-2]))(?P<guard1>)",
                DATE_GUARDS,
                |c, _| {
                    if let Some((ys, ms, ds)) = triple_group(c, "y1", "m1", "d1")
                        .or_else(|| triple_group(c, "y2", "m2", "d2"))
                        .or_else(|| triple_group(c, "y3", "m3", "d3"))
                    {
                        return Some(vec![
                            Component::Year(crate::number(ys)?),
                            Component::Month(crate::number(ms)?),
                            Component::Day(crate::number(ds)?),
                        ]);
                    }
                    if let Some((ds, ms, ys)) = triple_group(c, "d4", "m4", "y4")
                        .or_else(|| triple_group(c, "d5", "m5", "y5"))
                        .or_else(|| triple_group(c, "d6", "m6", "y6"))
                    {
                        return Some(vec![
                            Component::Year(parse_2_or_4_year(ys)?),
                            Component::Month(crate::number(ms)?),
                            Component::Day(crate::number(ds)?),
                        ]);
                    }
                    let d = crate::number(c.name("sd")?.as_str())?;
                    let m = crate::number(c.name("sm")?.as_str())?;
                    Some(vec![Component::Month(m), Component::Day(d)])
                },
            ),
            Pattern::with_builder(
                "bn_nthWeekday",
                &format!(
                    "(?P<guard0>)(?P<month>{MONTH_ALT})(?:\\s+মাস(?:ের|ে)?|\\s+এর)?\\s+(?P<ord>সর্বশেষ|শেষের|অন্তিম|আখেরি|শেষ|প্রথম|1ম|দ্বিতী(?:য়|য\u{09BC})|2(?:য়|য\u{09BC})|তৃতী(?:য়|য\u{09BC})|3(?:য়|য\u{09BC})|চতুর্থ|4র্থ|পঞ্চম|5ম)\\s+(?P<wd>{WEEKDAY_ALT})(?P<guard1>)"
                ),
                BN_GUARDS,
                |c, _| {
                    let month = lookup_month(c.name("month")?.as_str())?;
                    let ord_raw = norm_nukta(c.name("ord")?.as_str());
                    let ord = match ord_raw.as_ref() {
                        "প্রথম" | "1ম" => 1,
                        "দ্বিতীয়" | "2য়" => 2,
                        "তৃতীয়" | "3য়" => 3,
                        "চতুর্থ" | "4র্থ" => 4,
                        "পঞ্চম" | "5ম" => 5,
                        "শেষ" | "সর্বশেষ" | "অন্তিম" | "আখেরি" | "শেষের" => {
                            -1
                        }
                        _ => return None,
                    };
                    let wd = lookup_weekday(c.name("wd")?.as_str())?;
                    Some(vec![Component::Nth(ord, wd, month)])
                },
            ),
            Pattern::with_builder(
                "bn_dayMonth",
                &format!(
                    "(?P<guard0>)(?P<d>[0-9]{{1,2}}(?:-?\\s*(?:লা|রা|ঠা|ই|শে|এ|তম|ম|(?:য়|য\u{09BC})|র্থ|ষ্ঠ))?|{ORD_DAY_ALT}|{WORD_NUM_1_31})(?:\\s+|[-/])(?P<m>{MONTH_ALT})(?P<guard1>)(?:(?:\\s*,\\s*|\\s+)(?P<y>(?:1[0-9]{{3}}|2[0-9]{{3}}))(?:\\s*সাল(?:ের|ে)?)?)?(?:\\s*তারিখ(?:ের|ে)?)?(?P<guard2>)"
                ),
                &[
                    (
                        "guard0",
                        true,
                        "[0-9.a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]",
                    ),
                    ("guard1", false, NON_DIGIT_WORD_CHAR),
                    ("guard2", false, COLON_WORD_CHAR),
                ],
                |c, _| {
                    let d = bn_number(c.name("d")?.as_str())?;
                    if !(1..=31).contains(&d) {
                        return None;
                    }
                    let m = lookup_month(c.name("m")?.as_str())?;
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(ym) = c.name("y") {
                        out.push(Component::Year(crate::number(ym.as_str())?));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "bn_monthDay",
                &format!(
                    "(?P<guard0>)(?P<m>{MONTH_ALT})(?:\\s+মাস(?:ের|ে)?|\\s+এর)?\\s+(?:(?P<d1>[0-9]{{1,2}}(?:-?(?:লা|রা|ঠা|ই|শে|এ|তম|ম|(?:য়|য\u{09BC})|র্থ|ষ্ঠ))?)(?:\\s*তারিখ(?:ের|ে)?)?|(?P<d2>{ORD_DAY_ALT})(?:\\s*তারিখ(?:ের|ে)?)?|(?P<d3>{WORD_NUM_1_31})\\s*তারিখ(?:ের|ে)?)(?P<guard1>)(?:(?:\\s*,\\s*|\\s+)(?P<y>(?:1[0-9]{{3}}|2[0-9]{{3}}))(?:\\s*সাল(?:ের|ে)?)?)?(?P<guard2>)"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    (
                        "guard1",
                        false,
                        "(?:[:0-9a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}%$৳]|\\.[0-9]|\\s*(?:টা(?:(?:য়|য\u{09BC})|র)?|টে(?:(?:য়|য\u{09BC})|র)?|টো(?:(?:য়|য\u{09BC})|র)?|বাজে|মিনিট|সেকেন্ড|ঘণ্টা|ঘন্টা|দিন(?:ের|ে)?|সপ্তাহ(?:ের|ে)?|হপ্তা(?:(?:য়|য\u{09BC})|র)?|মাস(?:ের|ে)?|বছর(?:ের|ে)?|বৎসর(?:ের|ে)?|সাল(?:ের|ে)?|[aA][mM]|[pP][mM]|[aA]\\.[mM]\\.|[pP]\\.[mM]\\.|এ\\.?\\s*এম\\.?|পি\\.?\\s*এম\\.?))",
                    ),
                    ("guard2", false, COLON_WORD_CHAR),
                ],
                |c, _| {
                    let m = lookup_month(c.name("m")?.as_str())?;
                    let ds = c
                        .name("d1")
                        .or_else(|| c.name("d2"))
                        .or_else(|| c.name("d3"))?
                        .as_str();
                    let d = bn_number(ds)?;
                    if !(1..=31).contains(&d) {
                        return None;
                    }
                    let mut out = vec![Component::Month(m), Component::Day(d)];
                    if let Some(ym) = c.name("y") {
                        out.push(Component::Year(crate::number(ym.as_str())?));
                    }
                    Some(out)
                },
            ),
            Pattern::with_builder(
                "bn_monthYear",
                &format!(
                    "(?P<guard0>)(?P<m>{MONTH_ALT})(?:\\s+মাস(?:ের|ে)?|\\s+এর)?(?:\\s*,\\s*|\\s+)(?P<y>(?:1[0-9]{{3}}|2[0-9]{{3}}))(?:\\s*সাল(?:ের|ে)?)?(?P<guard1>)"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, COLON_WORD_CHAR),
                ],
                |c, _| {
                    Some(vec![
                        Component::Month(lookup_month(c.name("m")?.as_str())?),
                        Component::Year(crate::number(c.name("y")?.as_str())?),
                    ])
                },
            ),
            Pattern::with_builder(
                "bn_monthPhrase",
                &format!("(?P<guard0>)(?P<m>{MONTH_ALT})\\s+মাস(?:ের|ে)?(?P<guard1>)"),
                BN_GUARDS,
                |c, _| Some(vec![Component::Month(lookup_month(c.name("m")?.as_str())?)]),
            ),
            Pattern::with_builder(
                "bn_within",
                &format!(
                    "(?P<guard0>)(?:(?:আগামী|আসছে|পরবর্তী)\\s+(?P<n1>[0-9]+|{WORD_NUM_ANY})\\s*(?P<u1>দিন(?:ের|ে)?|সপ্তাহ(?:ের|ে)?|হপ্তা(?:(?:য়|য\u{09BC})|র)?)(?:\\s+(?:মধ্যে|ভিতরে|ভেতরে))?|(?P<n2>[0-9]+|{WORD_NUM_ANY})\\s*(?P<u2>দিন(?:ের)?|সপ্তাহ(?:ের)?|হপ্তা(?:র)?)\\s+(?:মধ্যে|ভিতরে|ভেতরে))(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let (n_s, u_s) = if let Some(n1) = c.name("n1") {
                        (n1.as_str(), c.name("u1")?.as_str())
                    } else {
                        (c.name("n2")?.as_str(), c.name("u2")?.as_str())
                    };
                    let n = bn_number(n_s)?;
                    let days = if u_s.starts_with("দিন") {
                        n
                    } else {
                        n.checked_mul(7)?
                    };
                    Some(vec![Component::Within(days)])
                },
            ),
            Pattern::with_builder(
                "bn_offset",
                &format!(
                    "(?P<guard0>)(?:(?:এখন|আজ(?:কে)?)\\s+থেকে\\s+)?(?P<n>[0-9]+|{WORD_NUM_ANY})\\s*(?P<u>দিন(?:ের|ে)?|সপ্তাহ(?:ের|ে)?|হপ্তা(?:(?:য়|য\u{09BC})|র)?|মাস(?:ের|ে)?|বছর(?:ের|ে)?|বৎসর(?:ের|ে)?|সাল(?:ের|ে)?)\\s*(?:(?P<pos>পরে|পর|বাদে|মাথা(?:য়|য\u{09BC}))|(?P<neg>আগেকার|আগে|পূর্বে))(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let raw = bn_number(c.name("n")?.as_str())?;
                    let val = if c.name("neg").is_some() {
                        raw.checked_neg()?
                    } else {
                        raw
                    };
                    let u = c.name("u")?.as_str();
                    let comp = if u.starts_with("দিন") {
                        Component::RelativeDay(val)
                    } else if u.starts_with("মাস") {
                        Component::MonthOffset(val)
                    } else if u.starts_with("বছর") || u.starts_with("বৎসর") || u.starts_with("সাল")
                    {
                        Component::YearOffset(val)
                    } else {
                        Component::Week(val, false)
                    };
                    Some(vec![comp])
                },
            ),
            Pattern::with_builder(
                "bn_namedYear",
                "(?P<guard0>)(?:(?P<y1>[0-9]{4})\\s*(?:সাল(?:ের|ে)?|বৎসর(?:ের|ে)?|খ্রিস্টাব্দ(?:ে)?)|(?:সাল|সন|বর্ষ|খ্রিস্টাব্দ)\\s+(?P<y2>[0-9]{4}))(?P<guard1>)",
                &[
                    ("guard0", true, WORD_CHAR),
                    (
                        "guard1",
                        false,
                        "(?:[0-9a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]|\\s*(?:পরে|পর|বাদে|আগে|পূর্বে))",
                    ),
                ],
                |c, _| {
                    let ys = c.name("y1").or_else(|| c.name("y2"))?.as_str();
                    let y = crate::number(ys)?;
                    (1..=9999).contains(&y).then_some(vec![Component::Year(y)])
                },
            ),
            Pattern::with_builder(
                "bn_relativeDayPhrase",
                "(?P<guard0>)(?:(?P<mod>আগামী|আসছে|সামনের|পরের|গত|আগের|বিগত)\\s+(?P<d1>পরশু\\s*দিন|পরশু|তরশু\\s*দিন|তরশু|কালকে|কাল)|(?P<d2>পরশু\\s+দিন|তরশু\\s+দিন|আজকের\\s+দিন))(?P<guard1>)",
                BN_GUARDS,
                |c, _| {
                    if let Some(d2) = c.name("d2") {
                        let s = d2.as_str();
                        let off = if s.starts_with("পরশু") {
                            2
                        } else if s.starts_with("তরশু") {
                            3
                        } else {
                            0
                        };
                        return Some(vec![Component::RelativeDay(off)]);
                    }
                    let m = c.name("mod")?.as_str();
                    let d = c.name("d1")?.as_str();
                    let base = if d.starts_with("তরশু") {
                        3
                    } else if d.starts_with("পরশু") {
                        2
                    } else {
                        1
                    };
                    let neg = matches!(m, "গত" | "আগের" | "বিগত");
                    Some(vec![Component::RelativeDay(if neg { -base } else { base })])
                },
            ),
            Pattern::new(
                "bn_relativeDay",
                "(?P<guard0>)(আগামীকালকের|আগামীকালের|আগামীকালকে|আগামীপরশুদিন|আগামীতরশুদিন|গতপরশুদিন|গততরশুদিন|আগামীকাল|আগামীপরশু|আগামীতরশু|গতকালকের|গতকালের|গতকালকে|গতকাল|গতপরশু|গততরশু|পরশুদিন|তরশুদিন|আজকের|কালকের|আজকে|কালকে|পরশু|তরশু|অদ্য|আজ|কাল)(?P<guard1>)",
                BN_GUARDS,
                &[
                    ("আজকের", &[Component::RelativeDay(0)]),
                    ("আজকে", &[Component::RelativeDay(0)]),
                    ("আজ", &[Component::RelativeDay(0)]),
                    ("অদ্য", &[Component::RelativeDay(0)]),
                    ("আগামীকালকের", &[Component::RelativeDay(1)]),
                    ("আগামীকালের", &[Component::RelativeDay(1)]),
                    ("আগামীকালকে", &[Component::RelativeDay(1)]),
                    ("আগামীকাল", &[Component::RelativeDay(1)]),
                    ("কালকের", &[Component::RelativeDay(1)]),
                    ("কালকে", &[Component::RelativeDay(1)]),
                    ("কাল", &[Component::RelativeDay(1)]),
                    ("গতকালকের", &[Component::RelativeDay(-1)]),
                    ("গতকালের", &[Component::RelativeDay(-1)]),
                    ("গতকালকে", &[Component::RelativeDay(-1)]),
                    ("গতকাল", &[Component::RelativeDay(-1)]),
                    ("আগামীপরশুদিন", &[Component::RelativeDay(2)]),
                    ("আগামীপরশু", &[Component::RelativeDay(2)]),
                    ("পরশুদিন", &[Component::RelativeDay(2)]),
                    ("পরশু", &[Component::RelativeDay(2)]),
                    ("গতপরশুদিন", &[Component::RelativeDay(-2)]),
                    ("গতপরশু", &[Component::RelativeDay(-2)]),
                    ("আগামীতরশুদিন", &[Component::RelativeDay(3)]),
                    ("আগামীতরশু", &[Component::RelativeDay(3)]),
                    ("তরশুদিন", &[Component::RelativeDay(3)]),
                    ("তরশু", &[Component::RelativeDay(3)]),
                    ("গততরশুদিন", &[Component::RelativeDay(-3)]),
                    ("গততরশু", &[Component::RelativeDay(-3)]),
                ],
            ),
            Pattern::with_builder(
                "bn_weekend",
                "(?P<guard0>)(?:(?:(?P<past>গত|আগের|বিগত|পূর্ববর্তী)|(?P<next>আগামী|পরের|পরবর্তী|সামনের|আসছে|এই|চলতি))\\s+)?(?:সপ্তাহান্ত(?:ের|ে)?|উইক(?:এন্ড|েন্ড)(?:ের|ে)?|সপ্তাহের\\s+শেষ(?:ের|ে)?)(?P<guard1>)",
                BN_GUARDS,
                |c, _| {
                    if c.name("past").is_some() {
                        Some(vec![Component::Week(-1, false), Component::Weekday(7)])
                    } else {
                        Some(vec![Component::Weekend])
                    }
                },
            ),
            Pattern::with_builder(
                "bn_anchor",
                "(?P<guard0>)(?:(?P<dmod>পরের\\s+পরের|আগামী\\s+পরের|আগের\\s+আগের|গত\\s+আগের)\\s+(?P<du>সপ্তাহ(?:ের|ে)?|হপ্তা(?:(?:য়|য\u{09BC})|র)?|মাস(?:ের|ে)?|বছর(?:ের|ে)?|বৎসর(?:ের|ে)?|সাল(?:ের|ে)?)|(?P<mod>আগামী|পরবর্তী|পরের|সামনের|আসছে|আসন্ন|গত|আগের|বিগত|পূর্ববর্তী|এই|চলতি|বর্তমান|এ)\\s+(?P<u>সপ্তাহ(?:ের|ে)?|হপ্তা(?:(?:য়|য\u{09BC})|র)?|মাস(?:ের|ে)?|বছর(?:ের|ে)?|বৎসর(?:ের|ে)?|সাল(?:ের|ে)?))(?P<guard1>)",
                BN_GUARDS,
                |c, _| {
                    let (off, u) = if let Some(dm) = c.name("dmod") {
                        let off = if dm.as_str().contains("আগের") {
                            -2
                        } else {
                            2
                        };
                        (off, c.name("du")?.as_str())
                    } else {
                        let m = c.name("mod")?.as_str();
                        let off = match m {
                            "আগামী" | "পরের" | "পরবর্তী" | "সামনের" | "আসছে" | "আসন্ন" => {
                                1
                            }
                            "গত" | "আগের" | "বিগত" | "পূর্ববর্তী" => {
                                -1
                            }
                            _ => 0,
                        };
                        (off, c.name("u")?.as_str())
                    };
                    let comp = if u.starts_with("সপ্তাহ") || u.starts_with("হপ্তা")
                    {
                        Component::Week(off, true)
                    } else if u.starts_with("মাস") {
                        Component::MonthOffset(off)
                    } else {
                        Component::YearOffset(off)
                    };
                    Some(vec![comp])
                },
            ),
            Pattern::with_builder(
                "bn_nextLastWeekday",
                &format!(
                    "(?P<guard0>)(?P<mod>আগামী|পরবর্তী|পরের|সামনের|আসছে|আসন্ন|গত|আগের|বিগত|পূর্ববর্তী|এই|চলতি)\\s+(?P<wd>{WEEKDAY_ALT})(?P<guard1>)"
                ),
                BN_GUARDS,
                |c, _| {
                    let wd = lookup_weekday(c.name("wd")?.as_str())?;
                    match c.name("mod")?.as_str() {
                        "আগামী" | "পরের" | "পরবর্তী" | "সামনের" | "আসছে" | "আসন্ন" => {
                            Some(vec![Component::Week(1, false), Component::Weekday(wd)])
                        }
                        "গত" | "আগের" | "বিগত" | "পূর্ববর্তী" => {
                            Some(vec![Component::Week(-1, false), Component::Weekday(wd)])
                        }
                        _ => Some(vec![Component::Weekday(wd)]),
                    }
                },
            ),
            Pattern::with_builder(
                "bn_weekdayPhrase",
                "(?P<guard0>)বৃহস্পতি\\s+বার(?:ের|ে)?(?P<guard1>)",
                BN_GUARDS,
                |_, _| Some(vec![Component::Weekday(4)]),
            ),
            Pattern::new(
                "bn_weekday",
                "(?P<guard0>)(বৃহস্পতিবারের|বৃহস্পতিবারে|বৃহস্পতিবার|মঙ্গলবারের|মঙ্গলবারে|মঙ্গলবার|শুক্রবারের|শুক্রবারে|শুক্রবার|সোমবারের|সোমবারে|সোমবার|বুধবারের|বুধবারে|বুধবার|বৃহঃবারের|বৃহঃবারে|বৃহঃবার|গুরুবারের|গুরুবারে|গুরুবার|শনিবারের|শনিবারে|শনিবার|রবিবারের|রবিবারে|রবিবার|রোববারের|রোববারে|রোববার|মঙ্গল\\.|শুক্র\\.|বৃহঃ\\.|সোম\\.|বুধ\\.|বৃহঃ|বৃহ\\.|শনি\\.|রবি\\.)(?P<guard1>)",
                BN_GUARDS,
                WEEKDAYS,
            ),
            Pattern::new(
                "bn_month",
                &format!("(?P<guard0>)({MONTH_ALT})(?P<guard1>)"),
                BN_GUARDS,
                MONTHS,
            ),
            Pattern::with_builder(
                "bn_day",
                &format!(
                    "(?P<guard0>)(?:(?P<d1>[0-9]{{1,2}}(?:-?\\s*(?:লা|রা|ঠা|ই|শে|এ|তম|ম|(?:য়|য\u{09BC})|র্থ|ষ্ঠ))?|{ORD_DAY_ALT}|{WORD_NUM_1_31})\\s*তারিখ(?:ের|ে)?|তারিখ\\s*:?\\s*(?P<d2>[0-9]{{1,2}}(?:-?(?:লা|রা|ঠা|ই|শে))?))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, BN_DAY_GUARD1),
                ],
                |c, _| {
                    let ds = c.name("d1").or_else(|| c.name("d2"))?.as_str();
                    let d = bn_number(ds)?;
                    (1..=31).contains(&d).then_some(vec![Component::Day(d)])
                },
            ),
            Pattern::with_builder(
                "bn_standaloneOrdDay",
                &format!(
                    "(?P<guard0>)(?P<d>0?1\\s*-?\\s*লা|0?[23]\\s*-?\\s*রা|0?4\\s*-?\\s*ঠা|(?:1[0-8]|0?[5-9])\\s*-?\\s*ই|(?:19|2[0-9]|3[01])\\s*-?\\s*(?:শে|ই)|{ORD_DAY_ALT})(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let d = bn_number(c.name("d")?.as_str())?;
                    (1..=31).contains(&d).then_some(vec![Component::Day(d)])
                },
            ),
            Pattern::with_builder(
                "bn_noonMidnight",
                "(?P<guard0>)(?:(?P<mid>মধ্য\\s*রাত্রি(?:তে)?|মধ্য\\s*রাত(?:ে)?|মাঝ\\s*রাত(?:ে)?|নিশীথ\\s*রাত(?:ে)?)|(?P<noon>ঠিক\\s+দুপুর(?:ে)?|মধ্যাহ্ন(?:ে)?))(?:\\s*12(?::00)?\\s*(?:টা(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|বাজে))?(?P<guard1>)",
                BN_GUARDS,
                |c, _| {
                    let h = if c.name("mid").is_some() { 0 } else { 12 };
                    Some(vec![Component::Time(h, Some(0), None)])
                },
            ),
            Pattern::with_builder(
                "bn_nightAmTime",
                &format!(
                    "(?P<guard0>)(?:গভীর\\s+|ভোর\\s*)?(?:রাত্রি(?:তে)?|রাত্রে|রাত(?:ের|ে)?)\\s+(?:(?P<dedh>দে(?:ড়|ড\u{09BC})\\s*{TIME_SUFFIX})|(?P<dhai>আ(?:ড়|ড\u{09BC})াই\\s*{TIME_SUFFIX})|(?P<sadhe>সা(?:ড়|ড\u{09BC})ে\\s*(?P<hs>12|[1-4]|বারো|বার|একটা(?:(?:য়|য\u{09BC})|র)?|এক|দুটো(?:(?:য়|য\u{09BC})|র)?|দুই|দু['’]?|তিনটে(?:(?:য়|য\u{09BC})|র)?|তিনটা(?:(?:য়|য\u{09BC})|র)?|তিন|চারটে(?:(?:য়|য\u{09BC})|র)?|চারটা(?:(?:য়|য\u{09BC})|র)?|চার)(?:\\s*{TIME_SUFFIX})?)|(?P<sawa>সো(?:য়|য\u{09BC})া\\s*(?:(?P<hq>12|[1-4]|বারো|বার|একটা(?:(?:য়|য\u{09BC})|র)?|এক|দুটো(?:(?:য়|য\u{09BC})|র)?|দুই|দু['’]?|তিনটে(?:(?:য়|য\u{09BC})|র)?|তিনটা(?:(?:য়|য\u{09BC})|র)?|তিন|চারটে(?:(?:য়|য\u{09BC})|র)?|চারটা(?:(?:য়|য\u{09BC})|র)?|চার)(?:\\s*{TIME_SUFFIX})?|{TIME_SUFFIX}))|(?P<paune>পৌনে\\s*(?:(?P<hp>[1-4]|একটা(?:(?:য়|য\u{09BC})|র)?|এক|দুটো(?:(?:য়|য\u{09BC})|র)?|দুই|দু['’]?|তিনটে(?:(?:য়|য\u{09BC})|র)?|তিনটা(?:(?:য়|য\u{09BC})|র)?|তিন|চারটে(?:(?:য়|য\u{09BC})|র)?|চারটা(?:(?:য়|য\u{09BC})|র)?|চার)(?:\\s*{TIME_SUFFIX})?|{TIME_SUFFIX}))|(?P<hc>12|[1-4]):(?P<mc>[0-5][0-9])(?:\\s*(?:{TIME_SUFFIX}|মিনিট(?:ে)?))?|(?P<hm>12|[1-4]|বারো|বার|এক|দুই|তিন|চার)\\s*(?:টা(?:(?:য়|য\u{09BC})|র)?|টে(?:(?:য়|য\u{09BC})|র)?|টো(?:(?:য়|য\u{09BC})|র)?)\\s*(?:বেজে\\s*)?(?P<mm>[0-9]{{1,2}}|{WORD_NUM_1_59})(?:\\s*মিনিট(?:ে)?)?|(?P<h>12|[1-4]|বারো|বার|দুই|তিন|চার)\\s*{TIME_SUFFIX}|(?P<hw>একটা(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|দুটো(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|তিনটে(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|চারটে(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, TIME_MIN_GUARD1),
                ],
                |c, _| {
                    let map_12 = |h: i32| if h == 12 { 0 } else { h };
                    let (h, m) = if c.name("dedh").is_some() {
                        (1, Some(30))
                    } else if c.name("dhai").is_some() {
                        (2, Some(30))
                    } else if let Some(hs) = c.name("hs") {
                        (map_12(parse_bn_hour_word(hs.as_str())?), Some(30))
                    } else if c.name("sawa").is_some() {
                        let h = match c.name("hq") {
                            Some(v) => map_12(parse_bn_hour_word(v.as_str())?),
                            None => 1,
                        };
                        (h, Some(15))
                    } else if c.name("paune").is_some() {
                        let h = match c.name("hp") {
                            Some(v) => parse_bn_hour_word(v.as_str())?,
                            None => 1,
                        };
                        ((h - 1).rem_euclid(24), Some(45))
                    } else if let Some(hc) = c.name("hc") {
                        let h = map_12(crate::number(hc.as_str())?);
                        let m = crate::number(c.name("mc")?.as_str())?;
                        (h, Some(m))
                    } else if let Some(hm) = c.name("hm") {
                        let h = map_12(bn_number(hm.as_str())?);
                        let m = bn_number(c.name("mm")?.as_str())?;
                        (h, Some(m))
                    } else {
                        let hs = c.name("h").or_else(|| c.name("hw"))?.as_str();
                        (map_12(parse_bn_hour_word(hs)?), None)
                    };
                    Some(vec![Component::Time(h, m, Some(false))])
                },
            ),
            Pattern::with_builder(
                "bn_belaTime",
                &format!(
                    "(?P<guard0>)বেলা(?:য়|য\u{09BC})?\\s+(?:(?P<dedh>দে(?:ড়|ড\u{09BC})(?:\\s*{TIME_SUFFIX})?)|(?P<dhai>আ(?:ড়|ড\u{09BC})াই(?:\\s*{TIME_SUFFIX})?)|(?P<sadhe>সা(?:ড়|ড\u{09BC})ে\\s*(?P<hs>1[0-2]|[1-47-9]|একটা(?:(?:য়|য\u{09BC})|র)?|এক|দুটো(?:(?:য়|য\u{09BC})|র)?|দুই|দু['’]?|তিনটে(?:(?:য়|য\u{09BC})|র)?|তিনটা(?:(?:য়|য\u{09BC})|র)?|তিন|চারটে(?:(?:য়|য\u{09BC})|র)?|চারটা(?:(?:য়|য\u{09BC})|র)?|চার|সাত|আট|ন(?:য়|য\u{09BC})|ন['’]?|দশ|এগারো|এগার|বারো|বার)(?:\\s*{TIME_SUFFIX})?)|(?P<sawa>সো(?:য়|য\u{09BC})া\\s*(?:(?P<hq>1[0-2]|[1-47-9]|একটা(?:(?:য়|য\u{09BC})|র)?|এক|দুটো(?:(?:য়|য\u{09BC})|র)?|দুই|দু['’]?|তিনটে(?:(?:য়|য\u{09BC})|র)?|তিনটা(?:(?:য়|য\u{09BC})|র)?|তিন|চারটে(?:(?:য়|য\u{09BC})|র)?|চারটা(?:(?:য়|য\u{09BC})|র)?|চার|সাত|আট|ন(?:য়|য\u{09BC})|ন['’]?|দশ|এগারো|এগার|বারো|বার)(?:\\s*{TIME_SUFFIX})?|{TIME_SUFFIX}))|(?P<paune>পৌনে\\s*(?:(?P<hp>1[0-2]|[1-47-9]|একটা(?:(?:য়|য\u{09BC})|র)?|এক|দুটো(?:(?:য়|য\u{09BC})|র)?|দুই|দু['’]?|তিনটে(?:(?:য়|য\u{09BC})|র)?|তিনটা(?:(?:য়|য\u{09BC})|র)?|তিন|চারটে(?:(?:য়|য\u{09BC})|র)?|চারটা(?:(?:য়|য\u{09BC})|র)?|চার|সাত|আট|ন(?:য়|য\u{09BC})|ন['’]?|দশ|এগারো|এগার|বারো|বার)(?:\\s*{TIME_SUFFIX})?|{TIME_SUFFIX}))|(?P<hc>1[0-2]|[1-47-9]):(?P<mc>[0-5][0-9])(?:\\s*(?:{TIME_SUFFIX}|মিনিট(?:ে)?))?|(?P<h>1[0-2]|[1-47-9]|বারো|বার|এগারো|এগার|দশ|ন(?:য়|য\u{09BC})|ন['’]?|আট|সাত|দুই|তিন|চার)\\s*{TIME_SUFFIX}|(?P<hw>একটা(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|দুটো(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|তিনটে(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|চারটে(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?))(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let (h, m) = if c.name("dedh").is_some() {
                        (1, Some(30))
                    } else if c.name("dhai").is_some() {
                        (2, Some(30))
                    } else if let Some(hs) = c.name("hs") {
                        (parse_bn_hour_word(hs.as_str())?, Some(30))
                    } else if c.name("sawa").is_some() {
                        let h = match c.name("hq") {
                            Some(v) => parse_bn_hour_word(v.as_str())?,
                            None => 1,
                        };
                        (h, Some(15))
                    } else if c.name("paune").is_some() {
                        let h = match c.name("hp") {
                            Some(v) => parse_bn_hour_word(v.as_str())?,
                            None => 1,
                        };
                        ((h - 1).rem_euclid(24), Some(45))
                    } else if let Some(hc) = c.name("hc") {
                        let h = crate::number(hc.as_str())?;
                        let m = crate::number(c.name("mc")?.as_str())?;
                        (h, Some(m))
                    } else {
                        let hs = c.name("h").or_else(|| c.name("hw"))?.as_str();
                        (parse_bn_hour_word(hs)?, None)
                    };
                    let pm = matches!(h, 0..=4 | 12);
                    Some(vec![Component::Time(h, m, Some(pm))])
                },
            ),
            Pattern::with_builder(
                "bn_timeAmPm",
                "(?P<guard0>)(?P<h>[0-9]{1,2})(?::(?P<m>[0-9]{2})(?::(?P<s>[0-9]{2}))?)?\\s*(?:(?P<am>[aA][mM]|[aA]\\.[mM]\\.|এ\\.?\\s*এম\\.?)|(?P<pm>[pP][mM]|[pP]\\.[mM]\\.|পি\\.?\\s*এম\\.?))(?P<guard1>)",
                &[
                    (
                        "guard0",
                        true,
                        "[0-9.:/\\-a-zA-Z\u{00C0}-\u{00D6}\u{00D8}-\u{00F6}\u{00F8}-\u{024F}\u{0980}-\u{09E3}\u{09F0}\u{09F1}\u{09FC}]",
                    ),
                    ("guard1", false, WORD_CHAR),
                ],
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    if !(1..=12).contains(&h) {
                        return None;
                    }
                    let m = match c.name("m") {
                        Some(mm) => Some(crate::number(mm.as_str())?),
                        None => None,
                    };
                    if let Some(sm) = c.name("s")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    Some(vec![Component::Time(h, m, Some(c.name("pm").is_some()))])
                },
            ),
            Pattern::with_builder(
                "bn_meridiemTime",
                &format!(
                    "(?P<guard0>)(?:(?P<am_mer>সকাল(?:ে)?|ভোর(?:ে)?|প্রভাত(?:ে)?|পূর্বাহ্ণ(?:ে)?|পূর্বাহ্ন(?:ে)?)|(?P<pm_mer>দুপুর(?:ে)?|বিকাল(?:ে)?|বিকেল(?:ে)?|অপরাহ্ণ(?:ে)?|অপরাহ্ন(?:ে)?|সন্ধ্যা(?:(?:য়|য\u{09BC}))?|সন্ধে(?:(?:য়|য\u{09BC}))?))\\s+(?:(?P<dedh>দে(?:ড়|ড\u{09BC})(?:\\s*{TIME_SUFFIX})?)|(?P<dhai>আ(?:ড়|ড\u{09BC})াই(?:\\s*{TIME_SUFFIX})?)|(?P<sadhe>সা(?:ড়|ড\u{09BC})ে\\s*(?P<hs>{HOUR_ALT})(?:\\s*{TIME_SUFFIX})?)|(?P<sawa>সো(?:য়|য\u{09BC})া\\s*(?:(?P<hq>{HOUR_ALT})(?:\\s*{TIME_SUFFIX})?|{TIME_SUFFIX}))|(?P<paune>পৌনে\\s*(?:(?P<hp>{HOUR_ALT})(?:\\s*{TIME_SUFFIX})?|{TIME_SUFFIX}))|(?P<colloq>একটা(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|দুটো(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|তিনটে(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?|চারটে(?:(?:য়|য\u{09BC})|র)?(?:\\s*বাজে)?)(?:\\s+(?:বেজে\\s+(?P<cm1>[0-9]{{1,2}}|{WORD_NUM_1_59})(?:\\s*মিনিট(?:ে)?)?|(?P<cm2>[0-9]{{1,2}}|{WORD_NUM_1_59})\\s*মিনিট(?:ে)?))?)(?P<guard1>)"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, BN_HOUR_GUARD1),
                ],
                |c, _| {
                    let pm = c.name("pm_mer").is_some();
                    let (h, m) = if c.name("dedh").is_some() {
                        (1, Some(30))
                    } else if c.name("dhai").is_some() {
                        (2, Some(30))
                    } else if let Some(hs) = c.name("hs") {
                        (parse_bn_hour_word(hs.as_str())?, Some(30))
                    } else if c.name("sawa").is_some() {
                        let h = match c.name("hq") {
                            Some(v) => parse_bn_hour_word(v.as_str())?,
                            None => 1,
                        };
                        (h, Some(15))
                    } else if c.name("paune").is_some() {
                        let h = match c.name("hp") {
                            Some(v) => parse_bn_hour_word(v.as_str())?,
                            None => 1,
                        };
                        if !(0..24).contains(&h) {
                            return None;
                        }
                        ((h - 1).rem_euclid(24), Some(45))
                    } else {
                        let h = parse_bn_hour_word(c.name("colloq")?.as_str())?;
                        let m = match c.name("cm1").or_else(|| c.name("cm2")) {
                            Some(cm) => {
                                let v = bn_number(cm.as_str())?;
                                if !(0..60).contains(&v) {
                                    return None;
                                }
                                Some(v)
                            }
                            None => None,
                        };
                        (h, m)
                    };
                    Some(vec![Component::Time(h, m, Some(pm))])
                },
            ),
            Pattern::with_builder(
                "bn_fracTime",
                &format!(
                    "(?P<guard0>)(?:(?P<dedh>দে(?:ড়|ড\u{09BC})\\s*{TIME_SUFFIX})|(?P<dhai>আ(?:ড়|ড\u{09BC})াই\\s*{TIME_SUFFIX})|(?P<sadhe>সা(?:ড়|ড\u{09BC})ে\\s*(?P<hs>{HOUR_ALT})\\s*{TIME_SUFFIX})|(?P<sawa>সো(?:য়|য\u{09BC})া\\s*(?:(?P<hq>{HOUR_ALT})\\s*)?{TIME_SUFFIX})|(?P<paune>পৌনে\\s*(?:(?P<hp>{HOUR_ALT})\\s*)?{TIME_SUFFIX}))(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let (h, m) = if c.name("dedh").is_some() {
                        (1, 30)
                    } else if c.name("dhai").is_some() {
                        (2, 30)
                    } else if let Some(hs) = c.name("hs") {
                        (parse_bn_hour_word(hs.as_str())?, 30)
                    } else if c.name("sawa").is_some() {
                        let h = match c.name("hq") {
                            Some(v) => parse_bn_hour_word(v.as_str())?,
                            None => 1,
                        };
                        (h, 15)
                    } else {
                        let h = match c.name("hp") {
                            Some(v) => parse_bn_hour_word(v.as_str())?,
                            None => 1,
                        };
                        if !(0..24).contains(&h) {
                            return None;
                        }
                        ((h - 1).rem_euclid(24), 45)
                    };
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "bn_toHourTime",
                &format!(
                    "(?P<guard0>)(?P<h>{HOUR_ALT})\\s*(?:টা|টে|টো)?\\s*বাজতে\\s*(?P<m>[0-9]{{1,2}}|{WORD_NUM_1_59})\\s*মিনিট(?:\\s*বাকি)?(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let h = parse_bn_hour_word(c.name("h")?.as_str())?;
                    let m = bn_number(c.name("m")?.as_str())?;
                    if !(0..24).contains(&h) || !(1..60).contains(&m) {
                        return None;
                    }
                    let total = (h * 60 - m).rem_euclid(24 * 60);
                    Some(vec![Component::Time(total / 60, Some(total % 60), None)])
                },
            ),
            Pattern::with_builder(
                "bn_hourMinTime",
                &format!(
                    "(?P<guard0>)(?:(?P<h1>{HOUR_ALT})\\s*(?:টা(?:(?:য়|য\u{09BC})|র)?|টে(?:(?:য়|য\u{09BC})|র)?|টো(?:(?:য়|য\u{09BC})|র)?)?\\s*বেজে\\s*(?P<m1>[0-9]{{1,2}}|{WORD_NUM_1_59})(?:\\s*মিনিট(?:ে)?)?|(?P<h2>{HOUR_ALT_NO_EKTA})\\s*(?:টা|টে|টো)\\s*(?P<m2>[0-9]{{1,2}}|{WORD_NUM_1_59})\\s*মিনিট(?:ে)?|(?P<h3>{HOUR_ALT_NO_EKTA})\\s*(?:টা|টে|টো)\\s+(?P<m3>[0-9]{{1,2}}|{WORD_NUM_1_59}))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, TIME_MIN_GUARD1),
                ],
                |c, _| {
                    let (hs, ms) = if let Some(h1) = c.name("h1") {
                        (h1.as_str(), c.name("m1")?.as_str())
                    } else if let Some(h2) = c.name("h2") {
                        (h2.as_str(), c.name("m2")?.as_str())
                    } else {
                        (c.name("h3")?.as_str(), c.name("m3")?.as_str())
                    };
                    let h = parse_bn_hour_word(hs)?;
                    let m = bn_number(ms)?;
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "bn_colonTa",
                &format!(
                    "(?P<guard0>)(?P<h>[0-9]{{1,2}}):(?P<m>[0-9]{{2}})(?::(?P<s>[0-9]{{2}}))?\\s*(?:{TIME_SUFFIX}|মিনিট(?:ে)?)(?P<guard1>)"
                ),
                WORD_GUARDS,
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = crate::number(c.name("m")?.as_str())?;
                    if let Some(sm) = c.name("s")
                        && !(0..60).contains(&crate::number(sm.as_str())?)
                    {
                        return None;
                    }
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "bn_hmsTime",
                "(?P<guard0>)(?P<h>[0-9]{1,2}):(?P<m>[0-9]{2}):(?P<s>[0-9]{2})(?P<guard1>)",
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, COLON_WORD_CHAR),
                ],
                |c, _| {
                    let h = crate::number(c.name("h")?.as_str())?;
                    let m = crate::number(c.name("m")?.as_str())?;
                    let s = crate::number(c.name("s")?.as_str())?;
                    if !(0..60).contains(&s) {
                        return None;
                    }
                    Some(vec![Component::Time(h, Some(m), None)])
                },
            ),
            Pattern::with_builder(
                "bn_hour",
                &format!(
                    "(?P<guard0>)(?:(?P<hd>[0-9]{{1,2}})\\s*{TIME_SUFFIX}|(?P<hw>(?:একটা(?:(?:য়|য\u{09BC})|র)(?:\\s*বাজে)?|একটা\\s*বাজে|দুটো(?:(?:য়|য\u{09BC})|র)(?:\\s*বাজে)?|দুটো\\s*বাজে|তিনটে(?:(?:য়|য\u{09BC})|র)(?:\\s*বাজে)?|তিনটে\\s*বাজে|চারটে(?:(?:য়|য\u{09BC})|র)(?:\\s*বাজে)?|চারটে\\s*বাজে|(?:{HOUR_WORD_NO_EKTA})\\s*{TIME_SUFFIX})))(?P<guard1>)"
                ),
                &[
                    ("guard0", true, WORD_CHAR),
                    ("guard1", false, BN_HOUR_GUARD1),
                ],
                |c, _| {
                    let h = if let Some(hd) = c.name("hd") {
                        crate::number(hd.as_str())?
                    } else {
                        parse_bn_hour_word(c.name("hw")?.as_str())?
                    };
                    (0..24)
                        .contains(&h)
                        .then_some(vec![Component::Time(h, None, None)])
                },
            ),
            Pattern::new("bn_colonTime", "([0-9]{1,2}):([0-9]{2})", &[], &[]),
            Pattern::with_builder(
                "bn_meridiemPhrase",
                "(?P<guard0>)(?:(?P<am>ভোর\\s+(?:রাত(?:ে)?|বেলা(?:য়|য\u{09BC})?)|(?:সকাল|প্রভাত)\\s+বেলা(?:য়|য\u{09BC})?)|(?P<pm>(?:দুপুর|বিকাল|বিকেল|সন্ধ্যা|সন্ধে|রাতের|রাত)\\s+বেলা(?:য়|য\u{09BC})?))(?P<guard1>)",
                BN_GUARDS,
                |c, _| Some(vec![Component::Meridiem(c.name("pm").is_some())]),
            ),
            Pattern::new(
                "bn_meridiem",
                "(?P<guard0>)(সকালবেলায়|সকালবেলায়|সকালবেলা|ভোরবেলায়|ভোরবেলায়|ভোরবেলা|দুপুরবেলায়|দুপুরবেলায়|দুপুরবেলা|বিকালবেলায়|বিকালবেলায়|বিকালবেলা|বিকেলবেলায়|বিকেলবেলায়|বিকেলবেলা|সন্ধ্যাবেলায়|সন্ধ্যাবেলায়|সন্ধ্যাবেলা|সন্ধেবেলায়|সন্ধেবেলায়|সন্ধেবেলা|রাতবেলায়|রাতবেলায়|রাতবেলা|পূর্বাহ্ণে|পূর্বাহ্নে|পূর্বাহ্ণ|পূর্বাহ্ন|অপরাহ্ণে|অপরাহ্নে|অপরাহ্ণ|অপরাহ্ন|ভোররাতে|ভোররাত|সন্ধ্যায়|সন্ধ্যায়|রাত্রিতে|সায়াহ্নে|সায\u{09BC}াহ্নে|প্রভাতে|সকাল|ভোরে|দুপুরে|বিকালে|বিকেলে|সকালে|প্রভাত|দুপুর|বিকাল|বিকেল|সন্ধ্যা|সন্ধেয়|সন্ধেয়|রাত্রে|সায়াহ্ন|সায\u{09BC}াহ্ন|রাত্রি|প্রাতে|প্রাতঃ|সন্ধে|রাতে|ভোর|রাত)(?P<guard1>)",
                BN_GUARDS,
                &[
                    ("সকালবেলায়", &[Component::Meridiem(false)]),
                    ("সকালবেলায়", &[Component::Meridiem(false)]),
                    ("সকালবেলা", &[Component::Meridiem(false)]),
                    ("সকালে", &[Component::Meridiem(false)]),
                    ("সকাল", &[Component::Meridiem(false)]),
                    ("ভোরবেলায়", &[Component::Meridiem(false)]),
                    ("ভোরবেলায়", &[Component::Meridiem(false)]),
                    ("ভোরবেলা", &[Component::Meridiem(false)]),
                    ("ভোররাতে", &[Component::Meridiem(false)]),
                    ("ভোররাত", &[Component::Meridiem(false)]),
                    ("ভোরে", &[Component::Meridiem(false)]),
                    ("ভোর", &[Component::Meridiem(false)]),
                    ("প্রভাতে", &[Component::Meridiem(false)]),
                    ("প্রভাত", &[Component::Meridiem(false)]),
                    ("প্রাতে", &[Component::Meridiem(false)]),
                    ("প্রাতঃ", &[Component::Meridiem(false)]),
                    ("পূর্বাহ্ণে", &[Component::Meridiem(false)]),
                    ("পূর্বাহ্নে", &[Component::Meridiem(false)]),
                    ("পূর্বাহ্ণ", &[Component::Meridiem(false)]),
                    ("পূর্বাহ্ন", &[Component::Meridiem(false)]),
                    ("দুপুরবেলায়", &[Component::Meridiem(true)]),
                    ("দুপুরবেলায়", &[Component::Meridiem(true)]),
                    ("দুপুরবেলা", &[Component::Meridiem(true)]),
                    ("দুপুরে", &[Component::Meridiem(true)]),
                    ("দুপুর", &[Component::Meridiem(true)]),
                    ("অপরাহ্ণে", &[Component::Meridiem(true)]),
                    ("অপরাহ্নে", &[Component::Meridiem(true)]),
                    ("অপরাহ্ণ", &[Component::Meridiem(true)]),
                    ("অপরাহ্ন", &[Component::Meridiem(true)]),
                    ("বিকালবেলায়", &[Component::Meridiem(true)]),
                    ("বিকালবেলায়", &[Component::Meridiem(true)]),
                    ("বিকালবেলা", &[Component::Meridiem(true)]),
                    ("বিকালে", &[Component::Meridiem(true)]),
                    ("বিকাল", &[Component::Meridiem(true)]),
                    ("বিকেলবেলায়", &[Component::Meridiem(true)]),
                    ("বিকেলবেলায়", &[Component::Meridiem(true)]),
                    ("বিকেলবেলা", &[Component::Meridiem(true)]),
                    ("বিকেলে", &[Component::Meridiem(true)]),
                    ("বিকেল", &[Component::Meridiem(true)]),
                    ("সন্ধ্যাবেলায়", &[Component::Meridiem(true)]),
                    ("সন্ধ্যাবেলায়", &[Component::Meridiem(true)]),
                    ("সন্ধ্যাবেলা", &[Component::Meridiem(true)]),
                    ("সন্ধ্যায়", &[Component::Meridiem(true)]),
                    ("সন্ধ্যায়", &[Component::Meridiem(true)]),
                    ("সন্ধ্যা", &[Component::Meridiem(true)]),
                    ("সন্ধেবেলায়", &[Component::Meridiem(true)]),
                    ("সন্ধেবেলায়", &[Component::Meridiem(true)]),
                    ("সন্ধেবেলা", &[Component::Meridiem(true)]),
                    ("সন্ধেয়", &[Component::Meridiem(true)]),
                    ("সন্ধেয়", &[Component::Meridiem(true)]),
                    ("সন্ধে", &[Component::Meridiem(true)]),
                    ("সায়াহ্নে", &[Component::Meridiem(true)]),
                    ("সায\u{09BC}াহ্নে", &[Component::Meridiem(true)]),
                    ("সায়াহ্ন", &[Component::Meridiem(true)]),
                    ("সায\u{09BC}াহ্ন", &[Component::Meridiem(true)]),
                    ("রাতবেলায়", &[Component::Meridiem(true)]),
                    ("রাতবেলায়", &[Component::Meridiem(true)]),
                    ("রাতবেলা", &[Component::Meridiem(true)]),
                    ("রাত্রিতে", &[Component::Meridiem(true)]),
                    ("রাত্রি", &[Component::Meridiem(true)]),
                    ("রাত্রে", &[Component::Meridiem(true)]),
                    ("রাতে", &[Component::Meridiem(true)]),
                    ("রাত", &[Component::Meridiem(true)]),
                ],
            ),
        ],
    )
}

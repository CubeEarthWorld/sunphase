use sunphase::NaiveDate;
#[path = "../benchmark/workloads.rs"]
mod data;
use std::{
    hint::black_box,
    time::{Duration, Instant},
};
use sunphase::{Options, Parser};
#[cfg(windows)]
fn memory() -> (usize, usize) {
    #[repr(C)]
    struct Counters {
        cb: u32,
        faults: u32,
        peak: usize,
        current: usize,
        pool_peak: usize,
        pool: usize,
        nonpaged_peak: usize,
        nonpaged: usize,
        page: usize,
        page_peak: usize,
    }
    #[link(name = "psapi")]
    unsafe extern "system" {
        fn GetProcessMemoryInfo(process: isize, counters: *mut Counters, size: u32) -> i32;
    }
    let mut c = Counters {
        cb: std::mem::size_of::<Counters>() as u32,
        faults: 0,
        peak: 0,
        current: 0,
        pool_peak: 0,
        pool: 0,
        nonpaged_peak: 0,
        nonpaged: 0,
        page: 0,
        page_peak: 0,
    };
    // SAFETY: -1 is the current-process pseudo handle; c has the API's layout.
    unsafe {
        GetProcessMemoryInfo(-1, &mut c, std::mem::size_of::<Counters>() as u32);
    }
    (c.current, c.peak)
}
#[cfg(not(windows))]
fn memory() -> (usize, usize) {
    (0, 0)
}
fn main() {
    let parser = Parser::default();
    let reference = NaiveDate::from_ymd_opt(2025, 2, 8)
        .unwrap()
        .and_hms_opt(11, 5, 0)
        .unwrap();
    let codes = ["en", "ja", "zh", "es", "hi", "ko", "ru"];
    for (name, count) in [
        ("parse_short_default", 2000),
        ("parse_seven_languages", 2000),
        ("parse_month_anchor", 2000),
        ("parse_range", 1500),
        ("parse_long_point", 50),
        ("parse_long_range", 40),
        ("parse_long_no_match", 300),
    ] {
        let run = |i: usize| {
            let mut o = Options::new(reference);
            let single = [codes[i % 7]];
            let input = match name {
                "parse_short_default" => data::SHORT[i % data::SHORT.len()],
                "parse_seven_languages" => {
                    o.languages = &single;
                    data::LANGUAGES[i % 7][(i / 7) % 3]
                }
                "parse_month_anchor" => {
                    o.languages = &["en"];
                    "next month on the 21st at 2pm"
                }
                "parse_range" => {
                    o.range = true;
                    data::RANGE[i % 5]
                }
                "parse_long_point" | "parse_long_range" => {
                    o.range = name == "parse_long_range";
                    data::LONG
                }
                _ => data::NO_MATCH,
            };
            let results = black_box(parser.parse(black_box(input), &o).unwrap());
            results.len()
                + results.first().map_or(0, |r| r.date.day() as usize)
                + results
                    .last()
                    .map_or(0, |r| input[..r.start].encode_utf16().count())
        };
        let warm = Instant::now();
        let mut i = 0;
        while warm.elapsed() < Duration::from_millis(250) {
            black_box(run(i));
            i += 1;
        }
        let timer = Instant::now();
        let mut checksum = 0;
        for i in 0..count {
            checksum += run(i);
        }
        let elapsed = timer.elapsed().as_micros();
        let (rss, peak) = memory();
        println!(
            "{{\"case\":\"{name}\",\"iterations\":{count},\"elapsed_us\":{elapsed},\"us_per_op\":{},\"checksum\":{checksum},\"rss_bytes\":{rss},\"max_rss_bytes\":{peak}}}",
            elapsed as f64 / count as f64
        );
    }
}

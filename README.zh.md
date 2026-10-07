# Sunphase — Rust

支持英语、日语、中文、西班牙语、印地语、韩语和俄语的自然语言日期时间解析器。使用Cargo管理依赖，支持原生和Wasm。

```toml
[dependencies]
sunphase = { git = "https://github.com/CubeEarthWorld/sunphase", tag = "v1.0.0" }
```

显式提供基准日期。结果使用原始文本的UTF-8字节位置。词汇与模式独立于通用的日期计算逻辑，可添加自定义语言。异步调用由应用的工作线程处理。

[Rust API与示例](README.md) / [扩展方法](docs/EXTENDING.md) / [性能比较](benchmark/REPORT.ja.md)

v1.0.0完全替换为Rust，不保留Dart包。BSD 3-Clause许可证。

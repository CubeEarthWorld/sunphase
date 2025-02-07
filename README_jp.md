---

#### README_zh.md

```markdown
# Sunphase

Sunphase 是一个用于 Dart/Flutter 的自然语言日期解析包。它支持解析包括英语、日语和中文在内的多种语言的日期表达，从文本中轻松提取日期信息。使用 Sunphase，您可以轻松将用户输入的文本中的日期提取出来，并在应用中进行处理。

## 功能

- 解析自然语言日期表达，例如 "today"、"tomorrow"、"yesterday"、"next week"、"last month"、"Monday"、"January 1, 2025" 等。
- 支持多种语言：英语、日语、中文。
- 可自定义的解析和细化流程。
- 提供单一日期模式和日期范围模式。
- 架构具有高扩展性，便于添加新的解析器和细化器。

## 入门指南

### 前提条件

- 已安装 Dart 或 Flutter SDK。
- 具备 Dart/Flutter 的基本知识。

### 安装

在 `pubspec.yaml` 文件中添加以下依赖：

```yaml
dependencies:
sunphase: ^1.0.0
```

然后运行以下命令：

```bash
dart pub get
# 或
flutter pub get
```

## 使用方法

导入包并调用 `parse` 函数：

```dart
import 'package:sunphase/sunphase.dart';

void main() {
final text = "next week, Monday and January 1, 2025";
// 如果不指定语言，默认会使用所有支持的语言（英语、日语、中文）进行解析。
final results = parse(text, language: 'en', rangeMode: true);
for (var result in results) {
print(result);
}
}
```

## 其他信息

有关如何扩展 Sunphase，添加新的解析器或细化器，请参阅源码中的文档。如果您有任何问题或建议，请在项目仓库中提交 issue。

## 许可证

本项目采用 CC0 1.0 Universal 许可证发布。
```

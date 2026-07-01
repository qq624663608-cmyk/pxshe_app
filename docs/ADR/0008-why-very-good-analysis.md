# ADR-0008: 为什么 very_good_analysis

## 背景

Flutter lint 选项:
- flutter_lints (官方, 默认)
- pedantic (deprecated)
- very_good_analysis (Very Good Ventures 维护, 严格)
- effective_dart (Effective Dart 团队)

候选:
- **A. very_good_analysis** (推荐)
- B. flutter_lints (默认)
- C. 自定义

## 决策

**用 very_good_analysis + bloc_lint**。

依赖:
```yaml
dev_dependencies:
  very_good_analysis: ^10.3.0
  bloc_lint: ^0.4.1
```

`analysis_options.yaml`:
```yaml
include:
  - package:very_good_analysis/analysis_options.yaml
  - package:bloc_lint/recommended.yaml
analyzer:
  exclude:
    - lib/l10n/gen/*
linter:
  rules:
    public_member_api_docs: false  # 关闭公开 API doc 强制
```

## 后果

### 好处
- **严格 lint** (200+ 规则, 业内最严)
- **bloc_lint** (BLoC 特定规则: state class Equatable 等)
- **跟 very_good_cli 集成** (模板自带)
- **CI 友好** (flutter analyze 0/0 是基线)

### 坏处
- **规则太严** (新手会吐槽: `prefer_single_quotes` / `lines_longer_than_80_chars` 等)
- **某些规则是 opinionated** (比如 `always_declare_return_types`)
- **false positive** (hive_ce 等生成的代码可能误报)

### 风险
- **第三方包不兼容** (某些包可能违反规则, 升级会报错)
- **代码生成** (json_serializable / freezed 输出可能违反)

## 替代方案

### B. flutter_lints (不选)
- 优势: 官方, 简单
- 不选: 规则太少, 不足以保证代码质量

### C. 自定义 (不选)
- 优势: 完全可控
- 不选: 维护成本高, 新人不知道哪些规则重要

## 实施细节

### 关闭某些规则

如果某些规则太严或 false positive, 可以在 `analysis_options.yaml` 关闭:

```yaml
linter:
  rules:
    public_member_api_docs: false  # 不强制公开 API doc
    avoid_redundant_argument_values: false  # 默认值冗余参数允许
```

### 跟 CI 集成

```yaml
# .github/workflows/ci.yml
- name: Analyze
  run: flutter analyze
```

`flutter analyze` 0/0 是 PR 合并必要条件 (AGENTS §12)。

### 跟 IDE 集成

VS Code `settings.json`:
```json
{
  "dart.lineLength": 80,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.rulers": [80]
  }
}
```

详见 [CONTRIBUTING.md §3 PR 模板](../CONTRIBUTING.md) + [BUILDING_BLOCKS.md §7 #26](../BUILDING_BLOCKS.md)。

---

*状态: 已接受 | 日期: 2026-07-01*
# ADR-0002: 为什么 Clean Architecture

## 背景

pxshe_app 是一个中型 Flutter app, 预计 5+ 个业务模块 (auth / registration / im / universe / table / row), 需要清晰的架构。

候选:
- **A. Clean Architecture** (推荐)
- B. MVC (老)
- C. 单一 module (不分层)
- D. Redux 模式

## 决策

**选 Clean Architecture**。

分层:
```
modules/  (业务层, 6 个 module)
  ↓
_core/   (基建层: DI / ApiClient / Database / Error)
_shared/ (跨 module 共享)
```

每个 module 内部:
```
data/      (Repository Impl + DataSource)
domain/    (Entity + Repository 接口)
bloc/      (BLoC / Cubit)
features/  (UI)
```

## 后果

### 好处
- **依赖方向明确** (只能向下, 不能反向), 编译时 + architecture test 强制
- **业务核心独立** (domain 层 0 依赖外层), 可独立测试
- **可替换性** (DI 注入, Repository 换实现不需要改业务逻辑)
- **团队熟悉** (universe_app 也用 Clean Arch)

### 坏处
- **样板代码多** (Entity / Repository / RepositoryImpl 3 个类)
- **学习曲线** (新人要理解分层)
- **过度设计风险** (简单功能可能被强制分 3 层)

### 风险
- **Repository 模式** 复杂业务可能要用 UseCase 编排, 增加复杂度
- **Entity 字段冗余** (DTO / Entity / Model 3 套)

## 替代方案

### B. MVC (不选)
- Controller 容易变成 god object
- Model 容易跟 Entity 混淆

### C. 单一 module (不选)
- 5+ module 不分层会混乱
- universe_app 教训

### D. Redux 模式 (不选)
- 单向数据流对 IM 事件流不友好
- 跟 BLoC 重复

## 实施细节

依赖方向 (AGENTS §49):
```
modules -> _core / _shared
_shared -> _core
_core -> 0 依赖 modules
modules 之间 ✗ (走 <module>_module.dart 门面)
```

Module 内部布局 (RECIPES §2):
```
module/
├── <name>_module.dart      (DI 注册)
├── <name>_routes.dart      (GoRoute 列表)
├── data/
│   ├── datasources/
│   ├── repositories/
│   └── models/
├── domain/
│   ├── entities/
│   ├── <name>_repository.dart  (接口)
│   └── <name>_usecases.dart   (可选)
├── bloc/
│   ├── <name>_bloc.dart / <name>_cubit.dart
│   ├── <name>_event.dart
│   └── <name>_state.dart
└── features/
    ├── <page>.dart
    └── widgets/
```

Architecture test 强制:
```dart
// test/architecture/no_cross_module_import_test.dart
// 禁止 modules/*/data 直接 import modules/*/presentation
```

详见 [ARCHITECTURE.md](../ARCHITECTURE.md) + [KNOWLEDGE_GRAPH.md §2](../KNOWLEDGE_GRAPH.md)。

---

*状态: 已接受 | 日期: 2026-07-01*
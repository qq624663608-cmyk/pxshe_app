# ADR-0005: 为什么 feature-first + 门面模式

## 背景

Clean Arch 解决了"分层", 但是 **module 之间** 的关系没规定。

候选:
- **A. feature-first + 门面** (推荐)
- B. 集中入口 (1 个 app.dart 路由所有)
- C. 自由 import (无约束)

## 决策

**每个 module 暴露 `<m>_module.dart` 门面**, 跨 module 调用走门面, **禁止直接 import 对方内部**。

```dart
// lib/modules/auth/auth_module.dart
class AuthModule {
  AuthBloc get bloc => di();
  AuthRepository get repository => di();
  Future<void> register() async { ... }
}

// lib/_core/_init_modules.dart
Future<void> initBeforeRunApp() async {
  await registerAuthModule();
  await registerIMModule();
  await registerUniverseModule();
  // ...
}
```

依赖方向 (硬约束):
- `modules/A/data` 绝不 import `modules/B/data` 或 `modules/B/presentation`
- `modules/A/data` 只能 import `modules/A/domain`
- `_core` 0 依赖 modules

## 后果

### 好处
- **删 module 删 1 目录** (设计初心 #2, AGENTS §★)
- **1 个改动 1 处修改** (设计初心 #1)
- **跨 module 走门面** — 改 AuthRepositoryImpl 内部, IM module 不用动
- **architecture test 强制** — CI 跑 no_cross_module_import_test

### 坏处
- **门面代码多** (每个 module 1 个)
- **event 跨 module 麻烦** (auth 状态变 → im 状态变, 要走 Cubit → Cubit event)
- **DI 容器大** (6+ module + 多个 cubit)

### 风险
- **过度门面化** (1 个简单 module 也写 facade 反而麻烦)
- **测试时跨 module 难** (要 mock 整个 facade)

## 替代方案

### B. 集中入口 (不选)
- 1 个 app.dart 路由所有 module
- 问题: app.dart 变成 god file
- 删 module 要改 app.dart

### C. 自由 import (不选)
- 跨 module 随便 import
- 问题: 删 module 牵一发动全身
- 反 5 大反模式 (AGENTS §★)

## 实施细节

### 模板: `<m>_module.dart`

```dart
// lib/modules/<m>/<m>_module.dart
import 'package:get_it/get_it.dart';

import '../../_core/di.dart';
import 'data/<m>_repository_impl.dart';
import 'domain/<m>_repository.dart';
import 'bloc/<m>_bloc.dart';
import 'bloc/<m>_cubit.dart';

final di = GetIt.instance;

Future<void> register<M>Module() async {
  // DataSource
  // di.registerLazySingleton<<M>RemoteDataSource>(() => <M>RemoteDataSource(di()));
  // di.registerLazySingleton<<M>LocalDataSource>(() => <M>LocalDataSource(di()));

  // Repository
  di.registerLazySingleton<<M>Repository>(
    () => <M>RepositoryImpl(di(), di()),
  );

  // Bloc / Cubit
  di.registerLazySingleton<<M>Bloc>(() => <M>Bloc(repository: di()));
  di.registerFactory<<M>Cubit>(() => <M>Cubit(...));
}
```

### 跨 module 调用 (走门面)

```dart
// ✅ 正确
final user = await di<AuthModule>().repository.getUser();

// ❌ 错误 (直接 import 对方内部)
import 'package:pxshe_app/modules/auth/data/auth_repository_impl.dart';
final user = await di<AuthRepositoryImpl>().getUser();
```

详见 [AGENTS.md §4](../AGENTS.md) + [RECIPES.md §2](../RECIPES.md) Recipe 2。

---

*状态: 已接受 | 日期: 2026-07-01*
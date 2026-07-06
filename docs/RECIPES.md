# docs/RECIPES.md — 5 个"加新 X"步骤

> **本文件是新增/修改的 SSOT。**
> 任何新功能 / widget / API / 错误码, 先看这里。

---

## Recipe 1: 加新 widget (6 步)

```bash
□ 1. 选位置:
     - 通用 widget (跨 module) → lib/_shared/widgets/<name>.dart
     - 通用 widget (跨 app) → lib/_core/widgets/<name>.dart
     - 业务 widget (单 module) → lib/modules/<m>/features/.../widgets/<name>.dart
□ 2. 创建 <name>.dart (必须用 4 Token + 已有 mixin, 见 BUILDING_BLOCKS.md)
□ 3. 写 test/widget/<name>_test.dart (5-10 case)
□ 4. docs/BUILDING_BLOCKS.md §3 加 1 行
□ 5. docs/RECIPES.md 更新 (如有新模式)
□ 6. 跑 flutter analyze + flutter test
```

### 模板

```dart
// lib/_shared/widgets/my_widget.dart
import 'package:flutter/material.dart';
import '../../_core/theme/app_colors.dart';
import '../../_core/theme/app_spacing.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(label, style: TextStyle(color: AppColors.textPrimary)),
    );
  }
}
```

---

## Recipe 2: 加新 module (12 步)

```bash
□ 1. mkdir lib/modules/<m>/
□ 2. 写 <m>_module.dart (DI 注册入口)
□ 3. 写 <m>_routes.dart (GoRoute 列表)
□ 4. 写 domain/entities/<entity>.dart (Hive TypeAdapter)
□ 5. 写 domain/<m>_repository.dart (接口)
□ 6. 写 data/<m>_repository_impl.dart (实现)
□ 7. 写 data/datasources/<m>_remote_ds.dart (HTTP 调用)
□ 8. 写 data/datasources/<m>_local_ds.dart (Hive 调用, 如有)
□ 9. 写 bloc/<m>_bloc.dart 或 bloc/<m>_cubit.dart
□ 10. 写 features/<page>.dart (UI)
□ 11. _core/_init_modules.dart 加 register<M>Module()
□ 12. 写 test/ (3 个文件: bloc / repository / widget)
    + docs/PAGE_CLASSIFICATION.md 加 1 行
    + docs/KNOWLEDGE_GRAPH.md §4 加 1 行
```

### 模板: `<m>_module.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../_core/constants.dart';
import '../../_core/di.dart';
import 'data/<m>_repository_impl.dart';
import 'domain/<m>_repository.dart';
import 'bloc/<m>_bloc.dart';

Future<void> register<M>Module() async {
  di.registerLazySingleton<<M>Repository>(
    () => <M>RepositoryImpl(dio: di(), hive: di()),
  );
  di.registerLazySingleton<<M>Bloc>(
    () => <M>Bloc(repository: di()),
  );
  di<List<RouteBase>>(instanceName: Constants.mainRouesDiKey).addAll(<m>Routes());
}
```

### 模板: `<m>_routes.dart`

```dart
import 'package:go_router/go_router.dart';
import '../../_core/app_router.dart';
import 'features/<page>.dart';

List<GoRoute> <m>Routes() {
  return [
    GoRoute(
      path: '/<m>',
      redirect: authRouteGuard,
      pageBuilder: (context, state) => const FadeTransitionPage(
        child: <Page>(),
      ),
    ),
  ];
}
```

### 模板: `<m>_bloc.dart` (BLoC)

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/<m>_repository.dart';
import '../domain/entities/<entity>.dart';

part '<m>_event.dart';
part '<m>_state.dart';

class <M>Bloc extends Bloc<<M>Event, <M>State> {
  <M>Bloc({required <M>Repository repository})
      : _repository = repository,
        super(const <M>State()) {
    on<<M>LoadRequested>(_onLoad);
  }

  final <M>Repository _repository;

  Future<void> _onLoad(
    <M>LoadRequested event,
    Emitter<<M>State> emit,
  ) async {
    emit(state.copyWith(status: <M>Status.loading));
    final res = await _repository.get<Thing>(event.id);
    res.fold(
      (failure) => emit(state.copyWith(
        status: <M>Status.error,
        errorMessage: failure.getMessage(),
      )),
      (data) => emit(state.copyWith(
        status: <M>Status.loaded,
        data: data,
      )),
    );
  }
}
```

### 模板: `<m>_event.dart` (part of)

```dart
part of '<m>_bloc.dart';

abstract class <M>Event extends Equatable {
  const <M>Event();
  @override
  List<Object> get props => [];
}

class <M>LoadRequested extends <M>Event {
  const <M>LoadRequested(this.id);
  final String id;
  @override
  List<Object> get props => [id];
}
```

### 模板: `<m>_state.dart` (part of)

```dart
part of '<m>_bloc.dart';

enum <M>Status { initial, loading, loaded, error }

class <M>State extends Equatable {
  const <M>State({
    this.status = <M>Status.initial,
    this.data,
    this.errorMessage,
  });

  final <M>Status status;
  final <Entity>? data;
  final String? errorMessage;

  <M>State copyWith({
    <M>Status? status,
    <Entity>? data,
    String? errorMessage,
  }) {
    return <M>State(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
```

---

## Recipe 3: 加新 API 端点 (5 步)

```bash
□ 1. modules/<m>/data/datasources/<m>_remote_ds.dart 加方法
□ 2. modules/<m>/domain/entities/<entity>.dart 加 entity (Hive TypeAdapter)
□ 3. modules/<m>/domain/<m>_repository.dart 加抽象
□ 4. modules/<m>/data/<m>_repository_impl.dart 实现
□ 5. docs/API.md 加 1 行
   + 写 3 个测试 (remote_ds / repository / bloc)
```

### 模板: remote_ds

```dart
class <M>RemoteDataSource {
  final Dio _dio;
  <M>RemoteDataSource(this._dio);

  Future<dynamic> get<Thing>(String id) async {
    final res = await _dio.post('/business/<m>/<action>', data: {'id': id});
    return res.data;
  }
}
```

---

## Recipe 4: 加新错误码 (3 步)

> **当前实现 (2026-07-06)**: 错误码在 `lib/_core/error/api_exception.dart:9` 的 `enum ErrorKey`,
> 错误消息**hardcoded 中文**在同文件 `_defaultMessageFor()` 函数里 (line 166)。
> 后端返的 `errMsg` 优先用, 没的话 fallback 到 hardcoded 中文。
>
> 阶段 4 (i18n 深化) 时, `_defaultMessageFor()` 应改用 `AppLocalizations.of(context)!.<key>`。

```bash
□ 1. lib/_core/error/api_exception.dart enum ErrorKey 加 1 行 (code, name)
□ 2. lib/_core/error/api_exception.dart _defaultMessageFor() 加 1 case (中文 fallback)
□ 3. test/_core/error/api_exception_test.dart 加 1 case
```

### 模板

```dart
// api_exception.dart:9 enum ErrorKey
enum ErrorKey {
  // ... existing
  myNewError(1009, 'MyNewError'),
}

// api_exception.dart:166 _defaultMessageFor() switch
case ErrorKey.myNewError:
  return '我的新错误';
```

---

## Recipe 5: 加新 ADR (4 步)

```bash
□ 1. docs/ADR/NNNN-decision-name.md 写 4 段:
     - 背景 (为什么)
     - 决策 (选了啥)
     - 后果 (好处/坏处)
     - 替代方案 (考虑过啥, 为啥不选)
□ 2. AGENTS.md 加交叉引用
□ 3. docs/KNOWLEDGE_GRAPH.md §5 加 1 行
□ 4. PR 标出 ADR-NNNN
```

### 模板

```markdown
# ADR-NNNN: <决策标题>

## 背景
<为什么需要决策, 什么问题>

## 决策
<选了哪个方案, 详细>

## 后果
- 好处
- 坏处
- 风险

## 替代方案
- 方案 A: ...
- 方案 B: ...
- 为啥不选 A/B
```

---

*最后更新: 2026-07-01*
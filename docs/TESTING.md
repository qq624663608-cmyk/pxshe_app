# docs/TESTING.md — 4 层级测试策略

> **本文件是测试策略 SSOT。**
> 目标覆盖率 ≥ 80%, CI 强制 100%。

---

## 1. 4 层级测试

```
┌─────────────────────────────────┐
│ L4. 真机 E2E (patrol)            │  慢 (> 5min)  │  5 关键流程 (阶段 5)
├─────────────────────────────────┤
│ L3. 集成测试 (integration_test/) │  中 (> 1min)  │  5 关键流程
├─────────────────────────────────┤
│ L2. Widget 测试 (test/widget/)   │  快 (< 30s)   │  通用 widget 全覆盖
├─────────────────────────────────┤
│ L1. 单元测试 (test/unit/)        │  最快 (< 5s)  │  Bloc/Cubit/Repository/UseCase ≥ 80%
└─────────────────────────────────┘
```

---

## 2. L1: 单元测试 (快, 必做)

**目标**: Bloc / Cubit / Repository / UseCase / Helper, 覆盖率 ≥ 80%。

### 工具

```yaml
dev_dependencies:
  very_good_cli: ^1.3.0   # 跑测试 + 覆盖率
  mocktail: ^1.0.5        # 纯 Dart mock (替代 mockito)
  bloc_test: ^10.0.0     # Bloc 单测
```

### 跑法

```bash
very_good test --coverage --min-coverage 100
```

### 模板: Bloc 单测

```dart
// test/modules/auth/bloc/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc', () {
    late AuthBloc bloc;
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
      bloc = AuthBloc(authUsecase: AuthUsecases(repo));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [authenticated] when login succeeds',
      build: () => bloc,
      act: (bloc) => bloc.add(LoginRequested(
        areaCode: '+86',
        phoneNumber: '13900000001',
        password: 'Test123456',
        platform: 2,
      )),
      expect: () => [
        predicate<AuthState>((s) => s.status == AuthStatus.loading),
        predicate<AuthState>((s) => s.status == AuthStatus.authenticated),
      ],
      verify: (_) {
        verify(() => repo.login(
          areaCode: '+86',
          phoneNumber: '13900000001',
          password: 'Test123456',
          platform: 2,
        )).called(1);
      },
    );
  });
}
```

### 模板: Cubit 单测

```dart
// test/modules/universe/bloc/universe_list_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUniverseRepository extends Mock implements UniverseRepository {}

void main() {
  group('UniverseListCubit', () {
    late UniverseListCubit cubit;
    late MockUniverseRepository repo;

    setUp(() {
      repo = MockUniverseRepository();
      cubit = UniverseListCubit(repo);
    });

    test('loads universes', () async {
      when(() => repo.list(keyword: '', page: 1, size: 20))
          .thenAnswer((_) async => Right(UniverseListResult(
                total: 1,
                list: [Universe(id: 1, name: 'test')],
                currentUid: '123',
              )));

      await cubit.load();
      expect(cubit.state.status, UniverseStatus.loaded);
      expect(cubit.state.data!.list.length, 1);
    });

    test('emits error on failure', () async {
      when(() => repo.list(keyword: '', page: 1, size: 20))
          .thenAnswer((_) async => const Left(ServerFailure('fail')));

      await cubit.load();
      expect(cubit.state.status, UniverseStatus.error);
      expect(cubit.state.errorMessage, 'fail');
    });
  });
}
```

### 模板: Repository 单测 (mocktail)

```dart
// test/modules/auth/data/auth_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}
class MockHiveInterface extends Mock implements HiveInterface {}

void main() {
  group('AuthRepositoryImpl', () {
    late AuthRepositoryImpl repo;
    late MockDio dio;

    setUp(() {
      dio = MockDio();
      repo = AuthRepositoryImpl(dio: dio, hive: MockHiveInterface());
    });

    test('login returns user on success', () async {
      when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response<dynamic>(
          data: {
            'errorCode': 0,
            'data': {
              'chatToken': 'eyJ...',
              'userID': '123',
              'imToken': 'eyJ...',
            },
          },
          requestOptions: RequestOptions(path: '/account/login'),
        ),
      );

      final res = await repo.login(
        areaCode: '+86',
        phoneNumber: '13900000001',
        password: 'Test123456',
        platform: 2,
      );
      expect(res.isRight(), isTrue);
    });
  });
}
```

---

## 3. L2: Widget 测试 (快, 必做)

**目标**: 通用 widget + 关键 Page。

### 工具

`flutter_test` (内置)

### 模板

```dart
// test/widgets/base_loading_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pxshe_app/_core/widgets/base_loading.dart';

void main() {
  testWidgets('BaseLoading renders CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BaseLoading())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

---

## 4. L3: 集成测试 (中, 关键流程)

**目标**: 5 关键流程。

```dart
// integration_test/login_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pxshe_app/main_development.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('登录 → 首页 → 退出', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // 1. SplashPage 跳 LoginPage
    expect(find.text('登录'), findsOneWidget);

    // 2. 输入 + 提交
    await tester.enterText(find.byType(TextField).first, '13900000001');
    await tester.enterText(find.byType(TextField).last, 'Test123456');
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    // 3. 验证跳首页
    expect(find.text('宇宙'), findsOneWidget);
  });
}
```

### 5 关键流程

1. 启动 → SplashPage → LoginPage → 登录 → HomePage
2. 世界列表 → 创建世界 → 创建子表 → 添加数据
3. IM 单聊 → 发消息 → 收到
4. 改密 → 踢下线 → 重新登录
5. 强升触发 → 弹窗 → 跳商店 (阶段 5)

---

## 5. L4: 真机 E2E (patrol, 阶段 5)

```dart
// integration_test/patrol/auth_flow_test.dart
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('登录 → 首页', ($) async {
    await $.pumpWidgetAndSettle(const App());
    await $.tap(find.text('登录'));
    await $.enterText(find.byType(TextField).first, '13900000001');
    await $.enterText(find.byType(TextField).last, 'Test123456');
    await $.tap(find.text('提交'));
    await $.native.pressHome();
    await $.native.openApp();
    await $.takeScreenshot(name: 'home');
  });
}
```

---

## 6. 架构测试 (硬约束)

```dart
// test/architecture/no_cross_module_import_test.dart
void main() {
  test('禁止 modules/*/data 直接 import modules/*/presentation', () {
    // 扫描 lib/modules/ 找违规 import
  });

  test('禁止 modules/*/ 直接 import 其他 modules/*/data', () {
    // 扫描 lib/modules/ 找违规 import
  });
}
```

详见 [ARCHITECTURE.md §7](./ARCHITECTURE.md) 模块依赖矩阵。

---

## 7. 覆盖率基线 100%

```bash
very_good test --coverage --min-coverage 100
```

**任何 commit 都不能让覆盖率下降**。

---

*最后更新: 2026-07-01*
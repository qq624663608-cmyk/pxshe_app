# docs/ARCHITECTURE.md — 架构总览

> **本文件是架构 SSOT。**
> 设计意图: 为什么用 Clean Arch + BLoC + Modular + Chat 域优先。

---

## 1. 分层 (Clean Architecture)

```
┌─────────────────────────────────────────┐
│ lib/                入口 (main_*.dart + bootstrap) │
├─────────────────────────────────────────┤
│ modules/           业务层 — 每个 module 自包含 (data / domain / bloc / features) │
├─────────────────────────────────────────┤
│ _shared/           跨 module 共享 (theme / 通用 widget / 公共路由) │
├─────────────────────────────────────────┤
│ _core/             基建层 — 无业务依赖 (Bootstrap / DI / ApiClient / Database / Error) │
└─────────────────────────────────────────┘
```

**依赖方向** (只能向下, 不能反向):
- `modules` → `_core` / `_shared`
- `_shared` → `_core`
- `_core` → 0 依赖 modules
- `modules` ↛ 其他 modules (走 `<module>_module.dart` 门面)

---

## 2. Module 隔离原则

每个 module 是**自包含**的:
- 1 个目录: `lib/modules/<m>/`
- 1 个门面: `<m>_module.dart` (`register<M>Module()`)
- 1 个路由: `<m>_routes.dart` (`<m>Routes()`)
- 1 个 Bloc/Cubit 入口
- data / domain / bloc / features 四个子目录

```dart
// ✅ 正确: 跨 module 调用走对方门面
registerAuthModule();
registerIMModule();

// ❌ 错误: 直接 import 对方内部
import 'package:pxshe_app/modules/auth/data/auth_repository_impl.dart';
final repo = AuthRepositoryImpl(...);
```

详见 [ADR-0005](./ADR/0005-why-feature-facade.md)。

---

## 3. BLoC 模式 (vs Riverpod/ChangeNotifier)

| 维度 | BLoC 9.x | Riverpod 2.x | ChangeNotifier |
|---|---|---|---|
| 事件驱动 | ✅ 天然 (适合 IM) | ⚠️ Notifier | ❌ |
| 多 sub-feature 隔离 | ✅ 天然 | ✅ | ❌ 易 god notifier |
| 编译时安全 | ✅ event/state 类强类型 | ✅ | ❌ |
| 测试容易 | ✅ bloc_test | ✅ ProviderContainer | ⚠️ |
| 学习曲线 | 中 | 中 | 低 |
| 适合 IM 消息流 | ✅ 最佳 | ⚠️ | ❌ |

详见 [ADR-0001](./ADR/0001-why-bloc.md)。

---

## 4. 目录结构

```
pxshe_app/
├── lib/
│   ├── main_*.dart               # 3 flavor 入口 (development/staging/production)
│   ├── bootstrap.dart            # very_good 4 阶段启动入口
│   ├── app/                      # App widget (MaterialApp.router)
│   ├── _core/                    # 基建
│   │   ├── _bootstrap.dart       # 4 阶段启动逻辑
│   │   ├── _init_modules.dart    # module 注册中心
│   │   ├── app_router.dart       # GoRouter + 路由守卫
│   │   ├── di.dart               # get_it 容器
│   │   ├── database.dart         # Hive CE 初始化
│   │   ├── http_client.dart      # ApiClient (Dio 封装, 拦截器)
│   │   ├── env.dart              # 环境配置
│   │   ├── theme.dart            # AppColors + Material 3
│   │   ├── error/                # ErrorHandler / ApiException / Failure
│   │   └── ...
│   ├── _shared/                  # 跨 module 共享
│   │   ├── shared_module.dart    # ThemeModeCubit 注册
│   │   ├── shared_routes.dart    # 公共路由 (Splash / Home / Settings)
│   │   ├── blocs/                # 全局 Cubit
│   │   └── features/             # 公共页面
│   └── modules/                  # 业务模块
│       ├── auth/                 # 登录
│       ├── registration/         # 注册 (阶段 1.5)
│       ├── im/                   # ✅ IM 客户端 (阶段 2)
│       │   ├── data/datasources/openim_sdk_wrapper.dart
│       │   ├── data/repositories/  # 5 个 repository 实现
│       │   ├── domain/             # 5 个 repository 接口
│       │   ├── bloc/               # 5 个 Cubit
│       │   ├── features/           # ChatList / ChatPage / Contacts / Profile
│       │   ├── auth_module_bridge.dart  # 跨 module 拿 imToken
│       │   ├── im_module.dart      # DI 注册 + bootstrapIMAfterLogin()
│       │   └── im_routes.dart      # GoRouter 路由
│       ├── universe/             # 业务 (阶段 3)
│       ├── table/                # 业务 (阶段 3)
│       └── row/                  # 业务 (阶段 3)
├── test/                         # 单元 + widget test
├── android/                       # Android 平台
├── ios/                           # iOS 平台
└── docs/                          # 18+ SSOT 文档 + 10 ADR
```

---

## 5. 启动流程 (4 阶段)

```
[1] Native 启动 (Android/iOS)
      ↓
[2] main_*.dart
      ├─ WidgetsFlutterBinding.ensureInitialized()
      └─ await bootstrap(() => App())
              ↓
[3] bootstrap.dart → Bootstrap.init() (lib/_core/_bootstrap.dart)
      ├─ Log.init
      ├─ HttpClient.init()                   # Dio 拦截器
      ├─ Database.init()                     # Hive CE box 打开
      ├─ RegistrationConfigService.init()   # 拉 /business/public/registration/config/get
      ├─ AppModules.initBeforeRunApp()       # 注册所有 module
      └─ AppRouter 注册
      ↓
[4] App 启动 (runApp)
      ├─ MultiBlocProvider (AuthBloc + ThemeModeCubit)
      └─ MaterialApp.router (LoadingPage 决定路由)
            ├─ status=unknown → LoadingPage 等待
            ├─ status=authenticated → HomePage
            └─ status=unauthenticated → LoginPage
```

详见 [docs/IM_INTEGRATION.md](./IM_INTEGRATION.md) 的 OpenIM 集成流程。

---

## 6. 数据流示例 (登录)

```
[LoginPage]
    │ 用户输入 areaCode + phoneNumber + password
    │ 点击"登录"
    ↓
[LoginCubit / AuthBloc]
    │ add(LoginRequested(...))
    ↓
[AuthUsecases]
    │ login(areaCode, phoneNumber, password, platform)
    ↓
[AuthRepositoryImpl]
    │ dio.post('/account/login', {...})
    ↓
[ApiClient + Dio + Interceptors]
    │ AuthInterceptor: 自动加 `token: <chatToken>` (如果有)
    │ OperationIdInterceptor: 自动生成 `operationID`
    ↓
[chat.pxshe.com:10008]
    ↓
[Response]
    │ errorCode: 0
    │ data: {
    │   chatToken: "eyJ...",
    │   userID: "3370159211",
    │   imToken: "eyJ..."
    │ }
    ↓
[AuthRepositoryImpl]
    │ _chatToken = payload['chatToken']
    │ _imToken = payload['imToken']
    │ _userId = payload['userID']
    │ _cacheTokens() → Hive
    │ _cacheUser() → Hive
    │ _userController.add(UserModel(...))
    ↓
[AuthBloc]
    │ emit(state.copyWith(status: authenticated))
    ↓
[App Router Guard]
    │ 检测到 authenticated → 跳 HomePage
```

**注意**: 之前是在 LoginPage 内手动 `context.go('/home')`。现在改用 **§ 6.5 refreshListenable 模式**, 业务层 (Bloc) emit 状态 → GoRouter 自动重跑守卫 → 跳。**业务代码不再需要碰 Navigator**。

---

## 6.5 路由刷新机制 (refreshListenable) ⭐

**背景**: 之前登录成功 spinner 一直转, **真因** 是 `AuthBloc` emit `authenticated` 后, GoRouter 不知道, 没人调 `context.go('/home')`。

**修法 (go_router 官方推荐模式)**: `GoRouter` 监听 `Listenable`, 每次 `AuthBloc.stream` emit 触发 `notifyListeners()`, GoRouter 重新评估所有 `redirect:` 守卫。

```dart
// lib/_core/app_router.dart
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  void bind(Stream<dynamic> authBlocStream) {
    _subscription = authBlocStream.listen((_) => notifyListeners());
  }
  StreamSubscription? _subscription;
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AppRouter {
  final _refreshNotifier = _AuthRouterRefreshNotifier();
  late final router = GoRouter(
    refreshListenable: _refreshNotifier,
    routes: routes,
  );
  void bindAuthBloc() => _refreshNotifier.bind(di<AuthBloc>().stream);
}

// lib/app/view/app.dart (App.build)
final router = di<AppRouter>();
router.bindAuthBloc();  // 一次性绑定
```

**go_router 17.x 提醒**: 该版本没 `GoRouterRefreshStream` (13.x+ 有, 17.x 删了), 自己包 `ChangeNotifier`。

### 路由守卫双向跳转 (refreshListenable + guards)

| 路径 | 守卫 | 已登录 | 未登录 |
|---|---|---|---|
| `/login` | `unAuthRouteGuard` | 跳 `/home` | 允许 |
| `/register` | `unAuthRouteGuard` | 跳 `/home` | 允许 |
| `/home` | `authRouteGuard` | 允许 | 跳 `/login` |
| `/profile` | `authRouteGuard` | 允许 | 跳 `/login` |

(`/home` 之前跳 `/errors/401`, 已改为 `/login` — 让用户能直接登录)

**效果**:
- 登录成功 → `AuthBloc` emit `authenticated` → `refreshListenable` 触发 → `/login` 的 `unAuthRouteGuard` 检测到已登录 → 跳 `/home`
- 登出 → `AuthBloc` emit `unauthenticated` → `/home` 的 `authRouteGuard` 检测到未登录 → 跳 `/login`
- 业务代码**零** `context.go()` 调用, 跳转全自动

### 6.6 启动时序 (硬约束)

`initAfterRunApp(context)` **必须**在 `App.build` 里调, 否则 navTabs 列表是空, 路由守卫死循环。

```dart
// lib/app/view/app.dart
@override
Widget build(BuildContext context) {
  final router = di<AppRouter>();
  router.bindAuthBloc();
  AppModules.initAfterRunApp(context);  // ← 缺这行 = 404

  return MultiBlocProvider(...);
}
```

| 步骤 | 调什么 | 在哪调 | 原因 |
|---|---|---|---|
| 1 | `Bootstrap.init()` | `main.dart` | 无 `BuildContext` 的初始化 (DI / HTTP / DB) |
| 2 | `App.build` + `AppModules.initAfterRunApp(context)` | `App.build` | 需要 `BuildContext` (注入 navTabs) |
| 3 | `router.bindAuthBloc()` | `App.build` | 绑 AuthBloc.stream → refreshListenable |

**Bug 教训 (1b9871a)**: 漏第 2 步 → `firstNavRoute()` 拿到空 list → fallback `"//"` →
`initialRedirect` state=authenticated → return `firstNavRoute() = "/"` → 死循环 → 404。

---

## 7. 模块依赖矩阵

| 模块 | 依赖 _core | 依赖 _shared | 依赖其他模块 |
|---|---|---|---|
| auth | ✅ | ✅ | ❌ |
| registration | ✅ | ✅ | ❌ |
| im | ✅ | ✅ | auth (拿 imToken) |
| universe | ✅ | ✅ | auth |
| table | ✅ | ✅ | universe |
| row | ✅ | ✅ | universe, table |

`features/` 之间**绝不**互相 import 内部实现, 需要跨模块通过 `get_it` 拿。

---

## 8. 测试架构

- `test/<module>/<vm>_test.dart` — Bloc / Cubit 单测 (bloc_test)
- `test/<module>/<repository>_test.dart` — Repository mock (mocktail)
- `test/integration_test/` — 集成测试 (真后端)
- `test/architecture/` — 架构约束测试 (禁止跨 module import)

覆盖率基线: **100%** (`very_good test --min-coverage 100`)

详见 [docs/TESTING.md](./TESTING.md)。

---

*最后更新: 2026-07-06 — 阶段 2 全功能完成 (Connection/Conversation/Message/Friend/Group + ChatList/ChatPage/Contacts/Profile) + 登录流程接入 IM bootstrap + Env 三域*
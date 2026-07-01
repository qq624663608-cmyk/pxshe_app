# ADR-0007: 为什么 go_router

## 背景

Flutter 路由选型:
- Navigator 1.0 (MaterialApp + Navigator.push)
- Navigator 2.0 (RouterDelegate)
- go_router (官方推荐包装)
- auto_route (codegen)

候选:
- **A. go_router** (推荐)
- B. auto_route
- C. Navigator 1.0

## 决策

**用 go_router**。

依赖:
```yaml
dependencies:
  go_router: ^17.3.0
```

## 后果

### 好处
- **Flutter 官方推荐** (package:go_router)
- **声明式 API** (类似 React Router)
- **嵌套路由** (嵌套 GoRoute)
- **路由守卫** (redirect / refreshListenable)
- **深链支持** (URL 跳转, 阶段 5 web 用)
- **跟 very_good_cli 模板集成**

### 坏处
- **API 演进快** (版本间有 breaking changes)
- **状态变化需要 listenable** (AuthBloc / ThemeModeCubit)
- **错误处理** (errorBuilder 容易写错)

### 风险
- **版本升级** — 16 → 17 改了不少 API
- **复杂守卫** — redirect 链太长会循环

## 替代方案

### B. auto_route (不选)
- 优势: codegen, 类型安全
- 不选: 跟 go_router 比社区小, 文档少, codegen 增加构建时间

### C. Navigator 1.0 (不选)
- 优势: 简单
- 不选: 老 API, 不支持深链, 复杂路由难管理

## 实施细节

### 路由表

```dart
// lib/_core/app_router.dart
GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(authBloc.stream),
  redirect: (context, state) {
    final authStatus = authBloc.state.status;
    final goingToLogin = state.matchedLocation == '/login';
    if (authStatus == AuthStatus.unknown) return null;
    if (authStatus == AuthStatus.unauthenticated && !goingToLogin) return '/login';
    if (authStatus == AuthStatus.authenticated && goingToLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/splash'),
    GoRoute(path: '/splash', pageBuilder: (c, s) => const SplashPage()),
    GoRoute(path: '/login', pageBuilder: (c, s) => const LoginPage()),
    GoRoute(path: '/home', pageBuilder: (c, s) => const HomePage()),
    // ...
  ],
);
```

### 路由守卫

```dart
// lib/_core/app_router.dart
String? authRouteGuard(BuildContext context, GoRouterState state) {
  final authBloc = context.read<AuthBloc>();
  if (authBloc.state.status == AuthStatus.unauthenticated) {
    return '/errors/401';
  }
  return null;
}

String? unAuthRouteGuard(BuildContext context, GoRouterState state) {
  final authBloc = context.read<AuthBloc>();
  if (authBloc.state.status == AuthStatus.authenticated) {
    return '/home';
  }
  return null;
}
```

详见 [KNOWLEDGE_GRAPH.md §3](../KNOWLEDGE_GRAPH.md) 启动流图。

---

*状态: 已接受 | 日期: 2026-07-01*
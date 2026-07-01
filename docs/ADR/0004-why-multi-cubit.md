# ADR-0004: 为什么多 Bloc/Cubit (防 mega 反模式)

## 背景

BLoC 模式容易陷入反模式: **1 个 mega Bloc 塞 5 个功能**, 导致:
- 单文件 1000+ 行
- 单 state 20+ 字段
- 测试难 (要 mock 5 个 service)
- 维护噩梦

候选:
- **A. 每个 module 多个 Bloc/Cubit** (推荐)
- B. 1 个 mega Bloc / module
- C. 不用 BLoC, 改用其他

## 决策

**每个 module 暴露 N 个 Bloc/Cubit, 不是 1 个 mega**。

粒度:
- **Cubit**: 1 个 sub-feature 1 个 (简单状态机)
- **Bloc**: 1 个事件流 1 个 (复杂事件)

例子 (auth module):
- `AuthBloc` (全局, 持久)
- `LoginCubit` (登录表单)
- `RegisterCubit` (注册表单, 阶段 1.5)
- `ProfileCubit` (用户资料)

例子 (im module, 阶段 2):
- `ConnectionBloc` (WebSocket 状态)
- `ConversationCubit` (会话列表)
- `MessageBloc` (消息流)
- `FriendCubit` / `GroupCubit`

## 后果

### 好处
- **单文件 < 200 行** (可读)
- **单 state < 10 字段** (聚焦)
- **测试简单** (1 个 Bloc 对应 1 个 service)
- **新功能加 Bloc** (而不是改 mega Bloc)

### 坏处
- **文件多** (auth 4 个 cubit = 4 个文件)
- **命名约定** (AuthBloc vs LoginCubit vs RegisterCubit 怎么取名)
- **di 容器大** (10+ lazySingleton)

### 风险
- **过度拆分** (1 个 sub-feature 拆 5 个 cubit 反而难维护)
- **跨 cubit 状态共享** (LoginCubit 完成 → AuthBloc 状态变) 需要 event 协调

## 替代方案

### B. 1 个 mega Bloc (不选)
- 不选: 5 大反模式之一 (AGENTS § ★)

### C. 不用 BLoC (不选)
- 不选: BLoC 本身没毛病, 是用法问题

## 实施细节

### 命名约定

```dart
// 跨 module 全局: <Module>Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> { }

// 简单 sub-feature: <Feature>Cubit
class LoginCubit extends Cubit<LoginState> { }

// 复杂事件流: <Feature>Bloc
class MessageBloc extends Bloc<MessageEvent, MessageState> { }
```

### 跨 Cubit 状态共享 (例子)

```dart
// LoginCubit 完成 → AuthBloc 状态变
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authBloc) : super(const LoginState());
  final AuthBloc _authBloc;
  
  Future<void> submit() async {
    final res = await _authUsecase.login(...);
    res.fold(
      (f) => emit(state.copyWith(status: LoginStatus.error)),
      (user) {
        _authBloc.add(AuthLoginSucceeded(user));  // 推 AuthBloc
        emit(state.copyWith(status: LoginStatus.success));
      },
    );
  }
}
```

详见 [BUILDING_BLOCKS.md §7 #13](../BUILDING_BLOCKS.md) + [RECIPES.md §2](../RECIPES.md) Recipe 2 模板。

---

*状态: 已接受 | 日期: 2026-07-01*
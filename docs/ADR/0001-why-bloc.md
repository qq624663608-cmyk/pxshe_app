# ADR-0001: 为什么选 BLoC 9.x

## 背景

pxshe_app 是一个 Flutter IM 客户端 + 业务后台, 状态管理选型是核心架构决策。

universe_app (前身) 选 Riverpod 2.x。pxshe_app 是新项目, **有机会重新选**。

候选:
- **A. BLoC 9.x** (推荐)
- B. Riverpod 2.x (universe_app 用过)
- C. ChangeNotifier (老 API, 不在考虑)
- D. GetX (社区常用, 不在考虑)

## 决策

**选 BLoC 9.x**。

理由:

1. **事件驱动, 适合 IM 场景** — IM 客户端的核心是**消息流** (收到新消息 / 消息已读 / 消息撤回 / 踢下线), 都是事件流。BLoC 的 `event` 抽象天然契合。
2. **state 类强类型** — Bloc 的 `State extends Equatable`, 编译时安全, 跟 Riverpod 的 `AsyncValue` 比, 类型更可控。
3. **测试成熟** — `bloc_test` 工具链完善, `blocTest()` 3 行代码写完一个事件-状态测试。
4. **跟 OpenIM SDK 适配** — SDK 回调函数 → 转成 Event → emit State, 模式清晰。
5. **跟 universe_app 差异化** — 不重复, 给团队新的工程经验。

## 后果

### 好处
- 事件流模型跟 IM 天然契合
- bloc_test 测试成熟
- 编译时类型安全
- 学习曲线有, 但是社区资源多 (bloclibrary.dev)

### 坏处
- 样板代码比 Riverpod 多 (event class + state class)
- 团队需要重新学 (universe_app 用 Riverpod)
- bloc 9.x 是较新版本, 文档以 8.x 为主

### 风险
- **bloc 9.x 兼容性** — 第三方插件可能没适配 9.x, 必要时降级到 8.x
- **状态管理升级成本** — 未来换状态管理需要重写所有 Bloc/Cubit

## 替代方案

### B. Riverpod 2.x (不选)
- 优势: 编译时安全, 嵌套 ProviderScope, 自动 cleanup
- 不选: 跟 universe_app 同, 没差异化; AsyncValue 不如 BLoC 的 state class 明确; 跟 OpenIM 事件流适配不如 BLoC 自然

### C. ChangeNotifier (不选)
- 不选: 老 API, 易 god notifier, 难测试

### D. GetX (不选)
- 不选: 社区分裂, 跟 Clean Arch 哲学冲突

## 实施细节

```dart
// Cubit: 简单状态机
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authUsecase) : super(const LoginState());
  final AuthUsecases _authUsecase;
  
  Future<void> submit() async {
    emit(state.copyWith(status: LoginStatus.loading));
    final res = await _authUsecase.login(...);
    res.fold(
      (f) => emit(state.copyWith(status: LoginStatus.error, message: f.getMessage())),
      (_) => emit(state.copyWith(status: LoginStatus.success)),
    );
  }
}

// Bloc: 复杂事件流
abstract class IMBlocEvent extends Equatable { ... }
class MessageReceived extends IMBlocEvent { final Message msg; ... }

class IMBloc extends Bloc<IMBlocEvent, IMState> {
  IMBloc() : super(const IMState()) {
    on<MessageReceived>((event, emit) {
      emit(state.copyWith(messages: [...state.messages, event.msg]));
    });
  }
}
```

详见 [ARCHITECTURE.md §3](../ARCHITECTURE.md) + [BUILDING_BLOCKS.md](../BUILDING_BLOCKS.md) §7 (硬规则 #12-13)。

---

*状态: 已接受 | 日期: 2026-07-01*
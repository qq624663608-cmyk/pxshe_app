# docs/CACHE_STRATEGY.md — 缓存设计

> **本文件是缓存策略 SSOT。**
> 什么数据缓存、缓存多久、何时失效, 看这里。

---

## 1. 存储分类

| 数据 | 存储 | TTL | 失效 |
|---|---|---|---|
| `chatToken` | `hive_ce` (lazyBox) | 30 天 | logout / 401 / 改密 |
| `imToken` | `hive_ce` (lazyBox) | 30 天 | logout / 401 |
| `userID` | `hive_ce` (user model) | 30 天 | 重新登录 |
| `User` 对象 | `hive_ce` (box: user) | 30 天 | logout / 重新登录 |
| `RegistrationConfig` | 内存 (singleton) | 会话期间 | 重启 App |
| `ThemeMode` | `hive_ce` (box: settings) | 永久 | 手动切换 |
| `IM 会话/消息` | OpenIM SDK 内部 | SDK 管 | SDK 管 |
| `搜索结果` | 内存 (Cubit state) | 5 分钟 | 过期 / 新搜索 |

---

## 2. Token 缓存 (关键)

### 存储 (Hive CE lazyBox)

```dart
// lib/modules/auth/data/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  static const _tokenBoxName = 'auth_token_box';
  static const _tokenKey = 'chat_token';
  static const _imTokenKey = 'im_token';
  static const _userBoxName = 'user_box';
  static const _userKey = 'current_user';

  Future<void> _cacheTokens({
    required String chatToken,
    String? imToken,
  }) async {
    try {
      final box = await hive.openLazyBox<String>(_tokenBoxName);
      await box.put(_tokenKey, chatToken);
      if (imToken != null) {
        await box.put(_imTokenKey, imToken);
      }
    } catch (_) {
      throw CacheException();
    }
  }

  Future<void> _cacheUser(UserModel user) async {
    final box = await hive.openBox<UserModel>(_userBoxName);
    await box.put(_userKey, user);
  }

  Future<UserModel?> _getCachedUser() async {
    final box = await hive.openBox<UserModel>(_userBoxName);
    return box.get(_userKey);
  }

  Future<void> clearCache() async {
    final userBox = await hive.openBox<UserModel>(_userBoxName);
    final tokenBox = await hive.openLazyBox<String>(_tokenBoxName);
    await userBox.clear();
    await tokenBox.clear();
  }
}
```

### 失效场景

| 场景 | 触发 | 操作 |
|---|---|---|
| 主动 logout | 用户点"退出" | `clearCache()` + 跳 `/login` |
| 被踢下线 | OpenIM `OnKickedOfflineListener` | `clearCache()` + 跳 `/login` |
| 业务 API 401 | dio 拦截器 | `clearCache()` + 跳 `/login` |
| 改密成功 | `changePassword` 返 `kicked=true` | `clearCache()` + 跳 `/login` |

### 反序列化 (硬约束)

```dart
// ✅ 正确 (AGENTS §35)
final raw = box.get('user');
if (raw is Map) {
  final user = Map<String, dynamic>.from(raw);
}

// ❌ 错误
final user = box.get('user') as Map<String, dynamic>;
```

---

## 3. Hive Box 设计

```dart
// lib/_core/database.dart
class Database {
  static const _tokenBox = 'auth_token_box';     // String (chatToken / imToken)
  static const _userBox = 'user_box';             // UserModel
  static const _settingsBox = 'settings_box';     // ThemeMode 等
}
```

**禁止**:
- ❌ 多个 box 存同一类数据
- ❌ box 名无 `_box` 后缀
- ❌ 不注册 HiveAdapter 就 `box.put(MyModel)` (运行时会抛 type not registered)

---

## 4. 内存缓存 (BLoC state)

BLoC/Cubit 的 state 本身就是内存缓存。例如:

```dart
// lib/modules/universe/bloc/universe_list_cubit.dart
class UniverseListCubit extends Cubit<UniverseListState> {
  // state = { universes: [...], loading: false }
  // 离开页面 → state 还在 (Cubit 是 singleton)
  // 重新进入 → 直接 emit 旧 state, 后台刷新
}
```

**禁止**:
- ❌ 在 Cubit 里再加一层 `cachedList` 字段
- ❌ 用全局 Map 缓存 (state 已经够)

---

## 5. OpenIM 缓存 (SDK 内部)

OpenIM SDK 内部管理消息/会话缓存。**不要** 自己再缓存一份。

业务层只读 SDK 的 `MessageList` / `ConversationList`, 通过 Repository 包装。

---

## 6. 启动时恢复流程

```dart
// lib/_core/_bootstrap.dart
Future<void> init() async {
  // 1. Database.init() - Hive box 打开
  // 2. AppModules.initBeforeRunApp() - 注册 module
  //    └─ registerAuthModule()
  //         └─ AuthRepositoryImpl() 构造时:
  //              └─ _bootstrapFromCache() - 读 Hive 恢复 token + user
  // 3. AuthBloc.start() - emit AuthState (authenticated / unauthenticated)
  // 4. App 启动 - SplashPage 看 AuthBloc 状态决定路由
}
```

---

*最后更新: 2026-07-01*
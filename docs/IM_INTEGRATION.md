# docs/IM_INTEGRATION.md — OpenIM SDK 集成

> **本文件是 OpenIM 集成的 SSOT。**
> 任何 IM 相关改动, 同步这里。

---

## 1. SDK

```yaml
# pubspec.yaml
dependencies:
  flutter_openim_sdk: ^3.8.3+hotfix.12
```

| 项 | 值 |
|---|---|
| 包名 | `flutter_openim_sdk` |
| 版本 | 3.8.3+hotfix.12 |
| License | **AGPL-3.0** |
| pub.dev | https://pub.dev/packages/flutter_openim_sdk |

⚠️ SDK 是 AGPL, **整个项目传染为 AGPL-3.0**。详见 [LICENSE_INFO.md](./LICENSE_INFO.md)。

---

## 2. 初始化流程

### 2.1 登录响应拿到 imToken

`POST /account/login` 响应里的 `data.imToken` 直接喂给 SDK, **不用单独再调 SDK 拿**。

```dart
// lib/modules/auth/data/auth_repository_impl.dart
final payload = Map<String, dynamic>.from(res.data['data'] as Map);
_imToken = payload['imToken'] as String?;
```

### 2.2 SDK 登录

```dart
// lib/modules/im/data/datasources/openim_sdk_wrapper.dart
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

class OpenIMSDKWrapper {
  /// Login with the imToken obtained from the business server.
  /// `userID` is required by the SDK; `imToken` comes from the
  /// `POST /account/login` response (`data.imToken`).
  Future<UserInfo> login({required String userID, required String imToken}) {
    return OpenIM.iMManager.login(userID: userID, token: imToken);
  }
}
```

### 2.3 监听事件

```dart
OpenIM.iMManager.addEventListener(
  OnConnectListener(
    onConnectSuccess: () => connectionBloc.add(ConnectionEstablished()),
    onConnecting: () => connectionBloc.add(ConnectionConnecting()),
    onConnectFailed: (code, error) {
      connectionBloc.add(ConnectionFailed(code, error));
    },
  ),
  OnMessageListener(
    onRecvNewMessage: (message) => messageBloc.add(MessageReceived(message)),
    onRecvC2CReadReceipt: (list) => messageBloc.add(ReadReceiptReceived(list)),
  ),
  OnKickedOfflineListener(
    onKickedOffline: () {
      // 1. 清 token
      authRepository.logout();
      // 2. 跳登录 — 实际由 refreshListenable + authRouteGuard 自动处理
      //    (AuthBloc logout → emit unauthenticated → /home guard 跳 /login)
      //    这里保留 router.go 是兜底保险, 不依赖 navigation 即可完成跳转
      router.go('/login');
      // 3. toast
      showErrorSnackBar(context, '您的账号在另一台设备登录');
    },
  ),
);
```

### 2.4 路由跳转 — refreshListenable 模式 (不推荐手动 router.go)

**之前**: 在 widget 内手动 `router.go('/login')` / `router.go('/home')` 跳转。

**现在 (推荐)**: 用 `refreshListenable` (详见 `docs/ARCHITECTURE.md § 6.5`):

- `AuthBloc` emit 状态变化 → `GoRouter` 自动重跑 `redirect:` 守卫 → 自动跳
- 业务代码**零** `router.go()` 调用, 跳转全自动
- 但**仍保留** `router.go` 作为兜底保险, 因为 listener 异步触发可能略晚于回调

**应用**:
- `_onAuthLoginSucceeded`: 派发 event → AuthBloc emit → refreshListenable 触发 → `/login` 的 unAuthRouteGuard 跳 `/home`
- `OnKickedOfflineListener.onKickedOffline`: `authRepository.logout()` → AuthBloc emit `unauthenticated` → refreshListenable 触发 → `/home` 的 authRouteGuard 跳 `/login`

---

## 3. 模块设计

> 阶段 2 (2026-07) 完成。下面是**实际代码**结构(`git ls-files lib/modules/im/`),
> 跟实际文件一一对应。**新加功能时,先改这里再写代码**(CONTRIBUTING §8)。

```
lib/modules/im/
├── auth_module_bridge.dart          (跨 module 拿 imToken,不依赖 auth 内部 — ADR-0005)
├── im_module.dart                   (DI 注册入口 + bootstrapIMAfterLogin/Logout)
├── im_routes.dart                   (GoRouter 路由 — 见下方)
│
├── data/
│   ├── datasources/
│   │   └── openim_sdk_wrapper.dart   (SDK 二次封装, 业务不直接调 SDK — AGENTS §18)
│   └── repositories/                 (5 个 repo impl)
│       ├── im_auth_repository_impl.dart
│       ├── conversation_repository_impl.dart
│       ├── message_repository_impl.dart
│       ├── friend_repository_impl.dart
│       └── group_repository_impl.dart
│
├── domain/                           (5 个 repository 接口)
│   ├── im_auth_repository.dart
│   ├── conversation_repository.dart
│   ├── message_repository.dart
│   ├── friend_repository.dart
│   └── group_repository.dart
│
├── bloc/                             (5 个 Cubit — ADR-0004 多 Cubit)
│   ├── connection_cubit.dart        (WebSocket 连接状态)
│   ├── conversation_cubit.dart
│   ├── message_cubit.dart
│   ├── friend_cubit.dart
│   └── group_cubit.dart
│
└── features/
    ├── chat_list/chat_list_page.dart      (/chat_list)
    ├── chat_page/chat_page.dart          (/chat/:id)
    ├── contacts/contacts_page.dart        (/contacts)
    ├── profile/profile_page.dart          (/profile)
    └── placeholder/connection_status_page.dart  (/im/status — 阶段 2.1 占位)
```

### 3.1 路由清单(实际)

| 路由 | 页面 | 阶段 |
|---|---|---|
| `/im/status` | `ConnectionStatusPage` | 2.1(占位) |
| `/chat_list` | `ChatListPage` | 2.2 |
| `/chat/:id` | `ChatPage` | 2.3 |
| `/contacts` | `ContactsPage` | 2.4 |
| `/profile` | `ProfilePage` | 2.5 |

---

## 4. SDK 封装原则 (重要, AGENTS §29)

### ❌ 不做的事

```dart
// ❌ 业务代码直接调 SDK API
await OpenIM.iMManager.sendMessage(...);

// ❌ 自己写 WebSocket
// ❌ 直接 HTTP 调 api.pxshe.com
```

### ✅ 正确做法

```dart
// ✅ 业务代码只调 Repository
final result = await messageRepository.sendMessage(
  conversationId: id,
  type: 'text',
  content: 'hello',
);

// Repository 内部调 SDK
class MessageRepositoryImpl {
  Future<void> sendMessage(...) async {
    final result = await OpenIM.iMManager.sendMessage(...);
    return result;
  }
}
```

业务层跟 SDK 解耦, 将来换 SDK 不用改业务代码。

---

## 5. 关键事件处理

### 5.1 踢下线 (AGENTS §31)

```dart
OnKickedOfflineListener(
  onKickedOffline: () async {
    // 1. 清本地 token
    await authRepository.logout();
    // 2. 跳登录页
    router.go('/login');
    // 3. toast
    showErrorSnackBar(context, '您的账号在另一台设备登录');
  },
);
```

### 5.2 连接状态 (AGENTS §32)

`ConnectionBloc` 状态机:
- `connected` — 正常
- `connecting` — 重连中 (显示"重连中..."横幅)
- `disconnected` — 断开

```dart
// ConnectionBloc 监听 OnConnectListener
on<ConnectionEvent>((event, emit) {
  switch (event) {
    case ConnectionEstablished _:
      emit(state.copyWith(status: ConnectionStatus.connected));
    case ConnectionConnecting _:
      emit(state.copyWith(status: ConnectionStatus.connecting));
    case ConnectionFailed _:
      emit(state.copyWith(status: ConnectionStatus.disconnected));
  }
});
```

SDK 内置自动重连, 业务层只需更新 UI 状态。

### 5.3 收到新消息

```dart
OnMessageListener(
  onRecvNewMessage: (message) {
    // 推到 message_bloc
    messageBloc.add(MessageReceived(message));
    // 推到 conversation_bloc 增量更新
    conversationBloc.add(ConversationUpdated(message.conversationID));
  },
);
```

### 5.4 消息已读回执

```dart
OnMessageListener(
  onRecvC2CReadReceipt: (list) {
    // 更新消息状态为"已读"
    messageBloc.add(MessagesMarkedAsRead(list));
  },
);
```

---

## 6. Android 配置 (关键)

```kotlin
// android/app/build.gradle.kts
android {
    defaultConfig {
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
        multiDexEnabled = true
    }
    buildTypes {
        release {
            isMinifyEnabled = false  // 避免 OpenIM SDK 被 R8 误删
            isShrinkResources = false
        }
    }
}
```

### AndroidManifest 权限

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

详见 [platform-config.md](./platform-config.md) (阶段 1.12 已配)。

### Flutter 依赖(pubspec.yaml)

OpenIM SDK 本身在 `flutter_openim_sdk: ^3.8.3+hotfix.12`,**Flutter 业务代码不直连 SDK**
(走 `OpenIMSDKWrapper`,AGENTS §18)。

阶段 2 新增依赖:
- **`path_provider: ^2.1.5`** — SDK `initSDK` 需要 `dataDir`,业务用
  `getApplicationDocumentsDirectory()` 传 app 持久目录
  (`lib/modules/im/data/repositories/im_auth_repository_impl.dart:46`)。

见 `docs/REFERENCE.md §1` 完整依赖表 + `docs/LICENSE_INFO.md §2` License 矩阵。

---

## 7. iOS 配置

iOS 不需要额外配置, SDK 自动处理。

```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>
```

---

## 8. 多端登录策略 (AGENTS §33)

OpenIM 默认: **PC 不互踢, 其他平台一台**。

```dart
// 登录时强制单端
await OpenIM.iMManager.login(
  token: imToken,
  platformID: 2,  // 2=Android
);
```

收到 `onKickedOffline` → 已在 PC 登录, Android 端被踢。

---

## 9. 网络协议

| 连接 | 协议 | 客户端地址 (Flutter 写) | 后端 (反代后) |
|---|---|---|---|
| WebSocket | `wss://` | `wss://api.pxshe.com` (默认 443) | nginx → `openim-server:10002` |
| HTTP API | `https://` | `https://api.pxshe.com` (默认 443) | nginx → `openim-server:10002` |

**重要**: **客户端不带端口** (跟 `chat.pxshe.com` 同样模式),反代在 443 上转发到后端 10002。
直接写 `:10002` 不会走反代,会被 GFW 拦 (海外主机常见)。

Flutter 端**不直接连**, 通过 SDK 间接通信。

---

## 10. License 注意事项

`flutter_openim_sdk` 是 AGPL-3.0, 传染整个项目。**已确认接受 AGPL** (见 ADR-0010)。

商业化场景详见 [LICENSE_INFO.md §3](./LICENSE_INFO.md)。

---

*最后更新: 2026-07-01*
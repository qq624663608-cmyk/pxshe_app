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
  Future<void> login({required String imToken, required String apiAddr}) async {
    await OpenIM.iMManager.login(
      token: imToken,
      apiAddr: apiAddr,  // 'api.pxshe.com:10002'
    );
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
      // 2. 跳登录
      router.go('/login');
      // 3. toast
      showErrorSnackBar(context, '您的账号在另一台设备登录');
    },
  ),
);
```

---

## 3. 模块设计

```
lib/modules/im/
├── im_module.dart             (DI 注册入口)
├── im_routes.dart             (路由: /chat, /chat/:id, /contacts, /groups)
│
├── data/
│   ├── datasources/
│   │   ├── openim_sdk_wrapper.dart    (SDK 二次封装, 业务不直接调 SDK)
│   │   └── im_local_cache.dart        (Hive 缓存, 备用)
│   └── repositories/
│       ├── im_auth_repository.dart
│       ├── conversation_repository.dart
│       ├── message_repository.dart
│       ├── friend_repository.dart
│       └── group_repository.dart
│
├── domain/
│   ├── entities/
│   │   ├── conversation.dart
│   │   ├── message.dart
│   │   ├── friend.dart
│   │   └── group.dart
│   └── usecases/
│       ├── send_message.dart
│       ├── load_history.dart
│       └── get_conversations.dart
│
├── bloc/
│   ├── connection_bloc.dart          (WebSocket 连接状态)
│   ├── conversation_bloc.dart
│   ├── message_bloc.dart
│   ├── friend_bloc.dart
│   └── group_bloc.dart
│
└── features/
    ├── chat_list/                    (会话列表)
    ├── chat_page/                    (聊天页)
    ├── contacts/                     (好友/群)
    └── profile/                      (个人/群信息)
```

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

| 连接 | 协议 | 端口 |
|---|---|---|
| WebSocket | `wss://api.pxshe.com` | 10002 (TLS) / 10003 (TCP) |
| HTTP API | SDK 内部用 | 同上 |

Flutter 端**不直接连**, 通过 SDK 间接通信。

---

## 10. License 注意事项

`flutter_openim_sdk` 是 AGPL-3.0, 传染整个项目。**已确认接受 AGPL** (见 ADR-0010)。

商业化场景详见 [LICENSE_INFO.md §3](./LICENSE_INFO.md)。

---

*最后更新: 2026-07-01*
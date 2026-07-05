# PHASE 2 — OpenIM 集成计划

> **SSOT**: 本文件是阶段 2 实施清单的唯一来源。改动需同步更新本文件。
> 阶段 2 = 在 pxshe_app 项目里集成 `flutter_openim_sdk: ^3.8.3+hotfix.12`,
> 实现 IM 客户端(单聊 + 群聊 + 好友)。分 5 个子阶段 + 1 个集成收尾。

---

## 阶段 2.0 — 前置(必做,~30 分钟)

**目的**:消除未来 80% 的坑(SDK API 误判 + 平台配置遗漏)

| 任务 | 文件 | 验证 |
|---|---|---|
| grep SDK 实际 API(5 manager × ~8 方法) | `F:\wx\openim\open-im-sdk-flutter-3.8.3-hotfix.12\lib\src\manager\*.dart` | `IM_API_MAP.md` 列出所有公开方法签名 |
| 建 SDK API SSOT | `docs/IM_API_MAP.md`(新建) | ~30 行表格,所有调用基于该表 |
| 检查 Android 配置 | `android/app/build.gradle.kts` | abiFilters=arm64-v8a+x86_64 / multiDexEnabled=true / minifyEnabled=false |
| 检查 Android 权限 | `android/app/src/main/AndroidManifest.xml` | INTERNET / ACCESS_NETWORK_STATE / WAKE_LOCK / VIBRATE / POST_NOTIFICATIONS 等 9 项 |
| 检查 iOS Podfile | `ios/Podfile` | platform :ios, '12.0' (OpenIM SDK 最低要求) |

---

## 阶段 2.1 — SDK init + Connection(~1.5 小时)

**目的**:打通"启动 → init SDK → 连接状态显示"最小闭环(验证 SDK 集成可行)

| 任务 | 文件 |
|---|---|
| mkdir | `lib/modules/im/{data/datasources,data/repositories,domain,bloc,features}/` |
| SDK 二次封装 | `data/datasources/openim_sdk_wrapper.dart` |
| ImAuthRepository 接口 | `domain/im_auth_repository.dart` |
| ImAuthRepository 实现 | `data/repositories/im_auth_repository_impl.dart` |
| ConnectionCubit | `bloc/connection_cubit.dart` |
| AuthModuleBridge | `auth_module_bridge.dart`(跨 module 拿 imToken,不直连 auth 内部) |
| Module 入口 | `im_module.dart` |
| 注册 | `_core/_init_modules.dart` + `_core/_bootstrap.dart` |
| Env 三域 | `_core/env.dart` 加 `chatBase` / `openimBase` / `adminBase` |
| 占位 Page | `features/placeholder/connection_status_page.dart`(显示连接状态) |
| 单元测试 | `test/modules/im/data/repositories/im_auth_repository_impl_test.dart`(mock wrapper) |
| 同步文档 | `docs/ARCHITECTURE.md`(按 CONTRIBUTING §8) |

**验证**:
- `flutter analyze` 0 error
- `flutter test` 全过(原有 194 + 新 1)
- `ai.ps1 all` 4/4 OK
- 真机:登录后跳 ConnectionStatusPage 看到连接状态(需后端 ws.pxshe.com 可达)

---

## 阶段 2.2 — Conversation + ChatList(~1.5 小时)

**前置**: 2.1 完成 + 真实 SDK 跑通

| 任务 | 文件 |
|---|---|
| ConversationRepository 接口 | `domain/conversation_repository.dart` |
| ConversationRepository 实现 | `data/repositories/conversation_repository_impl.dart` |
| ConversationCubit | `bloc/conversation_cubit.dart` |
| ChatListPage | `features/chat_list/chat_list_page.dart` |
| im_routes 加 `/chat_list` | `im_routes.dart` |
| 单元测试 | `conversation_repository_impl_test.dart` + `conversation_cubit_test.dart` |
| 同步 `docs/PAGE_CLASSIFICATION.md` | |

---

## 阶段 2.3 — Message + ChatPage(~1.5 小时)

**前置**: 2.2 完成

| 任务 | 文件 |
|---|---|
| MessageRepository 接口 | `domain/message_repository.dart` |
| MessageRepository 实现 | `data/repositories/message_repository_impl.dart` |
| MessageCubit | `bloc/message_cubit.dart` |
| ChatPage | `features/chat_page/chat_page.dart` |
| im_routes 加 `/chat/:id` | `im_routes.dart` |
| 单元测试 | `message_repository_impl_test.dart` + `message_cubit_test.dart` |

**验证**: 真机双端测试(2 个账号)收发消息

---

## 阶段 2.4 — Friend + Contacts(~1 小时)

**前置**: 2.3 完成

| 任务 | 文件 |
|---|---|
| FriendRepository 接口 + 实现 | `domain/friend_repository.dart` + `data/repositories/friend_repository_impl.dart` |
| FriendCubit | `bloc/friend_cubit.dart` |
| ContactsPage | `features/contacts/contacts_page.dart` |
| im_routes 加 `/contacts` | `im_routes.dart` |
| 单元测试 | `friend_repository_impl_test.dart` + `friend_cubit_test.dart` |

---

## 阶段 2.5 — Group + Profile(~1 小时)

**前置**: 2.4 完成

| 任务 | 文件 |
|---|---|
| GroupRepository 接口 + 实现 | `domain/group_repository.dart` + `data/repositories/group_repository_impl.dart` |
| GroupCubit | `bloc/group_cubit.dart` |
| ProfilePage | `features/profile/profile_page.dart` |
| im_routes 加 `/profile` | `im_routes.dart` |
| 单元测试 | `group_repository_impl_test.dart` + `group_cubit_test.dart` |
| 同步 `docs/PAGE_CLASSIFICATION.md` + `docs/KNOWLEDGE_GRAPH.md §4` | |

---

## 阶段 2.6 — 集成 + 文档(~45 分钟)

**前置**: 2.1-2.5 全完成

| 任务 | 文件 |
|---|---|
| 登录流程触发 IM init + login | `lib/modules/auth/bloc/auth_bloc.dart`(在登录成功事件调 `bootstrapIMAfterLogin()`) |
| Connection 状态横幅 | `lib/_shared/features/home/page/home_page.dart` |
| 同步 CHANGELOG | `docs/CHANGELOG.md` |
| 同步 KNOWLEDGE_GRAPH | `docs/KNOWLEDGE_GRAPH.md` §4 目录树 |
| 同步 ARCHITECTURE | `docs/ARCHITECTURE.md` §4 + §6 |
| 同步 PAGE_CLASSIFICATION | `docs/PAGE_CLASSIFICATION.md` 路由清单 |
| 端到端 widget test | `test/integration/im_e2e_test.dart` |
| `flutter test --coverage` | 验证 ≥ 80% |
| `flutter analyze` | 0 error |
| `ai.ps1 all` | 4/4 OK |

---

## 工作量总览

| 阶段 | 工作量 | 累计 |
|---|---|---|
| 2.0 前置 | 30 分钟 | 30 分钟 |
| 2.1 SDK+Connection | 1.5 小时 | 2 小时 |
| 2.2 Conversation | 1.5 小时 | 3.5 小时 |
| 2.3 Message | 1.5 小时 | 5 小时 |
| 2.4 Friend | 1 小时 | 6 小时 |
| 2.5 Group | 1 小时 | 7 小时 |
| 2.6 集成+文档 | 45 分钟 | 7.75 小时 |

---

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| SDK 方法签名误判 | 2.0 阶段建 `IM_API_MAP.md` SSOT,所有调用基于该表 |
| Android Gradle / iOS Pod 缺配置 | 2.0 阶段检查配置 |
| 实时消息收不到 | 2.3 双端测试 |
| `flutter_openim_sdk` 是 AGPL | 已接受(ADR-0010) |
| `auth_repository_impl.dart` 用裸 Dio(已知阶段 1 违规) | 阶段 2 不动它,IM 通过 `AuthModuleBridge` 拿 imToken |

---

*创建: 2026-07-06*
*完成: 2026-07-06 — 阶段 2 全功能完成(2.1 SDK init + 2.2 Conversation + 2.3 Message + 2.4 Friend + 2.5 Group + 2.6 集成 + 文档)*
*SSOT: 本文件是阶段 2 实施清单,改动需同步更新*
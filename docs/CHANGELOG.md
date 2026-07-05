# CHANGELOG

> **本文件是 pxshe_app 版本历史 SSOT。**
> 每次发版必更新。

pxshe_app 版本历史。

## [Unreleased]

### Added (阶段 2 — OpenIM 集成 ✅)

- `modules/im` — 完整 IM 客户端模块(连接/会话/消息/好友/群)
- 5 个 repository:`ImAuthRepository` / `ConversationRepository` / `MessageRepository` / `FriendRepository` / `GroupRepository`
- 5 个 Cubit:`ConnectionCubit` / `ConversationCubit` / `MessageCubit` / `FriendCubit` / `GroupCubit`
- 4 个页面:`ChatListPage` (`/chat_list`) / `ChatPage` (`/chat/:id`) / `ContactsPage` (`/contacts`) / `ProfilePage` (`/profile`)
- 1 个占位页:`ConnectionStatusPage` (`/im/status`)
- `bootstrapIMAfterLogin()` / `bootstrapIMAfterLogout()` 钩子(在 `auth_bloc` 里调用)
- `AuthModuleBridge` — IM 拿 imToken 不依赖 auth 内部
- `path_provider` 依赖(SDK dataDir)
- `Env` 三域配置:`chatBase` / `openimBase` / `adminBase`

### Added (阶段 1 收尾 + 工具)

- `ApiClient` DI 注册(`_bootstrap.dart`)
- `themeBoxName` 统一 `_BOX` 后缀
- `cachedImTokenRef` 常量(消除字面量)
- `hard_rules_lint_test.dart` — 永久捕获 `print` / `Color(0xFF...)` / 裸 `Dio` / `flutter_openim_sdk` 直连违规

### Fixed

- `http_client.dart`:`||` → `&&` / `ServerException() as Response` 强转改 `throw` / `print` → `Log.e/w/d`
- `http_client.dart`:每次请求 `await openLazyBox` 改为容错处理
- `auth_repository_impl.dart`:错误处理改走 `ApiException.fromResponse`
- `exceptions.dart`:删未使用的 `dio` import

### Notes

- 阶段 1 (业务骨架 + 文档) ✅
- 阶段 2 (OpenIM 集成) ✅
- 阶段 3 (业务模块 universe/table/row) 待开始
- 阶段 4 (测试 + 集成) 待开始
- 阶段 5 (部署 + 监控) 待开始

## [0.1.0] - 2026-07-01

### Added

- 项目初始化 (very_good CLI)
- 23+ 核心依赖 (BLoC, get_it, dio, hive_ce, go_router, openim-sdk-flutter)
- 移植 flutter_clean_starter 业务骨架 (_core / _shared)
- 移植 auth module (login + register 占位)
- auth 改造: phone + password + areaCode + platform 登录
- 8 个 SSOT 文档 (KNOWLEDGE_GRAPH, ARCHITECTURE, ERROR_HANDLING, ...)
- 10 个 ADR (技术选型决策记录)
- AGENTS.md 53+ 宪法 (16 章)
- Android 构建配置 (OpenIM abifilters + multiDex + minify=false)
- 腾讯云 Gradle 镜像 + 阿里云 Maven 镜像 (中国网络优化)
- OpenIM SDK 必需权限 (9 个)
- LICENSE: AGPL-3.0-or-later

### Notes

- 阶段 0 (项目脚手架) ✅
- 阶段 1 (业务骨架 + 文档) ✅
- 阶段 2 (OpenIM 集成) 待开始
- 阶段 3 (业务模块) 待开始
- 阶段 4 (测试 + 集成) 待开始
- 阶段 5 (部署 + 监控) 待开始

---

*最后更新: 2026-07-01*
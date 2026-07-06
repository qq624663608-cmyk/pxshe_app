# AGENTS.md — pxshe_app 宪法

> **本文件是项目的唯一宪法 SSOT。**
> 任何 PR 改动前必读,违反直接拒绝合并。
> 顶部 ★ 设计初心 区是项目存在的原因,永不动。

---

## 目录

- [★ 设计初心](#-设计初心项目存在的-5-个理由任何改动前必读)
- [★ 5 大反模式](#-5-大反模式看到就拒绝-pr)
- [第一章:项目基本信息](#第一章项目基本信息)
- [第二章:开发约定(第 1-12 条)](#第二章开发约定第-1-12-条)
- [第三章:API 与路由(第 13-16 条)](#第三章api-与路由第-13-16-条)
- [第四章:UI 与主题(第 17-21 条)](#第四章ui-与主题第-17-21-条)
- [第五章:认证(第 22-28 条)](#第五章认证第-22-28-条)
- [第六章:IM 集成(第 29-33 条)](#第六章im-集成第-29-33-条)
- [第七章:数据持久化(第 34-35 条)](#第七章数据持久化第-34-35-条)
- [第八章:多环境(第 36-38 条)](#第八章多环境第-36-38-条)
- [第九章:测试(第 39-41 条)](#第九章测试第-39-41-条)
- [第十章:文档规范(第 42-45 条)](#第十章文档规范第-42-45-条)
- [第十一章:设计护栏(第 46-48 条)](#第十一章设计护栏第-46-48-条)
- [第十二章:分层约束(第 49 条)](#第十二章分层约束第-49-条)
- [第十三章:扩展约束(第 50 条)](#第十三章扩展约束第-50-条)
- [第十四章:防堆砌约束(第 51 条)](#第十四章防堆砌约束第-51-条--旅行箱原则)
- [第十五章:官方优先原则(第 52 条)](#第十五章官方优先原则第-52-条--菜谱原则)
- [第十六章:防遗忘约束(第 53 条)](#第十六章防遗忘约束第-53-条--戴工牌原则)

---

## ★ 设计初心(项目存在的 5 个理由,任何改动前必读)

1. **简化**:1 个 module = 1 个目录,1 个改动 = 1 处修改
2. **隔离**:module 之间不互相 import 内部,删 module 删 1 目录
3. **可读**:1 个新功能,新人能在 1 小时内理解
4. **可加**:加 1 个 widget 6 步,加 1 个 module 12 步,有 Recipe
5. **可测**:测试 4 层级,覆盖率 ≥ 80%

## ★ 5 大反模式(看到就拒绝 PR)

- ❌ mega Bloc(5 个功能塞一起)
- ❌ State 不分职责的 ChangeNotifier
- ❌ 跨 module 互相 import 内部
- ❌ 直接 setState 调 ApiClient
- ❌ 在 widget build 里写业务逻辑

---

## 第一章:项目基本信息

| 项 | 值 |
|---|---|
| 名称 | pxshe_app |
| 类型 | Flutter Android/iOS App |
| 后端 | 4 域架构: chat.pxshe.com (chat-api) + api.pxshe.com (openim-api) + ws.pxshe.com (openim-msggateway) + admin.pxshe.com |
| 仓库 | `F:\wx\pxshe_app` |
| 启动 | `flutter run --flavor=development` |
| 测试 | `very_good test --coverage --min-coverage 100` |
| 分析 | `flutter analyze` |
| 平台 | Android + iOS (web 暂不) |
| 架构 | Clean Architecture + Modular + BLoC 9.x |
| 状态管理 | BLoC + get_it + GoRouter |
| Lint | very_good_analysis 10.x + bloc_lint |
| L10n | zh + en + ar + es (intl gen-l10n, 阶段 2.7 基础 + 阶段 3 业务边用边补) |
| License | AGPL-3.0-or-later |

**新人入职**: 先读 [`docs/KNOWLEDGE_GRAPH.md`](./docs/KNOWLEDGE_GRAPH.md) (30 分钟全貌), 再读本文件顶部 30 行 (设计初心 + 5 反模式)。

---

## 第二章:开发约定(第 1-12 条)

### 第 1 条:初始化位置

**所有初始化分 2 步, 缺一不可**:

1. **`Bootstrap.init()`** (`lib/_core/_bootstrap.dart`) — 无 `BuildContext` 的初始化
   (HttpClient / Database / DI 注册 / `AppModules.initBeforeRunApp`)。`main.dart` 调。
2. **`AppModules.initAfterRunApp(context)`** (`lib/_core/_init_modules.dart:21`)
   — 需要 `BuildContext` 的初始化 (注入 navTabs)。**在 `MaterialApp.router.builder`
   里调** (见 `lib/app/view/app.dart`),**不**在 `App.build` 顶层调。

理由: `main.dart` 只做 `WidgetsFlutterBinding.ensureInitialized()` + 启动 `Bootstrap`,
保持冷启动同步路径短。`initAfterRunApp` **必须**通过 `MaterialApp.router.builder` 调
(那里 context 经过了 MaterialApp + Localizations + Router 包装), 否则
`AppLocalizations.of(context)` 抛 null 异常。漏调 → navTabs 列表空 → `firstNavRoute()`
fallback 到 "/" → 登录成功后 GoRouter 进入死循环并跳 Error404Page (bug 3b1fca8 真实踩坑)。

### 第 2 条:状态管理 (BLoC 强制)

**所有异步数据/状态必须用 BLoC**, **禁止**:
- ❌ StatefulWidget + setState 调 ApiClient
- ❌ ChangeNotifier 跨 module 共享
- ❌ mega Bloc(多 State 塞一起)
- ❌ mega Cubit

**正确**: 每个 module 1 个或多个 Bloc/Cubit, Page 用 `BlocBuilder` + `context.watch`/`context.read`。

详见 [ADR-0001](./docs/ADR/0001-why-bloc.md)。

### 第 3 条:依赖注入

**所有 service/repository/usecase 必须通过 `get_it` 注册** (`lib/_core/di.dart` + `lib/_core/_init_modules.dart`)。

**禁止**:
- 直接 `new` 依赖
- 在 widget 里手动注入
- 用 Provider/Riverpod 做 DI (状态用 BLoC, 服务用 get_it)

### 第 4 条:Module 隔离

**每个 module 必有 `<name>_module.dart` 门面** (`lib/modules/<m>/<m>_module.dart`)。

```dart
// ✅ 正确: 跨 module 调用走对方门面
registerAuthModule();
registerIMModule();

// ❌ 错误: 直接 import 对方内部
import 'package:pxshe_app/modules/auth/data/auth_repository_impl.dart';
final repo = AuthRepositoryImpl(...);
```

详见 [ADR-0005](./docs/ADR/0005-why-feature-facade.md)。

### 第 5 条:多 Bloc/Cubit 模式 (防 mega 反模式)

**每个 module 暴露 N 个 Bloc/Cubit, 不是 1 个 mega Bloc**。

```dart
// ✅ 正确
class AuthBloc extends Bloc<AuthEvent, AuthState> { ... }
class LoginCubit extends Cubit<LoginState> { ... }
class RegisterCubit extends Cubit<RegisterState> { ... }

// ❌ 错误: 1 个 mega Bloc 塞 5 个
class AuthMegaBloc extends Bloc<AuthEvent, AuthState> {
  // 5 个 state + 5 个 event 塞一起
}
```

详见 [ADR-0004](./docs/ADR/0004-why-multi-cubit.md)。

### 第 6 条:错误处理

**客户端唯一错误入口**: `ErrorHandler.handle(context, exception)` (`lib/_core/error/error_handler.dart`)。

**禁止**:
- ❌ 直接 `ScaffoldMessenger.showSnackBar` 在 widget 里 catch
- ❌ 各 view 自行处理 401 / 403 / 404
- ❌ 错误文案自己写(走 `ErrorMessages.t(key)`)

**Snackbar fallback (硬约束)**: `ErrorHandler._showSnack` 必须用 3 级 fallback,
`ScaffoldMessenger.maybeOf(context)` 找不到时 fallback 到 `rootNavigatorKey`,
再找不到用 `Log.e` 兜底。**禁止**只 local maybeOf 找不到就静默 return
(用户看不到错误也无处查)。

详见 [docs/ERROR_HANDLING.md](./docs/ERROR_HANDLING.md)。

### 第 7 条:日志

用 `appLogger` (wrapper) 而不是 `print()`。3 个级别:
- `i` (info) — 正常流程
- `w` (warning) — 异常但可恢复
- `e` (error) — 致命, 需排查

**禁止** log token / 密码 / 身份证等敏感信息。

### 第 8 条:静默失败

Bootstrap 中任何异常必须 catch 并 log warning, 禁止向上抛出。

### 第 9 条:超时保护

**LoadingPage** 在启动后启动 **3 秒定时器**, 到时无论 Bootstrap 是否完成都强制跳转首页。Bootstrap 本身只 catch 异常并 `_ready.complete()`, **不做 3s 强制跳转**。

### 第 10 条:API 错误解析

所有 HTTP 错误都走 `ApiClient._mapError` → 提取 `(errCode, errMsg)` → 封装 `ApiException` → `ErrorHandler` 统一展示。

### 第 11 条:单元测试

每个 Bloc / Cubit / Repository / UseCase 必须有单元测试。**位置**: `test/<module>/<name>_test.dart`。

### 第 12 条:Lint

`flutter analyze` 0 errors。CI 强制(失败则 PR 拒绝)。

---

## 第三章:API 与路由(第 13-16 条)

### 第 13 条:颜色使用

**统一用 `AppColors`** (`lib/_core/theme/app_colors.dart`), **禁止**:
- 业务代码里用 `Colors.orange` 等 Material 默认色
- 业务代码里用 `Color(0xFF...)` 硬编码

**例外**:
- `AppColors` 内部定义本身
- `Colors.transparent` (透明, 无主题语义)
- `Colors.white` / `Colors.black` 在 `AppColors` 未覆盖的极端场景 (需注释说明)

### 第 14 条:路由架构

**前端路由 100% 硬编码, 后端不再控制前端路由**。

- 路由表在 `lib/_core/app_router.dart` 写死
- 后端只负责 page recipe (`/api/v1/page/{type}/{slug}/`) 和 module data
- 路由跳转走 `context.go('/path')` 或 `context.push('/path')`

### 第 15 条:4 域对接 (硬约束,后端 SSOT: [`docs/app/SERVICE_INVENTORY.md`](./docs/app/SERVICE_INVENTORY.md))

**Flutter 业务代码只调 `chat.pxshe.com`** (chat-api)。**绝不**:
- ❌ 直接 HTTP 调 `api.pxshe.com` (openim-api:10002) — 必须用 `flutter_openim_sdk` SDK
- ❌ 直接 WSS 调 `ws.pxshe.com` (openim-msggateway:10001) — SDK 内部用
- ❌ 调 `admin.pxshe.com` (admin-api) — 给超管用, Flutter 不用

**4 域架构**:

| 域 | 客户端谁用 | 后端进程 | 后端端口 | 协议 |
|---|---|---|---|---|
| `chat.pxshe.com` | **Flutter 业务** ✅ | chat-api | 10008 | HTTPS |
| `api.pxshe.com` | **OpenIM SDK 内部** | openim-api | 10002 | HTTPS |
| `ws.pxshe.com` | **OpenIM SDK 内部** | openim-msggateway | 10001 | WSS |
| `admin.pxshe.com` | ❌ 超管用 | admin-api | 10009 | HTTPS |

**关键**: `api.pxshe.com` 和 `ws.pxshe.com` 是**独立**域名,后端 nginx 反代到**不同**后端进程 (openim-api:10002 vs openim-msggateway:10001)。
WS 走 `wss://api.pxshe.com` 会 404 (反代没配 WSS),必须 `wss://ws.pxshe.com`。

详见 [docs/IM_INTEGRATION.md §9](./docs/IM_INTEGRATION.md) 和 [docs/app/SERVICE_INVENTORY.md](./docs/app/SERVICE_INVENTORY.md)。

### 第 16 条:Token 体系 (硬约束)

| Token | 来源 | 用途 | 存储 |
|---|---|---|---|
| `chatToken` | `/account/login` 响应 | 业务 HTTP header `token` | Hive (lazyBox) |
| `imToken` | `/account/login` 响应 | OpenIM SDK 登录 | Hive (lazyBox) |
| `userID` | `/account/login` 响应 | 用户唯一标识 | Hive (user model) |

**禁止** 把 token 存 SharedPreferences / 内存 (Hive CE 是唯一选择)。

---

## 第四章:UI 与主题(第 17-21 条)

### 第 17 条:Material 3

**强制用 Material 3** (`useMaterial3: true`), 主题走 `flex_color_scheme`。

### 第 18 条:主题切换

通过 `ThemeModeCubit` (`lib/_shared/blocs/theme_mode_cubit.dart`), 3 模式: light / dark / system。

### 第 19 条:无障碍

- 触控目标 ≥ 48x48 dp
- 颜色对比度 ≥ WCAG AA (4.5:1)
- 语义化 widget (Semantics / Tooltip)

### 第 20 条:响应式

`responsive_framework` 已集成, 3 断点: MOBILE / TABLET / DESKTOP。

### 第 21 条:Loading 与 Empty

**统一用**:
- `BaseLoading` (`lib/_core/widgets/base_loading.dart`)
- `BaseEmptyView` (`lib/_core/widgets/base_empty_view.dart`)
- `BaseErrorRetry` (`lib/_core/widgets/base_error_retry.dart`)

**禁止** widget 自己写 `CircularProgressIndicator` 或 `Center(Text(...))`。

---

## 第五章:认证(第 22-28 条)

### 第 22 条:登录域 (`chat.pxshe.com`)

**所有登录走 `chat.pxshe.com`**, 不用 `admin.pxshe.com`。

### 第 23 条:登录请求

```http
POST https://chat.pxshe.com/account/login
{
  "areaCode": "+86",
  "phoneNumber": "13900000001",
  "password": "Test123456",
  "platform": 2  // 1=iOS 2=Android 3=Windows ...
}
```

**禁止** MD5 密码, 走明文(后端要求)。

### 第 24 条:登录响应

```json
{
  "errorCode": 0,
  "data": {
    "chatToken": "eyJ...",
    "userID": "3370159211",
    "imToken": "eyJ..."
  }
}
```

3 个字段缺一不可, **imToken 不要单独再调 SDK 拿**。

### 第 25 条:Token 缓存

- 登录成功后立刻缓存到 Hive
- 启动时 `Bootstrap.init()` 读 Hive 恢复
- 401 → 清 token + 跳登录 (在 `ApiClient` 拦截器)

### 第 26 条:Logout

- 清 Hive (chatToken / imToken / user)
- 调 `OpenIM.iMManager.logout()` (阶段 2)
- 重置 AuthBloc 状态为 `unauthenticated`
- 跳 `/login`

### 第 27 条:注册 (3 种方式)

启动时拉 `/business/public/registration/config/get` 决定 UI (phone / email / username)。

### 第 28 条:隐私协议 (GDPR)

- 后端返回 Markdown 格式协议内容 (`privacyPolicyMarkdown`)
- Flutter 端用 `flutter_markdown` 渲染
- 提交注册时必须传 `privacyPolicyVersion` + `userAgreementVersion` (老版本会被拒)

---

## 第六章:IM 集成(第 29-33 条)

### 第 29 条:SDK 强制

**所有 IM 功能必须用 `flutter_openim_sdk` SDK**。**禁止**:
- ❌ 自己写 WebSocket
- ❌ 直接 HTTP 调 `api.pxshe.com` (openim-server)
- ❌ 业务代码直接 import `package:flutter_openim_sdk`

业务层只调 `IMRepository` (在 `lib/modules/im/data/repositories/`), **绝不**直接调 SDK API。

### 第 30 条:登录

登录响应拿 `imToken` → `IMRepository.login(imToken)` → SDK 内部连 `api.pxshe.com:10002`。

### 第 31 条:踢下线

监听 `OnKickedOfflineListener` → 清本地 token + 跳 `/login` + toast "已在其他设备登录"。

### 第 32 条:连接状态

监听 `OnConnectListener` → `ConnectionBloc` emit:
- `connected` — 正常
- `connecting` — 重连中 (显示"重连中..."横幅)
- `disconnected` — 断开

### 第 33 条:多端登录

OpenIM 默认: **PC 不互踢, 其他平台一台**。新设备登录会踢旧设备, 触发 §31。

---

## 第七章:数据持久化(第 34-35 条)

### 第 34 条:Hive CE 强制

**所有本地存储用 Hive CE** (hive_ce + hive_ce_flutter), 不用标准 hive (deprecated)。

**禁止**:
- ❌ SharedPreferences 存复杂对象
- ❌ 文件系统直接写 JSON
- ❌ SQL 关系型数据 (业务不需要)

### 第 35 条:反序列化 (硬约束)

子 map 必须 `is Map` + `Map<String, dynamic>.from()`, **不能** `is Map<String, dynamic>` 严格断言。

```dart
// ✅ 正确
final raw = box.get('user');
if (raw is Map) {
  final user = Map<String, dynamic>.from(raw);
}

// ❌ 错误 (冷启动 BUG)
final user = box.get('user') as Map<String, dynamic>;
```

理由: 冷启动时 `openimConfig` 可能为 null, 严格断言失败导致 IM 不自动重连。

---

## 第八章:多环境(第 36-38 条)

### 第 36 条:3 Flavor

- `production` — `com.pxshe.app`
- `staging` — `com.pxshe.app.stg` (app name "[STG] Pxshe App")
- `development` — `com.pxshe.app.dev` (app name "[DEV] Pxshe App")

入口文件:
- `lib/main_production.dart`
- `lib/main_staging.dart`
- `lib/main_development.dart`

### 第 37 条:启动命令

```bash
flutter run --flavor=development lib/main_development.dart
flutter run --flavor=staging lib/main_staging.dart
flutter run --flavor=production lib/main_production.dart
```

### 第 38 条:env.dart 配置

`lib/_core/env.dart` 集中放配置 (baseUrl / openim 地址), 通过 `--dart-define` 覆盖。

---

## 第九章:测试(第 39-41 条)

### 第 39 条:覆盖率基线 100%

`very_good test --coverage --min-coverage 100`, **覆盖率不能降**。

### 第 40 条:4 层级测试

| 层 | 工具 | 目标 |
|---|---|---|
| L1 单元 | `flutter_test` + `mocktail` + `bloc_test` | Bloc/Cubit/Repository/UseCase |
| L2 Widget | `flutter_test` | 通用 widget + 关键 Page |
| L3 集成 | `integration_test` | 5 关键流程 |
| L4 E2E | `patrol` (阶段 5) | 真机 |

详见 [docs/TESTING.md](./docs/TESTING.md)。

### 第 41 条:Architecture Test

```dart
// test/architecture/no_cross_module_import_test.dart
// 禁止 modules/*/data 直接 import modules/*/presentation
```

---

## 第十章:文档规范(第 42-45 条)

### 第 42 条:SSOT 原则

每个概念只有**一个**权威文档, 其它地方**引用**而不重复。

### 第 43 条:改动同步

代码改动 → 同步更新对应文档 → PR 标出。

### 第 44 条:ADR

任何**技术选型决策**必须有 ADR (Architecture Decision Record) 解释"为什么"。

ADR 命名: `NNNN-decision-name.md`, 数字递增。

### 第 45 条:新人 30 分钟

新人入职 30 分钟内能读 [`docs/KNOWLEDGE_GRAPH.md`](./docs/KNOWLEDGE_GRAPH.md) 看清整个项目。

---

## 第十一章:设计护栏(第 46-48 条)

### 第 46 条:状态管理简单优先

能 Cubit 解决的不用 Bloc。Bloc 只在事件流复杂时用 (IM 消息、OpenIM 事件)。

### 第 47 条:Repository 模式

业务逻辑在 Repository, 不在 DataSource。DataSource 只做 HTTP/Hive 调用 + 序列化。

### 第 48 条:UseCase 模式 (可选)

简单业务可以省 UseCase, 直接 Bloc → Repository。复杂业务 (跨多个 Repository) 用 UseCase 编排。

---

## 第十二章:分层约束(第 49 条)

### 第 49 条:依赖方向 (硬约束)

只能向下依赖, 不能反向:

```
app -> modules -> _core / _shared
modules 之间 ✗(走 <module>_module.dart 门面)
_core / _shared -> 0 依赖 modules / app
```

`flutter analyze` + architecture test 强制。

---

## 第十三章:扩展约束(第 50 条)

### 第 50 条:新 widget 跟现有 ≥ 80% 重合 → 扩展现有, 不许新建

**禁止** Avatar / Avatar2 / MyAvatar 共存。

---

## 第十四章:防堆砌约束(第 51 条) — 旅行箱原则

### 第 51 条:加新东西必须挤掉旧的

加 1 个新文件/函数/依赖, 必须先 `@Deprecated` 1 个旧的 (3 sprint 后必须删除)。

**禁止**:
- ❌ AppColors + AppColors2 + AppColorsV3
- ❌ utils + helpers + extensions + utils2
- ❌ 累积 100+ 弃用文件

---

## 第十五章:官方优先原则(第 52 条) — 菜谱原则

### 第 52 条:官方文档优先

**任何自定义实现前, 必须先查官方文档**:
- 官方 package 有 → 用官方的
- 官方没但社区有 (⭐ 1000+) → 用社区的
- 都没 → 自己写 + 写 ADR 解释为什么

**禁止** 自己写而不用 `flutter_*` / `dart:*` 官方包。

---

## 第十六章:防遗忘约束(第 53 条) — 戴工牌原则

### 第 53 条:AI 协作必读

任何 AI (包括我) 在做改动前必读本文件 + [`docs/KNOWLEDGE_GRAPH.md`](./docs/KNOWLEDGE_GRAPH.md) + [`docs/RECIPES.md`](./docs/RECIPES.md)。

### 第 53.1 条:改动前 5 问

1. 这条改动属于哪个 module?
2. 跨 module 吗? (走门面)
3. **影响 docs/ 吗? (强制: 改完代码必须同步文档, `tool/pre-commit.ps1` 会强制检查 `git diff --staged` 是否改了对应文档, 只 `Test-Path` 永远 true 不算改)**
4. 覆盖率会降吗? (要补测)
5. AGENTS.md 哪条相关? (要查)

### 第 53.2 条:commit 前 doc-sync checklist

每次 commit 前**必做**(`pre-commit` 钩子会强制):

```
[ ] git diff --staged --name-only 看改了哪些 .dart 文件
[ ] 对照映射主动改文档:
    - 改 lib/_core/        → docs/ARCHITECTURE.md 或 docs/KNOWLEDGE_GRAPH.md
    - 改 lib/_shared/      → docs/BUILDING_BLOCKS.md
    - 改 lib/modules/<m>/  → docs/PAGE_CLASSIFICATION.md
    - 改 lib/modules/auth/data/ → docs/ERROR_HANDLING.md
    - 改 lib/modules/<m>/data/ → docs/API.md
    - 改 pubspec.yaml      → docs/REFERENCE.md + docs/LICENSE_INFO.md
[ ] 跑 tool/doc_sync_audit.ps1 验证 code↔docs 内容一致
[ ] pre-commit 钩子必须 pass (OK: doc sync check pass)
```

**禁止**:
- ❌ 只看到 `OK: doc sync check pass` 就当 "文档已同步" — pre-commit 用 `Test-Path` 检查文件存在, 永远 true
- ❌ 改完代码后不主动想"哪个文档该更新", 期待 hook catch
- ❌ 用 `git commit --no-verify` 绕过 doc-sync (除非真无文档需要改)

---

## 第十七章:l10n 基础设施(第 54 条) — 地基原则

### 第 54 条:l10n 硬约束

**单一来源 = `intl` gen-l10n (ARB)**,**禁止** `easy_localization` (违反 § 51 防堆砌)。

| 资源 | 位置 | 备注 |
|---|---|---|
| ARB 文件 (SSOT) | `lib/l10n/arb/app_{zh,en,ar}.arb` | `app_en.arb` 是 template (`l10n.yaml` 配) |
| 生成代码 | `lib/l10n/gen/app_localizations*.dart` | `flutter gen-l10n` 自动生成, **不要手改** |
| 配置 | `l10n.yaml` | `arb-dir` / `output-localization-file` / `output-dir` 已配 |
| 启用 | `pubspec.yaml` `flutter: generate: true` | ✅ 已开 |
| Locale 状态 | `lib/_shared/blocs/locale_cubit.dart` | 持久化到 `THEME_BOX` (复用, 避免新增 box) |
| 调用方式 | `AppLocalizations.of(context)!.xxxCamelCase` | **不是** `context.tr('xxx.yyy')` |
| 配挂载 | `app.dart` `MaterialApp.router` 传 `localizationsDelegates` + `supportedLocales` + `locale: LocaleCubit.state` | **必须**配齐, 缺一抛 `LocalizationsNotFoundException` (bug f219a19 真实踩坑) |

**新增 key 流程**:
1. `lib/l10n/arb/app_en.arb` 加 `"xxxYyy": "English value"`
2. `lib/l10n/arb/app_zh.arb` 加 `"xxxYyy": "中文"`
3. (ar/es 同理, 缺翻译用英文 placeholder)
4. `flutter gen-l10n` 重生成 `lib/l10n/gen/`
5. 业务调 `AppLocalizations.of(context)!.xxxYyy`

**禁止**:
- ❌ 用 `easy_localization` 的 `context.tr()` / `context.locale` / `context.setLocale()` (已删, 不要回引)
- ❌ `assets/translations/*.json` (跟 ARB 重复)
- ❌ 在 widget 里硬编码中英文字符串 (除非是动态数据)
- ❌ 加新 locale 却不配 ARB 文件 (gen-l10n 会失败)
- ❌ 假设测试 widget 不需要 `MaterialApp` wrap (L10n 需要 Localizations ancestor)

### 第 54.1 条:踩过的坑 (bug f219a19)

**症状**: 改完代码, 真机启动后**红屏** `Localization not found for current context`。

**真因**: 模板 fork 时用了 `easy_localization` 的 `context.tr()`, 但**从来没**挂 `EasyLocalization` widget,**从来没**配 `assets/translations/*.json`,**从来没**在 `MaterialApp.localizationsDelegates` 配 `AppLocalizations.delegate`。

**教訓**:
1. **调用**任何 l10n API 前, **先验证基础设施闭环** (见 § 1):
   - widget tree 根挂 `Localizations` 提供者 (EasyLocalization widget **或** `MaterialApp.localizationsDelegates`)
   - 翻译资源存在 (JSON **或** ARB + 生成)
   - `pubspec.yaml` 注册 `assets:` 路径
2. **真机手动走一遍**所有 page — 测试覆盖率 100% ≠ 端到端可跑
3. **AGENTS.md vs ROADMAP.md 阶段号打架** (`EasyLocalization 阶段 4` vs `i18n 阶段 8+`) — 两份 SSOT 必对齐, 否则工程债永远藏
4. **业务代码**调用了**未配齐**的 API = 架构债 = 违反 § 51

### 第 54.1 条:l10n 迁移 intl gen-l10n (commit 6cfe911)

### 第 55 条:改动后端架构前必读后端 SSOT (硬约束)

**任何**涉及后端进程 / 端口 / 域名 / 协议 的改动,**第一步**是读 [`docs/app/SERVICE_INVENTORY.md`](./docs/app/SERVICE_INVENTORY.md) (后端 SSOT 权威)。

| 误踩坑 (历史 bug) | 教训 |
|---|---|
| 阶段 2.13 IM 地址配错 (`api.pxshe.com:10002` 直连) | 必读后端 SSOT,反代模式下 443 → 10002 走反代 |
| 阶段 2.16 WS 域名配错 (`wss://api.pxshe.com`) | 必读后端 SSOT,WS 走独立 `ws.pxshe.com` → 10001 (openim-msggateway),4 域架构 |

**4 域架构** (后端 SSOT 唯一权威):
| 域 | 后端进程 | 后端端口 | 客户端谁用 | 协议 |
|---|---|---|---|---|
| `chat.pxshe.com` | chat-api | 10008 | **Flutter 业务** | HTTPS |
| `api.pxshe.com` | openim-api | 10002 | OpenIM SDK 内部 | HTTPS |
| `ws.pxshe.com` | openim-msggateway | 10001 | OpenIM SDK 内部 | WSS |
| `admin.pxshe.com` | admin-api | 10009 | ❌ 超管用 | HTTPS |

**禁止**:
- ❌ `Test-Path` 文档存在 ≠ 文档已最新 (过时引用是 SSOT 漏洞)
- ❌ 看 chat 域模式就类推其他域 (4 域各自独立,WS/HTTP 走不同进程)
- ❌ 业务代码直接 HTTP/WS 调 `api.pxshe.com` / `ws.pxshe.com` (AGENTS §15)

### 第 56 条:dev 路由硬约束

**`/dev` 路由仅 `kDebugMode` 可见,生产 build 不应有此路由**。

| 项 | 约束 |
|---|---|
| 注册位置 | `lib/_shared/dev/dev_routes.dart` `devRoutes()` 函数 |
| 触发条件 | `kDebugMode == true` (release 返空 list) |
| 入口 | HomePage AppBar 右上角 `bug_report` 图标 (也用 `dart.vm.product` 守门) |
| 路由内容 | `DevMenuPage` 列出 16 路由,按 group 分组 (业务域/IM 域/认证域/错误域/阶段 3 占位) |
| 路由数据 | `DevRouteEntry` (label/path/description/icon/group) 硬编码在 `dev_routes.dart` |

**禁止**:
- ❌ 业务代码 import `dev_*` widget (反向依赖,违反 § 50 复用原则)
- ❌ 把 dev 路由当生产功能 (release 不应有 `/dev`)
- ❌ 在 dev 工具加业务逻辑 (dev 工具只服务于 dev,生产不带)
- ❌ 绕过 `kDebugMode` 守卫 (硬约束)

详见:
- `docs/BUILDING_BLOCKS.md` § 3.2 — Dev 工具 (`_shared/dev/`)
- `docs/PAGE_CLASSIFICATION.md` — `/dev` 路由行
- `docs/ARCHITECTURE.md` § 6 — 路由表 + dev 路由说明

---

*最后更新: 2026-07-06 — `/dev` 路由 (commit 阶段 2.16)*
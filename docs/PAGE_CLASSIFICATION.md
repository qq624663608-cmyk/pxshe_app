# docs/PAGE_CLASSIFICATION.md — 页面 × Module 矩阵

> **本文件是页面 × 构件的 SSOT 矩阵。**
> 每加 1 个页面, 加 1 行; 每加 1 个 module, 加 1 列。

---

## 矩阵 (pxshe_app 当前)

| 页面 (lib/modules/.../features/) | auth | registration | im | universe | table | row |
|---|---|---|---|---|---|---|
| `auth/login_page` | ✅ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| `auth/placeholder_page` | ✅ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| `registration/register_page` | ⬜ | ✅ | ⬜ | ⬜ | ⬜ | ⬜ |
| `im/chat_list_page` (阶段 2.2 ✅) | ⬜ | ⬜ | ✅ | ⬜ | ⬜ | ⬜ |
| `im/chat_page` (阶段 2.3 ✅) | ⬜ | ⬜ | ✅ | ⬜ | ⬜ | ⬜ |
| `im/contacts_page` (阶段 2.4 ✅) | ⬜ | ⬜ | ✅ | ⬜ | ⬜ | ⬜ |
| `im/placeholder/connection_status_page` (阶段 2.1 ✅) | ⬜ | ⬜ | ✅ | ⬜ | ⬜ | ⬜ |
| `universe/list_page` (阶段 3) | ⬜ | ⬜ | ⬜ | ✅ | ⬜ | ⬜ |
| `universe/detail_page` (阶段 3) | ⬜ | ⬜ | ⬜ | ✅ | ✅ | ✅ |
| `table/manage_page` (阶段 3) | ⬜ | ⬜ | ⬜ | ✅ | ✅ | ⬜ |
| `row/list_page` (阶段 3) | ⬜ | ⬜ | ⬜ | ✅ | ✅ | ✅ |
| `row/edit_page` (阶段 3) | ⬜ | ⬜ | ⬜ | ⬜ | ✅ | ✅ |
| `_shared/home_page` | ⬜ | ⬜ | ✅ | ✅ | ⬜ | ⬜ |
| `_shared/settings_page` | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| `_shared/splash_page` | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

✅ = 已用, ⬜ = 不适用

---

## 覆盖率

```
总: 13 页面 × 6 module = 78 单元
已用: ~30
覆盖率: ~38%

目标: 每页至少用 1 个 module
当前: 需要补足 (阶段 2/3)
```

---

## 改这表的规则

```
1. 加新页面 → 立即在矩阵加 1 行
2. 加新 module → 立即在矩阵加 1 列
3. 矩阵覆盖率 ≥ 80%
4. CI 跑 check (阶段 5 加)
```

---

## 路由清单 (pxshe_app)

| 路由 | 守卫 | 页面 | module |
|---|---|---|---|
| `/` | `initialRedirect` | redirect (Splash) | - |
| `/splash` | - | SplashPage | _shared |
| `/errors/401` | - | Error401Page | _shared |
| `/errors/404` | - | Error404Page | _shared |
| `/login` | `unAuthRouteGuard` | LoginPage | auth |
| `/register` | `unAuthRouteGuard` | RegisterPage | registration |
| `/home` | `authRouteGuard` | HomePage | _shared |
| `/settings` | `authRouteGuard` | SettingsPage | _shared |
| `/im/status` (阶段 2.1 ✅, 2.15 修地址) | `authRouteGuard` | ConnectionStatusPage | im |
| `/chat_list` (阶段 2.2 ✅) | `authRouteGuard` | ChatListPage | im |
| `/chat/:id` (阶段 2.3 ✅) | `authRouteGuard` | ChatPage | im |
| `/contacts` (阶段 2.4 ✅) | `authRouteGuard` | ContactsPage | im |
| `/profile` (阶段 2.5 ✅) | `authRouteGuard` | ProfilePage | im |

**IM 后端地址** (阶段 2.15 + 2.16 修): 4 域架构
- 业务代码: `https://chat.pxshe.com` (chat-api:10008) — **唯一业务域**
- SDK 内部 HTTP: `https://api.pxshe.com` (openim-api:10002)
- SDK 内部 WSS: `wss://ws.pxshe.com` (openim-msggateway:10001, **独立 msg-gateway 域**)
- 客户端**不带端口** (反代 443),详见 [docs/IM_INTEGRATION.md §9](./IM_INTEGRATION.md) + 后端 SSOT [docs/app/SERVICE_INVENTORY.md](./app/SERVICE_INVENTORY.md)。
| `/universe` (阶段 3) | `authRouteGuard` | UniverseListPage | universe |
| `/universe/:id` (阶段 3) | `authRouteGuard` | UniverseDetailPage | universe |
| `/universe/:id/table/:name` (阶段 3) | `authRouteGuard` | RowListPage | row |
| `/universe/:id/table/:name/edit` (阶段 3) | `authRouteGuard` | RowEditPage | row |

### 守卫说明

| 守卫 | 检查 | 行为 |
|---|---|---|
| `unAuthRouteGuard` | `AuthBloc.state.status` | 已登录 → 跳 `firstNavRoute()`, 未登录 → 允许 |
| `authRouteGuard` | `AuthBloc.state.status` | 未登录 → 跳 `/login`, 已登录 → 允许 |

**`firstNavRoute()` 依赖 navTabs 列表**:

```dart
String firstNavRoute() {
  var navRoutes = getNavRoutes();        // di<List<...>>(instanceName: navTabsDiKey)
  if (navRoutes.isNotEmpty) {
    return navRoutes.first.route;        // 当前 = "/home"
  }
  return "/";  // fallback — Bug 1b9871a 死循环起点
}
```

navTabs 列表由 `AppModules.initAfterRunApp(context)` 填充, 详见 `docs/ARCHITECTURE.md § 6.6`。
**漏调** → 列表空 → 死循环 → Error404Page。

**跳转机制**: 通过 `GoRouter.refreshListenable` (绑定 `AuthBloc.stream`) 自动重跑守卫, 业务层**零** `router.go()` 调用。
详见 `docs/ARCHITECTURE.md § 6.5`。

### L10n (阶段 2.14 完成)

`/login` + `/register` + `/home` + `/settings` + `/profile` (auth module 的 `getAuthNavTabs`) 全部用 `AppLocalizations.of(context)!` 取 tab 标题。**新增路由**必须 i18n-friendly:

```dart
// ✅ 正确
final l10n = AppLocalizations.of(context);
AdaptiveDestination(title: l10n.layoutPageHome, ...);

// ❌ 错误 (违反 AGENTS §54)
AdaptiveDestination(title: 'Home', ...);  // 硬编码
AdaptiveDestination(title: context.tr('layoutPage.home'), ...);  // easy_localization API, 已删
```

加新 key 流程: `app_en.arb` → `app_zh.arb` → `flutter gen-l10n` → 调 `l10n.xxxCamelCase`。详见 `docs/I18N.md § 3.4`。

**Import 路径** (常踩坑): 生成文件在 `lib/l10n/gen/`,不是 `lib/_shared/l10n/gen/` 或 `lib/modules/<m>/l10n/gen/`。见 `BUILDING_BLOCKS.md § 3.1` 禁止条款。

---

*最后更新: 2026-07-06 — 阶段 2.5 ProfilePage 完成 (+ 阶段 2.1-2.4)*
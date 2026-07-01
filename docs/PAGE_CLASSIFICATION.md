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
| `im/chat_list_page` (阶段 2) | ⬜ | ⬜ | ✅ | ⬜ | ⬜ | ⬜ |
| `im/chat_page` (阶段 2) | ⬜ | ⬜ | ✅ | ⬜ | ⬜ | ⬜ |
| `im/contacts_page` (阶段 2) | ⬜ | ⬜ | ✅ | ⬜ | ⬜ | ⬜ |
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

| 路由 | 页面 | module |
|---|---|---|
| `/` | redirect | - |
| `/splash` | SplashPage | _shared |
| `/errors/401` | Error401Page | _shared |
| `/errors/404` | Error404Page | _shared |
| `/login` | LoginPage | auth |
| `/register` | RegisterPage | registration |
| `/home` | HomePage | _shared |
| `/settings` | SettingsPage | _shared |
| `/chat` (阶段 2) | ChatListPage | im |
| `/chat/:id` (阶段 2) | ChatPage | im |
| `/contacts` (阶段 2) | ContactsPage | im |
| `/universe` (阶段 3) | UniverseListPage | universe |
| `/universe/:id` (阶段 3) | UniverseDetailPage | universe |
| `/universe/:id/table/:name` (阶段 3) | RowListPage | row |
| `/universe/:id/table/:name/edit` (阶段 3) | RowEditPage | row |

---

*最后更新: 2026-07-01*
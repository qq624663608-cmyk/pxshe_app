# docs/AI_GUIDE.md — AI 助手协作指南

> **本文件是 AI 协作 SSOT。**
> 任何 AI (包括我) 在做改动前必读本文 + AGENTS.md + KNOWLEDGE_GRAPH.md + RECIPES.md。

---

## 0. tool/ 脚本使用 (必读)

pxshe_app 提供 11 个 AI 协作脚本 (`tool/`), 强制使用:

| 脚本 | 何时跑 | 作用 |
|---|---|---|
| `tool/ai_recite.ps1` | **对话开始时** | AI 复述 5 段规定 (设计初心 + 5 反模式 + 任务文档 + 23 硬规则 + 4 步防错) |
| `tool/ai_self_check.ps1` | **每 5 轮对话** | 5 项自检 (颜色 / BLoC / 跨 module / 业务位置 / 文档同步) |
| `tool/ai_pre_change.ps1` | **大改动前** | 5 问自检 (跟现有重叠?新 widget?新 provider?文档影响?用户确认?) |
| `tool/ai_session_end.ps1` | **commit 前** | 6 项 + 4 lint 必跑 |
| `tool/doc_lint.ps1` | 文档改动后 | 文档质量 (行数 / DEPRECATED / SSOT 头) |
| `tool/check_duplicates.ps1` | 加 widget 前 | 防 widget 重复 (AGENTS §50) |
| `tool/check_official.ps1` | 加依赖前 | 官方优先 + 禁止包 (AGENTS §52) |
| `tool/doc_freshness.ps1` | 每周 CI | 文档陈旧度 |
| `tool/pre-commit.ps1` | **git commit 时自动** | 改代码必带文档 |
| `tool/quarterly_cleanup.ps1` | 每季度 | 断舍离 (AGENTS §51) |

### 入口

```powershell
# 菜单
pwsh tool/ai.ps1

# 一步到位
pwsh tool/ai.ps1 new     # 对话开始 (5 段复述)
pwsh tool/ai.ps1 check   # 5 轮自检
pwsh tool/ai.ps1 change  # 大改动前
pwsh tool/ai.ps1 done    # commit 前 (跑 4 lint)
pwsh tool/ai.ps1 all     # 全套
```

### 启用 pre-commit 钩子 (重要!)

```bash
git config core.hooksPath tool
```

启用后, **每次 `git commit` 自动跑** `pre-commit.ps1`, 检查代码改动是否同步了文档。

### AI 协作流程

```
1. 对话开始 → pwsh tool/ai.ps1 new → AI 复述 5 段
2. 改动代码 → 同步文档 → pwsh tool/ai_self_check.ps1
3. 大改动前 → pwsh tool/ai_pre_change.ps1
4. git commit → 自动跑 tool/pre-commit.ps1
5. 每天 1 次 → pwsh tool/ai_session_end.ps1 (跑 4 lint)
6. 每周 → pwsh tool/doc_freshness.ps1
7. 每季度 → pwsh tool/quarterly_cleanup.ps1
```

详见 [AGENTS.md §16 防遗忘约束](../AGENTS.md)。

---

## 1. 5 大反模式 (看到就拒绝 PR)

```
❌ mega Bloc (5 个功能塞一起)
❌ State 不分职责的 ChangeNotifier
❌ 跨 module 互相 import 内部
❌ 直接 setState 调 ApiClient
❌ 在 widget build 里写业务逻辑
```

详见 [AGENTS.md § ★ 5 大反模式](../AGENTS.md)。

---

## 2. 改动前 5 问

```
1. 这条改动属于哪个 module?
2. 跨 module 吗? (走门面)
3. 影响 docs/ 吗? (要同步)
4. 覆盖率会降吗? (要补测)
5. AGENTS.md 哪条相关? (要查)
```

---

## 3. 沟通风格

- **不啰嗦** — 不要复述用户的话
- **不擅自执行** — 用户问"怎么做"先给方案
- **一次问完** — 必须问用户时打包相关问题
- **直接做** — 用户说"做"立刻动手, 跳过中间确认

---

## 4. 代码引用格式

永远用 `file_path:line_number`:

```dart
// ✅ 正确
// 改 lib/modules/auth/data/auth_repository_impl.dart:65
final token = res.data['data']['chatToken'] as String;

// ❌ 错误
// 改 auth repository 里的 token 解析
```

---

## 5. 改动约束 (硬约束)

```
- 不引入新依赖 (除非用户明确要求)
- 不创建新文件除非必要 (优先编辑现有)
- 不修改 docs/ 下的 SSOT 文档 (除非 doc 修复)
- 不改 lib/modules/*/data/ 里 Datasource 的"接口"层, 只改实现
- VM 改动必须配单测
- 保持 flutter analyze 0 errors
- 保持 very_good test --min-coverage 100
```

---

## 6. 三域对接 (硬约束)

```
✅ Flutter 客户端只调 chat.pxshe.com (chat-api)
❌ 绝不直接 HTTP 调 api.pxshe.com (openim-server) - 必须用 flutter_openim_sdk
❌ 调 admin.pxshe.com (admin-api) - 给超管用, Flutter 不用
```

详见 [IM_INTEGRATION.md](./IM_INTEGRATION.md) + [ARCHITECTURE.md §3](./ARCHITECTURE.md)。

---

## 7. BLoC 栈约定

```
- Bloc: 复杂事件流 (IM 消息、踢下线)
- Cubit: 简单状态机 (登录表单、主题切换)
- 每个 module 1 个或多个 Bloc/Cubit, 不是 1 个 mega
- state 类必须 extends Equatable
- event 类必须 extends Equatable
- 用 bloc_test 写单测
```

详见 [ADR-0001](./ADR/0001-why-bloc.md) + [ADR-0004](./ADR/0004-why-multi-cubit.md)。

---

## 8. 错误处理

```
- 业务代码永远不直接 catch (除了 BLoC 内部)
- 走 ErrorHandler.handle(context, e) 唯一入口
- 登录/注册/改密页传 isOnAuthPage: true 防误跳
- 401 → 自动清 token + 跳登录 (在 ApiClient 拦截器)
```

详见 [ERROR_HANDLING.md](./ERROR_HANDLING.md)。

---

## 9. 测试

```
- 每个 Bloc/Cubit/Repository 配单测
- 覆盖率不能降 (very_good test --min-coverage 100)
- 用 mocktail mock, 不用 mockito
- 用 bloc_test 测 Bloc, 用 ProviderContainer 测 Cubit
```

详见 [TESTING.md](./TESTING.md)。

---

## 10. 项目文件结构 (AI 必须知道)

```
pxshe_app/
├── AGENTS.md                 ← 53+ 宪法
├── docs/                     ← 18+ SSOT 文档 + 10 ADR
├── lib/
│   ├── main_*.dart          ← 3 flavor 入口
│   ├── bootstrap.dart       ← very_good 4 阶段启动
│   ├── app/                 ← MaterialApp.router
│   ├── _core/               ← Bootstrap / DI / ApiClient / Database / Error
│   ├── _shared/             ← Theme / 公共路由 / 公共 widget
│   └── modules/             ← 6 个业务 module (auth/registration/im/universe/table/row)
└── test/                    ← 单元 + widget test
```

---

## 11. pxshe_app 特定术语

| 术语 | 含义 |
|---|---|
| 4 阶段启动 | Native → main → Bootstrap → App |
| 三域 | api.pxshe.com / chat.pxshe.com / admin.pxshe.com |
| 6 段错误码 | 1xxx 参数 / 2xxx 鉴权 / 3xxx 资源 / 4xxx IM / 5xxx 业务 / 6xxx 服务 |
| 32+ 宪法 | AGENTS.md 里的所有硬规则 |
| superCode | `666666`, 测试阶段验证码 |
| 6 段 (errors) | 错误码 1xxx-6xxx |
| imToken | OpenIM SDK 登录用的 token (chat.pxshe.com 返回) |
| 25 widget | universe_app 特有的 widgetLocator 概念, **pxshe_app 不存在** |

---

## 12. 跟 universe_app 的差异

| 项 | universe_app | pxshe_app |
|---|---|---|
| 状态管理 | Riverpod 2.x | **BLoC 9.x** |
| 客户端身份 | 内部员工 + 客户 | 内部用 + 普通用户 |
| 业务域 | universe-api (Django) | chat.pxshe.com (Go) |
| IM SDK | openim-sdk-flutter | openim-sdk-flutter (同) |
| License | 商业 (未开源) | **AGPL-3.0** (开源) |
| 25 widget | ✅ 有 | ❌ 没有 (pubshe 不用 widgetLocator 模板) |
| AUTH 三方 | chatAdmin (超管) | 普通用户 (phone + password) |
| Token 类型 | 1 种 (JWT) | 3 种 (chatToken + imToken + userID) |

---

## 13. 跟用户沟通的格式

- 每次 commit 完成: 简短汇报
- 每次遇到问题: 先给方案, 等用户决定
- 每次代码改动: 引用 `file:line`
- 每次询问: 把相关问题打包, 不要拆碎

---

*最后更新: 2026-07-01*
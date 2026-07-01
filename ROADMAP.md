# ROADMAP — pxshe_app 实施路线图

> **8 阶段 30+ commit + 18 成熟维度 checklist。**
> 每次 commit 完成更新 ✓ 状态。
> 详情见 [docs/](docs/) + [AGENTS.md](AGENTS.md)。

---

## 项目目标

pxshe_app = Flutter IM 客户端 + 宇宙业务后台

**MVP** (阶段 1+2 完成后):
- 启动 → SplashPage → LoginPage → 输入 phone+password → HomePage
- OpenIM 集成 (会话/聊天/好友)
- 业务模块 (universe/table/row) 完整

**长期目标** (阶段 3-8+):
- 完整测试覆盖
- CI/CD + 监控 + 灰度
- UI 美化 + 动画 + 品牌
- 高级功能 (推送/文件/语音, 按需)
- a11y + i18n + 灾备 + 数据分析

---

## 进度总览 (8 阶段 + 18 维度)

| 阶段 | 主题 | 状态 | 覆盖维度 |
|---|---|---|---|
| **0** 规则 | AGENTS/18 docs/10 ADR/tool | ✅ 100% | 7 |
| **1** 骨架 | ApiClient/ErrorHandler/AppColors/registration/bootstrap | 🟡 65% | 1+6 |
| **2** IM | OpenIM 集成 | ❌ 0% | 1+6+18 |
| **3** 业务 | universe/table/row | ❌ 0% | 1+6+10 |
| **4** 质量 | 集成测试/异常路径/Code Review | ❌ 0% | 2+8+9 |
| **5** 工程化 | CI/CD/灰度/监控/可观测性 | ❌ 0% | 3+4+5+12+14 |
| **6** 美化 | 动画/微交互/空状态/品牌色 | ❌ 0% | 6 (深化) |
| **7** 高级 | 推送/文件/语音 (按需) | ❌ 0% | 18 (扩展) |
| **8+** 长尾 | a11y/i18n/灾备/数据分析 | ❌ 0% | 11+13+15+17 |
| **合计** | | | **18 维度** |

图例: ✅ 完成 | 🟡 部分 | ❌ 未开始

---

## 18 成熟维度 Checklist

| # | 维度 | 阶段 | 状态 | 位置 |
|---|---|---|---|---|
| 1 | 分层架构 | 1-3 | ✅ 100% | `lib/_core` `lib/modules/*` |
| 2 | 测试金字塔 | 4 | ❌ 0% | `test/` |
| 3 | CI/CD 流水线 | 5 | ❌ 0% | `.github/workflows/` |
| 4 | 监控告警 | 5 | ❌ 0% | `lib/_core/monitoring/` (阶段 5) |
| 5 | 灰度发布 | 5 | ❌ 0% | Feature flag (FEATURE_FLAGS.md) |
| 6 | 设计系统 | 1+6 | 🟡 30% | `lib/_core/theme/` |
| 7 | SSOT + ADR | 0 | ✅ 100% | `docs/` + `docs/ADR/` |
| 8 | Code Review | 4 | ❌ 0% | PR 模板 + AGENTS 自检 |
| 9 | SemVer | 4-5 | 🟡 20% | `pubspec.yaml` 1.0.0+1 |
| 10 | GDPR | 3+7 | 🟡 30% | privacy 协议 + 注销待做 |
| 11 | a11y | 8+ | ❌ 0% | 阶段 8+ 评估 |
| 12 | 性能预算 | 5-6 | ❌ 0% | 阶段 5 监控 + 阶段 6 调优 |
| 13 | i18n | 8+ | ❌ 0% | `lib/_core/i18n/` (EasyLocalization 已装) |
| 14 | 可观测性 | 5 | 🟡 30% | `lib/_core/logger/` (appLogger) |
| 15 | 灾备 | 8+ | ❌ 0% | 阶段 8+ 评估 |
| 16 | 协作流程 | 4 | 🟡 30% | `docs/CONTRIBUTING.md` |
| 17 | 数据分析 | 8+ | ❌ 0% | 阶段 8+ 评估 |
| 18 | 运营 (推送/分享) | 7 | ❌ 0% | 阶段 7 按需 |

**当前覆盖**: 7/18 = 39% (含部分覆盖)

---

## 阶段 0: 规则 (✅ 100%)

| Commit | 内容 | 状态 |
|---|---|---|
| 0.1 | `very_good create flutter_app pxshe_app` | ✅ |
| 0.2 | lint (very_good_analysis + bloc_lint) | ✅ |
| 0.3 | LICENSE (AGPL-3.0) | ✅ |
| 0.4 | 18 docs + 10 ADR (策略 B) | ✅ |
| 0.5 | tool/ 11 脚本 + ROADMAP | ✅ |

---

## 阶段 1: 业务骨架 (🟡 65%)

### 已完成 (7 commit)
| Commit | 内容 | 状态 |
|---|---|---|
| 1.1 | 核心依赖 + flutter_markdown + openim-sdk-flutter | ✅ |
| 1.2 | `_core/` + `_shared/` 移植 | ✅ |
| 1.3 | auth module 移植 | ✅ |
| 1.4 | auth 改造 (phone + password) | ✅ |
| 1.11 | Android 构建配置 (Stage 3 修复) | ✅ |
| 1.12 | OpenIM SDK 权限 | ✅ |
| 1.13-1.16 | 8 个 SSOT 文档 | ✅ |

### 待完成 (5 commit, ~12 小时)
| Commit | 内容 | 状态 |
|---|---|---|
| **1.9** | ApiClient (chat 域 + operationID + 401 拦截器) | 🟡 下一个 |
| **1.10** | 32 条宪法 (AppColors / ErrorHandler / ApiException) | ❌ |
| **1.5** | registration module (实体 + Service) | ❌ |
| **1.7** | 4 阶段启动 + LoadingPage 决定路由 | ❌ |
| **1.8** | Logout use case + 401 简单方案 | ❌ |

### 阶段 1 验收
- [ ] 模拟器启动看 SplashPage
- [ ] 跳 LoginPage (有 phone+password 输入框)
- [ ] 输入 + 提交 → Loading → 跳 HomePage
- [ ] flutter analyze 0 errors
- [ ] very_good test 100% coverage

---

## 阶段 2: OpenIM 集成 (❌ 0%, 4-5 天)

| Commit | 内容 | 覆盖维度 |
|---|---|---|
| 2.1 | SDK 封装层 (`openim_sdk_wrapper.dart`) | 1 |
| 2.2 | 登录串联 (login → imToken → SDK login) | 1 |
| 2.3 | IM 实体 + Repository (Conversation/Message/Friend/Group) | 1 |
| 2.4 | IM Bloc (Connection/Conversation/Message) | 1 |
| 2.5 | IM UI (会话列表 / 聊天页 / 好友) | 1+6 |
| 2.6 | 踢下线 + 重连监听 | 1+18 |
| 2.7 | IM 测试 (mock SDK + Bloc test) | 2 |

### 阶段 2 验收
- [ ] 登录后能进 IM 聊天页
- [ ] 收到消息能显示
- [ ] 踢下线能自动跳登录

---

## 阶段 3: 业务模块 (❌ 0%, 5-7 天)

| Commit | 内容 | 覆盖维度 |
|---|---|---|
| 3.1 | universe module (CRUD + visibility + 不传 creatorId) | 1+6+10 |
| 3.2 | table module (CRUD + ^[A-Za-z0-9_]+$ 校验) | 1+6 |
| 3.3 | row module (CRUD + 动态 JSON 编辑器) | 1+6 |
| 3.4 | 业务测试 (3 module 各 1 套) | 2 |

### 阶段 3 验收
- [ ] 能创建/编辑/删除世界
- [ ] 能创建子表 + 加数据
- [ ] 移动端 UX 跟 web 端一致

---

## 阶段 4: 质量 (❌ 0%, 3-5 天)

| Commit | 内容 | 覆盖维度 |
|---|---|---|
| 4.1 | 集成测试 (`integration_test/`, 5 关键流程) | 2 |
| 4.2 | 异常路径测试 (网络断/服务器挂/IM 断) | 2+8 |
| 4.3 | Code Review 流程跑通 (PR + 模板) | 8+16 |
| 4.4 | SemVer 流程 (CI 自动递增) | 9 |

### 阶段 4 验收
- [ ] 5 关键流程集成测试通过
- [ ] PR 模板强制填写
- [ ] CI 自动递增版本

---

## 阶段 5: 工程化 (❌ 0%, 3-5 天)

| Commit | 内容 | 覆盖维度 |
|---|---|---|
| 5.1 | CI 流水线 (8 job, `.github/workflows/ci.yml`) | 3 |
| 5.2 | 灰度发布 (feature flag 流程) | 5 |
| 5.3 | 监控告警 (Sentry / Crashlytics 评估) | 4 |
| 5.4 | 性能监控 (启动 / Frame / 包大小) | 12 |
| 5.5 | 可观测性 (log 聚合 + metrics) | 14 |

### 阶段 5 验收
- [ ] CI 8 job 全过
- [ ] 监控接入, 崩溃可见
- [ ] 启动时间 < 3s

---

## 阶段 6: UI 美化 (❌ 0%, 1 周)

| Commit | 内容 | 覆盖维度 |
|---|---|---|
| 6.1 | 动画 (`flutter_animate` 集成) | 6 |
| 6.2 | 微交互 (按钮反馈/页面切换) | 6 |
| 6.3 | 空状态/加载/错误状态设计 | 6 |
| 6.4 | 品牌色 + Logo + 自定义字体 | 6 |

### 阶段 6 验收
- [ ] 视觉一致 (AppColors/AppSpacing 全用)
- [ ] 动画流畅 (60fps)
- [ ] 加载/空/错误状态有插画

---

## 阶段 7: 高级功能 (❌ 0%, 2 周, 按需)

| Commit | 内容 | 覆盖维度 |
|---|---|---|
| 7.1 | 推送通知 (FCM) | 18 |
| 7.2 | 文件上传 (头像/封面) | 18 |
| 7.3 | 语音消息 | 18 |
| 7.4 | @ 提及 + 已读回执 | 18 |
| 7.5 | 账号注销 (GDPR) | 10 |

### 阶段 7 验收 (按需)
- [ ] 推送能收到
- [ ] 语音能发送

---

## 阶段 8+: 长尾 (❌ 0%, 持续)

| Commit | 内容 | 覆盖维度 |
|---|---|---|
| 8.1 | a11y (TalkBack / VoiceOver / 对比度) | 11 |
| 8.2 | i18n (EasyLocalization 配置 + 多语言) | 13 |
| 8.3 | 灾备 (多区域部署 + 数据备份) | 15 |
| 8.4 | 数据分析 (漏斗/留存) | 17 |

---

## 跟用户的协议

- **每个 commit 完成 → 汇报** (含验证结果)
- **遇到问题 → 先给方案 → 等用户决定** (不擅自执行)
- **每阶段结束 → 更新 ROADMAP ✓ 状态**
- **文档改动 → 同步到 ROADMAP + CHANGELOG**

---

## 下一步 (当前)

```
下一步: Commit 1.9 ApiClient
时间:   ~1-2 小时
内容:
  - lib/_core/network/api_client.dart (Dio + 拦截器)
  - lib/_core/network/operation_id_interceptor.dart
  - lib/_core/network/auth_interceptor.dart
  - lib/_core/network/error_interceptor.dart
验证:
  - flutter analyze 0 errors
  - very_good test 100% coverage
```

---

*最后更新: 2026-07-01 — 阶段 1 收尾中, 18 维度 39% 覆盖*
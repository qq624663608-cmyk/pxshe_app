# docs/README.md — 文档总览

> **本文件是 docs/ 目录 SSOT (Single Source of Truth) 入口。**
> pxshe_app 文档入口, 新人从这里开始, 4 层读法。

---

## 1. 4 层读法

### 第 1 层: 总览 (30 分钟)

- [KNOWLEDGE_GRAPH.md](./KNOWLEDGE_GRAPH.md) — 1 文档看懂整个项目
- [../AGENTS.md § 设计初心](../AGENTS.md) — 5 大反模式

### 第 2 层: 架构 (1 小时)

- [ARCHITECTURE.md](./ARCHITECTURE.md) — Clean Arch + Modular + BLoC
- [ERROR_HANDLING.md](./ERROR_HANDLING.md) — 6 段错误码
- [API.md](./API.md) — 全部 API 端点

### 第 3 层: 流程 (1 小时)

- [CONTRIBUTING.md](./CONTRIBUTING.md) — PR / commit / 分支 / 命名
- [DEPLOYMENT.md](./DEPLOYMENT.md) — Release + CI + Flavors
- [TESTING.md](./TESTING.md) — 4 层级测试

### 第 4 层: 细节 (按需)

- [BUILDING_BLOCKS.md](./BUILDING_BLOCKS.md) — 通用 widget + 23 硬规则
- [RECIPES.md](./RECIPES.md) — 5 个"加新 X"步骤
- [CACHE_STRATEGY.md](./CACHE_STRATEGY.md) — 缓存设计
- [CONFIGURATION.md](./CONFIGURATION.md) — env.dart + 监控开关
- [IM_INTEGRATION.md](./IM_INTEGRATION.md) — OpenIM SDK 集成
- [LICENSE_INFO.md](./LICENSE_INFO.md) — AGPL-3.0 兼容性
- [PAGE_CLASSIFICATION.md](./PAGE_CLASSIFICATION.md) — 页面 × module 矩阵
- [AI_GUIDE.md](./AI_GUIDE.md) — AI 协作指南
- [REFERENCE.md](./REFERENCE.md) — 官方资源 + 必备/禁止包
- [CHANGELOG.md](./CHANGELOG.md) — 版本历史
- [ADR/](./ADR/) — 10 个架构决策记录

---

## 2. 文档清单 (18 + 10 ADR)

| 文档 | 用途 |
|---|---|
| [KNOWLEDGE_GRAPH.md](./KNOWLEDGE_GRAPH.md) | ★ 总览 SSOT (30 分钟) |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 架构 SSOT |
| [API.md](./API.md) | API 端点 SSOT |
| [ERROR_HANDLING.md](./ERROR_HANDLING.md) | 错误码 SSOT |
| [TESTING.md](./TESTING.md) | 测试策略 SSOT |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | 协作流程 SSOT |
| [DEPLOYMENT.md](./DEPLOYMENT.md) | 发布 SSOT |
| [BUILDING_BLOCKS.md](./BUILDING_BLOCKS.md) | widget 复用 SSOT |
| [RECIPES.md](./RECIPES.md) | 新增/修改 SSOT |
| [CACHE_STRATEGY.md](./CACHE_STRATEGY.md) | 缓存策略 SSOT |
| [CONFIGURATION.md](./CONFIGURATION.md) | 配置 SSOT |
| [REFERENCE.md](./REFERENCE.md) | 依赖选型 SSOT |
| [PAGE_CLASSIFICATION.md](./PAGE_CLASSIFICATION.md) | 页面 × module SSOT |
| [AI_GUIDE.md](./AI_GUIDE.md) | AI 协作 SSOT |
| [IM_INTEGRATION.md](./IM_INTEGRATION.md) | OpenIM 集成 SSOT |
| [LICENSE_INFO.md](./LICENSE_INFO.md) | License 兼容性 SSOT |
| [FEATURE_FLAGS.md](./FEATURE_FLAGS.md) | Feature Flag SSOT |
| [CHANGELOG.md](./CHANGELOG.md) | 版本历史 |
| [ADR/](./ADR/) | 10 个架构决策 |

---

## 3. 找 X 看哪里 (快速导航)

| 我想... | 看哪里 |
|---|---|
| 了解项目架构 | [KNOWLEDGE_GRAPH.md](./KNOWLEDGE_GRAPH.md) → [ARCHITECTURE.md](./ARCHITECTURE.md) |
| 了解错误处理 | [ERROR_HANDLING.md](./ERROR_HANDLING.md) |
| 加新 widget | [BUILDING_BLOCKS.md](./BUILDING_BLOCKS.md) + [RECIPES.md §1](./RECIPES.md) |
| 加新 module | [RECIPES.md §2](./RECIPES.md) + [ARCHITECTURE.md §2](./ARCHITECTURE.md) |
| 加新 API 端点 | [RECIPES.md §3](./RECIPES.md) + [API.md](./API.md) |
| 加新错误码 | [RECIPES.md §4](./RECIPES.md) + [ERROR_HANDLING.md](./ERROR_HANDLING.md) |
| 了解 OpenIM 集成 | [IM_INTEGRATION.md](./IM_INTEGRATION.md) |
| 了解 License 兼容性 | [LICENSE_INFO.md](./LICENSE_INFO.md) |
| 了解部署流程 | [DEPLOYMENT.md](./DEPLOYMENT.md) |
| 了解缓存设计 | [CACHE_STRATEGY.md](./CACHE_STRATEGY.md) |
| 了解设计 Token | [BUILDING_BLOCKS.md §1](./BUILDING_BLOCKS.md) |
| 了解技术选型理由 | [ADR/](./ADR/) 目录 |
| 了解贡献流程 | [CONTRIBUTING.md](./CONTRIBUTING.md) |
| 了解环境配置 | [CONFIGURATION.md](./CONFIGURATION.md) |
| 了解测试 | [TESTING.md](./TESTING.md) |

---

## 4. ADR 目录

| ADR | 主题 |
|---|---|
| [0001](./ADR/0001-why-bloc.md) | 为什么选 BLoC |
| [0002](./ADR/0002-why-clean-arch.md) | 为什么 Clean Arch |
| [0003](./ADR/0003-why-no-sentry.md) | 为什么暂不接 Sentry |
| [0004](./ADR/0004-why-multi-cubit.md) | 为什么多 Bloc/Cubit |
| [0005](./ADR/0005-why-feature-facade.md) | 为什么 feature-first + 门面 |
| [0006](./ADR/0006-why-hive-ce.md) | 为什么 hive_ce |
| [0007](./ADR/0007-why-go-router.md) | 为什么 go_router |
| [0008](./ADR/0008-why-very-good-analysis.md) | 为什么 very_good_analysis |
| [0009](./ADR/0009-ai-behavior.md) | AI 行为规范 |
| [0010](./ADR/0010-agpl-license.md) | 为什么选 AGPL-3.0 |

---

*最后更新: 2026-07-01*
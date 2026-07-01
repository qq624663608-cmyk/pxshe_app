# CHANGELOG

> **本文件是 pxshe_app 版本历史 SSOT。**
> 每次发版必更新。

pxshe_app 版本历史。

## [Unreleased]

### 计划

- registration module (阶段 1.5)
- Bootstrap 4 阶段启动改造 (阶段 1.7)
- Logout use case (阶段 1.8)
- ApiClient (阶段 1.9)
- AppColors / ErrorHandler (阶段 1.10)
- OpenIM 集成 (阶段 2)
- universe / table / row 业务 (阶段 3)

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
# ADR-0009: AI 行为规范

## 背景

pxshe_app 项目使用 AI 助手 (Claude, GPT, 等) 协作开发。AI 助手对项目不了解, 容易:
- 引入反模式 (mega Bloc, ChangeNotifier)
- 跨 module 互相 import
- 直接 setState 调 API
- 写硬编码颜色 / 间距
- 不更新文档

## 决策

**AI 助手必须遵守 [AGENTS.md §2 行为铁律](../AGENTS.md) + [AI_GUIDE.md](../AI_GUIDE.md)**。

具体约束:

### 必读文档 (改动前)

1. `AGENTS.md` (53+ 宪法, 16 章)
2. `docs/KNOWLEDGE_GRAPH.md` (30 分钟总览)
3. `docs/ARCHITECTURE.md` (Clean Arch + Modular)
4. `docs/RECIPES.md` (5 个加新 X 步骤)
5. 任务相关的 `docs/ADR/*.md` (技术选型理由)

### 必做约束

```yaml
- 不引入新依赖 (除非用户明确要求)
- 不创建新文件除非必要 (优先编辑现有)
- 不修改 docs/ 下的 SSOT 文档 (除非 doc 修复)
- 不改 lib/modules/*/data/ 里 Datasource 的"接口"层, 只改实现
- VM 改动必须配单测
- 保持 flutter analyze 0 errors
- 保持 very_good test --min-coverage 100
- 颜色用 AppColors, 不用 Colors.X
- HTTP 走 ApiClient, 不用 dio 直接调
- 错误走 ErrorHandler, 不用 widget 自己 catch
- 路由走 context.go(), 不用 Navigator.push
- 业务代码不直接 import flutter_openim_sdk
```

### 必不做

```yaml
- mega Bloc
- ChangeNotifier
- 跨 module import 内部
- StatefulWidget + setState 调 API
- widget build 写业务逻辑
- print() 代替 appLogger
- Colors.X 代替 AppColors
- Color(0xFF...) 硬编码
- Navigator.push 代替 context.go
- 业务代码直接调 SDK API
- 写新文件而不复用现有 widget
```

## 后果

### 好处
- **AI 产出符合项目规范** (符合 53+ 宪法)
- **新人 30 分钟就能 review AI 产出** (KNOWLEDGE_GRAPH)
- **改动有据可查** (ADR 记录所有技术选型)
- **CI 强制** (lint + 测试 + 覆盖率)

### 坏处
- **AI 上下文消耗大** (要读 5+ 文档)
- **首次响应慢** (AI 准备时间)
- **需要持续更新 AGENTS.md** (新技术要补)

### 风险
- **AI 误解文档** (沟通成本)
- **AI 找不到矛盾** (人需要 review)
- **AI 抄错代码** (业务逻辑错误)

## 实施细节

### 改动前 5 问

```
1. 这条改动属于哪个 module?
2. 跨 module 吗? (走门面)
3. 影响 docs/ 吗? (要同步)
4. 覆盖率会降吗? (要补测)
5. AGENTS.md 哪条相关? (要查)
```

### 沟通风格

```yaml
- 不啰嗦
- 不擅自执行 (用户问"怎么做"先给方案)
- 一次问完 (打包相关问题)
- 直接做 (用户说"做"立刻动手)
```

### 代码引用格式

永远用 `file_path:line_number`:
```
// ✅ 正确
// 改 lib/modules/auth/data/auth_repository_impl.dart:65
final token = res.data['data']['chatToken'] as String;

// ❌ 错误
// 改 auth repository 里的 token 解析
```

详见 [AI_GUIDE.md](../AI_GUIDE.md) 完整指南。

---

*状态: 已接受 | 日期: 2026-07-01*
# ADR-0010: 为什么选 AGPL-3.0 (License 决策)

## 背景

pxshe_app 使用 `flutter_openim_sdk` (AGPL-3.0), AGPL 是强 copyleft, **传染整个项目**。

候选:
- **A. 接受 AGPL-3.0** (推荐)
- B. 换非 AGPL 的 IM SDK (融云/环信/腾讯云 IM)
- C. 买 OpenIM 商业 License
- D. 自己实现 IM 协议

## 决策

**选 A. 接受 AGPL-3.0**。

依赖传染链:
```
flutter_openim_sdk (AGPL-3.0)
        ↓ 传染
本项目所有 Dart 代码 (AGPL-3.0)
        ↓ 传染
整体 = AGPL-3.0-or-later
```

## 后果

### 好处
- **零额外成本** (OpenIM 整个生态 AGPL, 接受传染)
- **跟 OpenIM 整个生态一致** (server / sdk / demo 都是 AGPL)
- **服务可以收费** (AGPL 不禁止收费, 跟 universe_app 之前做法一致)
- **简单** (不用买商业 license, 不用换 SDK)

### 坏处
- **不能闭源商业化** (AGPL Section 13)
- **不能卖给大客户做私有部署** (除非他们付钱买 OpenIM 商业 license)
- **传染** (所有派生代码都要开源)

### 风险
- **未来商业化困难** — 走 SaaS 模式而不是卖代码
- **竞争对手 copy 改一改卖** — AGPL 强制他们也开源, 但中国执行不严

## 替代方案

### B. 换非 AGPL 的 IM SDK (不选)
- 优势: 自由商业
- 不选: 工作量大 (2-3 周重写所有 IM 代码), 风险高 (新 SDK 可能有问题)

### C. 买 OpenIM 商业 License (不选, 短期)
- 优势: 闭源商业
- 不选: 几千到几万/年, 商业模式未明, MVP 阶段不投

### D. 自己实现 IM 协议 (不选)
- 优势: 不依赖任何 SDK
- 不选: 工作量大 (3-4 周), 不稳定, 不值

## 实施细节

### 项目 License 配置

```yaml
# pubspec.yaml
license: AGPL-3.0-or-later
```

```markdown
<!-- LICENSE -->
GNU AFFERO GENERAL PUBLIC LICENSE
Version 3, 19 November 2007
...
```

### AGPL 合规场景

| 场景 | 合规? |
|---|---|
| 内部使用 (公司/团队) | ✅ |
| 小规模 SaaS (给少量付费用户提供服务) | ✅ |
| 服务收费 (订阅/月费) | ✅ |
| 开源项目 | ✅ |
| 大规模闭源商业化 | ❌ (走路径 A/B/C) |

### 商业化路径 (未来)

如果未来要大规模闭源商业化:
1. 联系 OpenIM 团队买商业 License (路径 C)
2. 换 IM SDK (路径 B)
3. 自己实现 (路径 D, 不推荐)

### 依赖 License 检查

CI 强制:
```bash
very_good packages check licenses --forbidden="SSPL,BSL,unknown"
```

禁止引入:
- SSPL (Server Side Public License)
- BSL (Business Source License)
- 商业专有 (不兼容 AGPL)
- 未知 license

详见 [LICENSE_INFO.md](../LICENSE_INFO.md) 完整说明 + 商业化路径。

---

*状态: 已接受 | 日期: 2026-07-01*
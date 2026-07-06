# docs/LICENSE_INFO.md — AGPL-3.0 兼容性说明

> **本文件是 License 兼容性 SSOT。**
> 任何依赖变更, 同步这里。

---

## 1. 项目 License

**AGPL-3.0-or-later** (`pubspec.yaml` + `LICENSE`)

理由 (详见 [ADR-0010](./ADR/0010-agpl-license.md)):
- `flutter_openim_sdk` 是 AGPL-3.0
- AGPL 强 copyleft 传染整个项目
- 接受传染 = 整个项目按 AGPL 开源
- pxshe_app 是内部用 + 小规模 SaaS, AGPL 合规

---

## 2. 直接依赖 License 矩阵

| 包 | License | 兼容 AGPL-3.0 |
|---|---|---|
| `bloc` | MIT | ✅ |
| `flutter_bloc` | MIT | ✅ |
| `equatable` | Apache-2.0 | ✅ |
| `get_it` | MIT | ✅ |
| `dio` | MIT | ✅ |
| `hive_ce` | Apache-2.0 | ✅ |
| `hive_ce_flutter` | Apache-2.0 | ✅ |
| `go_router` | BSD-3-Clause | ✅ |
| `dartz` | BSD-3-Clause | ✅ |
| `rxdart` | Apache-2.0 | ✅ |
| `flutter_form_builder` | MIT | ✅ |
| `form_builder_validators` | MIT | ✅ |
| `loader_overlay` | MIT | ✅ |
| `toastification` | MIT | ✅ |
| `url_launcher` | BSD-3-Clause | ✅ |
| `flex_color_scheme` | BSD-3-Clause | ✅ |
| `infinite_scroll_pagination` | MIT | ✅ |
| `flutter_markdown` | BSD-3-Clause (discontinued) | ✅ |
| `flutter_openim_sdk` | **AGPL-3.0** | ✅ (传染源) |
| `logger` | MIT | ✅ |
| `responsive_framework` | MIT | ✅ |
| `universal_html` | MIT | ✅ |

### 开发依赖

| 包 | License | 兼容 AGPL-3.0 |
|---|---|---|
| `bloc_lint` | MIT | ✅ |
| `bloc_test` | MIT | ✅ |
| `bloc_tools` | MIT | ✅ |
| `mocktail` | MIT | ✅ |
| `very_good_analysis` | MIT | ✅ |

---

## 3. 商业化路径 (3 条)

### 路径 A: 联系 OpenIM 买商业 License (推荐)

- 联系 OpenIM 团队 (https://www.openim.io/)
- 价格: 几千到几万/年 (具体谈)
- 获得: OpenIM SDK 商业 License + 你的项目可以闭源商业化
- 适合: 大规模闭源商业化

### 路径 B: 换非 AGPL 的 IM SDK (中等成本)

| SDK | License | 价格 |
|---|---|---|
| 融云 (RongCloud) | 商业 License | 免费档够用, 商业收费 |
| 环信 (EaseMob) | 商业 License | 同上 |
| 腾讯云 IM | 商业 License | 按 DAU 收费 |
| 阿里云 IMS | 商业 License | 按 DAU 收费 |
| Firebase | 商业 License + 免费档 | 免费档够小项目 |

**优点**: 你的 Flutter 项目可以用 MIT/Apache-2.0, 自由商业。
**缺点**: SDK API 跟 OpenIM 完全不同, **全部 IM 代码重写** (2-3 周)。

### 路径 C: 自己实现 IM 协议 (不推荐)

- 写 WebSocket + openim-api 协议封装
- 跳过 SDK
**优点**: 不依赖任何 IM SDK
**缺点**: 工作量大 (3-4 周), 不稳定, 不值

---

## 4. 接受 AGPL 的合规场景

AGPL-3.0 不禁止收费, 允许以下场景:

| 场景 | 合规? |
|---|---|
| 内部使用 (公司/团队) | ✅ |
| 小规模 SaaS (给少量付费用户提供服务) | ✅ |
| 服务收费 (订阅/部署/支持) | ✅ |
| 开源项目 | ✅ |
| 大规模闭源商业化 (卖给大客户) | ❌ (要走路径 A/B/C) |

---

## 5. AGPL 传染性说明

AGPL-3.0 Section 13 (网络服务条款):

> 如果你修改 AGPL 程序并在服务器上运行通过网络向用户提供服务, 你必须向所有用户公开你修改后的源代码。

**传染链**:
```
flutter_openim_sdk (AGPL-3.0)
        ↓ 传染
本项目所有 Dart 代码 (AGPL-3.0)
        ↓ 传染
整体 = AGPL-3.0-or-later
```

**不传染的**:
- ❌ 业务逻辑 (我们的 universe/table/row 代码)
- ❌ 文档 (docs/)
- ❌ 设计 (UI/UX)

**传染的**:
- ✅ 整个 Flutter app (含业务逻辑)
- ✅ 后端 (如果用 AGPL SDK)

---

## 6. 依赖 License 检查

CI 强制:
```bash
very_good packages check licenses --forbidden="SSPL,BSL,unknown"
```

禁止引入:
- SSPL (Server Side Public License)
- BSL (Business Source License)
- 商业专有 (不兼容 AGPL)
- 未知 license

---

## 7. 加新依赖流程

```bash
□ 1. 检查 License (不能是 SSPL/BSL/商业专有)
□ 2. 优先选 Apache-2.0 / MIT / BSD
□ 3. flutter pub add <package>
□ 4. very_good packages check licenses --forbidden="SSPL,BSL,unknown"
□ 5. very_good test --coverage --min-coverage 100
□ 6. flutter analyze
□ 7. 同步更新本文档 §2 表格
```

---

*最后更新: 2026-07-01*
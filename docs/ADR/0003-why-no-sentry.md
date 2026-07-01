# ADR-0003: 为什么暂不接 Sentry / 监控

## 背景

生产级 Flutter app 通常要接:
- 远程崩溃监控 (Sentry / Firebase Crashlytics)
- 用户行为埋点 (Firebase Analytics / 友盟)
- 性能监控 (Firebase Performance / 自建)

候选:
- **A. 暂不接** (推荐, 阶段 1)
- B. 立即接 Sentry
- C. 立即接 Firebase Crashlytics

## 决策

**阶段 1 暂不接任何监控**, 阶段 5 评估。

理由:

1. **业务优先** — MVP 阶段先跑通, 监控是优化阶段的事
2. **AGPL 兼容性** — Sentry / Crashlytics 不是 AGPL, 但要配 License, 阶段 5 评估
3. **资源消耗** — Crashlytics 增加 APK 体积, 启动时间 +200ms
4. **隐私** — 埋点要遵守 GDPR, 阶段 1 简单 SaaS 内部用, 不需要
5. **本地日志够用** — `appLogger` 写本地 logcat / console, 调试时看

## 后果

### 好处
- MVP 快速跑起来
- 不依赖第三方
- APK 体积小
- 启动快

### 坏处
- 线上崩溃无法远程监控
- 性能问题无法远程定位
- 用户行为数据缺失

### 风险
- 阶段 5 评估时, 选 Sentry 还是 Crashlytics 又是新决策
- 老用户从无监控迁到有监控, 数据断层

## 替代方案

### B. 立即接 Sentry (不选)
- 优势: 远程崩溃 + 性能 + 行为
- 不选: AGPL 兼容性要评估, MVP 阶段太重

### C. 立即接 Firebase Crashlytics (不选)
- 优势: 免费 + Android 集成成熟
- 不选: 同样 AGPL 兼容性, 阶段 1 太重

## 实施细节

### 阶段 1: 不接

`pubspec.yaml` **不**包含:
- ❌ `sentry_flutter`
- ❌ `firebase_crashlytics`
- ❌ `firebase_analytics`

`lib/_core/env.dart` 默认所有监控开关 false:
```dart
static const bool enableCrashlytics = false;
static const bool enableAnalytics = false;
static const bool enablePerformance = false;
```

### 阶段 5: 评估

候选:
- Sentry (商业 License, $26/月起)
- Firebase Crashlytics (免费)
- 自建 (ELK + 自家 SDK)

**评估维度**:
- 跟 AGPL 的兼容性
- 价格
- Android / iOS 集成成熟度
- 数据隐私 (GDPR)

详见 [CONFIGURATION.md §3](../CONFIGURATION.md) 监控开关。

---

*状态: 已接受 (阶段 1) | 日期: 2026-07-01*
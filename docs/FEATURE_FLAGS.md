# docs/FEATURE_FLAGS.md — Feature Flag SSOT

> **本文件是 Feature Flag 列表的 SSOT。**
> 改 FlagKeys → 同步这里。

---

## 1. Flag 列表

| Flag | 类型 | 默认 | 用途 |
|---|---|---|---|
| `enable_biometric` | bool | `false` | 生物识别登录 (阶段 4) |
| `enable_push_notification` | bool | `true` | 推送通知开关 |
| `enable_avatar_upload` | bool | `true` | 头像上传开关 |
| `max_upload_size_mb` | int | `10` | 上传文件最大 MB |
| `homepage_layout` | string | `grid` | 首页布局: `grid` / `list` / `card` |
| `enable_super_code` | bool | `true` | 测试模式验证码 `666666` |

详见 `lib/_core/feature_flags/feature_flag_service.dart` 的 `FlagKeys` 类。

---

## 2. 启用 / 关闭流程

```
1. 改 FlagKeys 类 (默认值)
2. 改 docs/FEATURE_FLAGS.md (本表)
3. 改 Firebase Console / 远程配置 (阶段 5)
4. PR + 1 个 reviewer
5. 灰度 → 全量
```

---

## 3. 灰度发布 (3 步)

```dart
// 1. 选 FlagKeys + 设 percent
FeatureFlagService.isInRollout(
  FlagKeys.newFeaturePercent,
  percent: 10,  // 10% 用户
)

// 2. 代码侧: 用 isInRollout() 而非 getBool()
// ❌ 错
if (FeatureFlagService.getBool(FlagKeys.newFeature)) { ... }
// ✅ 对
if (FeatureFlagService.isInRollout(FlagKeys.newFeaturePercent, percent: 10)) { ... }

// 3. 远程配置设 new_feature_percent = 10 → 25 → 50 → 100
```

---

## 4. A/B 测试

| Flag | A 版本 | B 版本 |
|---|---|---|
| `homepage_layout` | `grid` (原) | `list` / `card` |

**分析指标**: Firebase Analytics 里的 `page_view` 事件 + `homepage_layout` 用户属性 → 看哪种布局转化率高。

---

*最后更新: 2026-07-01*
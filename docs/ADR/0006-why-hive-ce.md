# ADR-0006: 为什么 hive_ce (不是标准 hive)

## 背景

pxshe_app 需要本地存储:
- chatToken / imToken (字符串)
- User 对象 (含嵌套字段)
- ThemeMode / settings (key-value)
- IM 缓存 (SDK 内部)

候选:
- **A. hive_ce (社区版, Isar 团队维护)** (推荐)
- B. 标准 hive (官方, deprecated)
- C. shared_preferences (只适合 KV)
- D. sqflite (关系型, 过重)

## 决策

**用 hive_ce + hive_ce_flutter**。

依赖:
```yaml
dependencies:
  hive_ce: ^2.19.3
  hive_ce_flutter: ^2.3.4
```

## 后果

### 好处
- **API 跟标准 hive 几乎一致** (迁移成本低)
- **维护活跃** (Isar 团队, 同 v2.x 同步)
- **支持 HiveAdapter** (TypeAdapter 自定义序列化)
- **跟 OpenIM SDK 兼容** (SDK 也用 Hive)

### 坏处
- **不是 Flutter 官方维护** (hive_ce 是社区 fork)
- **某些第三方包没适配** (但 pxshe_app 用法简单, 不依赖)
- **文档少** (大部分还是标准 hive 的文档)

### 风险
- **如果 hive_ce 停止维护** — 回到标准 hive, API 兼容
- **flutter_openim_sdk 内部用 hive** — 跨版本兼容要测

## 替代方案

### B. 标准 hive (不选)
- 已被 [作者标记 deprecated](https://pub.dev/packages/hive)
- 维护停滞, bug 不修

### C. shared_preferences (不选)
- 只适合简单 KV, 不支持自定义对象
- User / Token 序列化麻烦

### D. sqflite (不选)
- 关系型数据库, 杀鸡用牛刀
- 复杂业务才需要

## 实施细节

### 反序列化 (硬约束, AGENTS §35)

```dart
// ✅ 正确
final raw = box.get('user');
if (raw is Map) {
  final user = Map<String, dynamic>.from(raw);
}

// ❌ 错误 (冷启动 BUG)
final user = box.get('user') as Map<String, dynamic>;
```

**理由**: 冷启动时 `openimConfig` 可能为 null, 严格断言失败 → IM 不自动重连。

### Hive TypeAdapter 示例

```dart
// lib/modules/auth/data/models/user_model.dart
class UserModel extends User {
  const UserModel({required super.id, ...});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userID'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      areaCode: json['areaCode'] as String? ?? '',
    );
  }
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  int get typeId => 1;
  // ... read / write
}
```

### Hive Box 设计

```dart
// lib/_core/database.dart
class Database {
  static const _tokenBox = 'auth_token_box';     // String (chatToken / imToken)
  static const _userBox = 'user_box';             // UserModel
  static const _settingsBox = 'settings_box';     // ThemeMode 等
}
```

详见 [CACHE_STRATEGY.md](../CACHE_STRATEGY.md) §3。

---

*状态: 已接受 | 日期: 2026-07-01*
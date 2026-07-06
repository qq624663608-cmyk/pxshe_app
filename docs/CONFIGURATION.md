# docs/CONFIGURATION.md — 配置 SSOT

> **本文件是项目配置 (环境变量、监控开关) 的 SSOT。**
> 改 `lib/_core/env.dart` → 同步这里。

---

## 1. 环境变量 (硬编码到 env.dart)

`lib/_core/env.dart`:

```dart
class Env {
  // 业务 API
  static const String apiBaseUrl = 'https://chat.pxshe.com';

  // OpenIM (反代: 443 → openim-server:10002, 不带端口)
  static const String openimApiUrl = 'wss://api.pxshe.com';
  static const String openimApiAddr = 'https://api.pxshe.com';

  // Flavor (dev/staging/production)
  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');

  // Feature flags
  static const bool enableSuperCode = bool.fromEnvironment('ENABLE_SUPER_CODE', defaultValue: true);

  // 日志
  static const String logLevel = String.fromEnvironment('LOG_LEVEL', defaultValue: 'debug');
}
```

### 启动命令 (传 dart-define)

```bash
flutter run --flavor=development \
  --dart-define=FLAVOR=development \
  --dart-define=LOG_LEVEL=debug \
  lib/main_development.dart

flutter run --flavor=production \
  --dart-define=FLAVOR=production \
  --dart-define=LOG_LEVEL=warn \
  --dart-define=ENABLE_SUPER_CODE=false \
  lib/main_production.dart
```

---

## 2. 3 Flavors

| Flavor | App ID | app name | baseUrl |
|---|---|---|---|
| `production` | `com.pxshe.app` | "Pxshe App" | https://chat.pxshe.com |
| `staging` | `com.pxshe.app.stg` | "[STG] Pxshe App" | https://chat.pxshe.com |
| `development` | `com.pxshe.app.dev` | "[DEV] Pxshe App" | https://chat.pxshe.com |

入口文件:
- `lib/main_production.dart`
- `lib/main_staging.dart`
- `lib/main_development.dart`

### Android 配置 (`android/app/build.gradle.kts`)

```kotlin
flavorDimensions += "default"
productFlavors {
    create("production") {
        applicationIdSuffix = ""
        manifestPlaceholders["appName"] = "Pxshe App"
    }
    create("staging") {
        applicationIdSuffix = ".stg"
        manifestPlaceholders["appName"] = "[STG] Pxshe App"
    }
    create("development") {
        applicationIdSuffix = ".dev"
        manifestPlaceholders["appName"] = "[DEV] Pxshe App"
    }
}
```

---

## 3. 监控开关 (5 个, 阶段 5 启用)

```
Crashlytics (远程崩溃):
  ENABLE_CRASHLYTICS=false (开发) → true (生产)

Analytics (用户埋点):
  ENABLE_ANALYTICS=false (开发) → true (生产)

Performance (性能):
  ENABLE_PERFORMANCE=false (开发) → true (生产)

Feature Flags (A/B 测试):
  ENABLE_FEATURE_FLAGS=false (开发) → true (生产)
```

阶段 5 之前,所有监控开关默认 false, 不接 Firebase。

---

## 4. 密钥管理 (3 类)

### API 密钥
- 不用 .env (后端 API 用 JWT 鉴权, JWT 存 Hive CE)
- 不用 .env (业务配置放 env.dart 硬编码)

### 签名密钥
- Android keystore: `android/upload-keystore.jks` (在 .gitignore)
- 配置: `android/key.properties` (在 .gitignore)
- 模板: `android/key.properties.example` (已提供)

### CI 密钥
- GitHub Actions secrets (在 repo Settings → Secrets)
- 不用 .env

---

## 5. .gitignore (关键项)

```gitignore
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
coverage/

# Android
android/upload-keystore.jks
android/key.properties
android/.gradle/
android/.idea/
android/.kotlin/
android/local.properties

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Generated.xcconfig
ios/Runner/GoogleService-Info.plist

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Env
.env
.env.local
```

---

## 6. 调试技巧

### 真机调试

```bash
# 列出设备
flutter devices

# 指定设备 + flavor
flutter run -d <device_id> --flavor=development lib/main_development.dart
```

### 切换 baseUrl (调试不同环境)

修改 `lib/_core/env.dart` 的 `apiBaseUrl`, 不需要改其他文件。

### 看日志

```bash
flutter logs
# 或在 IDE 的 Debug Console
```

### 强制覆盖 env (临时)

```bash
flutter run --flavor=development \
  --dart-define=apiBaseUrl=https://test.chat.pxshe.com \
  lib/main_development.dart
```

(需要在 env.dart 改成 `String.fromEnvironment` 形式)

---

*最后更新: 2026-07-01*
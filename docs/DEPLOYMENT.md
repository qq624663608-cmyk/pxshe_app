# docs/DEPLOYMENT.md — Release + CI + Flavors

> **本文件是发布 SSOT。**
> 怎么 build / 怎么发 / 怎么 CI。

---

## 1. 多 Flavors

```
dev           →  https://chat.pxshe.com  (测试)
staging       →  https://chat.pxshe.com  (内部测试)
production    →  https://chat.pxshe.com  (生产)
```

### pubspec.yaml

```yaml
name: pxshe_app
description: "pxshe IM 客户端 + 宇宙业务"
publish_to: "none"
version: 1.0.0+1
license: AGPL-3.0-or-later
```

### 启动命令

```bash
flutter run --flavor=development lib/main_development.dart
flutter run --flavor=staging lib/main_staging.dart
flutter run --flavor=production lib/main_production.dart
```

### Build

```bash
flutter build apk --release --flavor=production
flutter build ipa --release --flavor=production
```

---

## 2. CI 流水线 (8 job)

`.github/workflows/ci.yml`:

```yaml
name: CI
on: [push, pull_request]

jobs:
  format-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart format --set-exit-if-changed lib test

  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze

  license-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: very_good packages check licenses --forbidden="SSPL,BSL,unknown"

  unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: very_good test --coverage --min-coverage 100

  integration-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test integration_test/

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release --flavor=staging
      - run: flutter build ipa --release --no-codesign --flavor=staging
```

---

## 3. Release 流程

```
1. develop 累积 1 周
2. git checkout -b release/v1.x.x
3. 自动递增版本 (sed 改 pubspec.yaml)
4. CHANGELOG.md 自动生成 (conventional-changelog)
5. 跑全部 CI (8 job)
6. 合并到 main
7. 打 tag: git tag v1.x.x
8. 触发 release workflow:
   - Android: fastlane android + 应用市场
   - iOS: fastlane ios + TestFlight
9. 灰度 5% → 20% → 50% → 100% (3 天)
10. 监控崩溃 / 性能
```

### 自动版本递增

```bash
# .github/workflows/release.yml
- name: Bump version
  run: |
    CURRENT=$(grep '^version:' pubspec.yaml | sed 's/version: //')
    MAJOR_MINOR_PATCH=$(echo $CURRENT | cut -d'+' -f1)
    BUILD=$(echo $CURRENT | cut -d'+' -f2)
    NEW_BUILD=$((BUILD + 1))
    sed -i "s/version: $MAJOR_MINOR_PATCH+$BUILD/version: $MAJOR_MINOR_PATCH+$NEW_BUILD/" pubspec.yaml
    git commit -am "chore(release): bump to $MAJOR_MINOR_PATCH+$NEW_BUILD"
```

---

## 4. Android Release 关键配置

`android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 35
    defaultConfig {
        minSdk = 24
        targetSdk = 35
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
        multiDexEnabled = true
    }
    buildTypes {
        release {
            isMinifyEnabled = false        // 防 R8 误删 OpenIM SDK
            isShrinkResources = false
        }
    }
}
```

详见 [docs/platform-config.md](./platform-config.md)。

---

## 5. iOS Release 关键配置

`ios/Runner/Info.plist`:

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
  <string>UIInterfaceOrientationPortrait</string>
</array>
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>
```

---

## 6. 体积优化

```bash
# 分析 APK 体积
flutter build apk --release --analyze-size

# 拆 ABI (更小)
flutter build apk --release --split-per-abi

# 混淆
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

---

*最后更新: 2026-07-01*
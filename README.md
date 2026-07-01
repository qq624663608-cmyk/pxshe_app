# pxshe_app

pxshe 移动端 (Flutter) — IM 客户端 + 宇宙业务后台

## 技术栈

- Flutter 3.44.1 / Dart 3.12+
- BLoC 9.x (状态管理)
- Clean Architecture + Modular Design
- get_it 9.x (DI)
- GoRouter 17.x (路由)
- Hive CE (本地存储)
- Dio 5.x (HTTP)
- openim-sdk-flutter 3.8.3 (IM SDK)
- **AGPL-3.0-or-later** (整体开源)

## 三域架构

| 域 | 端口 | 用途 | Flutter 端调用 |
|---|---|---|---|
| `api.pxshe.com` | 10002 | openim-server | SDK 内部 (禁直连) |
| `chat.pxshe.com` | 10008 | chat-api | HTTP `/account/*` + `/business/*` |
| `admin.pxshe.com` | 10009 | admin-api | ❌ 不调用 (超管用) |

## 快速开始

### 环境要求

- Flutter 3.44.1+
- Dart 3.12+
- Android Studio / VS Code
- Java 17 (Android 构建)

### 安装

```bash
git clone https://github.com/your-org/pxshe_app.git
cd pxshe_app
flutter pub get
```

### 启动 (Android 模拟器)

```bash
flutter run -d emulator-5554
```

### 测试

```bash
very_good test --coverage --min-coverage 100
```

## 项目结构

```
pxshe_app/
├── lib/
│   ├── _core/              全局基础设施 (Bootstrap / DI / ApiClient / Database)
│   ├── _shared/            跨模块复用 (Theme / Navigation / Error pages)
│   ├── modules/
│   │   ├── auth/           登录 (phone + password)
│   │   ├── registration/   注册 (3 种方式 + GDPR 隐私协议)
│   │   ├── im/             IM 客户端 (阶段 2)
│   │   ├── universe/       业务 (阶段 3)
│   │   ├── table/          业务 (阶段 3)
│   │   └── row/            业务 (阶段 3)
│   ├── app.dart
│   └── main.dart
├── docs/                   项目文档 (架构 / 后端 / IM / 规范 / 依赖)
├── analysis_options.yaml   very_good_analysis + bloc_lint
└── LICENSE                 AGPL-3.0
```

## 文档导航

- [AGENTS.md](./AGENTS.md) — AI 协作规则 / 核心约束
- [docs/architecture.md](./docs/architecture.md) — 架构说明
- [docs/getting-started.md](./docs/getting-started.md) — 第一次跑通
- [docs/backend-integration.md](./docs/backend-integration.md) — 后端对接
- [docs/im-integration.md](./docs/im-integration.md) — OpenIM 集成
- [docs/conventions.md](./docs/conventions.md) — 命名 / Commit 规范
- [docs/dependencies.md](./docs/dependencies.md) — 依赖选型 + License

## License

**AGPL-3.0-or-later**

注意: `flutter_openim_sdk` 是 AGPL-3.0, 因此本项目整体按 AGPL-3.0 开源。
详见 [docs/dependencies.md](./docs/dependencies.md) 的 License 兼容性分析。

如果不想传染 AGPL, 商业化路径参见 [AGENTS.md §4](./AGENTS.md)。
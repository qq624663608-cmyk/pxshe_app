# docs/KNOWLEDGE_GRAPH.md — 项目知识图谱

> **新人入职第一篇。30 分钟读完, 1 个 doc 看清整个项目。**
> 本文件是总览 SSOT, 所有其他 docs 是展开。

---

## 1. 项目一句话

```
pxshe_app = Flutter IM 客户端 + 宇宙业务后台
- 平台: Android + iOS (web 暂不)
- 架构: Clean Architecture + Modular + BLoC 9.x
- 后端: chat.pxshe.com (chat-api) + api.pxshe.com (openim-server)
- License: AGPL-3.0-or-later
- 仓库: F:\wx\pxshe_app
- 启动: cd F:\wx\pxshe_app && flutter run --flavor=development
```

---

## 2. 架构分层图 (Clean Arch)

```
┌─────────────────────────────────────────────────────────┐
│ lib/                入口 (main_*.dart + bootstrap)         │
├─────────────────────────────────────────────────────────┤
│ modules/           业务层 (6 个 module,阶段 2 完成 im)    │
│  - auth/            登录 / 登出 / Token 缓存             │
│  - registration/    注册 (3 种方式 + GDPR 隐私协议)     │
│  - im/              ✅ OpenIM 集成 (阶段 2 完成)        │
│    * data/datasources/openim_sdk_wrapper.dart          │
│    * data/repositories/{im_auth,conversation,message,  │
│      friend,group}_repository_impl.dart               │
│    * domain/{im_auth,conversation,message,            │
│      friend,group}_repository.dart                    │
│    * bloc/{connection,conversation,message,           │
│      friend,group}_cubit.dart                         │
│    * features/{chat_list,chat_page,contacts,           │
│      profile,placeholder}/                            │
│    * auth_module_bridge.dart (跨 module 拿 imToken)   │
│    * im_module.dart (DI 注册 + bootstrap 钩子)        │
│    * im_routes.dart (GoRouter 集成)                   │
│  - universe/        宇宙模块 (世界/子表/行) (阶段 3)   │
│  - table/           子表管理 (阶段 3)                  │
│  - row/             数据行编辑 (动态 JSON) (阶段 3)    │
├─────────────────────────────────────────────────────────┤
│ _core/             基建层 (无业务依赖)                   │
│  - _bootstrap.dart  4 阶段启动                          │
│  - _init_modules.dart module 注册中心                  │
│  - app_router.dart  GoRouter + 路由守卫                │
│  - di.dart          get_it 容器                         │
│  - database.dart    Hive CE 初始化                      │
│  - http_client.dart 老 HttpClient (阶段 2 后基本不用)  │
│  - network/         ApiClient (Dio + 拦截器 + ✅ 注册) │
│  - env.dart         Env 三域配置 ✅                    │
│  - error/           ErrorHandler + 7 段 28 个错误码  │
│  - theme/           AppColors/Spacing/Radius/Durations  │
│  - network_info.dart 网络检测                          │
│  - logger.dart      日志                                │
├─────────────────────────────────────────────────────────┤
│ _shared/           跨 module 共享 UI                     │
│  - shared_module.dart  ThemeModeCubit 注册              │
│  - shared_routes.dart  公共路由 (Splash/Home/Settings) │
│  - blocs/           全局 Cubit                          │
│  - features/        公共页面 (Splash/Home/Settings)    │
│  - widgets/         通用 widget                        │
│  - domain/          CQRS 基础类                         │
└─────────────────────────────────────────────────────────┘

依赖方向 (只能向下, 不能反向):
  modules -> _core / _shared
  _shared -> _core
  _core -> 0 依赖 modules
  modules 之间 ✗ (走 <module>_module.dart 门面)
```

---

## 3. 启动流图 (4 阶段)

```
main_development.dart (flavor 入口)
  |- WidgetsFlutterBinding.ensureInitialized()
  |- await bootstrap(() => const App())
       |
       v
bootstrap.dart (very_good)
  |
  v
Bootstrap.init() (lib/_core/_bootstrap.dart)
  |- Log.init
  |- HttpClient.init()                     # Dio 拦截器
  |- Database.init()                       # Hive CE box 打开
  |- RegistrationConfigService.init()     # 拉 /business/public/registration/config/get
  |- AppModules.initBeforeRunApp()         # 注册所有 module (auth, registration, ...)
  `- AppRouter 注册
       |
       v
runApp(const App())
  |
  v
App (lib/app/app.dart)
  |- MultiBlocProvider (AuthBloc + ThemeModeCubit)
  |- MaterialApp.router (routerConfig: di<AppRouter>().router)
  |
  v
LoadingPage (lib/_shared/features/splash/...)
  |- 3 秒定时器 (强制跳路由保护)
  |- BlocBuilder<AuthBloc>
       |- status=unknown → 显示 loading
       |- status=authenticated → 跳 HomePage
       `- status=unauthenticated → 跳 LoginPage
```

---

## 4. 完整目录树 (200+ 文件, 每行 1 文件说明)

```
F:\wx\pxshe_app\
|-- pubspec.yaml                       23+ 依赖 (ADR-0001 ~ 0010)
|-- analysis_options.yaml              very_good_analysis + bloc_lint 严 lint
|-- AGENTS.md                          53+ 宪法 + 设计初心 (永不退让)
|-- README.md                          入口
|-- LICENSE                            AGPL-3.0-or-later
|
|-- .github/
|   `-- workflows/ci.yml               CI 流水线 (8 job)
|
|-- docs/                              18+ SSOT 文档
|   |-- README.md                      入口 + 4 层读法
|   |-- KNOWLEDGE_GRAPH.md             ★ 本文 (总览)
|   |-- ARCHITECTURE.md                Clean + BLoC + Modular
|   |-- ERROR_HANDLING.md              7 段错误码 (1xxx/1.5xxx/2xxx-6xxx, 28 个 ErrorKey)
|   |-- TESTING.md                     4 层级测试 (L1-L4)
|   |-- DEPLOYMENT.md                  Release + CI + Flavors
|   |-- CONTRIBUTING.md                PR / commit / 分支 / 命名
|   |-- CACHE_STRATEGY.md              缓存设计 (Hive CE)
|   |-- BUILDING_BLOCKS.md             通用 widget + 23 硬规则
|   |-- RECIPES.md                     5 个"加新 X"步骤
|   |-- API.md                         三域架构 + 全部端点
|   |-- CONFIGURATION.md               env.dart + 监控开关
|   |-- REFERENCE.md                   官方资源 + 必备/禁止包
|   |-- PAGE_CLASSIFICATION.md         页面 × module 矩阵
|   |-- AI_GUIDE.md                    AI 助手指导 (防遗忘)
|   |-- IM_INTEGRATION.md              OpenIM SDK 集成 (新增)
|   |-- LICENSE_INFO.md                AGPL-3.0 兼容性 (新增)
|   |-- CHANGELOG.md                   auto-generated
|   `-- ADR/                           10 个决策记录
|
|-- lib/
|   |-- main_*.dart                    3 个 flavor 入口
|   |-- bootstrap.dart                 very_good 4 阶段启动
|   |-- app/                           聚合层
|   |   `-- app.dart                   MaterialApp.router 入口
|   |-- _core/                         基建层
|   |   |-- _bootstrap.dart            启动流程
|   |   |-- _init_modules.dart         module 注册
|   |   |-- app_router.dart            GoRouter
|   |   |-- di.dart                    get_it
|   |   |-- database.dart              Hive CE
|   |   |-- http_client.dart           ApiClient
|   |   |-- env.dart                   配置
|   |   |-- theme.dart                 主题
|   |   `-- error/                     错误处理
|   |-- _shared/                       共享
|   |   |-- shared_module.dart         ThemeModeCubit
|   |   |-- shared_routes.dart         公共路由
|   |   |-- blocs/                     全局 Cubit
|   |   `-- features/                  公共页面
|   `-- modules/                       业务层 (6 个 module)
|       |-- auth/                      登录
|       |-- registration/              注册
|       |-- im/                        OpenIM
|       |-- universe/                  业务
|       |-- table/                     业务
|       `-- row/                       业务
|
|-- test/                              单元 + widget test
|-- android/                           Android 平台
|-- ios/                               iOS 平台
`-- assets/                            资源 (图片 / 字体)
```

---

## 5. 找 X 看哪里 (快速导航)

| 我想... | 看哪里 |
|---|---|
| 了解项目架构 | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| 了解错误处理 | [ERROR_HANDLING.md](./ERROR_HANDLING.md) |
| 了解测试策略 | [TESTING.md](./TESTING.md) |
| 加新 widget | [BUILDING_BLOCKS.md](./BUILDING_BLOCKS.md) + [RECIPES.md §1](./RECIPES.md) |
| 加新 module | [RECIPES.md §2](./RECIPES.md) |
| 加新 API 端点 | [RECIPES.md §3](./RECIPES.md) + [API.md](./API.md) |
| 加新错误码 | [RECIPES.md §4](./RECIPES.md) + [ERROR_HANDLING.md](./ERROR_HANDLING.md) |
| 了解 OpenIM 集成 | [IM_INTEGRATION.md](./IM_INTEGRATION.md) |
| 了解 License 兼容性 | [LICENSE_INFO.md](./LICENSE_INFO.md) |
| 了解部署流程 | [DEPLOYMENT.md](./DEPLOYMENT.md) |
| 了解缓存设计 | [CACHE_STRATEGY.md](./CACHE_STRATEGY.md) |
| 了解设计 Token | [BUILDING_BLOCKS.md §1](./BUILDING_BLOCKS.md) |
| 了解技术选型理由 | [ADR/](./ADR/) 目录 |
| 了解贡献流程 | [CONTRIBUTING.md](./CONTRIBUTING.md) |
| 了解环境配置 | [CONFIGURATION.md](./CONFIGURATION.md) |

---

## 6. 关键概念速查

### 三域架构 (硬约束)

| 域 | 客户端地址 | 后端端口 (反代后) | 用途 | Flutter 端 |
|---|---|---|---|---|
| `api.pxshe.com` | `https://api.pxshe.com` | 10002 | openim-server | SDK 内部 (禁直连) |
| `chat.pxshe.com` | `https://chat.pxshe.com` | 10008 | chat-api | ✅ HTTP 业务调用 |
| `admin.pxshe.com` | `https://admin.pxshe.com` | 10009 | admin-api | ❌ 不调用 |

### Token 体系

| Token | 来源 | 用途 | 存储 |
|---|---|---|---|
| `chatToken` | /account/login 响应 | 业务 HTTP `token` header | Hive CE |
| `imToken` | /account/login 响应 | OpenIM SDK 登录 | Hive CE |
| `userID` | /account/login 响应 | 用户唯一标识 | Hive CE |

### 错误码体系 (7 段,28 个 ErrorKey)

与后端 `F:\wx\pxshe_app\docs/ERROR_CODES.md` 一一对应。

| 段位 | 含义 | HTTP | 客户端动作 | 数量 |
|---|---|---|---|---|
| 1xxx | 通用/参数 (ArgsError / NoPermission / DuplicateKey / RecordNotFound) | 400 | SnackBar | 4 |
| 1.5xxx | Token 错误 (OpenIM 标准 7 个) | 401 | 跳登录 + 清 Token | 7 |
| 2xxx | 注册/登录/账号 (密码/账号/验证/邀请) | 400/409 | SnackBar | 12 |
| 3xxx | 资源/文件 | 400 | SnackBar | 3 |
| 4xxx | OpenIM 透传 | 401/403/500 | 跳登录/SnackBar | 5 |
| 5xxx | 业务逻辑 (universe/table/row) | 400/409 | SnackBar | 6 |
| 6xxx | 服务异常 (ServerInternalError) | 500 | SnackBar | 1 |

详见 [ERROR_HANDLING.md](./ERROR_HANDLING.md) (28 个 ErrorKey 完整表) 和 [docs/ERROR_CODES.md](./ERROR_CODES.md) (后端 SSOT)。

### BLoC vs Cubit 选型

- **Cubit**: 简单状态机 (login form, theme toggle) — 1-2 个方法
- **Bloc**: 复杂事件流 (IM message, kick offline) — 多个 Event, 需要 event-driven 语义

---

## 7. 文档阅读路径 (4 层)

### 第 1 层: 总览 (30 分钟)
- 本文 (KNOWLEDGE_GRAPH.md)
- [AGENTS.md § 设计初心 + 5 反模式](../AGENTS.md)

### 第 2 层: 架构 (1 小时)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [ERROR_HANDLING.md](./ERROR_HANDLING.md)
- [API.md](./API.md)

### 第 3 层: 流程 (1 小时)
- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [DEPLOYMENT.md](./DEPLOYMENT.md)
- [TESTING.md](./TESTING.md)

### 第 4 层: 细节 (按需)
- [BUILDING_BLOCKS.md](./BUILDING_BLOCKS.md)
- [RECIPES.md](./RECIPES.md)
- [CACHE_STRATEGY.md](./CACHE_STRATEGY.md)
- [IM_INTEGRATION.md](./IM_INTEGRATION.md) — OpenIM SDK 集成
- [IM_API_MAP.md](./IM_API_MAP.md) — **阶段 2 SDK API SSOT**
- [PHASE2_PLAN.md](./PHASE2_PLAN.md) — **阶段 2 实施清单**
- [CONFIGURATION.md](./CONFIGURATION.md)
- [LICENSE_INFO.md](./LICENSE_INFO.md)
- [ADR/](./ADR/) (10 个)

---

*最后更新: 2026-07-01*
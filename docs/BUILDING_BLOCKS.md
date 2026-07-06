# docs/BUILDING_BLOCKS.md — 可复用构件 + 硬规则

> **本文件是 widget 复用 SSOT。**
> 新页面用哪些 widget、禁止自己写什么, 看这里。

---

## 1. 设计 Token (必用)

```dart
// lib/_core/theme/app_colors.dart
class AppColors {
  static const background = Color(0xFF1a1a1a);
  static const surface = Color(0xFF2a2a2a);
  static const primary = Color(0xFF6c63ff);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFb0b0b0);
  // ... 共 50+ 个
}

// lib/_core/theme/app_spacing.dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

// lib/_core/theme/app_radius.dart
class AppRadius {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 100.0;
}

// lib/_core/theme/app_durations.dart
class AppDurations {
  static const tap = Duration(milliseconds: 100);
  static const short = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 500);
  static const splashTimeout = Duration(seconds: 3);
}
```

**禁止**: 任何业务代码用 `Colors.X` / `Color(0xFF...)` / 硬编码数字。

---

## 2. 通用 widget (已存在, 跨 module 复用)

```dart
// lib/_core/widgets/base_loading.dart
BaseLoading()  // 全屏 loading

// lib/_core/widgets/base_empty_view.dart
BaseEmptyView(icon: ..., message: '暂无内容', actionLabel: '刷新', onAction: ...)

// lib/_core/widgets/base_error_retry.dart
BaseErrorRetry(message: '加载失败', onRetry: ...)

// lib/_core/widgets/cached_image.dart
CachedImage(url: ..., cacheWidth: 200, cacheHeight: 200)

// lib/_core/widgets/skeleton_loader.dart
SkeletonLoader(width: 200, height: 20)

// lib/_core/widgets/error_boundary.dart
ErrorBoundary(child: ..., onError: (e, st) => ...)

// lib/_core/widgets/pagination_list.dart
PaginationList<T>(items: ..., onLoadMore: ..., itemBuilder: (ctx, item) => ...)
```

---

## 3. 跨 module 共享 widget (`_shared/`)

```dart
// lib/_shared/widgets/app_text_field.dart
AppTextField(controller: ..., label: '用户名', obscure: false, validator: (v) => ...)

// lib/_shared/widgets/app_button.dart
AppElevatedButton(label: '提交', onPressed: ..., loading: false)
AppTextButton(label: '取消', onPressed: ...)

// lib/_shared/widgets/back_navbar.dart
BackNavbar(title: '标题', onBack: () => ...)

// lib/_shared/widgets/text_divider.dart
TextDivider(text: '或使用以下方式')

// lib/_shared/widgets/connection_indicator_widget.dart
// 自动消费 ConnectionBloc 状态, 显示"重连中..."横幅
```

### 3.1 跨 module 共享 Cubit (`_shared/blocs/`)

```dart
// lib/_shared/blocs/theme_mode_cubit.dart
// ThemeMode 状态 (light/dark/system), 持久化到 THEME_BOX
context.read<ThemeModeCubit>().lightMode();
BlocBuilder<ThemeModeCubit, ThemeMode>(builder: (context, mode) => ...)

// lib/_shared/blocs/locale_cubit.dart  ← 阶段 2.14 (commit f219a19 fix)
// 当前 Locale 状态 (en/zh/ar/es), 持久化到 THEME_BOX,
// 驱动 MaterialApp.router.locale, 切换语言时整 app 重新渲染
context.read<LocaleCubit>().setLocale(Locale('zh'));
BlocBuilder<LocaleCubit, Locale>(builder: (context, locale) => ...)

// L10n 调用方式 (单一来源 = intl gen-l10n, 详见 docs/I18N.md):
import 'package:pxshe_app/_shared/l10n/gen/app_localizations.dart';
final l10n = AppLocalizations.of(context);
Text(l10n.layoutPageHome);
```

**禁止**:
- ❌ 业务代码 `import 'package:easy_localization/...'` + `context.tr('xxx.yyy')` (已删, 见 AGENTS § 54)
- ❌ 业务代码自己用 `Navigator.push` 切语言 — 必须走 `LocaleCubit` + `MaterialApp.router.locale`
- ❌ `import '<...>/_shared/l10n/gen/app_localizations.dart'` — 生成文件在 `lib/l10n/gen/` (l10n.yaml `output-dir`), 是 `lib/` 的兄弟, **不**是 `_shared/` 的子目录
  - ✅ `lib/_shared/widgets/foo.dart` 用 `import '../../l10n/gen/app_localizations.dart';`
  - ✅ `lib/_core/.../foo.dart` 用 `import '../../../../l10n/gen/app_localizations.dart';`
  - ✅ `lib/modules/<m>/foo.dart` 用 `import '../../l10n/gen/app_localizations.dart';`

### 3.2 Dev 工具 (`_shared/dev/`,阶段 2.16 阶段 2 收尾用)

> **dev-only** — 仅 `kDebugMode` 时注册路由,生产 build tree-shake 掉。

```dart
// lib/_shared/dev/dev_routes.dart
// 列出所有 16 路由的元数据 (label / path / description / icon / group),
// devRoutes() 返回 [/dev] 路由 (kDebugMode 为 false 时空 list)
context.go('/dev');  // 跳到 DevMenuPage

// 入口 (HomePage AppBar 加 bug_report 图标, 仅 dev build 显示)
if (const bool.fromEnvironment('dart.vm.product') == false)
  IconButton(icon: Icon(Icons.bug_report), onPressed: () => context.go('/dev'));

// DevMenuPage 列出 16 路由 (按 group 分组):
// 业务域 / IM 域 / 认证域 / 错误域 / 阶段 3 占位
```

**文件关系** (`_shared/dev/` 内部):
- `dev_routes.dart` → 依赖 `dev_menu_page.dart` (导出 `/dev` 路由)
- `dev_menu_page.dart` → 依赖 `dev_routes.dart` (读 `devRouteEntries` 列表)

→ **两个文件互相 import 对方,无环**。`dev_routes.dart` 必须 import `dev_menu_page.dart` (否则 `DevMenuPage` 未定义);`dev_menu_page.dart` 必须 import `dev_routes.dart` (否则 `devRouteEntries` 未定义)。两者依赖是**单向 cross**: routes 引用 page, page 引用 entries, 不存在循环 import。

**用途**:
- 阶段 2 收尾: 手动测试每个路由 (e2e 验证)
- 阶段 3 业务模块: 测试新增的 universe 路由
- 阶段 4 集成测试: 模拟用户路径

**禁止**:
- ❌ 把 dev 路由当生产功能 (release build 必不含)
- ❌ 在业务 widget 调 dev 工具 (违反 § 50 复用原则, dev 工具只服务于 dev)
- ❌ dev 工具 import 业务代码 (反向依赖)

---

## 4. SnackBar helpers (必用)

```dart
// lib/_shared/widgets/show_snack_bar.dart
showInfoSnackBar(context, '提示');
showSuccessSnackBar(context, '操作成功');
showErrorSnackBar(context, '出错了');
showLoadingSnackBar(context, '加载中...');
showComingSoonSnackBar(context, feature: '功能名');
```

**禁止**: 任何业务代码直接调 `ScaffoldMessenger.of(context).showSnackBar(...)`。

---

## 5. 全局弹窗

```dart
// lib/_shared/widgets/confirm_dialog.dart
final ok = await ConfirmDialog.show(
  context,
  title: '退出?',
  message: '确定退出吗?',
  isDanger: true,  // 红色按钮 (用于删除/退出)
);
if (ok) { /* 确认 */ }

// lib/_shared/widgets/loading_dialog.dart
LoadingDialog.show(context, message: '加载中...');
await someAsyncOp();
LoadingDialog.hide(context);
```

---

## 6. 日志

```dart
// lib/_core/logger/app_logger.dart
appLogger.i('登录成功');
appLogger.w('token 即将过期', error: e);
appLogger.e('API 调用失败', error: e, stackTrace: st);
```

**禁止**: 任何业务代码用 `print()` (AGENTS §7)。

---

## 7. 26 条硬规则 (违反直接 fail CI)

| # | 规则 | 防什么 |
|---|---|---|
| 1 | SnackBar 必须用 `show*SnackBar` helpers | 5 处手写重复 |
| 2 | 顶部返回必须用 `BackNavbar` | 3 处手写 navbar |
| 3 | 输入框必须用 `AppTextField` | login 70 行手写 _buildInput |
| 4 | 按钮必须用 `AppElevatedButton` / `AppTextButton` | 直接 ElevatedButton 散落 |
| 5 | 文字分隔必须用 `TextDivider` | 手写 Row(Expanded, Divider, Text, Divider) |
| 6 | "X 功能暂未开放" 必须用 `showComingSoonSnackBar` | 8 处 _showPlaceholder |
| 7 | AppBar 必须用 `AppAppBar` | 直接 AppBar 用 |
| 8 | 颜色必须用 `AppColors.X` | 业务硬编码 |
| 9 | 间距必须用 `AppSpacing.X` | 业务硬编码 16/24/32 |
| 10 | 圆角必须用 `AppRadius.X` | 业务硬编码 BorderRadius.circular(16) |
| 11 | 时长必须用 `AppDurations.X` | 业务硬编码 Duration(...) |
| 12 | 异步数据必须用 BLoC/Cubit | StatefulWidget + setState 调 API |
| 13 | 每个 module 多 Bloc/Cubit (防 mega) | mega Bloc / mega Cubit |
| 14 | 跨 module 调用走对方 `<m>_module.dart` 门面 | 直接 import 内部 |
| 15 | 错误必须走 `ErrorHandler.handle()` | widget 自己 try/catch |
| 16 | HTTP 必须走 `ApiClient` | 直接用 dio |
| 17 | 路由必须用 `context.go()` / `context.push()` | 直接 Navigator.push |
| 18 | 业务代码禁止 import `package:flutter_openim_sdk` | 绕过 im_repository.dart 适配层 |
| 19 | `BuildContext` widget 销毁后必须 `if (!context.mounted) return` | 异步后 setState 崩溃 |
| 20 | 函数 ≤ 50 行 / 圈复杂度 ≤ 10 | 大函数 / 嵌套地狱 |
| 21 | **新 widget 跟现有 ≥ 80% 重合 → 扩展现有, 不许新建** (AGENTS §50) | Avatar / Avatar2 / MyAvatar 共存搞不清 |
| 22 | **旅行箱原则: 加新东西必须挤掉旧的**, `@Deprecated` 3 sprint 必删 (AGENTS §51) | 无限堆砌 |
| 23 | **官方文档优先 (菜谱原则)**, 自定义实现必加 ADR 解释 (AGENTS §52) | 自己乱写, 不查官方 |
| 24 | **确认弹窗必须用 `ConfirmDialog.show()`**, 不用 `showDialog` 自己写 | 散落手写 |
| 25 | **加载弹窗必须用 `LoadingDialog.show() + hide()` 配对** | 散落手写 |
| 26 | **必须用 `appLogger` 不用 `print()`** (AGENTS §7) | 5 处 print 散落 |
| 27 | **L10n 必须用 `intl` gen-l10n** + `AppLocalizations.of(context)!` (AGENTS §54, 见 [docs/I18N.md](./I18N.md)) | 26 处 `context.tr()` 调未配齐的 easy_localization → bug f219a19 |

详见 [RECIPES.md](./RECIPES.md) 怎么用。

---

## 8. 加新 widget 流程

详见 [RECIPES.md §1](./RECIPES.md)。

---

*最后更新: 2026-07-01*
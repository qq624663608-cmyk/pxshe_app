# docs/REFERENCE.md — 官方资源 + 必备/禁止包

> **本文件是依赖选型 SSOT。**
> 选新依赖前, 必查这里。

---

## 1. 状态管理

| 用 | 不用 |
|---|---|
| ✅ `flutter_bloc` ^9.x | ❌ `riverpod` (universe_app 用了, pxshe_app 不用) |
| ✅ `bloc` ^9.x | ❌ `provider` (老 API) |
| ✅ `bloc_test` ^10.x | ❌ `mockito` (慢) |
| ✅ `mocktail` ^1.x | ❌ `mockito` |
| ✅ `bloc_lint` | ❌ `riverpod_lint` |

详见 [ADR-0001](./ADR/0001-why-bloc.md)。

---

## 2. 路由

| 用 | 不用 |
|---|---|
| ✅ `go_router` ^17.x | ❌ `auto_route` |
| | ❌ `Navigator 1.0` (老 API) |

详见 [ADR-0007](./ADR/0007-why-go-router.md)。

---

## 3. 依赖注入

| 用 | 不用 |
|---|---|
| ✅ `get_it` ^9.x | ❌ `get_it_mixin` |
| | ❌ `riverpod` 做 DI (状态用 BLoC) |

详见 [AGENTS.md §3](../AGENTS.md)。

---

## 4. 本地存储

| 用 | 不用 |
|---|---|
| ✅ `hive_ce` ^2.x | ❌ `hive` (deprecated) |
| ✅ `hive_ce_flutter` | ❌ `shared_preferences` 存复杂对象 |
| | ❌ `sqflite` (业务不需要) |

详见 [ADR-0006](./ADR/0006-why-hive-ce.md) + [CACHE_STRATEGY.md](./CACHE_STRATEGY.md)。

---

## 5. HTTP

| 用 | 不用 |
|---|---|
| ✅ `dio` ^5.x | ❌ `http` (功能少) |
| ✅ `retrofit` (如需要 codegen) | ❌ 手写 HTTP 客户端 |
| ✅ `dartz` (Either/Option) | ❌ 自定义 sealed class |

---

## 6. IM SDK

| 用 | 不用 |
|---|---|
| ✅ `flutter_openim_sdk` ^3.8.3+hotfix.12 | ❌ 自己写 WebSocket |
| | ❌ 融云 / 环信 / 腾讯云 IM (商业, 阶段 2 后评估) |

详见 [IM_INTEGRATION.md](./IM_INTEGRATION.md)。

---

## 7. UI / 主题

| 用 | 不用 |
|---|---|
| ✅ `flex_color_scheme` ^8.x | ❌ 自定义 ThemeData |
| ✅ `flutter_animate` | ❌ `flutter_sequence_animations` (老) |
| ✅ `toastification` ^3.x | ❌ `fluttertoast` |
| ✅ `loader_overlay` ^5.x | ❌ 自定义 loading widget |
| ✅ `cached_network_image` | ❌ 直接 `Image.network` |
| ✅ `flutter_markdown` (临时) | ❌ `flutter_html` (重) |

---

## 8. 表单

| 用 | 不用 |
|---|---|
| ✅ `flutter_form_builder` ^10.x | ❌ 手写 Form |
| ✅ `form_builder_validators` ^11.x | ❌ 自定义 validator |

---

## 9. 国际化

| 用 | 不用 |
|---|---|
| ✅ `easy_localization` ^3.x | ❌ `intl` (底层) |
| ✅ `flutter_localizations` | ❌ `i18n_extension` |

---

## 10. Lint / 分析

| 用 | 不用 |
|---|---|
| ✅ `very_good_analysis` ^10.x | ❌ `flutter_lints` (太松) |
| ✅ `bloc_lint` | ❌ `pedantic` (deprecated) |
| ✅ `very_good_cli` ^1.x | ❌ `dart_code_metrics` (重) |

详见 [ADR-0008](./ADR/0008-why-very-good-analysis.md)。

---

## 11. 测试

| 用 | 不用 |
|---|---|
| ✅ `flutter_test` (内置) | ❌ 自写 test runner |
| ✅ `mocktail` ^1.x | ❌ `mockito` (慢) |
| ✅ `bloc_test` ^10.x | ❌ `bloc_test` 老版本 |
| ✅ `integration_test` (内置) | ❌ 自写 e2e |
| ✅ `patrol` (阶段 5) | ❌ `flutter_driver` (deprecated) |

---

## 12. 工具 / 杂项

| 用 | 不用 |
|---|---|
| ✅ `logger` ^2.x | ❌ `print()` |
| ✅ `responsive_framework` ^1.x | ❌ 手写 MediaQuery 断点 |
| ✅ `url_launcher` ^6.x | ❌ `flutter_custom_tabs` |
| ✅ `infinite_scroll_pagination` ^5.x | ❌ 手写分页逻辑 |
| ✅ `universal_html` ^2.x (web 兼容) | ❌ `dart:html` (deprecated) |

---

## 13. 官方资源 (SSOT)

- [Flutter 官方文档](https://docs.flutter.dev/)
- [BLoC 官方文档](https://bloclibrary.dev/)
- [GetIt 官方文档](https://pub.dev/packages/get_it)
- [GoRouter 官方文档](https://pub.dev/packages/go_router)
- [Hive CE 官方文档](https://pub.dev/packages/hive_ce)
- [Dio 官方文档](https://pub.dev/packages/dio)
- [very_good_analysis](https://pub.dev/packages/very_good_analysis)

---

## 14. 加新依赖流程

```
1. 查本文档 §1-12 (该用哪个)
2. 没找到 → 查 [pub.dev](https://pub.dev) 找候选
3. 检查 License (不能 SSPL/BSL/商业专有, 兼容 AGPL)
4. flutter pub add <package>
5. very_good packages check licenses --forbidden="SSPL,BSL,unknown"
6. very_good test --coverage --min-coverage 100
7. flutter analyze
8. 同步更新 [LICENSE_INFO.md](./LICENSE_INFO.md) §2 表格
```

---

*最后更新: 2026-07-01*
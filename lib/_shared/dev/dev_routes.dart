import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One dev menu entry. Public so the dev page can build list tiles.
class DevRouteEntry {
  const DevRouteEntry({
    required this.label,
    required this.path,
    required this.description,
    required this.icon,
    required this.group,
  });

  final String label;
  final String path;
  final String description;
  final IconData icon;
  final String group;
}

/// Master list. Keep in sync with `lib/_core/app_router.dart` and the
/// per-module `*Routes()` functions.
const List<DevRouteEntry> devRouteEntries = [
  // 业务域
  DevRouteEntry(
    label: 'Home (Universes)',
    path: '/home',
    description: '阶段 1.5 — 业务首页, IM banner + FAB',
    icon: Icons.home,
    group: '业务域',
  ),
  DevRouteEntry(
    label: 'Settings',
    path: '/settings',
    description: '阶段 1.5 — 主题/语言/退出',
    icon: Icons.settings,
    group: '业务域',
  ),

  // IM 域
  DevRouteEntry(
    label: 'IM Status (ConnectionStatusPage)',
    path: '/im/status',
    description: '阶段 2.1 — IM 连接状态详细页',
    icon: Icons.network_check,
    group: 'IM 域',
  ),
  DevRouteEntry(
    label: 'Chat List',
    path: '/chat_list',
    description: '阶段 2.2 — 会话列表 (14 个会话)',
    icon: Icons.chat_bubble_outline,
    group: 'IM 域',
  ),
  DevRouteEntry(
    label: 'Chat (固定 id=si_3285247985_import_a)',
    path: '/chat/si_3285247985_import_a',
    description: '阶段 2.3 — 聊天详情 (单聊)',
    icon: Icons.message,
    group: 'IM 域',
  ),
  DevRouteEntry(
    label: 'Contacts (好友列表)',
    path: '/contacts',
    description: '阶段 2.4 — 11 好友 + 1 黑名单',
    icon: Icons.people,
    group: 'IM 域',
  ),
  DevRouteEntry(
    label: 'Profile (Placeholder)',
    path: '/profile',
    description: '阶段 2.5 — 群组 (目前是占位)',
    icon: Icons.person,
    group: 'IM 域',
  ),

  // 认证域
  DevRouteEntry(
    label: 'Splash',
    path: '/splash',
    description: '阶段 0 — 启动页 (redirect 守卫)',
    icon: Icons.bolt,
    group: '认证域',
  ),
  DevRouteEntry(
    label: 'Landing',
    path: '/landing',
    description: 'web 版 LandingPage (unAuth guard)',
    icon: Icons.public,
    group: '认证域',
  ),
  DevRouteEntry(
    label: 'Login',
    path: '/login',
    description: '阶段 1.5 — 登录页 (unAuth guard)',
    icon: Icons.login,
    group: '认证域',
  ),
  DevRouteEntry(
    label: 'Register',
    path: '/register',
    description: '阶段 1.5 — 注册页 (unAuth guard)',
    icon: Icons.app_registration,
    group: '认证域',
  ),

  // 错误域
  DevRouteEntry(
    label: 'Error 401',
    path: '/errors/401',
    description: '未授权错误页',
    icon: Icons.lock_outline,
    group: '错误域',
  ),
  DevRouteEntry(
    label: 'Error 404',
    path: '/errors/404',
    description: 'Not Found (errorPageBuilder 默认)',
    icon: Icons.search_off,
    group: '错误域',
  ),

  // 阶段 3 (未实现)
  DevRouteEntry(
    label: 'Universe List (阶段 3)',
    path: '/universe',
    description: '阶段 3 — 业务 CRUD 入口',
    icon: Icons.public,
    group: '阶段 3 占位',
  ),
  DevRouteEntry(
    label: 'Universe Detail (阶段 3)',
    path: '/universe/import_a',
    description: '阶段 3 — 单一 universe 详情 + 子表',
    icon: Icons.public,
    group: '阶段 3 占位',
  ),
];

/// Dev-only: returns the `/dev` route list, or empty in release builds.
///
/// We don't gate on `kDebugMode` at the function level so callers can
/// always invoke it; instead the route registration is a no-op when
/// the build is not debug (a debug-only route in a release binary
/// would still be reachable from the router, which is what we want to
/// avoid). Use [kDebugMode] when adding these to the router.
List<GoRoute> devRoutes() {
  if (!kDebugMode) return const <GoRoute>[];
  return [
    GoRoute(
      path: '/dev',
      pageBuilder: (context, state) => MaterialPage(
        child: const DevMenuPage(),
      ),
    ),
  ];
}

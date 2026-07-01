import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../_core/app_router.dart';
import '../../_core/di.dart';
import '../../_core/layout/adaptive_layout/adaptive_destination.dart';
import 'domain/auth_repository.dart';
import 'features/login/login_page.dart';
import 'features/placeholder_page.dart';

enum AuthNavTab implements NavTab { profile }

List<AdaptiveDestination> getAuthNavTabs(BuildContext context) {
  return <AdaptiveDestination>[
    AdaptiveDestination(
      title: context.tr('layoutPage.profile'),
      icon: Icons.person,
      route: '/profile',
      navTab: AuthNavTab.profile,
      order: 30,
    ),
  ];
}

List<GoRoute> authRoutes() {
  return [
    GoRoute(
      path: '/login',
      redirect: unAuthRouteGuard,
      pageBuilder: (context, state) => FadeTransitionPage(
        child: LoginPage(repository: di<AuthRepository>()),
      ),
    ),
    GoRoute(
      path: '/register',
      redirect: unAuthRouteGuard,
      pageBuilder: (context, state) => FadeTransitionPage(
        child: const PlaceholderPage(title: 'Register'),
      ),
    ),
    GoRoute(
      path: '/profile',
      redirect: authRouteGuard,
      pageBuilder: (context, state) => FadeTransitionPage(
        child: const PlaceholderPage(title: 'Profile'),
      ),
    ),
  ];
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../_core/app_router.dart';
import '../../_core/di.dart';
import '../../_core/layout/adaptive_layout/adaptive_destination.dart';
import '../../_shared/l10n/gen/app_localizations.dart';
import '../registration/data/registration_service.dart';
import '../registration/domain/entities/registration_config.dart';
import '../registration/features/register_page.dart';
import 'domain/auth_repository.dart';
import 'features/login/login_page.dart';
import 'features/placeholder_page.dart';

enum AuthNavTab implements NavTab { profile }

List<AdaptiveDestination> getAuthNavTabs(BuildContext context) {
  return <AdaptiveDestination>[
    AdaptiveDestination(
      title: AppLocalizations.of(context).layoutPageProfile,
      icon: Icons.person,
      route: '/profile',
      navTab: AuthNavTab.profile,
      order: 30,
    ),
  ];
}

List<GoRoute> authRoutes() {
  return [
    // /login and /register use unAuthRouteGuard (NOT authRouteGuard).
    // unAuthRouteGuard redirects already-logged-in users to firstNavRoute
    // and lets unauthenticated users through. Works in tandem with
    // AppRouter.refreshListenable which re-evaluates these on every
    // AuthBloc state change — so after a successful login, the guard
    // pushes the user to /home automatically.
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
      pageBuilder: (context, state) {
        final config = di<RegistrationService>().cachedConfig ??
            const RegistrationConfig(allowRegister: true, availableMethods: ['phone']);
        return FadeTransitionPage(
          child: RegisterPage(
            repository: di<AuthRepository>(),
            config: config,
          ),
        );
      },
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
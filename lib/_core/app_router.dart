import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../_shared/features/error/error_404_page.dart';
import '../modules/auth/bloc/auth_bloc.dart';
import 'constants.dart';
import 'di.dart';
import 'layout/adaptive_layout/adaptive_destination.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

List<AdaptiveDestination> getNavRoutes() => di.get(instanceName: Constants.navTabsDiKey);

String firstNavRoute() {
  var navRoutes = getNavRoutes();
  if (navRoutes.isNotEmpty) {
    return navRoutes.first.route;
  }
  return "/";
}

FutureOr<String?> authRouteGuard(BuildContext context, GoRouterState state) async {
  var authBloc = context.read<AuthBloc>();

  if (authBloc.state.status == AuthStatus.unknown) {
    final wait = authBloc.stream.firstWhere((state) =>
        state.status == AuthStatus.authenticated ||
        state.status == AuthStatus.unauthenticated);
    context.read<AuthBloc>().add(AppLoaded());
    await wait;
  }

  if (authBloc.state.status == AuthStatus.authenticated) {
    return null;
  } else {
    // Unauthenticated → bounce to /login. (Was /errors/401, but a 401
    // page would prevent the user from signing in.)
    return "/login";
  }
}

FutureOr<String?> unAuthRouteGuard(BuildContext context, GoRouterState state) async {
  var authBloc = context.read<AuthBloc>();

  if (authBloc.state.status == AuthStatus.unknown) {
    final wait = authBloc.stream.firstWhere((state) =>
        state.status == AuthStatus.authenticated ||
        state.status == AuthStatus.unauthenticated);
    context.read<AuthBloc>().add(AppLoaded());
    await wait;
  }

  if (authBloc.state.status == AuthStatus.unauthenticated) {
    return null;
  } else {
    return firstNavRoute();
  }
}

FutureOr<String?> initialRedirect(BuildContext context, GoRouterState state) {
  var authBloc = context.read<AuthBloc>();
  var status = authBloc.state.status;

  if (status == AuthStatus.authenticated) {
    return firstNavRoute();
  } else if (status == AuthStatus.unauthenticated) {
    return kIsWeb ? "/landing" : "/login";
  } else {
    return null;
  }
}

/// A `ChangeNotifier` that the AuthBloc stream drives. Pairs with
/// [AppRouter.refreshListenable] so that every auth-state change
/// triggers GoRouter to re-evaluate its `redirect:` guards
/// (industry-standard pattern, see go_router docs on `refreshListenable`).
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  /// Subscribe once in `App.build`. All AuthBloc state changes
  /// invoke the callback, which calls [notifyListeners].
  void bind(Stream<dynamic> authBlocStream) {
    _subscription = authBlocStream.listen((_) => notifyListeners());
  }

  StreamSubscription<dynamic>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AppRouter {
  final List<RouteBase> routes;

  AppRouter({required this.routes});

  /// Notifier driven by AuthBloc.stream. See [_AuthRouterRefreshNotifier].
  final _refreshNotifier = _AuthRouterRefreshNotifier();

  late final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: "/",
    refreshListenable: _refreshNotifier,
    errorPageBuilder: (_, __) => NoTransitionPage<void>(child: const Error404Page()),
    debugLogDiagnostics: false,
    routes: routes,
  );

  /// Call this once from `App.build` to wire AuthBloc.stream → notifier.
  void bindAuthBloc() {
    _refreshNotifier.bind(di<AuthBloc>().stream);
  }
}

class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({
    super.key,
    required super.child,
  }) : super(
          transitionsBuilder: (c, animation, a2, child) => FadeTransition(
            opacity: animation.drive(_curveTween),
            child: child,
          ),
        );
  static final _curveTween = CurveTween(curve: Curves.easeIn);
}

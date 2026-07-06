import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../_core/_init_modules.dart';
import '../../_core/app_router.dart';
import '../../_core/di.dart';
import '../../_core/theme.dart';
import '../../_shared/blocs/locale_cubit.dart';
import '../../_shared/blocs/theme_mode_cubit.dart';
import '../../_shared/l10n/gen/app_localizations.dart';
import '../../modules/auth/bloc/auth_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = di<AppRouter>();
    // Bind AuthBloc.stream → router.refreshListenable so that every
    // auth-state change re-evaluates route guards (industry standard).
    router.bindAuthBloc();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeModeCubit>(create: (_) => di<ThemeModeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => di<LocaleCubit>()),
        BlocProvider<AuthBloc>(create: (_) => di<AuthBloc>()),
      ],
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (themeContext, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (localeContext, locale) {
              return MaterialApp.router(
                title: 'pxshe',
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeMode,
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router.router,
                // Populate navTabs here — `builder`'s context is wrapped by
                // MaterialApp + Localizations (via delegates) + Router, so
                // `AppLocalizations.of(context)` in `getAuthNavTabs` works.
                // `initAfterRunApp` is idempotent (navTabs.clear() + addAll()),
                // so being invoked on every rebuild is safe.
                builder: (innerContext, child) {
                  AppModules.initAfterRunApp(innerContext);
                  return child!;
                },
              );
            },
          );
        },
      ),
    );
  }
}

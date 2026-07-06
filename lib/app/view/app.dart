import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../_core/app_router.dart';
import '../../_core/di.dart';
import '../../_core/theme.dart';
import '../../_shared/blocs/theme_mode_cubit.dart';
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
        BlocProvider<AuthBloc>(create: (_) => di<AuthBloc>()),
      ],
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'pxshe',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            routerConfig: router.router,
          );
        },
      ),
    );
  }
}
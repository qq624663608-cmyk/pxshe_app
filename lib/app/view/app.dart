import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../_core/app_router.dart';
import '../../_core/di.dart';
import '../../_core/theme.dart';
import '../../_shared/blocs/theme_mode_cubit.dart';
import '../../_shared/features/splash/page/splash_page.dart';
import '../../modules/auth/bloc/auth_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
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
            routerConfig: di<AppRouter>().router,
          );
        },
      ),
    );
  }
}
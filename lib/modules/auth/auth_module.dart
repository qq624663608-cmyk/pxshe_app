import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';

import '../../_core/constants.dart';
import '../../_core/di.dart';
import '../../_core/layout/adaptive_layout/adaptive_destination.dart';
import 'auth_routes.dart';
import 'bloc/auth_bloc.dart';
import 'data/auth_repository_impl.dart';
import 'data/models/user_model.dart';
import 'domain/auth_repository.dart';
import 'domain/auth_usecases.dart';

Future<void> registerAuthModule() async {
  di<HiveInterface>().registerAdapter<UserModel>(UserModelAdapter());

  di.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dio: di(), hive: di(), networkInfo: di()),
  );

  di.registerLazySingleton<AuthUsecases>(() => AuthUsecases(di()));

  di.registerLazySingleton(
    () => AuthBloc(userUsecase: di())..add(AuthStatusSubscriptionRequested()),
  );

  di<List<RouteBase>>(instanceName: Constants.mainRouesDiKey).addAll(authRoutes());
}

void registerAuthModuleWithContext(BuildContext context) {
  var navTabs = di<List<AdaptiveDestination>>(instanceName: Constants.navTabsDiKey);
  navTabs.addAll(getAuthNavTabs(context));
}
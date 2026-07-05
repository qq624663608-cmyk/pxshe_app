import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:pxshe_app/_core/app_router.dart';
import 'package:pxshe_app/_core/constants.dart';
import 'package:pxshe_app/_core/di.dart';
import 'package:pxshe_app/modules/im/auth_module_bridge.dart';
import 'package:pxshe_app/modules/im/bloc/connection_cubit.dart';
import 'package:pxshe_app/modules/im/bloc/conversation_cubit.dart';
import 'package:pxshe_app/modules/im/bloc/friend_cubit.dart';
import 'package:pxshe_app/modules/im/bloc/group_cubit.dart';
import 'package:pxshe_app/modules/im/bloc/message_cubit.dart';
import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/data/repositories/conversation_repository_impl.dart';
import 'package:pxshe_app/modules/im/data/repositories/friend_repository_impl.dart';
import 'package:pxshe_app/modules/im/data/repositories/group_repository_impl.dart';
import 'package:pxshe_app/modules/im/data/repositories/im_auth_repository_impl.dart';
import 'package:pxshe_app/modules/im/data/repositories/message_repository_impl.dart';
import 'package:pxshe_app/modules/im/domain/conversation_repository.dart';
import 'package:pxshe_app/modules/im/domain/friend_repository.dart';
import 'package:pxshe_app/modules/im/domain/group_repository.dart';
import 'package:pxshe_app/modules/im/domain/im_auth_repository.dart';
import 'package:pxshe_app/modules/im/domain/message_repository.dart';
import 'package:pxshe_app/modules/im/features/placeholder/connection_status_page.dart';
import 'package:pxshe_app/modules/im/im_routes.dart';

/// Module facade for IM.
/// Phase 2.1 — SDK init + Connection.
/// Phase 2.2 — + Conversation repository + cubit + chat list route.
/// Phase 2.3 — + Message repository + cubit + chat route.
/// Phase 2.4 — + Friend repository + cubit + contacts route.
/// Phase 2.5 — + Group repository + cubit + profile route.
Future<void> registerIMModule() async {
  // Bridge to auth module — gives IM access to userID / imToken without
  // importing auth internals (ADR-0005).
  di.registerLazySingleton<AuthModuleBridge>(() => AuthModuleBridge(di()));

  // Datasource (single SDK wrapper — OpenIM.iMManager is already a singleton).
  di.registerLazySingleton<OpenIMSDKWrapper>(OpenIMSDKWrapper.new);

  // Repositories.
  di.registerLazySingleton<ImAuthRepository>(
    () => ImAuthRepositoryImpl(di()),
  );
  di.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(di()),
  );
  di.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(di()),
  );
  di.registerLazySingleton<FriendRepository>(
    () => FriendRepositoryImpl(di()),
  );
  di.registerLazySingleton<GroupRepository>(
    () => GroupRepositoryImpl(di()),
  );

  // Blocs (one per sub-feature per ADR-0004).
  di.registerLazySingleton<ConnectionCubit>(
    () => ConnectionCubit(di<ImAuthRepository>()),
  );
  di.registerLazySingleton<ConversationCubit>(
    () => ConversationCubit(di()),
  );
  di.registerLazySingleton<MessageCubit>(
    () => MessageCubit(di()),
  );
  di.registerLazySingleton<FriendCubit>(
    () => FriendCubit(di()),
  );
  di.registerLazySingleton<GroupCubit>(
    () => GroupCubit(di()),
  );

  di<List<RouteBase>>(instanceName: Constants.mainRouesDiKey).addAll(imRoutes());
}

/// Hook into the auth flow — called after AuthLoginSucceeded.
/// Idempotent: safe to call on every successful login (e.g. cold start).
Future<void> bootstrapIMAfterLogin() async {
  final im = di<ImAuthRepository>();
  final bridge = di<AuthModuleBridge>();
  if (!im.isInitialised) {
    await im.init();
  }
  final cached = bridge.cachedSession();
  final userID = cached.userId;
  final imToken = cached.imToken;
  if (userID != null && imToken != null) {
    await im.login(userID: userID, imToken: imToken);
  }
}

/// Mirror of [bootstrapIMAfterLogin] for logout.
/// Idempotent: safe to call even when SDK was never initialised.
Future<void> bootstrapIMAfterLogout() async {
  final im = di<ImAuthRepository>();
  await im.logout();
}
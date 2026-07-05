import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/_core/app_router.dart';
import 'package:pxshe_app/_core/di.dart';
import 'package:pxshe_app/modules/im/bloc/connection_cubit.dart';
import 'package:pxshe_app/modules/im/bloc/conversation_cubit.dart';
import 'package:pxshe_app/modules/im/bloc/friend_cubit.dart';
import 'package:pxshe_app/modules/im/bloc/group_cubit.dart';
import 'package:pxshe_app/modules/im/bloc/message_cubit.dart';
import 'package:pxshe_app/modules/im/features/chat_list/chat_list_page.dart';
import 'package:pxshe_app/modules/im/features/chat_page/chat_page.dart';
import 'package:pxshe_app/modules/im/features/contacts/contacts_page.dart';
import 'package:pxshe_app/modules/im/features/placeholder/connection_status_page.dart';
import 'package:pxshe_app/modules/im/features/profile/profile_page.dart';
import 'package:pxshe_app/modules/im/im_routes.dart';

/// Routes registered for the IM module.
/// Phase 2.1: `/im/status` placeholder.
/// Phase 2.2: + `/chat_list`.
/// Phase 2.3: + `/chat/:id`.
/// Phase 2.4: + `/contacts`.
/// Phase 2.5: + `/profile`.
List<GoRoute> imRoutes() => [
      GoRoute(
        path: ImRoutes.status,
        redirect: authRouteGuard,
        pageBuilder: (context, state) => FadeTransitionPage(
          child: BlocProvider.value(
            value: di<ConnectionCubit>(),
            child: const ConnectionStatusPage(),
          ),
        ),
      ),
      GoRoute(
        path: ImRoutes.chatList,
        redirect: authRouteGuard,
        pageBuilder: (context, state) => FadeTransitionPage(
          child: BlocProvider.value(
            value: di<ConversationCubit>(),
            child: const ChatListPage(),
          ),
        ),
      ),
      GoRoute(
        path: ImRoutes.chat,
        redirect: authRouteGuard,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra;
          // extra is an int (flutter_openim_sdk.ConversationType.single = 1).
          final type = extra is int ? extra : ConversationType.single;
          return FadeTransitionPage(
            child: BlocProvider.value(
              value: di<MessageCubit>(),
              child: ChatPage(
                conversationID: id,
                conversationType: type,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: ImRoutes.contacts,
        redirect: authRouteGuard,
        pageBuilder: (context, state) => FadeTransitionPage(
          child: BlocProvider.value(
            value: di<FriendCubit>(),
            child: const ContactsPage(),
          ),
        ),
      ),
      GoRoute(
        path: ImRoutes.profile,
        redirect: authRouteGuard,
        pageBuilder: (context, state) => FadeTransitionPage(
          child: BlocProvider.value(
            value: di<GroupCubit>(),
            child: const ProfilePage(),
          ),
        ),
      ),
    ];

class ImRoutes {
  ImRoutes._();

  /// Phase 2.1 placeholder — kept for the connection status banner.
  static const status = '/im/status';

  /// Phase 2.2.
  static const chatList = '/chat_list';
  static const chat = '/chat/:id';

  /// Phase 2.4.
  static const contacts = '/contacts';

  /// Phase 2.5.
  static const profile = '/profile';
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:go_router/go_router.dart';

import 'package:pxshe_app/_core/theme/app_colors.dart';
import 'package:pxshe_app/modules/im/bloc/connection_cubit.dart' as im;
import 'package:pxshe_app/modules/im/bloc/conversation_cubit.dart';
import 'package:pxshe_app/modules/im/im_routes.dart';

/// Conversation list page — all conversations, newest-first.
/// Phase 2.2. Subsequent phases reuse this view from /chat_list.
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ConversationCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Chats',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<im.ConnectionCubit, im.ConnectionState>(
        builder: (context, conn) {
          final reconnecting = conn.status == im.ConnectionStatus.connecting ||
              conn.status == im.ConnectionStatus.disconnected;
          return Column(
            children: [
              if (reconnecting) const _ReconnectingBanner(),
              Expanded(
                child: BlocBuilder<ConversationCubit, ConversationState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case ConversationStatus.loading:
                        return const Center(
                            child: CircularProgressIndicator());
                      case ConversationStatus.error:
                        return _ErrorView(message: state.error ?? 'unknown');
                      case ConversationStatus.initial:
                      case ConversationStatus.loaded:
                        if (state.items.isEmpty) {
                          return const _EmptyView();
                        }
                        return ListView.separated(
                          itemCount: state.items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = state.items[i];
                            return _ConversationTile(info: c);
                          },
                        );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.info});
  final ConversationInfo info;

  @override
  Widget build(BuildContext context) {
    final preview = info.latestMsg?.textElem?.content ?? '';
    final title = info.showName?.trim().isNotEmpty == true
        ? info.showName!
        : info.conversationID;
    return ListTile(
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: preview.isEmpty
          ? null
          : Text(preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary)),
      trailing: info.unreadCount > 0
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${info.unreadCount}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: () => context.push(
        '${ImRoutes.chat.split('/:id').first}/${Uri.encodeComponent(info.conversationID)}'
            .replaceFirst('//', '/'),
        extra: info.conversationType ?? ConversationType.single,
      ),
    );
  }
}

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(8),
      child: const Text(
        'Reconnecting…',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No conversations yet',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
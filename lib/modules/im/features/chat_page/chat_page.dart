import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/_core/theme/app_colors.dart';
import 'package:pxshe_app/_core/theme/app_radius.dart';
import 'package:pxshe_app/modules/im/bloc/message_cubit.dart' as im;

/// Single-conversation chat page. Loads history on enter, sends text on tap.
/// Phase 2.3 — reuses the same `MessageCubit` instance route-scoped.
///
/// `message_cubit.dart` is imported with the `im.` prefix because
/// `MessageStatus` is also exported by `flutter_openim_sdk`.
class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.conversationID,
    required this.conversationType,
    super.key,
  });

  final String conversationID;

  /// `int` because `flutter_openim_sdk.ConversationType` is a class with
  /// static `int` constants (not an enum).
  final int conversationType;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<im.MessageCubit>();
    cubit.loadHistory(conversationID: widget.conversationID);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await context.read<im.MessageCubit>().sendText(
          recvID: widget.conversationID,
          text: text,
          type: widget.conversationType,
        );
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          widget.conversationID,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<im.MessageCubit, im.MessageState>(
              builder: (context, state) {
                if (state.status == im.MessageStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == im.MessageStatus.error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.error ?? 'unknown error',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  );
                }
                if (state.items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  itemCount: state.items.length,
                  itemBuilder: (_, i) {
                    final m = state.items[i];
                    final isMine = m.sendID != widget.conversationID;
                    return _Bubble(message: m, isMine: isMine);
                  },
                );
              },
            ),
          ),
          _Composer(controller: _ctrl, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final text = message.textElem?.content ?? '';
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: 'Type a message',
                  hintStyle: const TextStyle(color: AppColors.textDisabled),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Send',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
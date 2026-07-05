import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/modules/im/domain/message_repository.dart';

class MessageCubit extends Cubit<MessageState> {
  MessageCubit(this._repo) : super(const MessageState.initial()) {
    _incomingSub = _repo.incoming.listen(_onIncoming);
  }

  final MessageRepository _repo;
  late final StreamSubscription<Message> _incomingSub;

  Future<void> loadHistory({
    required String conversationID,
    Message? lastMsg,
    int count = 20,
  }) async {
    emit(state.copyWith(
      status: MessageStatus.loading,
      conversationID: conversationID,
    ));
    try {
      final list = await _repo.loadHistory(
        conversationID: conversationID,
        lastMsg: lastMsg,
        count: count,
      );
      emit(state.copyWith(
        status: MessageStatus.loaded,
        items: list,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: MessageStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> sendText({
    required String recvID,
    required String text,
    int type = ConversationType.single,
    String? groupID,
  }) async {
    try {
      final sent = await _repo.sendText(
        recvID: recvID,
        text: text,
        type: type,
        groupID: groupID,
      );
      // Optimistic append — sender sees their bubble immediately.
      emit(state.copyWith(items: [...state.items, sent]));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: MessageStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onIncoming(Message msg) {
    // SDK Message has no conversationID field — match by sendID/recvID
    // against the active conversation. For single-chat, the conversation
    // ID is `si_<userA>_<userB>`, so we just check sendID/recvID
    // membership instead.
    final active = state.conversationID;
    if (active == null) return;
    final isActiveChat =
        msg.sendID != null && active.contains(msg.sendID!) ||
            msg.recvID != null && active.contains(msg.recvID!);
    if (!isActiveChat) return;
    if (state.items.any((m) => m.clientMsgID == msg.clientMsgID)) return;
    emit(state.copyWith(items: [...state.items, msg]));
  }

  @override
  Future<void> close() async {
    await _incomingSub.cancel();
    await super.close();
  }
}

enum MessageStatus { initial, loading, loaded, error }

class MessageState extends Equatable {
  const MessageState({
    this.status = MessageStatus.initial,
    this.items = const [],
    this.conversationID,
    this.error,
  });
  const MessageState.initial() : this();

  final MessageStatus status;
  final List<Message> items;
  final String? conversationID;
  final String? error;

  MessageState copyWith({
    MessageStatus? status,
    List<Message>? items,
    String? conversationID,
    String? error,
  }) =>
      MessageState(
        status: status ?? this.status,
        items: items ?? this.items,
        conversationID: conversationID ?? this.conversationID,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, items, conversationID, error];
}
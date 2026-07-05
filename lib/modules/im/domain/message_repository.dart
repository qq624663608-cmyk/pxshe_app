import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

/// Send / receive / history per single conversation (1-1 or group).
/// Implemented by `MessageRepositoryImpl`. Consumed by `MessageCubit` and
/// `ChatPage`.
///
/// Note: `flutter_openim_sdk`'s `ConversationType` is a class with static
/// `int` constants (not an enum), so [type] is an int.
abstract class MessageRepository {
  /// Pull history for a conversation (newest-first).
  /// [lastMsg] — pass the last message from the current page to load older
  /// history. Pass null on the first page.
  Future<List<Message>> loadHistory({
    required String conversationID,
    Message? lastMsg,
    int count = 20,
  });

  /// Send a text message. Returns the server-assigned message after success.
  /// [type] defaults to [ConversationType.single] (1).
  Future<Message> sendText({
    required String recvID,
    required String text,
    int type = ConversationType.single,
    String? groupID,
  });

  /// Live stream of incoming messages for any conversation.
  Stream<Message> get incoming;
}
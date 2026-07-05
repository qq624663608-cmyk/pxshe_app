import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

/// Conversation list + unread tracking contract.
/// Implemented by `ConversationRepositoryImpl`. Consumed by
/// `ConversationCubit` and `ChatListPage`.
abstract class ConversationRepository {
  /// All conversations, newest-first.
  Future<List<ConversationInfo>> getAll();

  /// Total unread across every conversation.
  Future<int> getTotalUnreadCount();

  /// Mark a conversation's messages as read (server-side).
  Future<void> markAsRead(String conversationID);

  /// Stream fired by SDK whenever the conversation list changes
  /// (new message / deletion / update).
  Stream<List<ConversationInfo>> get changes;
}
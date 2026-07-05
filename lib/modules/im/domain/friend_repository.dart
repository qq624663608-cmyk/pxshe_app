import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

/// Friends / friend requests / blacklist contract.
/// Implemented by `FriendRepositoryImpl`. Consumed by `FriendCubit`
/// and `ContactsPage`.
abstract class FriendRepository {
  Future<List<FriendInfo>> getFriendList();
  Future<List<FriendApplicationInfo>> getReceivedFriendRequests();

  Future<void> acceptRequest({required String fromUserID});
  Future<void> rejectRequest({required String fromUserID});

  Future<void> deleteFriend({required String userID});

  /// Search users by keyword (userID or nickname).
  Future<List<UserInfo>> searchUsers(String keyword);

  /// Stream of SDK friend events.
  Stream<void> get changes;
}
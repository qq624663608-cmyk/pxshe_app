import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

/// Group contract (joined groups, members, create / join / quit).
/// Implemented by `GroupRepositoryImpl`. Consumed by `GroupCubit`.
abstract class GroupRepository {
  /// All groups the current user has joined.
  Future<List<GroupInfo>> getJoinedGroups();

  /// Create a new group.
  Future<GroupInfo> create({
    required String groupName,
    required List<String> memberUserIDs,
    String? introduction,
  });

  /// Join a group by ID.
  Future<void> join({required String groupID, String? reason});

  /// Quit a group.
  Future<void> quit(String groupID);

  /// Get detailed info for one or more groups.
  Future<List<GroupInfo>> getInfo(List<String> groupIDs);

  /// Stream of group events (joined / quit / info changed).
  Stream<void> get changes;
}
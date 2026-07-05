import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/domain/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._wrapper);

  final OpenIMSDKWrapper _wrapper;
  final _changesController = StreamController<void>.broadcast();
  bool _listenerRegistered = false;

  @override
  Future<List<GroupInfo>> getJoinedGroups() async {
    final result = await _wrapper.manager.groupManager.getJoinedGroupList();
    return result ?? const <GroupInfo>[];
  }

  @override
  Future<GroupInfo> create({
    required String groupName,
    required List<String> memberUserIDs,
    String? introduction,
  }) {
    // SDK requires a fully-constructed `GroupInfo`. We pre-populate the
    // minimum required field and let the server fill the rest.
    return _wrapper.manager.groupManager.createGroup(
      groupInfo: GroupInfo(
        groupID: '',
        groupName: groupName,
        introduction: introduction,
      ),
      memberUserIDs: memberUserIDs,
    );
  }

  @override
  Future<void> join({required String groupID, String? reason}) {
    return _wrapper.manager.groupManager.joinGroup(
      groupID: groupID,
      reason: reason,
    );
  }

  @override
  Future<void> quit(String groupID) {
    return _wrapper.manager.groupManager.quitGroup(groupID: groupID);
  }

  @override
  Future<List<GroupInfo>> getInfo(List<String> groupIDs) async {
    final result =
        await _wrapper.manager.groupManager.getGroupsInfo(groupIDList: groupIDs);
    return result ?? const <GroupInfo>[];
  }

  @override
  Stream<void> get changes async* {
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      _wrapper.manager.groupManager.setGroupListener(
        OnGroupListener(
          onJoinedGroupAdded: (_) => _emit(),
          onJoinedGroupDeleted: (_) => _emit(),
          onGroupInfoChanged: (_) => _emit(),
          onGroupDismissed: (_) => _emit(),
        ),
      );
    }
    yield* _changesController.stream;
  }

  void _emit() {
    if (!_changesController.isClosed) {
      _changesController.add(null);
    }
  }

  void dispose() {
    _changesController.close();
  }
}
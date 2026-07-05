import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/data/repositories/group_repository_impl.dart';

class _MockWrapper extends Mock implements OpenIMSDKWrapper {}

class _MockManager extends Mock implements IMManager {}

class _MockGroupManager extends Mock implements GroupManager {}

void main() {
  late _MockWrapper wrapper;
  late _MockManager manager;
  late _MockGroupManager groupManager;

  setUpAll(() {
    registerFallbackValue(OnGroupListener());
    registerFallbackValue(GroupInfo(groupID: ''));
  });

  setUp(() {
    wrapper = _MockWrapper();
    manager = _MockManager();
    groupManager = _MockGroupManager();

    when(() => wrapper.manager).thenReturn(manager);
    when(() => manager.groupManager).thenReturn(groupManager);
  });

  group('GroupRepositoryImpl', () {
    test('getJoinedGroups() forwards to groupManager', () async {
      when(() => groupManager.getJoinedGroupList())
          .thenAnswer((_) async => [GroupInfo(groupID: 'g1', groupName: 'G1')]);

      final repo = GroupRepositoryImpl(wrapper);
      final list = await repo.getJoinedGroups();

      expect(list, hasLength(1));
      expect(list.first.groupID, 'g1');
    });

    test('getJoinedGroups() unwraps empty list', () async {
      when(() => groupManager.getJoinedGroupList())
          .thenAnswer((_) async => <GroupInfo>[]);

      final repo = GroupRepositoryImpl(wrapper);
      expect(await repo.getJoinedGroups(), isEmpty);
    });

    test('create() forwards groupInfo + members', () async {
      when(() => groupManager.createGroup(
            groupInfo: any(named: 'groupInfo'),
            memberUserIDs: any(named: 'memberUserIDs'),
            adminUserIDs: any(named: 'adminUserIDs'),
            ownerUserID: any(named: 'ownerUserID'),
          )).thenAnswer((_) async =>
          GroupInfo(groupID: 'g_new', groupName: 'New Group'));

      final repo = GroupRepositoryImpl(wrapper);
      final result = await repo.create(
        groupName: 'New Group',
        memberUserIDs: ['u1', 'u2'],
      );

      expect(result.groupID, 'g_new');
      verify(() => groupManager.createGroup(
            groupInfo: any(named: 'groupInfo'),
            memberUserIDs: ['u1', 'u2'],
            adminUserIDs: any(named: 'adminUserIDs'),
            ownerUserID: any(named: 'ownerUserID'),
          )).called(1);
    });

    test('join() forwards groupID + reason', () async {
      when(() => groupManager.joinGroup(
            groupID: any(named: 'groupID'),
            reason: any(named: 'reason'),
            joinSource: any(named: 'joinSource'),
            ex: any(named: 'ex'),
          )).thenAnswer((_) async {});

      final repo = GroupRepositoryImpl(wrapper);
      await repo.join(groupID: 'g1', reason: 'please');
      verify(() => groupManager.joinGroup(
            groupID: 'g1',
            reason: 'please',
            joinSource: any(named: 'joinSource'),
            ex: any(named: 'ex'),
          )).called(1);
    });

    test('quit() forwards groupID', () async {
      when(() => groupManager.quitGroup(groupID: any(named: 'groupID')))
          .thenAnswer((_) async {});

      final repo = GroupRepositoryImpl(wrapper);
      await repo.quit('g1');
      verify(() => groupManager.quitGroup(groupID: 'g1')).called(1);
    });

    test('getInfo() forwards groupIDList', () async {
      when(() => groupManager.getGroupsInfo(
              groupIDList: any(named: 'groupIDList')))
          .thenAnswer((_) async => [
            GroupInfo(groupID: 'g1'),
            GroupInfo(groupID: 'g2'),
          ]);

      final repo = GroupRepositoryImpl(wrapper);
      final results = await repo.getInfo(['g1', 'g2']);

      expect(results, hasLength(2));
    });

    test('changes stream registers listener exactly once', () async {
      when(() => groupManager.setGroupListener(any()))
          .thenAnswer((_) async {});

      final repo = GroupRepositoryImpl(wrapper);
      final sub1 = repo.changes.listen((_) {});
      final sub2 = repo.changes.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub1.cancel();
      await sub2.cancel();
      repo.dispose();

      verify(() => groupManager.setGroupListener(any())).called(1);
    });
  });
}
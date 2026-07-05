import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/data/repositories/friend_repository_impl.dart';

class _MockWrapper extends Mock implements OpenIMSDKWrapper {}

class _MockManager extends Mock implements IMManager {}

class _MockFriendshipManager extends Mock implements FriendshipManager {}

void main() {
  late _MockWrapper wrapper;
  late _MockManager manager;
  late _MockFriendshipManager friendshipManager;

  setUpAll(() {
    registerFallbackValue(OnFriendshipListener());
  });

  setUp(() {
    wrapper = _MockWrapper();
    manager = _MockManager();
    friendshipManager = _MockFriendshipManager();

    when(() => wrapper.manager).thenReturn(manager);
    when(() => manager.friendshipManager).thenReturn(friendshipManager);
  });

  group('FriendRepositoryImpl', () {
    test('getFriendList() forwards to friendshipManager', () async {
      when(() => friendshipManager.getFriendList())
          .thenAnswer((_) async => [FriendInfo(userID: 'u1')]);

      final repo = FriendRepositoryImpl(wrapper);
      final list = await repo.getFriendList();

      expect(list, hasLength(1));
      expect(list.first.userID, 'u1');
    });

    test('getReceivedFriendRequests() unwraps null list', () async {
      when(() => friendshipManager.getFriendApplicationListAsRecipient())
          .thenAnswer((_) async => <FriendApplicationInfo>[]);

      final repo = FriendRepositoryImpl(wrapper);
      expect(await repo.getReceivedFriendRequests(), isEmpty);
    });

    test('acceptRequest() forwards fromUserID via SDK `userID`', () async {
      when(() => friendshipManager.acceptFriendApplication(
              userID: any(named: 'userID'),
              handleMsg: any(named: 'handleMsg')))
          .thenAnswer((_) async {});

      final repo = FriendRepositoryImpl(wrapper);
      await repo.acceptRequest(fromUserID: 'alice');
      verify(() => friendshipManager.acceptFriendApplication(
          userID: 'alice', handleMsg: '')).called(1);
    });

    test('rejectRequest() forwards fromUserID via SDK `userID`', () async {
      when(() => friendshipManager.refuseFriendApplication(
              userID: any(named: 'userID'),
              handleMsg: any(named: 'handleMsg')))
          .thenAnswer((_) async {});

      final repo = FriendRepositoryImpl(wrapper);
      await repo.rejectRequest(fromUserID: 'eve');
      verify(() => friendshipManager.refuseFriendApplication(
          userID: 'eve', handleMsg: '')).called(1);
    });

    test('deleteFriend() forwards userID', () async {
      when(() => friendshipManager.deleteFriend(userID: any(named: 'userID')))
          .thenAnswer((_) async {});

      final repo = FriendRepositoryImpl(wrapper);
      await repo.deleteFriend(userID: 'u1');
      verify(() => friendshipManager.deleteFriend(userID: 'u1')).called(1);
    });

    test('searchUsers() converts SearchFriendsInfo → UserInfo', () async {
      // SearchFriendsInfo's constructor only accepts `relationship`; the
      // parent FriendInfo fields are set via direct field assignment.
      when(() => friendshipManager.searchFriends(
              keywordList: any(named: 'keywordList'),
              isSearchUserID: any(named: 'isSearchUserID'),
              isSearchNickname: any(named: 'isSearchNickname'),
            )).thenAnswer((_) async {
        final a = SearchFriendsInfo(relationship: 0)..userID = 'u1';
        final b = SearchFriendsInfo(relationship: 1)..userID = 'u2';
        return [a, b];
      });

      final repo = FriendRepositoryImpl(wrapper);
      final results = await repo.searchUsers('u');

      expect(results, hasLength(2));
      expect(results.first.userID, 'u1');
    });

    test('changes stream registers listener exactly once', () async {
      when(() => friendshipManager.setFriendshipListener(any()))
          .thenAnswer((_) async {});

      final repo = FriendRepositoryImpl(wrapper);
      final sub1 = repo.changes.listen((_) {});
      final sub2 = repo.changes.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub1.cancel();
      await sub2.cancel();
      repo.dispose();

      verify(() => friendshipManager.setFriendshipListener(any())).called(1);
    });
  });
}
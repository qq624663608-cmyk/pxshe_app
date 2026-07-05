import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/domain/friend_repository.dart';

class FriendRepositoryImpl implements FriendRepository {
  FriendRepositoryImpl(this._wrapper);

  final OpenIMSDKWrapper _wrapper;
  final _changesController = StreamController<void>.broadcast();
  bool _listenerRegistered = false;

  @override
  Future<List<FriendInfo>> getFriendList() async {
    return _wrapper.manager.friendshipManager.getFriendList();
  }

  @override
  Future<List<FriendApplicationInfo>> getReceivedFriendRequests() async {
    return _wrapper.manager.friendshipManager
        .getFriendApplicationListAsRecipient();
  }

  @override
  Future<void> acceptRequest({required String fromUserID}) {
    // SDK signature: `acceptFriendApplication({required String userID, ...})`.
    // `userID` is the initiator (i.e. our `fromUserID`); SDK maps it to
    // `toUserID` internally.
    return _wrapper.manager.friendshipManager.acceptFriendApplication(
      userID: fromUserID,
      handleMsg: '',
    );
  }

  @override
  Future<void> rejectRequest({required String fromUserID}) {
    return _wrapper.manager.friendshipManager.refuseFriendApplication(
      userID: fromUserID,
      handleMsg: '',
    );
  }

  @override
  Future<void> deleteFriend({required String userID}) {
    return _wrapper.manager.friendshipManager.deleteFriend(userID: userID);
  }

  @override
  Future<List<UserInfo>> searchUsers(String keyword) async {
    final result = await _wrapper.manager.friendshipManager.searchFriends(
      keywordList: [keyword],
      isSearchUserID: true,
      isSearchNickname: true,
    );
    // SearchFriendsInfo extends FriendInfo, so it has `userID`/`nickname`
    // fields. Treat them as UserInfo via the parent fields.
    return result
        .map((info) => UserInfo(
              userID: info.userID,
              nickname: info.nickname,
              faceURL: info.faceURL,
            ))
        .toList();
  }

  @override
  Stream<void> get changes async* {
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      _wrapper.manager.friendshipManager.setFriendshipListener(
        OnFriendshipListener(
          onFriendAdded: (_) {
            if (!_changesController.isClosed) {
              _changesController.add(null);
            }
          },
          onFriendDeleted: (_) {
            if (!_changesController.isClosed) {
              _changesController.add(null);
            }
          },
          onFriendApplicationAccepted: (_) {
            if (!_changesController.isClosed) {
              _changesController.add(null);
            }
          },
          onFriendApplicationRejected: (_) {
            if (!_changesController.isClosed) {
              _changesController.add(null);
            }
          },
          onFriendApplicationAdded: (_) {
            if (!_changesController.isClosed) {
              _changesController.add(null);
            }
          },
          onFriendApplicationDeleted: (_) {
            if (!_changesController.isClosed) {
              _changesController.add(null);
            }
          },
          onBlackAdded: (_) {
            if (!_changesController.isClosed) {
              _changesController.add(null);
            }
          },
          onBlackDeleted: (_) {
            if (!_changesController.isClosed) {
              _changesController.add(null);
            }
          },
        ),
      );
    }
    yield* _changesController.stream;
  }

  void dispose() {
    _changesController.close();
  }
}
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/modules/im/domain/friend_repository.dart';

class FriendCubit extends Cubit<FriendState> {
  FriendCubit(this._repo) : super(const FriendState.initial()) {
    _changesSub = _repo.changes.listen((_) => load());
  }

  final FriendRepository _repo;
  late final StreamSubscription<void> _changesSub;

  Future<void> load() async {
    emit(state.copyWith(status: FriendStatus.loading));
    try {
      final friends = await _repo.getFriendList();
      final requests = await _repo.getReceivedFriendRequests();
      emit(state.copyWith(
        status: FriendStatus.loaded,
        friends: friends,
        requests: requests,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: FriendStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> accept({required String fromUserID}) async {
    await _repo.acceptRequest(fromUserID: fromUserID);
    await load();
  }

  Future<void> reject({required String fromUserID}) async {
    await _repo.rejectRequest(fromUserID: fromUserID);
    await load();
  }

  @override
  Future<void> close() async {
    await _changesSub.cancel();
    await super.close();
  }
}

enum FriendStatus { initial, loading, loaded, error }

class FriendState extends Equatable {
  const FriendState({
    this.status = FriendStatus.initial,
    this.friends = const [],
    this.requests = const [],
    this.error,
  });
  const FriendState.initial() : this();

  final FriendStatus status;
  final List<FriendInfo> friends;
  final List<FriendApplicationInfo> requests;
  final String? error;

  FriendState copyWith({
    FriendStatus? status,
    List<FriendInfo>? friends,
    List<FriendApplicationInfo>? requests,
    String? error,
  }) =>
      FriendState(
        status: status ?? this.status,
        friends: friends ?? this.friends,
        requests: requests ?? this.requests,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, friends, requests, error];
}
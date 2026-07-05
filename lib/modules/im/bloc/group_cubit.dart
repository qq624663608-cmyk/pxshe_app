import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/modules/im/domain/group_repository.dart';

class GroupCubit extends Cubit<GroupState> {
  GroupCubit(this._repo) : super(const GroupState.initial()) {
    _changesSub = _repo.changes.listen((_) => load());
  }

  final GroupRepository _repo;
  late final StreamSubscription<void> _changesSub;

  Future<void> load() async {
    emit(state.copyWith(status: GroupStatus.loading));
    try {
      final groups = await _repo.getJoinedGroups();
      emit(state.copyWith(status: GroupStatus.loaded, groups: groups));
    } on Exception catch (e) {
      emit(state.copyWith(status: GroupStatus.error, error: e.toString()));
    }
  }

  Future<void> create({
    required String name,
    required List<String> memberUserIDs,
  }) async {
    final info = await _repo.create(
      groupName: name,
      memberUserIDs: memberUserIDs,
    );
    emit(state.copyWith(groups: [...state.groups, info]));
  }

  Future<void> join({required String groupID, String? reason}) async {
    await _repo.join(groupID: groupID, reason: reason);
    await load();
  }

  Future<void> quit(String groupID) async {
    await _repo.quit(groupID);
    await load();
  }

  @override
  Future<void> close() async {
    await _changesSub.cancel();
    await super.close();
  }
}

enum GroupStatus { initial, loading, loaded, error }

class GroupState extends Equatable {
  const GroupState({
    this.status = GroupStatus.initial,
    this.groups = const [],
    this.error,
  });
  const GroupState.initial() : this();

  final GroupStatus status;
  final List<GroupInfo> groups;
  final String? error;

  GroupState copyWith({
    GroupStatus? status,
    List<GroupInfo>? groups,
    String? error,
  }) =>
      GroupState(
        status: status ?? this.status,
        groups: groups ?? this.groups,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, groups, error];
}
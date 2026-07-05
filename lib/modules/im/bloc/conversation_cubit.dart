import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/modules/im/domain/conversation_repository.dart';

class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit(this._repo) : super(const ConversationState.initial()) {
    _changesSub = _repo.changes.listen(_onChanges);
  }

  final ConversationRepository _repo;
  late final StreamSubscription<List<ConversationInfo>> _changesSub;

  Future<void> load() async {
    emit(state.copyWith(status: ConversationStatus.loading));
    try {
      final list = await _repo.getAll();
      emit(state.copyWith(
        status: ConversationStatus.loaded,
        items: list,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: ConversationStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> markRead(String conversationID) async {
    await _repo.markAsRead(conversationID);
    await load();
  }

  void _onChanges(List<ConversationInfo> list) {
    emit(state.copyWith(items: list));
  }

  @override
  Future<void> close() async {
    await _changesSub.cancel();
    await super.close();
  }
}

enum ConversationStatus { initial, loading, loaded, error }

class ConversationState extends Equatable {
  const ConversationState({
    this.status = ConversationStatus.initial,
    this.items = const [],
    this.error,
  });
  const ConversationState.initial() : this();

  final ConversationStatus status;
  final List<ConversationInfo> items;
  final String? error;

  ConversationState copyWith({
    ConversationStatus? status,
    List<ConversationInfo>? items,
    String? error,
  }) =>
      ConversationState(
        status: status ?? this.status,
        items: items ?? this.items,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, items, error];
}
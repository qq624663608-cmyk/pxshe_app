import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pxshe_app/modules/im/domain/im_auth_repository.dart';

/// Connection lifecycle surfaced to UI as a Cubit — UI watches
/// [ConnectionCubit] to render the "重连中..." banner (IM_INTEGRATION
/// §5.2 / AGENTS §32).
class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit(this._repo) : super(const ConnectionState.initial()) {
    _sub = _repo.connectionEvents.listen(_onEvent);
  }

  final ImAuthRepository _repo;
  late final StreamSubscription<ImConnectionEvent> _sub;

  void _onEvent(ImConnectionEvent event) {
    switch (event) {
      case ImConnectionEvent.connecting:
        emit(state.copyWith(status: ConnectionStatus.connecting));
      case ImConnectionEvent.connected:
        emit(state.copyWith(status: ConnectionStatus.connected));
      case ImConnectionEvent.disconnected:
        emit(state.copyWith(status: ConnectionStatus.disconnected));
      case ImConnectionEvent.kickedOffline:
        emit(state.copyWith(status: ConnectionStatus.kickedOffline));
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    await super.close();
  }
}

enum ConnectionStatus {
  initial,
  connecting,
  connected,
  disconnected,
  kickedOffline,
}

class ConnectionState extends Equatable {
  const ConnectionState({this.status = ConnectionStatus.initial});
  const ConnectionState.initial() : this();

  final ConnectionStatus status;

  ConnectionState copyWith({ConnectionStatus? status}) =>
      ConnectionState(status: status ?? this.status);

  @override
  List<Object?> get props => [status];
}
import 'dart:async';

/// IM authentication / lifecycle contract.
///
/// Implemented by `ImAuthRepositoryImpl`. Consumed by ConnectionCubit +
/// future LoginBloc. Methods stay SDK-agnostic so the repository impl is
/// the only file that knows about `flutter_openim_sdk`.
abstract class ImAuthRepository {
  /// Whether `init()` has already been called successfully.
  bool get isInitialised;

  /// Initialise the SDK. Idempotent — safe to call twice.
  Future<void> init();

  /// Login with the imToken obtained from the business server.
  Future<void> login({required String userID, required String imToken});

  /// Tear-down. Called on logout / module dispose.
  Future<void> logout();

  /// Stream of connection lifecycle events surfaced by the SDK's
  /// `OnConnectListener`. UI subscribes via `ConnectionCubit`.
  Stream<ImConnectionEvent> get connectionEvents;
}

/// Lifecycle events surfaced by the SDK's `OnConnectListener` (mapped to
/// a single enum so Bloc / UI can switch on it).
enum ImConnectionEvent { connecting, connected, disconnected, kickedOffline }
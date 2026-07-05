import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pxshe_app/_core/logger.dart';
import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/domain/im_auth_repository.dart';

/// Implementation backed by [OpenIMSDKWrapper]. Holds SDK init state and
/// bridges `OnConnectListener` callbacks into a broadcast [Stream] of
/// [ImConnectionEvent] values.
class ImAuthRepositoryImpl extends ChangeNotifier
    implements ImAuthRepository {
  ImAuthRepositoryImpl(this._wrapper);

  final OpenIMSDKWrapper _wrapper;

  bool _initialised = false;
  @override
  bool get isInitialised => _initialised;

  final _connectionController =
      StreamController<ImConnectionEvent>.broadcast();

  @override
  Stream<ImConnectionEvent> get connectionEvents =>
      _connectionController.stream;

  @override
  Future<void> init() async {
    if (_initialised) return;

    final docs = await getApplicationDocumentsDirectory();
    final dataDir = '${docs.path}${Platform.pathSeparator}';

    await _wrapper.initSDK(
      platformID: _platformID(),
      apiAddr: _apiAddr(),
      wsAddr: _wsAddr(),
      dataDir: dataDir,
      listener: _bridge(),
    );

    _initialised = true;
    Log.i('ImAuthRepositoryImpl: SDK initialised at $dataDir');
  }

  @override
  Future<void> login({required String userID, required String imToken}) async {
    Log.i('ImAuthRepositoryImpl.login user=$userID');
    await _wrapper.login(userID: userID, imToken: imToken);
  }

  @override
  Future<void> logout() async {
    if (!_initialised) return;
    await _wrapper.logout();
  }

  /// Build a bridge from `OnConnectListener` callbacks to the broadcast
  /// stream of [ImConnectionEvent].
  OnConnectListener _bridge() => OnConnectListener(
        onConnecting: () => _emit(ImConnectionEvent.connecting),
        onConnectSuccess: () => _emit(ImConnectionEvent.connected),
        onConnectFailed: (_, __) => _emit(ImConnectionEvent.disconnected),
        onKickedOffline: () => _emit(ImConnectionEvent.kickedOffline),
        onUserTokenExpired: () => _emit(ImConnectionEvent.kickedOffline),
        onUserTokenInvalid: () => _emit(ImConnectionEvent.kickedOffline),
      );

  void _emit(ImConnectionEvent event) {
    if (_connectionController.isClosed) return;
    _connectionController.add(event);
  }

  int _platformID() {
    // Override at compile time with --dart-define=IM_PLATFORM_ID=...
    return const int.fromEnvironment('IM_PLATFORM_ID', defaultValue: 2);
  }

  String _apiAddr() {
    return const String.fromEnvironment(
      'IM_API_ADDR',
      defaultValue: 'https://api.pxshe.com:10002',
    );
  }

  String _wsAddr() {
    return const String.fromEnvironment(
      'IM_WS_ADDR',
      defaultValue: 'wss://api.pxshe.com:10002',
    );
  }

  @override
  void dispose() {
    _connectionController.close();
    if (_initialised) _wrapper.unInit();
    super.dispose();
  }
}
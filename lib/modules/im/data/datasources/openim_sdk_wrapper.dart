import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/_core/logger.dart';

/// Thin wrapper around `OpenIM.iMManager` — the only file in the im module
/// that imports `flutter_openim_sdk` directly (per IM_INTEGRATION §4 +
/// AGENTS §18). Business code (Bloc / Page / Repository) must depend on
/// this class instead.
///
/// API surface is intentionally minimal: only what phase 2.1 needs.
class OpenIMSDKWrapper {
  OpenIMSDKWrapper();

  IMManager get manager => OpenIM.iMManager;

  /// Initialise the SDK and register the connection listener.
  /// See docs/IM_API_MAP.md §IMManager.initSDK.
  Future<dynamic> initSDK({
    required int platformID,
    required String apiAddr,
    required String wsAddr,
    required String dataDir,
    required OnConnectListener listener,
  }) {
    Log.i('OpenIMSDKWrapper.initSDK platform=$platformID api=$apiAddr');
    return manager.initSDK(
      platformID: platformID,
      apiAddr: apiAddr,
      wsAddr: wsAddr,
      dataDir: dataDir,
      listener: listener,
    );
  }

  /// Login with the imToken obtained from the business server's
  /// `POST /account/login` response.
  Future<UserInfo> login({required String userID, required String imToken}) {
    return manager.login(userID: userID, token: imToken);
  }

  Future<dynamic> logout() => manager.logout();

  void unInit() => manager.unInitSDK();
}
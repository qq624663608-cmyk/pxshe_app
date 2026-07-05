/// Environment configuration for the three-domain backend architecture
/// (`chat.pxshe.com` for chat-api, `api.pxshe.com` for openim-server,
/// `admin.pxshe.com` for admin-api). Override any value with
/// `--dart-define=KEY=VALUE` when running or building the app.
///
/// See docs/IM_INTEGRATION.md §9 for the network protocol details.
class Env {
  Env._();

  /// Base URL for chat.pxshe.com (chat-api) — primary Flutter HTTP API.
  static final String chatBase = const String.fromEnvironment(
    'CHAT_BASE',
    defaultValue: 'https://chat.pxshe.com',
  );

  /// Base URL for api.pxshe.com (openim-server) — used by
  /// `flutter_openim_sdk` internally. Flutter business code MUST NOT call
  /// this domain directly; only the SDK speaks to it (AGENTS §15).
  static final String openimBase = const String.fromEnvironment(
    'OPENIM_BASE',
    defaultValue: 'https://api.pxshe.com',
  );

  /// Base URL for admin.pxshe.com (admin-api) — super-admin tools only.
  /// Flutter clients MUST NOT call this domain.
  static final String adminBase = const String.fromEnvironment(
    'ADMIN_BASE',
    defaultValue: 'https://admin.pxshe.com',
  );

  /// @Deprecated('Use chatBase directly. Will remove in v2.0.')
  /// Kept for backward compatibility with the legacy single-base
  /// configuration.
  static final String apiBase = chatBase;
}
import 'package:pxshe_app/modules/auth/domain/auth_repository.dart';

/// Thin bridge from the im module to the auth module. Avoids cross-module
/// imports of internals (ADR-0005). Registered as a wrapper around the
/// singleton [AuthRepository].
class AuthModuleBridge {
  AuthModuleBridge(this._repo);

  final AuthRepository _repo;

  String? get imToken => _repo.imToken;
  String? get userId => _repo.userId;

  /// Snapshot of the currently-authenticated session (no Hive / no SDK).
  ({String? userId, String? imToken}) cachedSession() =>
      (userId: _repo.userId, imToken: _repo.imToken);
}
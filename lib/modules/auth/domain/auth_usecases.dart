import 'package:dartz/dartz.dart';

import '../../../_core/error/failures.dart';
import 'auth_repository.dart';
import 'user.dart';

class AuthUsecases {
  AuthUsecases(this._authRepository);

  final AuthRepository _authRepository;

  Stream<User> get userStream => _authRepository.userStream;
  String? get chatToken => _authRepository.chatToken;
  String? get imToken => _authRepository.imToken;
  String? get userId => _authRepository.userId;

  Future<Either<Failure, User>> login({
    required String areaCode,
    required String phoneNumber,
    required String password,
    required int platform,
  }) {
    return _authRepository.login(
      areaCode: areaCode,
      phoneNumber: phoneNumber,
      password: password,
      platform: platform,
    );
  }

  Future<User?> loadCachedSession() => _authRepository.loadCachedSession();

  Future<void> logout() => _authRepository.logout();

  void dispose() => _authRepository.dispose();
}
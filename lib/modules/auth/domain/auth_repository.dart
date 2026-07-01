import 'package:dartz/dartz.dart';

import '../../../_core/error/failures.dart';
import 'user.dart';

abstract class AuthRepository {
  Stream<User> get userStream;
  String? get chatToken;
  String? get imToken;
  String? get userId;

  Future<Either<Failure, User>> login({
    required String areaCode,
    required String phoneNumber,
    required String password,
    required int platform,
  });

  Future<User?> loadCachedSession();
  Future<void> logout();
  void dispose();
}
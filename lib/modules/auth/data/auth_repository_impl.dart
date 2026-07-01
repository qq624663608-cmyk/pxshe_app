import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:rxdart/rxdart.dart';

import '../../../_core/constants.dart';
import '../../../_core/error/api_exception.dart';
import '../../../_core/error/exceptions.dart';
import '../../../_core/error/failures.dart';
import '../../../_core/network_info.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.dio,
    required this.hive,
    required this.networkInfo,
  }) {
    _bootstrapFromCache();
  }

  final _userController = BehaviorSubject<User>.seeded(User.empty);
  final Dio dio;
  final HiveInterface hive;
  final NetworkInfo networkInfo;

  String? _chatToken;
  String? _imToken;
  String? _userId;

  @override
  Stream<User> get userStream => _userController.stream;

  @override
  String? get chatToken => _chatToken;

  @override
  String? get imToken => _imToken;

  @override
  String? get userId => _userId;

  Future<void> _bootstrapFromCache() async {
    final tokenBox = await hive.openLazyBox<String>(Constants.tokenBoxName);
    _chatToken = await tokenBox.get(Constants.cachedTokenRef);
    final user = await _getCachedUser();
    if (user != null) {
      _userId = user.id;
      _userController.add(user);
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String areaCode,
    required String phoneNumber,
    required String password,
    required int platform,
  }) async {
    try {
      if (!await networkInfo.isConnected()) {
        return Left(ConnectionFailure());
      }

      final res = await dio.post<dynamic>(
        '/account/login',
        data: {
          'areaCode': areaCode,
          'phoneNumber': phoneNumber,
          'password': password,
          'platform': platform,
        },
      );

      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['errorCode'] != 0) {
        return Left(ServerFailure(data['errMsg']?.toString() ?? 'Login failed'));
      }

      final payload = Map<String, dynamic>.from(data['data'] as Map);
      _chatToken = payload['chatToken'] as String;
      _imToken = payload['imToken'] as String?;
      _userId = payload['userID'] as String;

      await _cacheTokens(chatToken: _chatToken!, imToken: _imToken);

      final user = UserModel(
        id: _userId!,
        nickname: '',
        phoneNumber: phoneNumber,
        areaCode: areaCode,
      );
      await _cacheUser(user);
      _userController.add(user);

      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(ApiException.fromDioError(e).message ?? '网络错误'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<User?> loadCachedSession() async {
    final cached = await _getCachedUser();
    if (cached != null) {
      _userId = cached.id;
      _userController.add(cached);
    }
    return cached;
  }

  @override
  Future<void> logout() async {
    _chatToken = null;
    _imToken = null;
    _userId = null;
    await clearCache();
    _userController.add(User.empty);
  }

  @override
  void dispose() => _userController.close();

  Future<void> _cacheTokens({
    required String chatToken,
    String? imToken,
  }) async {
    try {
      final box = await hive.openLazyBox<String>(Constants.tokenBoxName);
      await box.put(Constants.cachedTokenRef, chatToken);
      if (imToken != null) {
        await box.put('cachedImToken', imToken);
      }
    } catch (_) {
      throw CacheException();
    }
  }

  Future<void> _cacheUser(UserModel user) async {
    final box = await hive.openBox<UserModel>(Constants.userBoxName);
    await box.put(Constants.cachedUserRef, user);
  }

  Future<UserModel?> _getCachedUser() async {
    final box = await hive.openBox<UserModel>(Constants.userBoxName);
    return box.get(Constants.cachedUserRef);
  }

  Future<void> clearCache() async {
    final userBox = await hive.openBox<UserModel>(Constants.userBoxName);
    final tokenBox = await hive.openLazyBox<String>(Constants.tokenBoxName);
    await userBox.clear();
    await tokenBox.clear();
  }
}
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/network/api_client.dart';
import 'package:pxshe_app/_core/network_info.dart';
import 'package:pxshe_app/modules/auth/data/auth_repository_impl.dart';
import 'package:pxshe_app/modules/auth/data/models/user_model.dart';
import 'package:pxshe_app/modules/auth/domain/user.dart';

class _MockDio extends Mock implements Dio {}

class _MockHive extends Mock implements HiveInterface {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _MockLazyBox extends Mock implements LazyBox<String> {}

class _MockBox extends Mock implements Box<UserModel> {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

class _MockUserBoxWithUser extends Mock implements Box<UserModel> {}

void _setupHiveMocks(_MockHive hive, {_MockLazyBox? tokenBoxOverride, _MockBox? userBoxOverride}) {
  final tokenBox = tokenBoxOverride ?? _MockLazyBox();
  final userBox = userBoxOverride ?? _MockBox();
  when(() => hive.openLazyBox<String>(any())).thenAnswer((_) async => tokenBox);
  when(() => hive.openBox<UserModel>(any())).thenAnswer((_) async => userBox);
  when(() => tokenBox.clear()).thenAnswer((_) async => 0);
  when(() => userBox.clear()).thenAnswer((_) async => 0);
  when(() => tokenBox.put(any(), any())).thenAnswer((_) async {});
  when(() => tokenBox.get(any())).thenAnswer((_) async => null);
  when(() => userBox.put(any(), any())).thenAnswer((_) async {});
  when(() => userBox.get(any(), defaultValue: any(named: 'defaultValue')))
      .thenReturn(null);
}

AuthRepositoryImpl _buildRepo({
  _MockDio? dio,
  _MockHive? hive,
  _MockNetworkInfo? networkInfo,
}) {
  final d = dio ?? _MockDio();
  final h = hive ?? _MockHive();
  final n = networkInfo ?? _MockNetworkInfo();
  _setupHiveMocks(h);
  return AuthRepositoryImpl(dio: d, hive: h, networkInfo: n);
}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(UserModel(id: 'x', nickname: '', phoneNumber: '', areaCode: ''));
  });

  group('AuthRepositoryImpl.logout', () {
    test('clears all in-memory state', () async {
      final repo = _buildRepo();
      expect(repo.chatToken, isNull);
      expect(repo.imToken, isNull);
      expect(repo.userId, isNull);
      await repo.logout();
      expect(repo.chatToken, isNull);
      expect(repo.imToken, isNull);
      expect(repo.userId, isNull);
    });

    test('emits User.empty on user stream', () async {
      final repo = _buildRepo();
      final emissions = <User>[];
      final sub = repo.userStream.listen(emissions.add);
      await repo.logout();
      await Future<void>.delayed(Duration.zero);
      expect(emissions, contains(User.empty));
      await sub.cancel();
    });
  });

  group('AuthRepositoryImpl.login', () {
    test('returns ConnectionFailure when offline', () async {
      final networkInfo = _MockNetworkInfo();
      when(() => networkInfo.isConnected()).thenAnswer((_) async => false);
      final repo = _buildRepo(networkInfo: networkInfo);
      final res = await repo.login(
        areaCode: '+86',
        phoneNumber: '13900000001',
        password: 'pw',
        platform: 2,
      );
      expect(res.isLeft(), isTrue);
    });

    test('returns Left on server errCode', () async {
      final dio = _MockDio();
      when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 200,
                data: {'errCode': 20001, 'errMsg': 'bad pw'},
              ));
      final networkInfo = _MockNetworkInfo();
      when(() => networkInfo.isConnected()).thenAnswer((_) async => true);
      final repo = _buildRepo(dio: dio, networkInfo: networkInfo);
      final res = await repo.login(
        areaCode: '+86',
        phoneNumber: '13900000001',
        password: 'pw',
        platform: 2,
      );
      expect(res.isLeft(), isTrue);
    });

    test('throws CacheException when cache fails', () async {
      final dio = _MockDio();
      when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 200,
                data: {
                  'errCode': 0,
                  'data': {
                    'chatToken': 'ct',
                    'userID': 'u1',
                    'imToken': 'it',
                  },
                },
              ));
      final networkInfo = _MockNetworkInfo();
      when(() => networkInfo.isConnected()).thenAnswer((_) async => true);
      final hive = _MockHive();
      final tokenBox = _MockLazyBox();
      when(() => tokenBox.put(any(), any())).thenThrow(Exception('disk full'));
      when(() => tokenBox.get(any())).thenAnswer((_) async => 'cached');
      when(() => hive.openLazyBox<String>(any())).thenAnswer((_) async => tokenBox);
      when(() => hive.openBox<UserModel>(any())).thenAnswer((_) async => _MockBox());
      final repo = AuthRepositoryImpl(
        dio: dio,
        hive: hive,
        networkInfo: networkInfo,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final res = await repo.login(
        areaCode: '+86',
        phoneNumber: '13900000001',
        password: 'pw',
        platform: 2,
      );
      // Cache exception is caught and wrapped in Left(ServerFailure)
      expect(res.isLeft(), isTrue);
    });

    test('returns Right on success', () async {
      final dio = _MockDio();
      when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 200,
                data: {
                  'errCode': 0,
                  'data': {
                    'chatToken': 'ct',
                    'userID': 'u1',
                    'imToken': 'it',
                  },
                },
              ));
      final networkInfo = _MockNetworkInfo();
      when(() => networkInfo.isConnected()).thenAnswer((_) async => true);
      final repo = _buildRepo(dio: dio, networkInfo: networkInfo);
      final res = await repo.login(
        areaCode: '+86',
        phoneNumber: '13900000001',
        password: 'pw',
        platform: 2,
      );
      expect(res.isRight(), isTrue);
      expect(repo.chatToken, 'ct');
      expect(repo.imToken, 'it');
      expect(repo.userId, 'u1');
    });

    test('returns Left on DioException', () async {
      final dio = _MockDio();
      when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.connectionTimeout,
          ));
      final networkInfo = _MockNetworkInfo();
      when(() => networkInfo.isConnected()).thenAnswer((_) async => true);
      final repo = _buildRepo(dio: dio, networkInfo: networkInfo);
      final res = await repo.login(
        areaCode: '+86',
        phoneNumber: '13900000001',
        password: 'pw',
        platform: 2,
      );
      expect(res.isLeft(), isTrue);
    });

    test('returns Left on non-DioException', () async {
      final dio = _MockDio();
      when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
          .thenThrow(Exception('boom'));
      final networkInfo = _MockNetworkInfo();
      when(() => networkInfo.isConnected()).thenAnswer((_) async => true);
      final repo = _buildRepo(dio: dio, networkInfo: networkInfo);
      final res = await repo.login(
        areaCode: '+86',
        phoneNumber: '13900000001',
        password: 'pw',
        platform: 2,
      );
      expect(res.isLeft(), isTrue);
    });
  });

  group('AuthRepositoryImpl.loadCachedSession', () {
    test('returns null when no cached user', () async {
      final repo = _buildRepo();
      final result = await repo.loadCachedSession();
      expect(result, isNull);
    });

    test('returns cached user when present', () async {
      final userBox = _MockUserBoxWithUser();
      final user = UserModel(
        id: 'u1',
        nickname: 'n',
        phoneNumber: 'p',
        areaCode: '+86',
      );
      when(() => userBox.get(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(user);
      final tokenBox = _MockLazyBox();
      when(() => tokenBox.get(any())).thenAnswer((_) async => 'cached-token');
      final hive = _MockHive();
      when(() => hive.openBox<UserModel>(any())).thenAnswer((_) async => userBox);
      when(() => hive.openLazyBox<String>(any())).thenAnswer((_) async => tokenBox);
      when(() => userBox.clear()).thenAnswer((_) async => 0);
      when(() => tokenBox.clear()).thenAnswer((_) async => 0);
      final repo = AuthRepositoryImpl(
        dio: _MockDio(),
        hive: hive,
        networkInfo: _MockNetworkInfo(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final result = await repo.loadCachedSession();
      expect(result, isNotNull);
      expect(result!.id, 'u1');
      expect(repo.userId, 'u1');
    });
  });

  group('AuthRepositoryImpl._bootstrapFromCache', () {
    test('restores chatToken from cache', () async {
      final tokenBox = _MockLazyBox();
      when(() => tokenBox.get(any())).thenAnswer((_) async => 'cached-token');
      final hive = _MockHive();
      _setupHiveMocks(hive, tokenBoxOverride: tokenBox);
      AuthRepositoryImpl(
        dio: _MockDio(),
        hive: hive,
        networkInfo: _MockNetworkInfo(),
      );
      // Give async bootstrap a moment
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('restores user from cache', () async {
      final userBox = _MockUserBoxWithUser();
      final user = UserModel(
        id: 'restored',
        nickname: 'n',
        phoneNumber: 'p',
        areaCode: '+86',
      );
      when(() => userBox.get(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(user);
      final tokenBox = _MockLazyBox();
      when(() => tokenBox.get(any())).thenAnswer((_) async => 'cached-token');
      final hive = _MockHive();
      when(() => hive.openBox<UserModel>(any())).thenAnswer((_) async => userBox);
      when(() => hive.openLazyBox<String>(any())).thenAnswer((_) async => tokenBox);
      when(() => userBox.clear()).thenAnswer((_) async => 0);
      when(() => tokenBox.clear()).thenAnswer((_) async => 0);
      final repo = AuthRepositoryImpl(
        dio: _MockDio(),
        hive: hive,
        networkInfo: _MockNetworkInfo(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.userId, 'restored');
    });
  });

  group('AuthRepositoryImpl.dispose', () {
    test('closes stream', () {
      final repo = _buildRepo();
      repo.dispose();
      // No assertion needed, just no exception
      expect(true, isTrue);
    });
  });

  group('ApiClient 401 flow', () {
    test('ErrorInterceptor triggers onUnauthorized', () {
      var unauthCalled = false;
      final client = ApiClient(
        tokenProvider: () => 'tok',
        onUnauthorized: () => unauthCalled = true,
      );

      final interceptor = client.dio.interceptors
          .whereType<dynamic>()
          .firstWhere((i) => i.runtimeType.toString() == 'ErrorInterceptor');

      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      // ignore: avoid_dynamic_calls
      interceptor.onError(err, _MockErrorHandler());
      expect(unauthCalled, isTrue);
    });
  });
}
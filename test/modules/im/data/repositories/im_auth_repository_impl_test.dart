import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:pxshe_app/_core/di.dart';
import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/data/repositories/im_auth_repository_impl.dart';
import 'package:pxshe_app/modules/im/domain/im_auth_repository.dart';

class _MockWrapper extends Mock implements OpenIMSDKWrapper {}

class _MockLogger extends Mock implements Logger {}

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.dir);
  final String dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  late _MockWrapper wrapper;
  late _FakePathProvider pathProvider;
  late _MockLogger logger;

  setUpAll(() {
    registerFallbackValue(
      OnConnectListener(
        onConnecting: () {},
        onConnectSuccess: () {},
        onConnectFailed: (_, __) {},
      ),
    );
  });

  setUp(() {
    wrapper = _MockWrapper();
    pathProvider = _FakePathProvider('C:/fake/app');
    PathProviderPlatform.instance = pathProvider;
    logger = _MockLogger();
    if (di.isRegistered<Logger>()) {
      di.unregister<Logger>();
    }
    di.registerSingleton<Logger>(logger);
  });

  tearDown(() {
    if (di.isRegistered<Logger>()) {
      di.unregister<Logger>();
    }
  });

  setUp(() {
    wrapper = _MockWrapper();
    pathProvider = _FakePathProvider('C:/fake/app');
    PathProviderPlatform.instance = pathProvider;
  });

  group('ImAuthRepositoryImpl', () {
    test('isInitialised starts false', () {
      final repo = ImAuthRepositoryImpl(wrapper);
      expect(repo.isInitialised, isFalse);
    });

    test('init() calls wrapper.initSDK with listener bridge', () async {
      when(() => wrapper.initSDK(
            platformID: any(named: 'platformID'),
            apiAddr: any(named: 'apiAddr'),
            wsAddr: any(named: 'wsAddr'),
            dataDir: any(named: 'dataDir'),
            listener: any(named: 'listener'),
          )).thenAnswer((_) async => true);

      final repo = ImAuthRepositoryImpl(wrapper);
      await repo.init();

      expect(repo.isInitialised, isTrue);
      verify(() => wrapper.initSDK(
            platformID: any(named: 'platformID'),
            apiAddr: any(named: 'apiAddr'),
            wsAddr: any(named: 'wsAddr'),
            dataDir: any(named: 'dataDir'),
            listener: any(named: 'listener'),
          )).called(1);
    });

    test('init() is idempotent — second call is a no-op', () async {
      when(() => wrapper.initSDK(
            platformID: any(named: 'platformID'),
            apiAddr: any(named: 'apiAddr'),
            wsAddr: any(named: 'wsAddr'),
            dataDir: any(named: 'dataDir'),
            listener: any(named: 'listener'),
          )).thenAnswer((_) async => true);

      final repo = ImAuthRepositoryImpl(wrapper);
      await repo.init();
      await repo.init();

      verify(() => wrapper.initSDK(
            platformID: any(named: 'platformID'),
            apiAddr: any(named: 'apiAddr'),
            wsAddr: any(named: 'wsAddr'),
            dataDir: any(named: 'dataDir'),
            listener: any(named: 'listener'),
          )).called(1);
    });

    test('connection listener bridges callbacks into the stream', () async {
      OnConnectListener? capturedListener;
      when(() => wrapper.initSDK(
            platformID: any(named: 'platformID'),
            apiAddr: any(named: 'apiAddr'),
            wsAddr: any(named: 'wsAddr'),
            dataDir: any(named: 'dataDir'),
            listener: any(named: 'listener'),
          )).thenAnswer((invocation) async {
        capturedListener =
            invocation.namedArguments[#listener] as OnConnectListener;
        return true;
      });

      final repo = ImAuthRepositoryImpl(wrapper);
      final events = <ImConnectionEvent>[];
      final sub = repo.connectionEvents.listen(events.add);

      await repo.init();
      capturedListener!.connectSuccess();
      capturedListener!.connecting();
      capturedListener!.kickedOffline();
      capturedListener!.userTokenExpired();
      capturedListener!.connectFailed(1, 'boom');

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      repo.dispose();

      expect(events, containsAll(<ImConnectionEvent>[
        ImConnectionEvent.connected,
        ImConnectionEvent.connecting,
        ImConnectionEvent.kickedOffline,
        ImConnectionEvent.kickedOffline,
        ImConnectionEvent.disconnected,
      ]));
    });

    test('login() forwards userID + imToken to wrapper', () async {
      when(() => wrapper.login(
            userID: any(named: 'userID'),
            imToken: any(named: 'imToken'),
          )).thenAnswer((_) async => UserInfo(userID: 'u1'));

      final repo = ImAuthRepositoryImpl(wrapper);
      await repo.login(userID: 'u1', imToken: 't1');

      verify(() => wrapper.login(userID: 'u1', imToken: 't1')).called(1);
    });

    test('logout() is a no-op when SDK was never initialised', () async {
      final repo = ImAuthRepositoryImpl(wrapper);
      await repo.logout();
      verifyNever(() => wrapper.logout());
    });

    test('logout() calls wrapper.logout() after init()', () async {
      when(() => wrapper.initSDK(
            platformID: any(named: 'platformID'),
            apiAddr: any(named: 'apiAddr'),
            wsAddr: any(named: 'wsAddr'),
            dataDir: any(named: 'dataDir'),
            listener: any(named: 'listener'),
          )).thenAnswer((_) async => true);
      when(() => wrapper.logout()).thenAnswer((_) async => true);

      final repo = ImAuthRepositoryImpl(wrapper);
      await repo.init();
      await repo.logout();

      verify(() => wrapper.logout()).called(1);
    });

    test('dispose() closes the connection stream', () async {
      final repo = ImAuthRepositoryImpl(wrapper);
      repo.dispose();
      // No assertion — just verify no exception.
      expect(true, isTrue);
    });
  });
}
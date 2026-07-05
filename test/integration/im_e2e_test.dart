// test/integration/im_e2e_test.dart
//
// Phase 2.6 — End-to-end widget test for the IM flow.
//
// Tests the full widget pipeline that `auth_bloc.bootstrapIMAfterLogin`
// drives in production:
//   1. App boots with a mocked auth session
//   2. AuthBloc restores the session → fires `AppLoaded`
//      → AuthBloc bootstraps IM via `bootstrapIMAfterLogin`
//   3. Mocked ImAuthRepository emits an `ImConnectionEvent`
//   4. ConnectionCubit maps the event to a `ConnectionStatus`
//   5. HomePage renders the connection banner for non-`connected` states
//   6. Kicked-offline event also surfaces the banner (auto-logout is
//      exercised in test/modules/auth/data/auth_repository_impl_test.dart)
//
// These tests do NOT depend on the real backend or SDK — `ImAuthRepository`
// is mocked via `mocktail`. Goal: validate the widget pipeline, not the
// SDK or transport.

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pxshe_app/_core/di.dart';

import 'package:pxshe_app/_core/error/failures.dart';
import 'package:pxshe_app/modules/auth/bloc/auth_bloc.dart';
import 'package:pxshe_app/modules/auth/domain/auth_repository.dart';
import 'package:pxshe_app/modules/auth/domain/auth_usecases.dart';
import 'package:pxshe_app/modules/auth/domain/user.dart';
import 'package:pxshe_app/modules/im/bloc/connection_cubit.dart' as im;
import 'package:pxshe_app/modules/im/domain/im_auth_repository.dart';
import 'package:pxshe_app/_shared/features/home/page/home_page.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockImAuthRepository extends Mock implements ImAuthRepository {}

class _MockAuthUsecases extends Mock implements AuthUsecases {}

void main() {
  setUpAll(() {
    registerFallbackValue(User.empty);
    // Log.w is invoked by AuthBloc when IM bootstrap fails. Provide a
    // no-op logger so the test doesn't depend on Bootstrap.init().
    if (!di.isRegistered<Logger>()) {
      di.registerSingleton<Logger>(Logger(level: Level.error));
    }
  });

  late _MockAuthRepository authRepo;
  late _MockAuthUsecases authUsecases;
  late _MockImAuthRepository imAuthRepo;
  late StreamController<ImConnectionEvent> imEventController;
  late im.ConnectionCubit connectionCubit;
  late AuthBloc authBloc;

  setUp(() {
    authRepo = _MockAuthRepository();
    authUsecases = _MockAuthUsecases();
    imAuthRepo = _MockImAuthRepository();
    imEventController = StreamController<ImConnectionEvent>.broadcast();

    when(() => authUsecases.dispose()).thenReturn(null);
    when(() => authUsecases.userStream)
        .thenAnswer((_) => const Stream<User>.empty());
    when(() => authUsecases.loadCachedSession())
        .thenAnswer((_) async => null);
    when(() => authUsecases.logout()).thenAnswer((_) async {});
    when(() => authRepo.userStream)
        .thenAnswer((_) => const Stream<User>.empty());
    when(() => authRepo.chatToken).thenReturn('mock-chat-token');
    when(() => authRepo.imToken).thenReturn('mock-im-token');
    when(() => authRepo.userId).thenReturn('mock-user-id');
    when(() => authRepo.logout()).thenAnswer((_) async {});
    when(() => authRepo.login(
          areaCode: any(named: 'areaCode'),
          phoneNumber: any(named: 'phoneNumber'),
          password: any(named: 'password'),
          platform: any(named: 'platform'),
        )).thenAnswer((_) async => const Right<Failure, User>(User.empty));

    when(() => imAuthRepo.isInitialised).thenReturn(false);
    when(() => imAuthRepo.init()).thenAnswer((_) async {
      when(() => imAuthRepo.isInitialised).thenReturn(true);
    });
    when(() => imAuthRepo.login(
          userID: any(named: 'userID'),
          imToken: any(named: 'imToken'),
        )).thenAnswer((_) async {});
    when(() => imAuthRepo.logout()).thenAnswer((_) async {});
    when(() => imAuthRepo.connectionEvents)
        .thenAnswer((_) => imEventController.stream);

    connectionCubit = im.ConnectionCubit(imAuthRepo);
    authBloc = AuthBloc(userUsecase: authUsecases);
  });

  tearDown(() async {
    await connectionCubit.close();
    await authBloc.close();
    await imEventController.close();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<im.ConnectionCubit>.value(value: connectionCubit),
        ],
        child: child,
      ),
    );
  }

  Widget wrapHome() {
    return wrap(
      HomePage(
        repository: authRepo,
        connectionCubit: connectionCubit,
      ),
    );
  }

  group('ConnectionCubit', () {
    test('starts in initial state', () {
      expect(connectionCubit.state.status, im.ConnectionStatus.initial);
    });

    test('emits connected when ImAuthRepository pushes connected event',
        () async {
      final future = connectionCubit.stream
          .firstWhere((s) => s.status == im.ConnectionStatus.connected);
      imEventController.add(ImConnectionEvent.connected);
      final state = await future.timeout(const Duration(seconds: 2));
      expect(state.status, im.ConnectionStatus.connected);
    });

    test('emits disconnected when ImAuthRepository pushes disconnected event',
        () async {
      final future = connectionCubit.stream
          .firstWhere((s) => s.status == im.ConnectionStatus.disconnected);
      imEventController.add(ImConnectionEvent.disconnected);
      final state = await future.timeout(const Duration(seconds: 2));
      expect(state.status, im.ConnectionStatus.disconnected);
    });

    test('emits kickedOffline when ImAuthRepository pushes kickedOffline',
        () async {
      final future = connectionCubit.stream
          .firstWhere((s) => s.status == im.ConnectionStatus.kickedOffline);
      imEventController.add(ImConnectionEvent.kickedOffline);
      final state = await future.timeout(const Duration(seconds: 2));
      expect(state.status, im.ConnectionStatus.kickedOffline);
    });
  });

  group('HomePage connection banner', () {
    testWidgets('hides banner when connected', (tester) async {
      imEventController.add(ImConnectionEvent.connected);
      await tester.pump();

      await tester.pumpWidget(wrapHome());
      await tester.pump();

      expect(find.text('重连中…'), findsNothing);
      expect(find.text('已断开'), findsNothing);
      expect(find.text('已在其他设备登录'), findsNothing);
    });

    testWidgets('shows banner when disconnected', (tester) async {
      imEventController.add(ImConnectionEvent.disconnected);
      await tester.pump();

      await tester.pumpWidget(wrapHome());
      await tester.pump();

      expect(find.text('已断开'), findsOneWidget);
    });

    testWidgets('shows banner when kicked offline', (tester) async {
      imEventController.add(ImConnectionEvent.kickedOffline);
      await tester.pump();

      await tester.pumpWidget(wrapHome());
      await tester.pump();

      expect(find.text('已在其他设备登录'), findsOneWidget);
    });

    testWidgets(
      'transitions banner as ConnectionCubit emits new states',
      (tester) async {
        await tester.pumpWidget(wrapHome());
        await tester.pump();

        // Simulate the network dropping while the page is mounted.
        // `runAsync` lets the real stream event tick through the cubit
        // before the test framework resumes control.
        await tester.runAsync(() async {
          imEventController.add(ImConnectionEvent.disconnected);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
        await tester.pump();

        expect(find.text('已断开'), findsOneWidget);

        // Then the user gets kicked offline.
        await tester.runAsync(() async {
          imEventController.add(ImConnectionEvent.kickedOffline);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
        await tester.pump();

        expect(find.text('已在其他设备登录'), findsOneWidget);
        expect(find.text('已断开'), findsNothing);
      },
    );

    testWidgets('shows connecting banner during initial reconnect',
        (tester) async {
      imEventController.add(ImConnectionEvent.connecting);
      await tester.pump();

      await tester.pumpWidget(wrapHome());
      await tester.pump();

      expect(find.text('重连中…'), findsOneWidget);
    });
  });

  group('AuthBloc + IM bootstrap', () {
    test('AppLoaded with no cached session leaves status unauthenticated',
        () async {
      final future = authBloc.stream
          .firstWhere((s) => s.status == AuthStatus.unauthenticated);
      authBloc.add(AppLoaded());
      final state = await future.timeout(const Duration(seconds: 2));
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('AppLoaded with cached session marks authenticated', () async {
      when(() => authUsecases.loadCachedSession()).thenAnswer(
        (_) async => const User(
          id: 'cached',
          nickname: 'cached',
          phoneNumber: '',
          areaCode: '',
        ),
      );
      final future = authBloc.stream
          .firstWhere((s) => s.status == AuthStatus.authenticated);
      authBloc.add(AppLoaded());
      final state = await future.timeout(const Duration(seconds: 2));
      expect(state.status, AuthStatus.authenticated);
    });
  });
}

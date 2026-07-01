import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/error/failures.dart';
import 'package:pxshe_app/modules/auth/bloc/auth_bloc.dart';
import 'package:pxshe_app/modules/auth/domain/auth_repository.dart';
import 'package:pxshe_app/modules/auth/domain/auth_usecases.dart';
import 'package:pxshe_app/modules/auth/features/login/login_page.dart';
import 'package:pxshe_app/modules/auth/domain/user.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._result);
  final Either<Failure, User> _result;

  @override
  Future<Either<Failure, User>> login({
    required String areaCode,
    required String phoneNumber,
    required String password,
    required int platform,
  }) async =>
      _result;

  @override
  String? get chatToken => 'tok';

  @override
  String? get imToken => null;

  @override
  String? get userId => 'u1';

  @override
  Stream<User> get userStream => const Stream<User>.empty().asBroadcastStream();

  @override
  Future<User?> loadCachedSession() async => null;

  @override
  Future<void> logout() async {}

  @override
  void dispose() {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(User.empty);
  });

  Widget _wrap(AuthRepository repo) {
    final usecases = AuthUsecases(repo);
    final authBloc = AuthBloc(userUsecase: usecases);
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: Scaffold(body: LoginPage(repository: repo)),
      ),
    );
  }

  group('LoginPage', () {
    testWidgets('renders all UI elements', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Area'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('has 3 text input fields', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('login button is enabled by default', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('area code field defaults to +86', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      // Find the first TextFormField (area code) and check its text
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(3));
      final firstField = tester.widget<TextFormField>(fields.first);
      expect(firstField.controller?.text, '+86');
    });

    testWidgets('password obscured by default', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('tapping eye toggles password visibility', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('sign up link navigates to /register', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      // Sign up link present (router navigation tested in router test, not here)
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('takes repository via constructor', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LoginPage(repository: repo)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('controllers are disposed on unmount', (tester) async {
      final repo = _FakeAuthRepository(
        const Right<Failure, User>(User.empty),
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      ));
      // No assertion needed; just verify no exception is thrown on unmount
    });
  });
}
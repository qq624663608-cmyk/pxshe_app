import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pxshe_app/_core/error/api_exception.dart';
import 'package:pxshe_app/_core/error/error_handler.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('ErrorHandler.handle', () {
    testWidgets('handles non-ApiException', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(context, Exception('plain'));
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('handles string error', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(context, 'string error');
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('handles ApiException with tokenInvalid', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.tokenInvalid),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isTrue);
    });

    testWidgets('handles ApiException with kickedOffline', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.kickedOffline),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isTrue);
    });

    testWidgets('does not call onUnauthorized for non-auth errors',
        (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.passwordError),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isFalse);
    });

    testWidgets('isOnAuthPage suppresses auth navigation', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.tokenInvalid),
              isOnAuthPage: true,
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isTrue);
    });

    testWidgets('handles tokenMissing', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.tokenMissing),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isTrue);
    });

    testWidgets('handles tokenExpired', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.tokenExpired),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isTrue);
    });

    testWidgets('shows snack for non-auth errors', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(
                errorKey: ErrorKey.unknown,
                message: 'generic failure',
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('generic failure'), findsOneWidget);
    });
  });
}
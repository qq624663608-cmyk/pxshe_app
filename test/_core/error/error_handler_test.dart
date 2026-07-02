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

    testWidgets('handles ApiException with tokenKicked (1506)', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.tokenKicked),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isTrue);
    });

    testWidgets('handles noPermission (1002) as auth', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.noPermission),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isTrue);
    });

    testWidgets('handles forbidden (20012) as auth', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.forbidden),
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

    testWidgets('does not call onUnauthorized for business errors',
        (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.universeAlreadyExists),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isFalse);
    });

    testWidgets('isOnAuthPage suppresses snack but still triggers onUnauthorized',
        (tester) async {
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

    testWidgets('handles tokenExpired (1501)', (tester) async {
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

    testWidgets('handles tokenMalformed (1503)', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.tokenMalformed),
              onUnauthorized: () => unauthorizedCalled = true,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unauthorizedCalled, isTrue);
    });

    testWidgets('handles tokenNotExist (1507)', (tester) async {
      var unauthorizedCalled = false;
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) {
            ErrorHandler.handle(
              context,
              ApiException(errorKey: ErrorKey.tokenNotExist),
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
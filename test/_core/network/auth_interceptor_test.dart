import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/network/auth_interceptor.dart';

class _MockHandler extends Mock implements RequestInterceptorHandler {}

void main() {
  group('AuthInterceptor', () {
    test('adds token header when token provided', () async {
      String? token = 'test_token';
      final interceptor = AuthInterceptor(tokenProvider: () => token);
      final options = RequestOptions(path: '/test');
      final handler = _MockHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['token'], 'test_token');
    });

    test('skips when token is null', () async {
      final interceptor = AuthInterceptor(tokenProvider: () => null);
      final options = RequestOptions(path: '/test');
      final handler = _MockHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('token'), isFalse);
    });

    test('skips when token is empty', () async {
      final interceptor = AuthInterceptor(tokenProvider: () => '');
      final options = RequestOptions(path: '/test');
      final handler = _MockHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('token'), isFalse);
    });

    test('works without tokenProvider', () async {
      final interceptor = AuthInterceptor();
      final options = RequestOptions(path: '/test');
      final handler = _MockHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('token'), isFalse);
    });
  });
}
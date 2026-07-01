import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/network/auth_interceptor.dart';

class _MockHandler extends Mock implements RequestInterceptorHandler {}

void main() {
  group('AuthInterceptor', () {
    test('adds token header when token provided', () {
      String? token = 'test_token';
      final interceptor = AuthInterceptor(tokenProvider: () => token);
      final options = RequestOptions(path: '/test');
      final handler = _MockHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['token'], 'test_token');
    });

    test('skips when token is null', () {
      final interceptor = AuthInterceptor(tokenProvider: () => null);
      final options = RequestOptions(path: '/test');
      final handler = _MockHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('token'), isFalse);
    });

    test('skips when token is empty', () {
      final interceptor = AuthInterceptor(tokenProvider: () => '');
      final options = RequestOptions(path: '/test');
      final handler = _MockHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('token'), isFalse);
    });

    test('works without tokenProvider', () {
      final interceptor = AuthInterceptor();
      final options = RequestOptions(path: '/test');
      final handler = _MockHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('token'), isFalse);
    });
  });
}
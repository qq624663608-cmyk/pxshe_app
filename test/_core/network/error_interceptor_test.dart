import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/error/api_exception.dart';
import 'package:pxshe_app/_core/network/error_interceptor.dart';

class _MockHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  group('ErrorInterceptor', () {
    test('triggers onUnauthorized on 401', () {
      var unauthorizedCalled = false;
      final interceptor = ErrorInterceptor(
        onUnauthorized: () => unauthorizedCalled = true,
      );

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(err, _MockHandler());

      expect(unauthorizedCalled, isTrue);
    });

    test('does not trigger onUnauthorized on 500', () {
      var unauthorizedCalled = false;
      final interceptor = ErrorInterceptor(
        onUnauthorized: () => unauthorizedCalled = true,
      );

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(err, _MockHandler());

      expect(unauthorizedCalled, isFalse);
    });

    test('triggers onApiError with ApiException', () {
      ApiException? captured;
      final interceptor = ErrorInterceptor(
        onApiError: (e) => captured = e,
      );

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {'errorCode': 20001, 'errMsg': 'password error'},
        ),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(err, _MockHandler());

      expect(captured, isNotNull);
      expect(captured!.errorKey, ErrorKey.passwordError);
    });

    test('works without onApiError callback', () {
      final interceptor = ErrorInterceptor();
      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );
      interceptor.onError(err, _MockHandler());
    });
  });

  group('ErrorKey.fromCode', () {
    test('returns passwordError for 20001', () {
      expect(ErrorKey.fromCode(20001), ErrorKey.passwordError);
    });

    test('returns networkError for 6030', () {
      expect(ErrorKey.fromCode(6030), ErrorKey.networkError);
    });

    test('returns timeout for 6020', () {
      expect(ErrorKey.fromCode(6020), ErrorKey.timeout);
    });

    test('returns unknown for null', () {
      expect(ErrorKey.fromCode(null), ErrorKey.unknown);
    });

    test('returns tokenInvalid for 2xxx unknown', () {
      expect(ErrorKey.fromCode(2999), ErrorKey.tokenInvalid);
    });
  });
}
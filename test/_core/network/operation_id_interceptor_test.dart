import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/network/api_client.dart';
import 'package:pxshe_app/_core/network/operation_id_interceptor.dart';

class _MockRequestOptions extends Mock implements RequestOptions {}

void main() {
  group('OperationIdInterceptor', () {
    late OperationIdInterceptor interceptor;

    setUp(() {
      interceptor = OperationIdInterceptor();
    });

    test('generates operationID with biz-ts-rand format', () {
      final options = RequestOptions(path: '/account/login');
      final handler = _MockHandler();
      interceptor.onRequest(options, handler);

      final id = options.headers['operationID'] as String;
      expect(id, matches(RegExp(r'^[a-z-]+-\d+-\d{4}$')));
    });

    test('extracts biz from path segments', () {
      final options = RequestOptions(path: '/business/universe/list');
      final handler = _MockHandler();
      interceptor.onRequest(options, handler);

      final id = options.headers['operationID'] as String;
      expect(id, startsWith('business-universe-'));
    });

    test('handles single segment path', () {
      final options = RequestOptions(path: '/login');
      final handler = _MockHandler();
      interceptor.onRequest(options, handler);

      final id = options.headers['operationID'] as String;
      expect(id, startsWith('login-'));
    });

    test('handles root path', () {
      final options = RequestOptions(path: '/');
      final handler = _MockHandler();
      interceptor.onRequest(options, handler);

      expect(options.headers['operationID'], isNotNull);
    });
  });
}

class _MockHandler extends Mock implements RequestInterceptorHandler {}
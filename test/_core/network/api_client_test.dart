import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/network/api_client.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(Options());
  });

  group('ApiClient.default constructor', () {
    test('uses Env.apiBase for baseUrl', () {
      final client = ApiClient();
      expect(client.dio.options.baseUrl, isNotEmpty);
      expect(client.dio.options.baseUrl, startsWith('http'));
    });

    test('configures 10s connect timeout', () {
      final client = ApiClient();
      expect(client.dio.options.connectTimeout, const Duration(seconds: 10));
    });

    test('configures 30s receive timeout', () {
      final client = ApiClient();
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 30));
    });

    test('configures 10s send timeout', () {
      final client = ApiClient();
      expect(client.dio.options.sendTimeout, const Duration(seconds: 10));
    });

    test('sets contentType to application/json', () {
      final client = ApiClient();
      expect(client.dio.options.contentType, 'application/json');
    });

    test('sets responseType to json', () {
      final client = ApiClient();
      expect(client.dio.options.responseType, ResponseType.json);
    });

    test('adds AuthInterceptor and OperationIdInterceptor by default', () {
      final client = ApiClient();
      final types = client.dio.interceptors
          .map((i) => i.runtimeType.toString())
          .toSet();
      expect(types.contains('AuthInterceptor'), isTrue);
      expect(types.contains('OperationIdInterceptor'), isTrue);
    });

    test('does not add ErrorInterceptor when onUnauthorized is null', () {
      final client = ApiClient();
      final types = client.dio.interceptors
          .map((i) => i.runtimeType.toString())
          .toSet();
      expect(types.contains('ErrorInterceptor'), isFalse);
    });

    test('exposes dio getter', () {
      final client = ApiClient();
      expect(client.dio, isNotNull);
      expect(client.dio, isA<Dio>());
    });
  });

  group('ApiClient.with custom Dio', () {
    test('uses provided dio, not _buildDio', () {
      final dio = _MockDio();
      final client = ApiClient(dio: dio);
      expect(client.dio, equals(dio));
    });
  });

  group('ApiClient.get', () {
    test('calls dio.get with path', () async {
      final dio = _MockDio();
      when(() => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
        data: {'ok': true},
      ));

      final client = ApiClient(dio: dio);
      final res = await client.get('/test');
      expect(res.statusCode, 200);
      verify(() => dio.get<dynamic>(
        '/test',
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).called(1);
    });

    test('passes query params', () async {
      final dio = _MockDio();
      when(() => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
      ));

      final client = ApiClient(dio: dio);
      await client.get('/test', query: {'a': 1});
      verify(() => dio.get<dynamic>(
        '/test',
        queryParameters: {'a': 1},
        options: any(named: 'options'),
      )).called(1);
    });
  });

  group('ApiClient.post', () {
    test('calls dio.post with body', () async {
      final dio = _MockDio();
      when(() => dio.post<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/login'),
        statusCode: 200,
        data: {'errorCode': 0, 'data': {}},
      ));

      final client = ApiClient(dio: dio);
      final res = await client.post('/login', data: {'x': 1});
      expect(res.statusCode, 200);
      verify(() => dio.post<dynamic>(
        '/login',
        data: {'x': 1},
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).called(1);
    });
  });

  group('ApiClient.put', () {
    test('calls dio.put with body', () async {
      final dio = _MockDio();
      when(() => dio.put<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
      ));

      final client = ApiClient(dio: dio);
      await client.put('/x', data: {'y': 1});
      verify(() => dio.put<dynamic>(
        '/x',
        data: {'y': 1},
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).called(1);
    });
  });

  group('ApiClient.delete', () {
    test('calls dio.delete with body', () async {
      final dio = _MockDio();
      when(() => dio.delete<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
      ));

      final client = ApiClient(dio: dio);
      await client.delete('/x', data: {'z': 1});
      verify(() => dio.delete<dynamic>(
        '/x',
        data: {'z': 1},
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).called(1);
    });
  });

  group('ApiClient.with onUnauthorized', () {
    test('adds ErrorInterceptor when onUnauthorized provided', () {
      final client = ApiClient(onUnauthorized: () {});
      final types = client.dio.interceptors
          .map((i) => i.runtimeType.toString())
          .toSet();
      expect(types.contains('ErrorInterceptor'), isTrue);
    });
  });
}
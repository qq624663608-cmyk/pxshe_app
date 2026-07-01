import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pxshe_app/_core/error/api_exception.dart';

void main() {
  group('ErrorKey.fromCode', () {
    test('returns passwordError for 20001', () {
      expect(ErrorKey.fromCode(20001), ErrorKey.passwordError);
    });

    test('returns userNotFound for 20002', () {
      expect(ErrorKey.fromCode(20002), ErrorKey.userNotFound);
    });

    test('returns badRequest for 400', () {
      expect(ErrorKey.fromCode(400), ErrorKey.badRequest);
    });

    test('returns networkError for 6030', () {
      expect(ErrorKey.fromCode(6030), ErrorKey.networkError);
    });

    test('returns timeout for 6020', () {
      expect(ErrorKey.fromCode(6020), ErrorKey.timeout);
    });

    test('returns tokenInvalid for 2xxx unknown', () {
      expect(ErrorKey.fromCode(2999), ErrorKey.tokenInvalid);
    });

    test('returns unknown for null', () {
      expect(ErrorKey.fromCode(null), ErrorKey.unknown);
    });

    test('returns unknown for 0', () {
      expect(ErrorKey.fromCode(0), ErrorKey.unknown);
    });

    test('returns unknown for completely unknown code', () {
      expect(ErrorKey.fromCode(99999), ErrorKey.unknown);
    });
  });

  group('ErrorKey.fromStatusCode', () {
    test('401 -> tokenInvalid', () {
      expect(ErrorKey.fromStatusCode(401), ErrorKey.tokenInvalid);
    });
    test('403 -> forbidden', () {
      expect(ErrorKey.fromStatusCode(403), ErrorKey.forbidden);
    });
    test('400 -> badRequest', () {
      expect(ErrorKey.fromStatusCode(400), ErrorKey.badRequest);
    });
    test('503 -> serverUnavailable', () {
      expect(ErrorKey.fromStatusCode(503), ErrorKey.serverUnavailable);
    });
    test('502 -> serverUnavailable', () {
      expect(ErrorKey.fromStatusCode(502), ErrorKey.serverUnavailable);
    });
    test('504 -> serverUnavailable', () {
      expect(ErrorKey.fromStatusCode(504), ErrorKey.serverUnavailable);
    });
    test('null -> unknown', () {
      expect(ErrorKey.fromStatusCode(null), ErrorKey.unknown);
    });
    test('200 -> unknown', () {
      expect(ErrorKey.fromStatusCode(200), ErrorKey.unknown);
    });
  });

  group('ErrorKey.fromDioType', () {
    test('connectionTimeout -> timeout', () {
      expect(ErrorKey.fromDioType(DioExceptionType.connectionTimeout),
          ErrorKey.timeout);
    });
    test('sendTimeout -> timeout', () {
      expect(ErrorKey.fromDioType(DioExceptionType.sendTimeout),
          ErrorKey.timeout);
    });
    test('receiveTimeout -> timeout', () {
      expect(ErrorKey.fromDioType(DioExceptionType.receiveTimeout),
          ErrorKey.timeout);
    });
    test('unknown -> networkError', () {
      expect(ErrorKey.fromDioType(DioExceptionType.unknown),
          ErrorKey.networkError);
    });
    test('badCertificate -> unknown', () {
      expect(ErrorKey.fromDioType(DioExceptionType.badCertificate),
          ErrorKey.unknown);
    });
    test('cancel -> unknown', () {
      expect(ErrorKey.fromDioType(DioExceptionType.cancel), ErrorKey.unknown);
    });
    test('badResponse -> unknown', () {
      expect(ErrorKey.fromDioType(DioExceptionType.badResponse),
          ErrorKey.unknown);
    });
  });

  group('ApiException.fromResponse', () {
    test('extracts errorCode and errMsg from data', () {
      final res = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: {'errorCode': 20001, 'errMsg': 'bad password'},
      );
      final ex = ApiException.fromResponse(res);
      expect(ex.errorKey, ErrorKey.passwordError);
      expect(ex.errCode, 20001);
      expect(ex.message, 'bad password');
    });

    test('falls back to statusCode when no errorCode', () {
      final res = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 401,
        data: {},
      );
      final ex = ApiException.fromResponse(res);
      expect(ex.errorKey, ErrorKey.tokenInvalid);
      expect(ex.statusCode, 401);
    });

    test('uses default message when data is not Map', () {
      final res = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: 'plain string',
      );
      final ex = ApiException.fromResponse(res);
      expect(ex.errorKey, ErrorKey.unknown);
      expect(ex.message, isNotNull);
    });

    test('handles 200 success with errorCode 0', () {
      final res = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: {'errorCode': 0, 'data': {}},
      );
      final ex = ApiException.fromResponse(res);
      expect(ex.errorKey, ErrorKey.unknown);
    });
  });

  group('ApiException.fromDioError (no response)', () {
    test('handles connectionTimeout', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.timeout);
      expect(ex.message, '连接超时');
    });

    test('handles sendTimeout', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.sendTimeout,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.timeout);
      expect(ex.message, '发送超时');
    });

    test('handles receiveTimeout', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.timeout);
      expect(ex.message, '响应超时');
    });

    test('handles unknown (network)', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.unknown,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.networkError);
      expect(ex.message, '网络错误');
    });

    test('handles badCertificate', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badCertificate,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.unknown);
    });

    test('handles cancel', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.cancel,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.unknown);
      expect(ex.message, 'Request was cancelled');
    });

    test('handles badResponse (delegates to fromResponse)', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 200,
          data: {'errorCode': 20001, 'errMsg': 'pw error'},
        ),
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.passwordError);
      expect(ex.message, 'pw error');
    });
  });

  group('ApiException toString', () {
    test('uses message when present', () {
      final ex = ApiException(errorKey: ErrorKey.unknown, message: 'custom');
      expect(ex.toString(), 'custom');
    });

    test('falls back to errorKey name', () {
      final ex = ApiException(errorKey: ErrorKey.timeout);
      expect(ex.toString(), 'timeout');
    });
  });
}
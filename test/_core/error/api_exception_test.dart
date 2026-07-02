import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pxshe_app/_core/error/api_exception.dart';

void main() {
  group('ErrorKey.fromCode', () {
    test('returns unknown for null', () {
      expect(ErrorKey.fromCode(null), ErrorKey.unknown);
    });

    test('returns unknown for 0 (success)', () {
      expect(ErrorKey.fromCode(0), ErrorKey.unknown);
    });

    test('returns unknown for unmapped code', () {
      expect(ErrorKey.fromCode(99999), ErrorKey.unknown);
    });

    test('returns argsError for 1001', () {
      expect(ErrorKey.fromCode(1001), ErrorKey.argsError);
    });

    test('returns noPermission for 1002', () {
      expect(ErrorKey.fromCode(1002), ErrorKey.noPermission);
    });

    test('returns duplicateKey for 1003', () {
      expect(ErrorKey.fromCode(1003), ErrorKey.duplicateKey);
    });

    test('returns recordNotFound for 1004', () {
      expect(ErrorKey.fromCode(1004), ErrorKey.recordNotFound);
    });

    test('returns tokenExpired for 1501', () {
      expect(ErrorKey.fromCode(1501), ErrorKey.tokenExpired);
    });

    test('returns tokenInvalid for 1502', () {
      expect(ErrorKey.fromCode(1502), ErrorKey.tokenInvalid);
    });

    test('returns tokenKicked for 1506', () {
      expect(ErrorKey.fromCode(1506), ErrorKey.tokenKicked);
    });

    test('returns passwordError for 20001', () {
      expect(ErrorKey.fromCode(20001), ErrorKey.passwordError);
    });

    test('returns accountNotFound for 20002', () {
      expect(ErrorKey.fromCode(20002), ErrorKey.accountNotFound);
    });

    test('returns phoneAlreadyRegister for 20003', () {
      expect(ErrorKey.fromCode(20003), ErrorKey.phoneAlreadyRegister);
    });

    test('returns accountAlreadyRegister for 20004', () {
      expect(ErrorKey.fromCode(20004), ErrorKey.accountAlreadyRegister);
    });

    test('returns verifyCodeNotMatch for 20006', () {
      expect(ErrorKey.fromCode(20006), ErrorKey.verifyCodeNotMatch);
    });

    test('returns invitationNotFound for 20011', () {
      expect(ErrorKey.fromCode(20011), ErrorKey.invitationNotFound);
    });

    test('returns forbidden for 20012', () {
      expect(ErrorKey.fromCode(20012), ErrorKey.forbidden);
    });

    test('returns emailAlreadyRegister for 20014', () {
      expect(ErrorKey.fromCode(20014), ErrorKey.emailAlreadyRegister);
    });

    test('returns fileRequired for 3001', () {
      expect(ErrorKey.fromCode(3001), ErrorKey.fileRequired);
    });

    test('returns imUnavailable for 4001', () {
      expect(ErrorKey.fromCode(4001), ErrorKey.imUnavailable);
    });

    test('returns universeAlreadyExists for 5001', () {
      expect(ErrorKey.fromCode(5001), ErrorKey.universeAlreadyExists);
    });

    test('returns createFailed for 5003', () {
      expect(ErrorKey.fromCode(5003), ErrorKey.createFailed);
    });

    test('returns serverInternalError for 6001', () {
      expect(ErrorKey.fromCode(6001), ErrorKey.serverInternalError);
    });

    test('returns unknown for 7000 (no such section)', () {
      expect(ErrorKey.fromCode(7000), ErrorKey.unknown);
    });
  });

  group('ErrorKey.fromStatusCode', () {
    test('401 -> tokenInvalid', () {
      expect(ErrorKey.fromStatusCode(401), ErrorKey.tokenInvalid);
    });
    test('403 -> noPermission', () {
      expect(ErrorKey.fromStatusCode(403), ErrorKey.noPermission);
    });
    test('400 -> argsError', () {
      expect(ErrorKey.fromStatusCode(400), ErrorKey.argsError);
    });
    test('502 -> serverInternalError', () {
      expect(ErrorKey.fromStatusCode(502), ErrorKey.serverInternalError);
    });
    test('503 -> serverInternalError', () {
      expect(ErrorKey.fromStatusCode(503), ErrorKey.serverInternalError);
    });
    test('504 -> serverInternalError', () {
      expect(ErrorKey.fromStatusCode(504), ErrorKey.serverInternalError);
    });
    test('null -> unknown', () {
      expect(ErrorKey.fromStatusCode(null), ErrorKey.unknown);
    });
    test('200 -> unknown (not an error)', () {
      expect(ErrorKey.fromStatusCode(200), ErrorKey.unknown);
    });
  });

  group('ErrorKey.fromDioType', () {
    test('connectionTimeout -> unknown', () {
      expect(
        ErrorKey.fromDioType(DioExceptionType.connectionTimeout),
        ErrorKey.unknown,
      );
    });
    test('receiveTimeout -> unknown', () {
      expect(
        ErrorKey.fromDioType(DioExceptionType.receiveTimeout),
        ErrorKey.unknown,
      );
    });
    test('sendTimeout -> unknown', () {
      expect(
        ErrorKey.fromDioType(DioExceptionType.sendTimeout),
        ErrorKey.unknown,
      );
    });
    test('unknown -> unknown', () {
      expect(
        ErrorKey.fromDioType(DioExceptionType.unknown),
        ErrorKey.unknown,
      );
    });
    test('badCertificate -> unknown', () {
      expect(
        ErrorKey.fromDioType(DioExceptionType.badCertificate),
        ErrorKey.unknown,
      );
    });
  });

  group('ErrorKey.isAuthError', () {
    test('token errors (1501-1507) are auth', () {
      for (final code in [1501, 1502, 1503, 1504, 1505, 1506, 1507]) {
        final key = ErrorKey.fromCode(code);
        expect(key.isAuthError, isTrue, reason: 'code $code should be auth');
      }
    });

    test('noPermission (1002) is auth', () {
      expect(ErrorKey.noPermission.isAuthError, isTrue);
    });

    test('forbidden (20012) is auth', () {
      expect(ErrorKey.forbidden.isAuthError, isTrue);
    });

    test('business errors are NOT auth', () {
      expect(ErrorKey.universeAlreadyExists.isAuthError, isFalse);
      expect(ErrorKey.createFailed.isAuthError, isFalse);
    });

    test('validation errors are NOT auth', () {
      expect(ErrorKey.argsError.isAuthError, isFalse);
      expect(ErrorKey.passwordError.isAuthError, isFalse);
    });

    test('server errors are NOT auth (in new scheme)', () {
      expect(ErrorKey.serverInternalError.isAuthError, isFalse);
    });
  });

  group('ErrorKey constants', () {
    test('code matches backend errCode', () {
      expect(ErrorKey.argsError.code, 1001);
      expect(ErrorKey.noPermission.code, 1002);
      expect(ErrorKey.tokenKicked.code, 1506);
      expect(ErrorKey.passwordError.code, 20001);
      expect(ErrorKey.universeAlreadyExists.code, 5001);
      expect(ErrorKey.serverInternalError.code, 6001);
    });

    test('backendName matches OpenIM convention', () {
      expect(ErrorKey.argsError.backendName, 'ArgsError');
      expect(ErrorKey.tokenExpired.backendName, 'TokenExpiredError');
    });
  });

  group('ApiException.fromResponse', () {
    test('extracts errorCode and errMsg from data', () {
      final res = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: {
          'errCode': 20001,
          'errMsg': 'password error',
        },
      );
      final ex = ApiException.fromResponse(res);
      expect(ex.errorKey, ErrorKey.passwordError);
      expect(ex.errCode, 20001);
      expect(ex.message, 'password error');
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

    test('handles 200 success with errorCode 0', () {
      final res = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: {'errCode': 0, 'data': {}},
      );
      final ex = ApiException.fromResponse(res);
      expect(ex.errorKey, ErrorKey.unknown);
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

    test('handles 502 (server unavailable)', () {
      final res = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 502,
        data: null,
      );
      final ex = ApiException.fromResponse(res);
      expect(ex.errorKey, ErrorKey.serverInternalError);
    });
  });

  group('ApiException.fromDioError (no response)', () {
    test('handles connectionTimeout', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.unknown);
      expect(ex.message, '连接超时');
    });

    test('handles sendTimeout', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.sendTimeout,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.unknown);
      expect(ex.message, '发送超时');
    });

    test('handles receiveTimeout', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.unknown);
      expect(ex.message, '响应超时');
    });

    test('handles unknown (network)', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.unknown,
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.unknown);
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
      expect(ex.message, '请求被取消');
    });

    test('handles badResponse (delegates to fromResponse)', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 200,
          data: {
            'errCode': 20003,
            'errMsg': 'phone already register',
          },
        ),
      );
      final ex = ApiException.fromDioError(err);
      expect(ex.errorKey, ErrorKey.phoneAlreadyRegister);
      expect(ex.message, 'phone already register');
    });
  });

  group('ApiException toString', () {
    test('uses message when present', () {
      final ex = ApiException(errorKey: ErrorKey.unknown, message: 'custom');
      expect(ex.toString(), 'custom');
    });

    test('falls back to errorKey name', () {
      final ex = ApiException(errorKey: ErrorKey.tokenKicked);
      expect(ex.toString(), 'tokenKicked');
    });
  });
}
import 'package:dio/dio.dart';

enum ErrorKey {
  unknown(-1),
  tokenMissing(2006),
  tokenExpired(2005),
  tokenInvalid(2004),
  passwordError(20001),
  userNotFound(20002),
  accountBanned(2003),
  kickedOffline(2007),
  forbidden(2008),
  networkError(6030),
  timeout(6020),
  serverUnavailable(6010),
  badRequest(400);

  const ErrorKey(this.code);
  final int code;

  static ErrorKey fromCode(int? code) {
    if (code == null || code == 0) return ErrorKey.unknown;
    for (final k in ErrorKey.values) {
      if (k.code == code) return k;
    }
    if (code == 20001) return ErrorKey.passwordError;
    if (code == 20002) return ErrorKey.userNotFound;
    if (code == 400) return ErrorKey.badRequest;
    if (code >= 2000 && code < 3000) return ErrorKey.tokenInvalid;
    if (code == 6030) return ErrorKey.networkError;
    return ErrorKey.unknown;
  }

  static ErrorKey fromStatusCode(int? statusCode) {
    if (statusCode == null) return ErrorKey.unknown;
    if (statusCode == 401) return ErrorKey.tokenInvalid;
    if (statusCode == 403) return ErrorKey.forbidden;
    if (statusCode == 400) return ErrorKey.badRequest;
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return ErrorKey.serverUnavailable;
    }
    return ErrorKey.unknown;
  }

  static ErrorKey fromDioType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ErrorKey.timeout;
      case DioExceptionType.unknown:
        return ErrorKey.networkError;
      default:
        return ErrorKey.unknown;
    }
  }
}

class ApiException implements Exception {
  ApiException({
    required this.errorKey,
    this.errCode,
    this.message,
    this.statusCode,
  });

  factory ApiException.fromResponse(Response<dynamic> res) {
    final data = res.data;
    int? errCode;
    String? errMsg;
    if (data is Map) {
      errCode = data['errorCode'] as int?;
      errMsg = data['errMsg']?.toString();
    }
    final key = errCode != null
        ? ErrorKey.fromCode(errCode)
        : ErrorKey.fromStatusCode(res.statusCode);

    return ApiException(
      errorKey: key,
      errCode: errCode,
      message: errMsg ?? _defaultMessageFor(key, res.statusCode),
      statusCode: res.statusCode,
    );
  }

  factory ApiException.fromDioError(DioException err) {
    if (err.response != null) {
      return ApiException.fromResponse(err.response!);
    }
    final key = ErrorKey.fromDioType(err.type);
    return ApiException(
      errorKey: key,
      message: _defaultDioTypeMessage(err.type),
      statusCode: err.response?.statusCode,
    );
  }

  final ErrorKey errorKey;
  final int? errCode;
  final String? message;
  final int? statusCode;

  @override
  String toString() => message ?? errorKey.name;
}

String _defaultMessageFor(ErrorKey key, int? statusCode) {
  switch (key) {
    case ErrorKey.passwordError:
      return '账号或密码错误';
    case ErrorKey.userNotFound:
      return '用户不存在';
    case ErrorKey.accountBanned:
      return '账号已被封禁';
    case ErrorKey.tokenMissing:
    case ErrorKey.tokenExpired:
    case ErrorKey.tokenInvalid:
      return '登录已过期,请重新登录';
    case ErrorKey.kickedOffline:
      return '您的账号在另一台设备登录';
    case ErrorKey.forbidden:
      return '没有权限';
    case ErrorKey.networkError:
      return '网络错误';
    case ErrorKey.timeout:
      return '请求超时';
    case ErrorKey.serverUnavailable:
      return '服务暂不可用';
    case ErrorKey.badRequest:
      return '请求参数错误';
    case ErrorKey.unknown:
      return statusCode != null
          ? '操作失败 ($statusCode)'
          : '操作失败';
  }
}

String _defaultDioTypeMessage(DioExceptionType type) {
  switch (type) {
    case DioExceptionType.cancel:
      return 'Request was cancelled';
    case DioExceptionType.connectionTimeout:
      return '连接超时';
    case DioExceptionType.receiveTimeout:
      return '响应超时';
    case DioExceptionType.sendTimeout:
      return '发送超时';
    case DioExceptionType.badResponse:
      return '服务器错误';
    case DioExceptionType.unknown:
      return '网络错误';
    default:
      return '未知错误';
  }
}